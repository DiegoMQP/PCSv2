package com.pcs.server.services;

import com.pcs.server.PostgresDatabase;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;

import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

public class LogService {
    private final Firestore db;

    public LogService(Firestore db) { this.db = db; }

    public List<Map<String, Object>> getLogs(String username) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT id,username,code,event_type,message,timestamp FROM logs WHERE username=? ORDER BY timestamp DESC LIMIT 200")) {
                ps.setString(1, username);
                ResultSet rs = ps.executeQuery();
                List<Map<String, Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id")); row.put("username", rs.getString("username"));
                    row.put("code", rs.getString("code")); row.put("event_type", rs.getString("event_type"));
                    row.put("message", rs.getString("message")); row.put("timestamp", rs.getLong("timestamp"));
                    list.add(row);
                }
                return list;
            }
        }
        if (db == null) return new ArrayList<>();
        ApiFuture<QuerySnapshot> query = db.collection("access_logs").whereEqualTo("username", username).get();
        return query.get().getDocuments().stream().map(d -> d.getData()).collect(Collectors.toList());
    }

    public boolean createLog(Map<String, Object> log) {
        try {
            long now = System.currentTimeMillis();
            String username   = log.getOrDefault("username", "").toString();
            String code       = log.containsKey("code") ? log.get("code").toString() : null;
            String eventType  = log.getOrDefault("event_type", "ACCESS").toString();
            String message    = log.containsKey("message") ? log.get("message").toString() : null;
            long ts = log.containsKey("timestamp") ? ((Number)log.get("timestamp")).longValue() : now;

            if (PostgresDatabase.isAvailable()) {
                try (Connection conn = PostgresDatabase.getConnection();
                     PreparedStatement ps = conn.prepareStatement(
                         "INSERT INTO logs(username,code,event_type,message,timestamp) VALUES(?,?,?,?,?)")) {
                    ps.setString(1, username);
                    if (code != null) ps.setString(2, code); else ps.setNull(2, Types.VARCHAR);
                    ps.setString(3, eventType);
                    if (message != null) ps.setString(4, message); else ps.setNull(4, Types.VARCHAR);
                    ps.setLong(5, ts);
                    ps.executeUpdate();
                    return true;
                }
            }
            if (db == null) return false;
            log.put("timestamp", ts);
            db.collection("access_logs").add(log).get();
            return true;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}
