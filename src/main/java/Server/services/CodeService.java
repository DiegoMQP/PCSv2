package com.pcs.server.services;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;

public class CodeService {
    private final Firestore db;

    public CodeService(Firestore db) {
        this.db = db;
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
        ApiFuture<WriteResult> future = db.collection("fractionation_codes").document(code).set(body);
        future.get();
    }

    public void deleteCode(String code) throws Exception {
        ApiFuture<WriteResult> future = db.collection("fractionation_codes").document(code).delete();
        future.get();
    }
}
