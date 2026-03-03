package com.pcs.server.services;

import com.pcs.server.CloudinaryService;
import com.pcs.server.PostgresDatabase;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.Firestore;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.sql.*;
import java.util.*;
import java.util.Base64;
import java.util.stream.Collectors;

public class GuestService {
    private final Firestore db;
    private final byte[] keyBytes;
    private final CloudinaryService cloudinary;

    public GuestService(Firestore db, byte[] keyBytes, CloudinaryService cloudinary) {
        this.db = db; this.keyBytes = keyBytes; this.cloudinary = cloudinary;
    }

    public Map<String, Object> createGuest(Map<String, Object> body) throws Exception {
        long now = System.currentTimeMillis();
        String accessType = "TIME";
        Long expiresAt = null;
        Long maxUses = null;
        Object durationObj = body.get("duration");
        if (durationObj != null) {
            String duration = durationObj.toString();
            if ("permanent".equals(duration)) { accessType = "PERMANENT"; }
            else if ("one_time".equals(duration)) { accessType = "ONE_TIME"; maxUses = 1L; }
            else if (duration.startsWith("limit_")) {
                accessType = "LIMIT";
                try { maxUses = Long.parseLong(duration.split("_")[1]); } catch (Exception e) { maxUses = 1L; }
            } else {
                accessType = "TIME";
                long ms = 0;
                if (duration.equals("30m")) ms = 30*60*1000L;
                else if (duration.equals("4h")) ms = 4*60*60*1000L;
                else if (duration.equals("12h")) ms = 12*60*60*1000L;
                else if (duration.equals("24h")) ms = 24*60*60*1000L;
                else { try { ms = Long.parseLong(duration)*60*60*1000L; } catch (Exception e) {} }
                if (ms > 0) expiresAt = now + ms;
            }
        }
        String rawCode = String.format("%06d", new Random().nextInt(999999));
        String encCode = encrypt(rawCode);
        String qrUrl = null;
        try { qrUrl = cloudinary.generateAndUpload(rawCode, "guest_" + rawCode + "_" + now); }
        catch (Exception e) { System.err.println("[GuestService] Cloudinary skipped: " + e.getMessage()); }

        String hostUsername = body.getOrDefault("host_username", "").toString();
        String guestName    = body.getOrDefault("name", "Guest").toString();
        String duration2    = durationObj != null ? durationObj.toString() : "permanent";

        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO guests(name,host_username,generated_code,encrypted_code,qr_url,status,access_type,duration,max_uses,usage_count,timestamp,expires_at) " +
                     "VALUES(?,?,?,?,?,'ACTIVE',?,?,?,0,?,?) RETURNING id")) {
                ps.setString(1, guestName);
                ps.setString(2, hostUsername);
                ps.setString(3, rawCode);
                ps.setString(4, encCode);
                ps.setString(5, qrUrl);
                ps.setString(6, accessType);
                ps.setString(7, duration2);
                if (maxUses != null) ps.setLong(8, maxUses); else ps.setNull(8, Types.BIGINT);
                ps.setLong(9, now);
                if (expiresAt != null) ps.setLong(10, expiresAt); else ps.setNull(10, Types.BIGINT);
                ResultSet rs = ps.executeQuery();
                long id = rs.next() ? rs.getLong(1) : 0;
                Map<String, Object> resp = new HashMap<>(body);
                resp.put("id", id); resp.put("generated_code", rawCode); resp.put("qr_url", qrUrl);
                resp.put("encrypted_code", encCode); resp.put("status", "ACTIVE");
                return resp;
            }
        }
        // Firestore fallback
        if (db == null) throw new IllegalStateException("No database available");
        body.put("created_at", now); body.put("status", "ACTIVE"); body.put("usage_count", 0);
        if (expiresAt != null) body.put("expires_at", expiresAt);
        if (maxUses != null) body.put("max_uses", maxUses);
        body.put("access_type", accessType);
        body.put("encrypted_code", encCode);
        if (qrUrl != null) body.put("qr_url", qrUrl);
        ApiFuture<DocumentReference> future = db.collection("guests").add(body);
        DocumentReference ref = future.get();
        Map<String, Object> respMap = new HashMap<>(body);
        respMap.put("generated_code", rawCode); respMap.put("qr_url", qrUrl); respMap.put("id", ref.getId());
        return respMap;
    }

    public List<Map<String, Object>> getGuests(String hostUsername) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT id,name,host_username,generated_code,qr_url,status,access_type,duration,max_uses,usage_count,timestamp,expires_at FROM guests WHERE host_username=? ORDER BY timestamp DESC")) {
                ps.setString(1, hostUsername);
                ResultSet rs = ps.executeQuery();
                List<Map<String, Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("name", rs.getString("name"));
                    row.put("host_username", rs.getString("host_username"));
                    row.put("generated_code", rs.getString("generated_code"));
                    row.put("qr_url", rs.getString("qr_url"));
                    row.put("status", rs.getString("status"));
                    row.put("access_type", rs.getString("access_type"));
                    row.put("duration", rs.getString("duration"));
                    long mu = rs.getLong("max_uses"); if (!rs.wasNull()) row.put("max_uses", mu);
                    row.put("usage_count", rs.getInt("usage_count"));
                    row.put("timestamp", rs.getLong("timestamp"));
                    long exp = rs.getLong("expires_at"); if (!rs.wasNull()) row.put("expires_at", exp);
                    list.add(row);
                }
                return list;
            }
        }
        if (db == null) return new ArrayList<>();
        return db.collection("guests").whereEqualTo("host_username", hostUsername).get()
            .get().getDocuments().stream().map(d -> {
                Map<String, Object> m = new HashMap<>(d.getData()); m.put("id", d.getId()); return m;
            }).collect(Collectors.toList());
    }

    public Map<String, Object> verifyCode(String rawCode) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT id,name,host_username,status,access_type,max_uses,usage_count,expires_at FROM guests WHERE generated_code=?")) {
                ps.setString(1, rawCode);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) return null;
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getLong("id")); row.put("name", rs.getString("name"));
                row.put("host_username", rs.getString("host_username")); row.put("status", rs.getString("status"));
                row.put("access_type", rs.getString("access_type"));
                long mu = rs.getLong("max_uses"); if (!rs.wasNull()) row.put("max_uses", mu);
                row.put("usage_count", rs.getInt("usage_count"));
                long exp = rs.getLong("expires_at"); if (!rs.wasNull()) row.put("expires_at", exp);
                return row;
            }
        }
        if (db == null) return null;
        return db.collection("guests").whereEqualTo("encrypted_code", encrypt(rawCode)).get()
            .get().getDocuments().stream().findFirst().map(d -> {
                Map<String, Object> m = new HashMap<>(d.getData()); m.put("id", d.getId()); return m;
            }).orElse(null);
    }

    public void incrementUsage(Object id) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement("UPDATE guests SET usage_count=usage_count+1 WHERE id=?")) {
                ps.setLong(1, ((Number)id).longValue()); ps.executeUpdate();
            }
            return;
        }
        if (db == null) return;
        Map<String, Object> u = new HashMap<>();
        u.put("usage_count", com.google.cloud.firestore.FieldValue.increment(1));
        db.collection("guests").document(id.toString()).update(u).get();
    }

    public List<Map<String, Object>> getExpiredGuests() throws Exception {
        long now = System.currentTimeMillis();
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT id,name,host_username FROM guests WHERE expires_at IS NOT NULL AND expires_at<? AND status='ACTIVE'")) {
                ps.setLong(1, now);
                ResultSet rs = ps.executeQuery();
                List<Map<String, Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id")); row.put("name", rs.getString("name")); row.put("host_username", rs.getString("host_username")); list.add(row);
                }
                return list;
            }
        }
        if (db == null) return new ArrayList<>();
        return db.collection("guests").whereLessThan("expires_at", now).whereEqualTo("status","ACTIVE").get()
            .get().getDocuments().stream().map(d -> { Map<String, Object> m = new HashMap<>(d.getData()); m.put("id", d.getId()); return m; }).collect(Collectors.toList());
    }

    public void markGuestExpired(Object id) throws Exception {
        if (PostgresDatabase.isAvailable()) {
            try (Connection conn = PostgresDatabase.getConnection();
                 PreparedStatement ps = conn.prepareStatement("UPDATE guests SET status='EXPIRED' WHERE id=?")) {
                ps.setLong(1, ((Number)id).longValue()); ps.executeUpdate();
            }
            return;
        }
        if (db == null) return;
        Map<String, Object> u = new HashMap<>(); u.put("status","EXPIRED");
        db.collection("guests").document(id.toString()).update(u).get();
    }

    private String encrypt(String data) throws Exception {
        SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");
        Cipher cipher = Cipher.getInstance("AES");
        cipher.init(Cipher.ENCRYPT_MODE, key);
        return Base64.getEncoder().encodeToString(cipher.doFinal(data.getBytes()));
    }
}
