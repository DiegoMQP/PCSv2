package com.pcs.server;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.WriteResult;
import com.google.cloud.firestore.Firestore;

import com.pcs.server.Database;
import com.pcs.server.Scheduler;
import com.pcs.server.services.CodeService;
import com.pcs.server.services.GuestService;
import com.pcs.server.services.LogService;
import com.pcs.server.services.NotificationService;

import io.javalin.Javalin;
import io.javalin.http.Context;
import org.mindrot.jbcrypt.BCrypt;

import java.io.FileInputStream;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.Random;

public class Main {
    private static Firestore db;
    private static CodeService codeService;
    private static GuestService guestService;
    private static LogService logService;
    private static NotificationService notifService;
    // Simple 16-byte key for AES
    private static final byte[] KEY_BYTES = "PCS_SECURE_KEY_1".getBytes(); 

    public static void main(String[] args) {
        // Initialize Firebase (moved to Database wrapper)
        try {
            db = Database.init("src/main/Server/pcssec-c4bf5-firebase-adminsdk-fbsvc-3cc88fc220.json");
            System.out.println("Firebase initialized successfully via Database wrapper.");
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Failed to initialize Firebase.");
            return;
        }

        // Initialize Web Server
        Javalin app = Javalin.create(config -> {
            config.plugins.enableCors(cors -> {
                cors.add(it -> {
                    it.anyHost();
                });
            });
        }).start("127.0.0.1", 7070);

        // Initialize services
        codeService = new CodeService(db);
        guestService = new GuestService(db, KEY_BYTES);
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
        app.get("/notifications", Main::handleGetNotifications); // New Endpoint
        
        app.post("/register", Main::handleRegister);
        app.post("/login", Main::handleLogin);
        app.post("/codes", Main::handleSaveCode);
        app.delete("/codes", Main::handleDeleteCode);
        app.post("/guests", Main::handleCreateGuest);
        app.post("/verify-access", Main::handleVerifyAccess); // New Endpoint
        
        System.out.println("Server started on port 7070");
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
            db.collection("users").document(username).set(body).get();
            ctx.status(200).result("registered");
        } catch (Exception e) {
            ctx.status(500).result("Error registering user");
        }
    }

    private static void handleLogin(Context ctx) {
        ctx.status(501).result("Not implemented");
    }

    private static void handleSaveCode(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        String code = (body.get("code") != null) ? body.get("code").toString() : null;
        String username = (body.get("host_username") != null) ? body.get("host_username").toString() : ctx.queryParam("username");
        try {
            if (code == null) { ctx.status(400).result("code required"); return; }
            codeService.saveCode(body, code, username);
            ctx.status(200).result("saved");
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
            ctx.json(resp);
        } catch (Exception e) {
            ctx.status(500).result("Error creating guest");
        }
    }

}
