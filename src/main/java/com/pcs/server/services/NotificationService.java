package com.pcs.server.services;

import com.pcs.server.PostgresDatabase;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;

import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

public class NotificationService {
    private final Firestore db;

    public NotificationService(Firestore db) {
        this.db = db;
    }

    public void addNotification(String username, String message, String type) {
        try {
            long now = System.currentTimeMillis();
            if (PostgresDatabase.isAvailable()) {
                try (Connection conn = PostgresDatabase.getConnection();
                     PreparedStatement ps = conn.prepareStatement(
                         "INSERT INTO notifications(username,type,title,message,read_status,timestamp) VALUES(?,?,?,?,false,?)")) {
                    ps.setString(1, username);
                    ps.setString(2, type);
                    ps.setString(3, type);
                    ps.setString(4, message);
                    ps.setLong(5, now);
                    ps.executeUpdate();
                }
                return;
            }
            Map<String, Object> notif = new HashMap<>();
            notif.put("host_username", username);
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

    public List<Map<String, Object>> getNotifications(String username) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT id,username,type,title,message,read_status,timestamp FROM notifications WHERE username=? ORDER BY timestamp DESC LIMIT 100")) {
                ps.setString(1, username);
                ResultSet rs = ps.executeQuery();
                List<Map<String, Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("username", rs.getString("username"));
                    row.put("type", rs.getString("type"));
                    row.put("title", rs.getString("title"));
                    row.put("message", rs.getString("message"));
                    row.put("read", rs.getBoolean("read_status"));
                    row.put("timestamp", rs.getLong("timestamp"));
                    list.add(row);
                }
                return list;
            }
        }
        return db.collection("notifications").whereEqualTo("host_username", username).get()
            .get().getDocuments().stream().map(d -> d.getData()).collect(Collectors.toList());
    }

    public void markAllRead(String username) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "UPDATE notifications SET read_status=true WHERE username=?")) {
                ps.setString(1, username);
                ps.executeUpdate();
            }
            return;
        }
        db.collection("notifications").whereEqualTo("host_username", username).get().get()
            .getDocuments().forEach(d -> d.getReference().update("read", true));
    }
}
