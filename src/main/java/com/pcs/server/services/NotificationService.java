package com.pcs.server.services;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;

import java.util.HashMap;
import java.util.Map;

public class NotificationService {
    private final Firestore db;

    public NotificationService(Firestore db) {
        this.db = db;
    }

    public void addNotification(String hostUsername, String message, String type) {
        try {
            long now = System.currentTimeMillis();
            Map<String, Object> notif = new HashMap<>();
            notif.put("host_username", hostUsername);
            notif.put("message", message);
            notif.put("timestamp", now);
            notif.put("read", false);
            notif.put("type", type);
            ApiFuture<?> f = db.collection("notifications").add(notif);
            f.get();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
