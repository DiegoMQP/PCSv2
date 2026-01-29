package Server;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import com.google.firebase.auth.UserRecord.CreateRequest;
import com.google.firebase.cloud.FirestoreClient;

import java.io.FileInputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.Scanner;
import java.util.concurrent.ExecutionException;

public class Main {

    private static Firestore db;
    private static FirebaseAuth auth;
    private static final String SERVICE_ACCOUNT_PATH = "src/main/Server/pcssec-c4bf5-firebase-adminsdk-fbsvc-3cc88fc220.json";

    public static void main(String[] args) {
        try {
            System.out.println("Iniciando Sistema PCS...");
            initializeFirebase();
            
            // Iniciar interfaz de consola para probar funcionalidades
            runCLI();
            
        } catch (Exception e) {
            System.err.println("Error en el sistema: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void initializeFirebase() throws IOException {
        FileInputStream serviceAccount = new FileInputStream(SERVICE_ACCOUNT_PATH);

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build();

        if (FirebaseApp.getApps().isEmpty()) {
            FirebaseApp.initializeApp(options);
            System.out.println("Firebase conectado exitosamente.");
        }
        
        db = FirestoreClient.getFirestore();
        auth = FirebaseAuth.getInstance();
    }

    private static void runCLI() {
        Scanner scanner = new Scanner(System.in);
        while (true) {
            System.out.println("\n--- PANEL DE CONTROL PCS ---");
            System.out.println("1. Registrar Usuario (SignUp)");
            System.out.println("2. Simular Login (Verificar Usuario)");
            System.out.println("3. Registrar Visitante y Generar Código");
            System.out.println("4. Salir");
            System.out.print("Seleccione una opción: ");

            String option = scanner.nextLine();

            switch (option) {
                case "1":
                    handleSignup(scanner);
                    break;
                case "2":
                    handleLoginCheck(scanner);
                    break;
                case "3":
                    handleVisitorRegistration(scanner);
                    break;
                case "4":
                    System.out.println("Cerrando sistema...");
                    return;
                default:
                    System.out.println("Opción inválida.");
            }
        }
    }

    // --- AUTENTICACIÓN ---

    private static void handleSignup(Scanner scanner) {
        System.out.println("\n--- REGISTRO DE USUARIO ---");
        System.out.print("Nombre completo: ");
        String name = scanner.nextLine();
        System.out.print("Correo electrónico: ");
        String email = scanner.nextLine();
        System.out.print("Contraseña: ");
        String password = scanner.nextLine();
        System.out.print("Código de Fraccionamiento: ");
        String condoCode = scanner.nextLine();

        try {
            CreateRequest request = new CreateRequest()
                    .setEmail(email)
                    .setEmailVerified(false)
                    .setPassword(password)
                    .setDisplayName(name)
                    .setDisabled(false);

            UserRecord userRecord = auth.createUser(request);
            System.out.println("Usuario creado exitosamente en Authentication: " + userRecord.getUid());

            // Guardar datos adicionales en Firestore
            Map<String, Object> userData = new HashMap<>();
            userData.put("uid", userRecord.getUid());
            userData.put("name", name);
            userData.put("email", email);
            userData.put("condoCode", condoCode);
            userData.put("role", "RESIDENT");
            userData.put("createdAt", new Date());

            db.collection("users").document(userRecord.getUid()).set(userData).get();
            System.out.println("Perfil de usuario guardado en Firestore.");

        } catch (Exception e) {
            System.err.println("Error al crear usuario: " + e.getMessage());
        }
    }

    private static void handleLoginCheck(Scanner scanner) {
        System.out.println("\n--- VERIFICACIÓN DE USUARIO (Simulación Login) ---");
        System.out.println("Nota: La validación de contraseña debe realizarse en el Cliente (App Móvil/Web).");
        System.out.print("Ingrese correo para verificar existencia: ");
        String email = scanner.nextLine();

        try {
            UserRecord userRecord = auth.getUserByEmail(email);
            System.out.println("Usuario encontrado: " + userRecord.getDisplayName() + " (UID: " + userRecord.getUid() + ")");
            // Aquí se consultaría Firestore para ver el código de fraccionamiento
        } catch (Exception e) {
            System.out.println("Usuario no encontrado o error: " + e.getMessage());
        }
    }

    // --- VISITANTES Y CÓDIGOS ---

    private static void handleVisitorRegistration(Scanner scanner) {
        System.out.println("\n--- REGISTRO DE VISITANTE ---");
        System.out.print("Nombre del Visitante: ");
        String visitorName = scanner.nextLine();
        System.out.print("Matrícula / Placa: ");
        String plate = scanner.nextLine();

        // Selección de duración
        System.out.println("Seleccione duración:");
        System.out.println("1. Minutos");
        System.out.println("2. Horas");
        System.out.println("3. Días");
        System.out.println("4. Semanas");
        System.out.println("5. Años");
        System.out.print("Opción: ");
        int typeInfo = Integer.parseInt(scanner.nextLine());
        
        System.out.print("Ingrese la cantidad (ej. 5): ");
        int amount = Integer.parseInt(scanner.nextLine());

        Date expireDate = calculateExpiration(typeInfo, amount);
        String code = generateAccessCode();

        Map<String, Object> visitData = new HashMap<>();
        visitData.put("visitorName", visitorName);
        visitData.put("plate", plate);
        visitData.put("accessCode", code);
        visitData.put("expiresAt", expireDate);
        visitData.put("createdAt", new Date());
        visitData.put("active", true);

        try {
            // Guardar visita en Firestore
            db.collection("visits").add(visitData).get();
            System.out.println("Visita registrada exitosamente.");
            System.out.println("===============================");
            System.out.println("CÓDIGO DE ACCESO: " + code);
            System.out.println("VÁLIDO HASTA: " + expireDate);
            System.out.println("===============================");
        } catch (InterruptedException | ExecutionException e) {
            System.err.println("Error al guardar visita: " + e.getMessage());
        }
    }

    private static String generateAccessCode() {
        Random rand = new Random();
        int code = 1000 + rand.nextInt(9000); // Código de 4 dígitos
        return String.valueOf(code);
    }

    private static Date calculateExpiration(int type, int amount) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime expiresAt = now;

        switch (type) {
            case 1: // Minutos
                expiresAt = now.plusMinutes(amount);
                break;
            case 2: // Horas
                expiresAt = now.plusHours(amount);
                break;
            case 3: // Días
                expiresAt = now.plusDays(amount);
                break;
            case 4: // Semanas
                expiresAt = now.plusWeeks(amount);
                break;
            case 5: // Años
                expiresAt = now.plusYears(amount);
                break;
            default:
                expiresAt = now.plusHours(4); // Default 4 horas
        }

        return Date.from(expiresAt.atZone(ZoneId.systemDefault()).toInstant());
    }
}
