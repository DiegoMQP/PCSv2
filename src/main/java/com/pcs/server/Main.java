package com.pcs.server;

import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

import org.mindrot.jbcrypt.BCrypt;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.pcs.server.services.CodeService;
import com.pcs.server.services.GuestService;
import com.pcs.server.services.LogService;
import com.pcs.server.services.NotificationService;

import io.javalin.Javalin;
import io.javalin.http.Context;

public class Main {
    private static Firestore db;
    private static CodeService codeService;
    private static GuestService guestService;
    private static LogService logService;
    private static NotificationService notifService;
    // Simple 16-byte key for AES
    private static final byte[] KEY_BYTES = "PCS_SECURE_KEY_1".getBytes(); 

    public static void main(String[] args) {
        // Start Javalin FIRST so /health responds immediately (Railway healthcheck)
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "7070"));
        Javalin app = Javalin.create(config -> {
            config.plugins.enableCors(cors -> {
                cors.add(it -> {
                    it.anyHost();
                });
            });
        }).start("0.0.0.0", port);

        // Initialize Firebase
        try {
            // Credentials path: env var takes priority (for Railway/production), fallback to bundled file
            String credPath = System.getenv().getOrDefault(
                "FIREBASE_CREDENTIALS_PATH",
                "src/main/Server/pcssec-c4bf5-firebase-adminsdk-fbsvc-f08fcbd987.json"
            );
            db = Database.init(credPath);
            System.out.println("Firebase initialized successfully via Database wrapper.");
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Failed to initialize Firebase. Server running without DB.");
        }

        // Initialize services
        CloudinaryService cloudinaryService = new CloudinaryService();
        codeService = new CodeService(db, cloudinaryService);
        guestService = new GuestService(db, KEY_BYTES, cloudinaryService);
        logService = new LogService(db);
        notifService = new NotificationService(db);

        // Start scheduler (expiration checks)
        Scheduler.startExpirationScheduler(guestService, codeService, notifService);

        // API Endpoints
        app.get("/health", ctx -> ctx.status(200).result("OK"));
        app.get("/verify-location", Main::handleVerifyLocation);
        app.get("/logs", Main::handleGetLogs);
        app.get("/alerts", Main::handleGetAlerts);
        app.get("/codes", Main::handleGetCodes);
        app.get("/notifications", Main::handleGetNotifications);
        
        app.post("/register", Main::handleRegister);
        app.post("/login", Main::handleLogin);
        app.post("/codes", Main::handleSaveCode);
        app.put("/codes", Main::handleUpdateCode);
        app.delete("/codes", Main::handleDeleteCode);
        app.post("/guests", Main::handleCreateGuest);
        app.get("/guests", Main::handleGetGuests);
        app.post("/verify-access", Main::handleVerifyAccess);
        app.get("/verify", Main::handleVerifyCode);

        // Admin endpoints
        app.get("/admin/users", Main::handleGetUsers);
        app.post("/admin/users", Main::handleCreateUser);
        app.put("/admin/users", Main::handleUpdateUser);
        app.delete("/admin/users", Main::handleDeleteUser);
        
        System.out.println("Server started on port 7070");
        seedAdminUser();
    }
    
    // --- Seed admin user ---
    private static void seedAdminUser() {
        try {
            com.google.cloud.firestore.DocumentSnapshot doc = db.collection("users").document("admin@admin.com").get().get();
            if (!doc.exists()) {
                Map<String, Object> admin = new HashMap<>();
                admin.put("username", "admin@admin.com");
                admin.put("name", "Administrador");
                admin.put("location", "Admin");
                admin.put("role", "admin");
                admin.put("password", BCrypt.hashpw("password", BCrypt.gensalt()));
                db.collection("users").document("admin@admin.com").set(admin).get();
                System.out.println("Admin user created: admin@admin.com");
            } else {
                System.out.println("Admin user already exists.");
            }
        } catch (Exception e) {
            System.err.println("Failed to seed admin user: " + e.getMessage());
        }
    }

    // --- Update Code (duration) ---
    private static void handleUpdateCode(Context ctx) {
        String code = ctx.queryParam("code");
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        try {
            if (code == null) { ctx.status(400).result("code required"); return; }
            codeService.updateCodeDuration(code, body);
            ctx.status(200).result("updated");
        } catch (Exception e) {
            ctx.status(500).result("Error updating code");
        }
    }

    // --- Unified Code Verifier ---
    private static void handleVerifyCode(Context ctx) {
        String code = ctx.queryParam("code");
        if (code == null || code.isEmpty()) {
            ctx.status(400).result("code required"); return;
        }
        try {
            // 1. Check fractionation_codes (Mis Codigos)
            com.google.cloud.firestore.DocumentSnapshot fracDoc =
                db.collection("fractionation_codes").document(code).get().get();
            if (fracDoc.exists() && "ACTIVE".equals(fracDoc.getString("status"))) {
                Long expiresAt = fracDoc.getLong("expires_at");
                if (expiresAt == null || expiresAt > System.currentTimeMillis()) {
                    Map<String, Object> resp = new HashMap<>(fracDoc.getData());
                    resp.put("valid", true);
                    resp.put("source", "personal");
                    resp.remove("password");
                    ctx.status(200).json(resp); return;
                }
            }
            // 2. Check guests collection (visitor codes via encrypted lookup)
            String encrypted = encrypt(code);
            if (encrypted != null) {
                ApiFuture<QuerySnapshot> query = db.collection("guests")
                    .whereEqualTo("encrypted_code", encrypted)
                    .whereEqualTo("status", "ACTIVE")
                    .get();
                java.util.List<com.google.cloud.firestore.QueryDocumentSnapshot> docs = query.get().getDocuments();
                if (!docs.isEmpty()) {
                    com.google.cloud.firestore.DocumentSnapshot guestDoc = docs.get(0);
                    Long expiresAt = guestDoc.getLong("expires_at");
                    if (expiresAt == null || expiresAt > System.currentTimeMillis()) {
                        Map<String, Object> resp = new HashMap<>();
                        resp.put("valid", true);
                        resp.put("source", "guest");
                        resp.put("name", guestDoc.getString("visitor_name"));
                        resp.put("host_username", guestDoc.getString("host_username"));
                        resp.put("access_type", guestDoc.getString("access_type"));
                        ctx.status(200).json(resp); return;
                    }
                }
            }
            ctx.status(404).json(Map.of("valid", false, "message", "Codigo invalido o expirado"));
        } catch (Exception e) {
            ctx.status(500).result("Error verifying code");
        }
    }

    // --- Scheduler for Expiration ---
    private static void startExpirationScheduler() {
        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
        scheduler.scheduleAtFixedRate(() -> {
            try {
                // Query active codes that have expired
                long now = System.currentTimeMillis();
                
                // 1. Check Guests
                ApiFuture<QuerySnapshot> query = db.collection("guests")
                    .whereEqualTo("status", "ACTIVE")
                    .whereLessThan("expires_at", now)
                    .get();
                
                for (com.google.cloud.firestore.DocumentSnapshot doc : query.get().getDocuments()) {
                     doc.getReference().update("status", "EXPIRED");
                     String host = doc.getString("host_username");
                     String visitor = doc.getString("visitor_name");
                     Map<String, Object> notif = new HashMap<>();
                     notif.put("host_username", host);
                     notif.put("message", "El código de visita para " + visitor + " ha expirado.");
                     notif.put("timestamp", now);
                     notif.put("read", false);
                     notif.put("type", "EXPIRATION");
                     if (host != null) db.collection("notifications").add(notif);
                }

                // 2. Check Fractionation Codes (My Codes)
                ApiFuture<QuerySnapshot> queryCodes = db.collection("fractionation_codes")
                    .whereEqualTo("status", "ACTIVE")
                    .whereLessThan("expires_at", now)
                    .get();
                
                for (com.google.cloud.firestore.DocumentSnapshot doc : queryCodes.get().getDocuments()) {
                     doc.getReference().delete(); // Or update to EXPIRED? "Eliminar" means delete usually.
                     
                     String host = doc.getString("host_username");
                     String name = doc.getString("name");
                     
                     Map<String, Object> notif = new HashMap<>();
                     notif.put("host_username", host);
                     notif.put("message", "El código personal '" + name + "' ha sido eliminado por expiración.");
                     notif.put("timestamp", now);
                     notif.put("read", false);
                     notif.put("type", "EXPIRATION");
                     if (host != null) db.collection("notifications").add(notif);
                }

            } catch (Exception e) {
                // e.printStackTrace(); 
            }
        }, 1, 1, TimeUnit.MINUTES);
    }
    
    // --- Encryption Helpers ---
    private static String encrypt(String data) {
        try {
            SecretKeySpec secretKey = new SecretKeySpec(KEY_BYTES, "AES");
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.ENCRYPT_MODE, secretKey);
            return Base64.getEncoder().encodeToString(cipher.doFinal(data.getBytes()));
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    // --- Endpoint Handlers ---

    // Get Notifications
    private static void handleGetNotifications(Context ctx) {
        String username = ctx.queryParam("username");
        try {
            ApiFuture<QuerySnapshot> query = db.collection("notifications")
                .whereEqualTo("host_username", username)
                .orderBy("timestamp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                .limit(20)
                .get();
            ctx.json(query.get().getDocuments().stream().map(d -> d.getData()).collect(java.util.stream.Collectors.toList()));
        } catch (Exception e) {
            ctx.status(500).result("Error fetching notifications");
        }
    }

    // Verify Access (Guard Logic)
    private static void handleVerifyAccess(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, String> body = ctx.bodyAsClass(Map.class);
        String code = body.get("code");
        
        try {
            String encrypted = encrypt(code);
            
            ApiFuture<QuerySnapshot> query = db.collection("guests")
                .whereEqualTo("encrypted_code", encrypted)
                .whereEqualTo("status", "ACTIVE")
                .get();
                
            if (!query.get().isEmpty()) {
                com.google.cloud.firestore.DocumentSnapshot doc = query.get().getDocuments().get(0);
                
                String accessType = doc.getString("access_type");
                Long uses = doc.getLong("usage_count");
                Long maxUses = doc.getLong("max_uses");
                
                long currentUses = (uses != null) ? uses : 0;
                
                if (maxUses != null && currentUses >= maxUses) {
                     ctx.status(403).result("Code usage limit reached");
                     doc.getReference().update("status", "COMPLETED");
                     return;
                }
                
                doc.getReference().update("usage_count", currentUses + 1);
                
                if ("ONE_TIME".equals(accessType) || (maxUses != null && currentUses + 1 >= maxUses)) {
                    doc.getReference().update("status", "COMPLETED");
                }
                
                ctx.status(200).result("Access Granted");
            } else {
                ctx.status(404).result("Invalid or Expired Code");
            }
        } catch (Exception e) {
            ctx.status(500).result("Error validating code");
        }
    }

    // --- Additional route handlers ---
    private static void handleVerifyLocation(Context ctx) {
        ctx.status(200).result("OK");
    }

    private static void handleGetLogs(Context ctx) {
        String username = ctx.queryParam("username");
        try {
            ctx.json(logService.getLogs(username));
        } catch (Exception e) {
            ctx.status(500).result("Error fetching logs");
        }
    }

    private static void handleGetAlerts(Context ctx) {
        String username = ctx.queryParam("username");
        try {
            ApiFuture<QuerySnapshot> query = db.collection("notifications")
                .whereEqualTo("host_username", username)
                .orderBy("timestamp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                .limit(20)
                .get();
            ctx.json(query.get().getDocuments().stream().map(d -> d.getData()).collect(java.util.stream.Collectors.toList()));
        } catch (Exception e) {
            ctx.status(500).result("Error fetching alerts");
        }
    }

    private static void handleGetCodes(Context ctx) {
        String username = ctx.queryParam("username");
        try {
            ctx.json(codeService.getCodes(username));
        } catch (Exception e) {
            ctx.status(500).result("Error fetching codes");
        }
    }

    private static void handleRegister(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        try {
            if (body.get("username") == null) { ctx.status(400).result("username required"); return; }
            String username = body.get("username").toString();
            // Hash password if provided
            if (body.get("password") != null) {
                String hashed = BCrypt.hashpw(body.get("password").toString(), BCrypt.gensalt());
                body.put("password", hashed);
            }
            db.collection("users").document(username).set(body).get();
            ctx.status(201).result("registered");
        } catch (Exception e) {
            ctx.status(500).result("Error registering user");
        }
    }

    private static void handleLogin(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        String username = (body.get("username") != null) ? body.get("username").toString() : null;
        String password = (body.get("password") != null) ? body.get("password").toString() : null;
        if (username == null || password == null) {
            ctx.status(400).result("username and password required");
            return;
        }
        try {
            // Buscar usuario en Firestore
            com.google.cloud.firestore.DocumentSnapshot userDoc = db.collection("users").document(username).get().get();
            if (!userDoc.exists()) {
                ctx.status(404).result("User not found");
                return;
            }
            String storedHash = userDoc.getString("password");
            if (storedHash == null) {
                ctx.status(500).result("User has no password set");
                return;
            }
            if (BCrypt.checkpw(password, storedHash)) {
                // Return user data as JSON
                Map<String, Object> userData = new HashMap<>();
                userData.put("username", username);
                Object name = userDoc.get("name");
                userData.put("name", name != null ? name : username);
                Object location = userDoc.get("location");
                if (location != null) userData.put("location", location);
                Object role = userDoc.get("role");
                userData.put("role", role != null ? role : "user");
                ctx.status(200).json(userData);
            } else {
                ctx.status(401).result("Invalid password");
            }
        } catch (Exception e) {
            ctx.status(500).result("Error during login");
        }
    }

    private static void handleSaveCode(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        String code = (body.get("code") != null) ? body.get("code").toString() : null;
        // Client may send 'username' or 'host_username'
        String username = null;
        if (body.get("host_username") != null) username = body.get("host_username").toString();
        else if (body.get("username") != null) username = body.get("username").toString();
        else username = ctx.queryParam("username");
        try {
            if (code == null) { ctx.status(400).result("code required"); return; }
            codeService.saveCode(body, code, username);
            ctx.status(201).result("saved");
        } catch (Exception e) {
            ctx.status(500).result("Error saving code");
        }
    }

    private static void handleDeleteCode(Context ctx) {
        String code = ctx.queryParam("code");
        try {
            if (code == null) { ctx.status(400).result("code required"); return; }
            codeService.deleteCode(code);
            ctx.status(200).result("deleted");
        } catch (Exception e) {
            ctx.status(500).result("Error deleting code");
        }
    }

    private static void handleCreateGuest(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        try {
            Map<String, Object> resp = guestService.createGuest(body);
            ctx.status(201).json(resp);  // 201 Created so clients can detect success
        } catch (Exception e) {
            ctx.status(500).result("Error creating guest");
        }
    }

    private static void handleGetGuests(Context ctx) {
        String username = ctx.queryParam("username");
        try {
            com.google.api.core.ApiFuture<QuerySnapshot> query = db.collection("guests")
                .whereEqualTo("host_username", username)
                .limit(50)
                .get();
            ctx.json(query.get().getDocuments().stream().map(d -> d.getData()).collect(java.util.stream.Collectors.toList()));
        } catch (Exception e) {
            ctx.status(500).result("Error fetching guests");
        }
    }

    // --- Admin User Management ---

    private static void handleGetUsers(Context ctx) {
        try {
            com.google.api.core.ApiFuture<com.google.cloud.firestore.QuerySnapshot> query =
                db.collection("users").get();
            java.util.List<Map<String, Object>> users = query.get().getDocuments().stream()
                .map(d -> {
                    Map<String, Object> data = new HashMap<>(d.getData());
                    data.remove("password"); // Never expose passwords
                    data.put("username", d.getId());
                    return data;
                })
                .collect(java.util.stream.Collectors.toList());
            ctx.json(users);
        } catch (Exception e) {
            ctx.status(500).result("Error fetching users");
        }
    }

    private static void handleCreateUser(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        try {
            if (body.get("username") == null) { ctx.status(400).result("username required"); return; }
            String username = body.get("username").toString();
            if (body.get("password") != null) {
                String hashed = BCrypt.hashpw(body.get("password").toString(), BCrypt.gensalt());
                body.put("password", hashed);
            }
            if (body.get("role") == null) body.put("role", "user");
            db.collection("users").document(username).set(body).get();
            // Return user without password
            body.remove("password");
            ctx.status(201).json(body);
        } catch (Exception e) {
            ctx.status(500).result("Error creating user: " + e.getMessage());
        }
    }

    private static void handleUpdateUser(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        String username = ctx.queryParam("username");
        try {
            if (username == null || username.isEmpty()) {
                ctx.status(400).result("username required"); return;
            }
            com.google.cloud.firestore.DocumentSnapshot existing =
                db.collection("users").document(username).get().get();
            if (!existing.exists()) {
                ctx.status(404).result("User not found"); return;
            }
            String newUsername = body.get("new_username") != null ? body.get("new_username").toString().trim() : null;
            // Build updates map
            Map<String, Object> updates = new HashMap<>(existing.getData());
            if (body.get("name")     != null) updates.put("name",     body.get("name").toString().trim());
            if (body.get("location") != null) updates.put("location", body.get("location").toString().trim());
            if (body.get("role")     != null) updates.put("role",     body.get("role").toString().trim());
            if (body.get("password") != null && !body.get("password").toString().isEmpty()) {
                String hashed = BCrypt.hashpw(body.get("password").toString(), BCrypt.gensalt());
                updates.put("password", hashed);
            }
            if (newUsername != null && !newUsername.isEmpty() && !newUsername.equals(username)) {
                // Username (doc ID) change: create new doc, delete old
                updates.put("username", newUsername);
                db.collection("users").document(newUsername).set(updates).get();
                db.collection("users").document(username).delete().get();
            } else {
                db.collection("users").document(username).set(updates).get();
            }
            updates.remove("password");
            ctx.status(200).json(updates);
        } catch (Exception e) {
            ctx.status(500).result("Error updating user: " + e.getMessage());
        }
    }

    private static void handleDeleteUser(Context ctx) {
        String username = ctx.queryParam("username");
        try {
            if (username == null) { ctx.status(400).result("username required"); return; }
            db.collection("users").document(username).delete().get();
            ctx.status(200).result("deleted");
        } catch (Exception e) {
            ctx.status(500).result("Error deleting user");
        }
    }

}
