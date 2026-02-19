package com.pcs.server;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;

import java.io.FileInputStream;
import java.io.InputStream;

public final class Database {
    private static Firestore db;

    private Database() {}

    public static Firestore init(String credentialsPath) throws Exception {
        if (db != null) return db;
        InputStream serviceAccount = new FileInputStream(credentialsPath);
        GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount);
        FirebaseOptions options = FirebaseOptions.builder()
            .setCredentials(credentials)
            .build();
        FirebaseApp.initializeApp(options);
        db = FirestoreClient.getFirestore();
        return db;
    }

    public static Firestore get() {
        return db;
    }
}
