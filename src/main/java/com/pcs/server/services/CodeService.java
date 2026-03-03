package com.pcs.server.services;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import com.pcs.server.CloudinaryService;

public class CodeService {
    private final Firestore db;
    private final CloudinaryService cloudinary;

    public CodeService(Firestore db, CloudinaryService cloudinary) {
        this.db = db;
        this.cloudinary = cloudinary;
    }

    public List<Map<String, Object>> getCodes(String username) throws Exception {
        ApiFuture<QuerySnapshot> query = db.collection("fractionation_codes")
            .whereEqualTo("host_username", username)
            .get();
        return query.get().getDocuments().stream().map(d -> d.getData()).collect(Collectors.toList());
    }

    public void saveCode(Map<String, Object> body, String code, String username) throws Exception {
        long now = System.currentTimeMillis();
        body.put("timestamp", now);
        if (username != null) body.put("host_username", username);
        body.put("status", "ACTIVE");
        // Generate QR image and upload to Cloudinary
        String qrUrl = cloudinary.generateAndUpload(code, "personal_" + code);
        if (qrUrl != null) body.put("qr_url", qrUrl);
        ApiFuture<WriteResult> future = db.collection("fractionation_codes").document(code).set(body);
        future.get();
    }

    public void deleteCode(String code) throws Exception {
        ApiFuture<WriteResult> future = db.collection("fractionation_codes").document(code).delete();
        future.get();
    }

    public void updateCodeDuration(String code, Map<String, Object> updates) throws Exception {
        long now = System.currentTimeMillis();
        Map<String, Object> fields = new java.util.HashMap<>();
        Object durationObj = updates.get("duration");
        if (durationObj != null) {
            String duration = durationObj.toString();
            fields.put("duration", duration);
            if ("permanent".equals(duration)) {
                // Remove expires_at by setting null — Firestore: delete the field
                fields.put("expires_at", com.google.cloud.firestore.FieldValue.delete());
            } else {
                long millisToAdd = 0;
                if (duration.equals("30m"))  millisToAdd = 30 * 60 * 1000L;
                else if (duration.equals("4h"))  millisToAdd = 4 * 60 * 60 * 1000L;
                else if (duration.equals("24h")) millisToAdd = 24 * 60 * 60 * 1000L;
                else if (duration.equals("1w"))  millisToAdd = 7 * 24 * 60 * 60 * 1000L;
                if (millisToAdd > 0) fields.put("expires_at", now + millisToAdd);
            }
        }
        if (!fields.isEmpty()) {
            db.collection("fractionation_codes").document(code).update(fields).get();
        }
    }
}
