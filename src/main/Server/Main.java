package Server;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.WriteResult;

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
    // Simple 16-byte key for AES
    private static final byte[] KEY_BYTES = "PCS_SECURE_KEY_1".getBytes(); 

    public static void main(String[] args) {
        // ... (Firebase init updates below) 
        // Initialize Firebase
        try {
            InputStream serviceAccount = new FileInputStream("src/main/Server/pcssec-c4bf5-firebase-adminsdk-fbsvc-3cc88fc220.json");
            GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount);
            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(credentials)
                .build();
            FirebaseApp.initializeApp(options);
            db = FirestoreClient.getFirestore();
            System.out.println("Firebase initialized successfully.");
            
            // Start Expiration Checker
            startExpirationScheduler();
            
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
                ApiFuture<QuerySnapshot> query = db.collection("guests")
                    .whereEqualTo("status", "ACTIVE")
                    .whereLessThan("expires_at", now)
                    .get();
                
                for (com.google.cloud.firestore.DocumentSnapshot doc : query.get().getDocuments()) {
                     // Update status
                     doc.getReference().update("status", "EXPIRED");
                     
                     // Create Notification
                     String host = doc.getString("host_username");
                     String visitor = doc.getString("visitor_name");
                     
                     Map<String, Object> notif = new HashMap<>();
                     notif.put("host_username", host);
                     notif.put("message", "El código de acceso para " + visitor + " ha expirado.");
                     notif.put("timestamp", now);
                     notif.put("read", false);
                     notif.put("type", "EXPIRATION");
                     
                     db.collection("notifications").add(notif);
                     System.out.println("Expired code for guest: " + visitor);
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
            // Because we use determinstic encryption (same key, AES ECB default if not specified or just similiar logic), 
            // we can look up by encrypted string. In prod use hashing for lookup.
            String encrypted = encrypt(code);
            
            ApiFuture<QuerySnapshot> query = db.collection("guests")
                .whereEqualTo("encrypted_code", encrypted)
                .whereEqualTo("status", "ACTIVE")
                .get();
                
            if (!query.get().isEmpty()) {
                com.google.cloud.firestore.DocumentSnapshot doc = query.get().getDocuments().get(0);
                
                // Check usage limits
                String accessType = doc.getString("access_type");
                Long uses = doc.getLong("usage_count");
                Long maxUses = doc.getLong("max_uses");
                
                long currentUses = (uses != null) ? uses : 0;
                
                if (maxUses != null && currentUses >= maxUses) {
                     ctx.status(403).result("Code usage limit reached");
                     doc.getReference().update("status", "COMPLETED"); // Changed from EXPIRED to COMPLETED for limits
                     return;
                }
                
                // Increment usage
                doc.getReference().update("usage_count", currentUses + 1);
                
                // Handle One-Time expiration
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


    // Verify Location (Fraccionamiento Code)
    private static void handleVerifyLocation(Context ctx) {
        String code = ctx.queryParam("code");
        if (code == null || code.isEmpty()) {
            ctx.status(400).result("Missing code");
            return;
        }
        try {
            // Assume "fractionation_codes" contains valid location codes
            DocumentReference docRef = db.collection("fractionation_codes").document(code);
            if (docRef.get().get().exists()) {
                Map<String, Object> resp = new HashMap<>();
                resp.put("success", true);
                resp.put("message", "Code valid");
                ctx.status(200).json(resp);
            } else {
                Map<String, Object> resp = new HashMap<>();
                resp.put("success", false);
                resp.put("message", "Code invalid");
                ctx.status(404).json(resp);
            }
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).result("Error checking code");
        }
    }

    // Get Logs (Access History)
    private static void handleGetLogs(Context ctx) {
        String username = ctx.queryParam("username");
        if (username == null) {
            ctx.status(400).result("Missing username");
            return;
        }
        try {
            // Fetch guests associated with this host as a proxy for logs
            ApiFuture<QuerySnapshot> query = db.collection("guests")
                .whereEqualTo("host_username", username)
                .get();
            // In a real app, you might have a separate 'access_logs' collection
            ctx.json(query.get().getDocuments().stream().map(d -> d.getData()).collect(java.util.stream.Collectors.toList()));
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).result("Error fetching logs");
        }
    }

    // Get Alerts (Global or User specific)
    private static void handleGetAlerts(Context ctx) {
        // Return dummy alerts for now as requested "functional" but maybe no alert backend logic existed
        // Or fetch from 'alerts' collection
        try {
            ApiFuture<QuerySnapshot> query = db.collection("alerts").get(); 
            ctx.json(query.get().getDocuments().stream().map(d -> d.getData()).collect(java.util.stream.Collectors.toList()));
        } catch (Exception e) {
            // If collection doesn't exist, return empty
            ctx.json(java.util.Collections.emptyList());
        }
    }

    // Get Codes (My Codes)
    private static void handleGetCodes(Context ctx) {
         String username = ctx.queryParam("username");
         if (username == null) {
             ctx.status(400).result("Missing username");
             return;
         }
         try {
             ApiFuture<QuerySnapshot> query = db.collection("fractionation_codes")
                 .whereEqualTo("host_username", username)
                 .get();
             ctx.json(query.get().getDocuments().stream().map(d -> d.getData()).collect(java.util.stream.Collectors.toList()));
         } catch (Exception e) {
             ctx.status(500).result("Error fetching codes");
         }
    }

    // Register Handler
    private static void handleRegister(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, String> body = ctx.bodyAsClass(Map.class);
        String username = body.get("username");
        String password = body.get("password");
        String location = body.get("location");
        String name = body.get("name"); // New field for display name

        if (username == null || password == null) {
            ctx.status(400).result("Missing username or password");
            return;
        }

        String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

        Map<String, Object> docData = new HashMap<>();
        docData.put("username", username);
        docData.put("password", hashedPassword);
        if (location != null) docData.put("location", location);
        if (name != null) docData.put("name", name);

        try {
            // Check if user exists
             ApiFuture<QuerySnapshot> query = db.collection("users").whereEqualTo("username", username).get();
             if (!query.get().isEmpty()) {
                 ctx.status(409).result("User already exists");
                 return;
             }

            ApiFuture<WriteResult> future = db.collection("users").document(username).set(docData);
            future.get(); // wait for write
            ctx.status(201).result("User created");
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).result("Error registering user");
        }
    }

    // Login Handler
    private static void handleLogin(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, String> body = ctx.bodyAsClass(Map.class);
        String username = body.get("username");
        String password = body.get("password");

        if (username == null || password == null) {
            ctx.status(400).result("Missing username or password");
            return;
        }

        try {
            DocumentReference docRef = db.collection("users").document(username);
            ApiFuture<com.google.cloud.firestore.DocumentSnapshot> future = docRef.get();
            com.google.cloud.firestore.DocumentSnapshot document = future.get();

            if (document.exists()) {
                String storedHash = document.getString("password");
                if (BCrypt.checkpw(password, storedHash)) {
                    Map<String, Object> response = new HashMap<>();
                    response.put("username", username);
                    response.put("name", document.contains("name") ? document.getString("name") : username); // Return name or fallback
                    response.put("message", "Login successful");
                    // Add other fields if available in document, e.g. email, role
                    ctx.status(200).json(response);
                } else {
                    ctx.status(401).result("Invalid credentials");
                }
            } else {
                ctx.status(401).result("User not found");
            }
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).result("Error logging in");
        }
    }

    // Fractionation Codes Handler
    private static void handleSaveCode(Context ctx) {
        // Expected JSON: { "name": "...", "code": "...", "location": "...", "visitors": [...], "logs": [...] }
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        String code = (String) body.get("code");
        String name = (String) body.get("name");
        String username = (String) body.get("username"); // Added username check
        
        if (code == null || name == null) {
             ctx.status(400).result("Missing code, name");
             return;
        }

        try {
            // Add a timestamp for when this was saved
            body.put("timestamp", System.currentTimeMillis());
            if (username != null) body.put("host_username", username);
            
            // Assuming "codes" is the collection name for fractionation codes
            ApiFuture<WriteResult> future = db.collection("fractionation_codes").document(code).set(body);
            future.get();
            ctx.status(201).result("Code saved successfully");
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).result("Error saving code");
        }
    }

    // Guest Registration Handler
    private static void handleCreateGuest(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, Object> body = ctx.bodyAsClass(Map.class);
        String visitorName = (String) body.get("visitor_name");
        String hostUsername = (String) body.get("host_username");
        String duration = (String) body.get("duration"); // 30m, 4h, permanent, one_time, limit_5
        
        if (visitorName == null || hostUsername == null) {
            ctx.status(400).result("Missing visitor name or host");
            return;
        }
        
        try {
           long now = System.currentTimeMillis();
           body.put("created_at", now);
           body.put("status", "ACTIVE");
           body.put("usage_count", 0);
           
           // Calculate Expiration & Type
           Long expiresAt = null;
           String accessType = "TIME";
           Long maxUses = null;
           
           if (duration != null) {
               if (duration.equals("permanent")) {
                   accessType = "PERMANENT";
                   // No expiration
               } else if (duration.equals("one_time")) {
                   accessType = "ONE_TIME";
                   maxUses = 1L;
               } else if (duration.startsWith("limit_")) {
                   accessType = "LIMIT";
                   try {
                       maxUses = Long.parseLong(duration.split("_")[1]);
                   } catch (Exception e) { maxUses = 1L; }
               } else {
                   // Time based
                   accessType = "TIME";
                   long millisToAdd = 0;
                   if (duration.equals("30m")) millisToAdd = 30 * 60 * 1000L;
                   else if (duration.equals("4h")) millisToAdd = 4 * 60 * 60 * 1000L;
                   else if (duration.equals("12h")) millisToAdd = 12 * 60 * 60 * 1000L;
                   else if (duration.equals("24h")) millisToAdd = 24 * 60 * 60 * 1000L;
                   // Parse "Other" hours if possible
                   else {
                       try {
                           millisToAdd = Long.parseLong(duration) * 60 * 60 * 1000L;
                       } catch (Exception e) {}
                   }
                   
                   if (millisToAdd > 0) expiresAt = now + millisToAdd;
               }
           }
           
           if (expiresAt != null) body.put("expires_at", expiresAt);
           if (maxUses != null) body.put("max_uses", maxUses);
           body.put("access_type", accessType);

           // Generate Code (6 digits) and Encrypt
           String rawCode = String.format("%06d", new Random().nextInt(999999));
           body.put("encrypted_code", encrypt(rawCode));
           
           // Return the raw code ONLY ONCE to the user
           Map<String, Object> respMap = new HashMap<>(body);
           respMap.put("generated_code", rawCode);

           // We let Firestore generate the ID or use a UUID
           ApiFuture<DocumentReference> future = db.collection("guests").add(body);
           DocumentReference ref = future.get();
           
           ctx.status(201).json(respMap); // Send back generated code
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).result("Error creating guest");
        }
    }
    
    // Helper for testing
    public static String hashPassword(String password) {
        return BCrypt.hashpw(password, BCrypt.gensalt());
    }
    
    public static boolean checkPassword(String password, String hashed) {
        return BCrypt.checkpw(password, hashed);
    }
}
