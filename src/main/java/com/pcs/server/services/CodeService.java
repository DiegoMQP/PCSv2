package com.pcs.server.services;

import com.pcs.server.CloudinaryService;
import com.pcs.server.PostgresDatabase;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;

import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

public class CodeService {
    private final Firestore db;
    private final CloudinaryService cloudinary;

    public CodeService(Firestore db, CloudinaryService cloudinary) {
        this.db = db;
        this.cloudinary = cloudinary;
    }

    public List<Map<String, Object>> getCodes(String username) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT code,name,host_username,status,duration,qr_url,timestamp,expires_at FROM codes WHERE host_username=? ORDER BY timestamp DESC")) {
                ps.setString(1, username);
                ResultSet rs = ps.executeQuery();
                List<Map<String, Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("code",          rs.getString("code"));
                    row.put("name",          rs.getString("name"));
                    row.put("host_username", rs.getString("host_username"));
                    row.put("status",        rs.getString("status"));
                    row.put("duration",      rs.getString("duration"));
                    row.put("qr_url",        rs.getString("qr_url"));
                    row.put("timestamp",     rs.getLong("timestamp"));
                    long exp = rs.getLong("expires_at");
                    if (!rs.wasNull()) row.put("expires_at", exp);
                    list.add(row);
                }
                return list;
            }
        }
        return db.collection("fractionation_codes").whereEqualTo("host_username", username).get()
            .get().getDocuments().stream().map(d -> {
                Map<String, Object> m = new HashMap<>(d.getData());
                m.put("code", d.getId());
                return m;
            }).collect(Collectors.toList());
    }

    public void saveCode(Map<String, Object> body, String code, String username) throws Exception {
        long now = System.currentTimeMillis();
        String name     = body.getOrDefault("name",     "Codigo").toString();
        String duration = body.getOrDefault("duration", "permanent").toString();
        Long expiresAt  = null;
        if (!"permanent".equals(duration)) {
            long millis = durationToMillis(duration);
            if (millis > 0) expiresAt = now + millis;
        }
        String qrUrl = null;
        try { qrUrl = cloudinary.generateAndUpload(code, "personal_" + code); }
        catch (Exception e) { System.err.println("[CodeService] Cloudinary skipped: " + e.getMessage()); }

        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO codes(code,name,host_username,status,duration,qr_url,timestamp,expires_at) " +
                     "VALUES(?,?,?,'ACTIVE',?,?,?,?) ON CONFLICT(code) DO UPDATE SET name=EXCLUDED.name,status='ACTIVE',duration=EXCLUDED.duration,qr_url=EXCLUDED.qr_url")) {
                ps.setString(1, code);
                ps.setString(2, name);
                ps.setString(3, username);
                ps.setString(4, duration);
                ps.setString(5, qrUrl);
                ps.setLong(6, now);
                if (expiresAt != null) ps.setLong(7, expiresAt); else ps.setNull(7, Types.BIGINT);
                ps.executeUpdate();
            }
            return;
        }
        body.put("code", code);
        body.put("timestamp", now);
        if (username != null) body.put("host_username", username);
        body.put("status", "ACTIVE");
        if (qrUrl != null) body.put("qr_url", qrUrl);
        db.collection("fractionation_codes").document(code).set(body).get();
    }

    public void deleteCode(String code) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement("DELETE FROM codes WHERE code=?")) {
                ps.setString(1, code); ps.executeUpdate();
            }
            return;
        }
        db.collection("fractionation_codes").document(code).delete().get();
    }

    public void updateCodeDuration(String code, Map<String, Object> updates) throws Exception {
        Object durationObj = updates.get("duration");
        if (durationObj == null) return;
        String duration = durationObj.toString();
        long now = System.currentTimeMillis();
        Long expiresAt = null;
        if (!"permanent".equals(duration)) {
            long millis = durationToMillis(duration);
            if (millis > 0) expiresAt = now + millis;
        }
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement("UPDATE codes SET duration=?,expires_at=? WHERE code=?")) {
                ps.setString(1, duration);
                if (expiresAt != null) ps.setLong(2, expiresAt); else ps.setNull(2, Types.BIGINT);
                ps.setString(3, code);
                ps.executeUpdate();
            }
            return;
        }
        Map<String, Object> fields = new HashMap<>();
        fields.put("duration", duration);
        if (expiresAt != null) fields.put("expires_at", expiresAt);
        else fields.put("expires_at", com.google.cloud.firestore.FieldValue.delete());
        db.collection("fractionation_codes").document(code).update(fields).get();
    }

    public Map<String, Object> findByCode(String code) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT code,name,host_username,status,duration,qr_url,timestamp,expires_at FROM codes WHERE code=?")) {
                ps.setString(1, code);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("code",          rs.getString("code"));
                    row.put("name",          rs.getString("name"));
                    row.put("host_username", rs.getString("host_username"));
                    row.put("status",        rs.getString("status"));
                    row.put("duration",      rs.getString("duration"));
                    row.put("qr_url",        rs.getString("qr_url"));
                    row.put("timestamp",     rs.getLong("timestamp"));
                    long exp = rs.getLong("expires_at"); if (!rs.wasNull()) row.put("expires_at", exp);
                    return row;
                }
                return null;
            }
        }
        com.google.cloud.firestore.DocumentSnapshot doc = db.collection("fractionation_codes").document(code).get().get();
        if (!doc.exists()) return null;
        Map<String, Object> data = new HashMap<>(doc.getData());
        data.put("code", doc.getId());
        return data;
    }

    public List<Map<String, Object>> getExpiredCodes() throws Exception {
        long now = System.currentTimeMillis();
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT code,name,host_username FROM codes WHERE expires_at IS NOT NULL AND expires_at<? AND status='ACTIVE'")) {
                ps.setLong(1, now);
                ResultSet rs = ps.executeQuery();
                List<Map<String, Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("code", rs.getString("code"));
                    row.put("name", rs.getString("name"));
                    row.put("host_username", rs.getString("host_username"));
                    list.add(row);
                }
                return list;
            }
        }
        return db.collection("fractionation_codes").whereLessThan("expires_at", now)
            .whereEqualTo("status", "ACTIVE").get().get().getDocuments().stream()
            .map(d -> { Map<String, Object> m = new HashMap<>(d.getData()); m.put("code", d.getId()); return m; })
            .collect(Collectors.toList());
    }

    public void markCodeExpired(String code) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement("UPDATE codes SET status='EXPIRED' WHERE code=?")) {
                ps.setString(1, code); ps.executeUpdate();
            }
            return;
        }
        Map<String, Object> u = new HashMap<>(); u.put("status", "EXPIRED");
        db.collection("fractionation_codes").document(code).update(u).get();
    }

    private static long durationToMillis(String duration) {
        if (duration == null) return 0;
        switch (duration) {
            case "30m": return 30L * 60 * 1000;
            case "4h":  return 4L  * 60 * 60 * 1000;
            case "24h": return 24L * 60 * 60 * 1000;
            case "1w":  return 7L  * 24 * 60 * 60 * 1000;
            default:    return 0;
        }
    }
}
