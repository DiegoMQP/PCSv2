package com.pcs.server.services;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.DocumentReference;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;

import com.pcs.server.CloudinaryService;

public class GuestService {
    private final Firestore db;
    private final byte[] keyBytes;
    private final CloudinaryService cloudinary;

    public GuestService(Firestore db, byte[] keyBytes, CloudinaryService cloudinary) {
        this.db = db;
        this.keyBytes = keyBytes;
        this.cloudinary = cloudinary;
    }

    public Map<String, Object> createGuest(Map<String, Object> body) throws Exception {
        long now = System.currentTimeMillis();
        body.put("created_at", now);
        body.put("status", "ACTIVE");
        body.put("usage_count", 0);

        Long expiresAt = null;
        String accessType = "TIME";
        Long maxUses = null;

        Object durationObj = body.get("duration");
        if (durationObj != null) {
            String duration = durationObj.toString();
            if ("permanent".equals(duration)) {
                accessType = "PERMANENT";
            } else if ("one_time".equals(duration)) {
                accessType = "ONE_TIME";
                maxUses = 1L;
            } else if (duration.startsWith("limit_")) {
                accessType = "LIMIT";
                try { maxUses = Long.parseLong(duration.split("_")[1]); } catch (Exception e) { maxUses = 1L; }
            } else {
                accessType = "TIME";
                long millisToAdd = 0;
                if (duration.equals("30m")) millisToAdd = 30 * 60 * 1000L;
                else if (duration.equals("4h")) millisToAdd = 4 * 60 * 60 * 1000L;
                else if (duration.equals("12h")) millisToAdd = 12 * 60 * 60 * 1000L;
                else if (duration.equals("24h")) millisToAdd = 24 * 60 * 60 * 1000L;
                else {
                    try { millisToAdd = Long.parseLong(duration) * 60 * 60 * 1000L; } catch (Exception e) {}
                }
                if (millisToAdd > 0) expiresAt = now + millisToAdd;
            }
        }

        if (expiresAt != null) body.put("expires_at", expiresAt);
        if (maxUses != null) body.put("max_uses", maxUses);
        body.put("access_type", accessType);

        String rawCode = String.format("%06d", new Random().nextInt(999999));
        body.put("encrypted_code", encrypt(rawCode));
        // Generate QR image and upload to Cloudinary
        String qrUrl = cloudinary.generateAndUpload(rawCode, "guest_" + rawCode + "_" + System.currentTimeMillis());
        if (qrUrl != null) body.put("qr_url", qrUrl);

        ApiFuture<DocumentReference> future = db.collection("guests").add(body);
        DocumentReference ref = future.get();

        Map<String, Object> respMap = new HashMap<>(body);
        respMap.put("generated_code", rawCode);
        respMap.put("qr_url", qrUrl);
        respMap.put("id", ref.getId());
        return respMap;
    }

    public String encrypt(String data) {
        try {
            SecretKeySpec secretKey = new SecretKeySpec(keyBytes, "AES");
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.ENCRYPT_MODE, secretKey);
            return Base64.getEncoder().encodeToString(cipher.doFinal(data.getBytes()));
        } catch (Exception e) {
            return null;
        }
    }
}
