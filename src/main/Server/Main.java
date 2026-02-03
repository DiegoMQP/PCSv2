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

public class Main {
    private static Firestore db;

    public static void main(String[] args) {
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
        }).start(7070);

        // API Endpoints
        app.get("/health", ctx -> ctx.status(200).result("OK"));
        app.post("/register", Main::handleRegister);
        app.post("/login", Main::handleLogin);
        app.post("/codes", Main::handleSaveCode);
        app.post("/guests", Main::handleCreateGuest);
        
        System.out.println("Server started on port 7070");
    }

    // Register Handler
    private static void handleRegister(Context ctx) {
        @SuppressWarnings("unchecked")
        Map<String, String> body = ctx.bodyAsClass(Map.class);
        String username = body.get("username");
        String password = body.get("password");
        String location = body.get("location"); // New field

        if (username == null || password == null) {
            ctx.status(400).result("Missing username or password");
            return;
        }

        String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

        Map<String, Object> docData = new HashMap<>();
        docData.put("username", username);
        docData.put("password", hashedPassword);
        if (location != null) docData.put("location", location);

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
        
        if (visitorName == null || hostUsername == null) {
            ctx.status(400).result("Missing visitor name or host");
            return;
        }
        
        try {
           body.put("created_at", System.currentTimeMillis());
           body.put("status", "SCHEDULED"); // Default status

           // We let Firestore generate the ID or use a UUID
           ApiFuture<DocumentReference> future = db.collection("guests").add(body);
           DocumentReference ref = future.get();
           
           ctx.status(201).result("Guest registered with ID: " + ref.getId());
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
