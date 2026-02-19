package com.pcs.server.services;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class LogService {
    private final Firestore db;

    public LogService(Firestore db) {
        this.db = db;
    }

    public List<Map<String, Object>> getLogs(String username) throws Exception {
        ApiFuture<QuerySnapshot> query = db.collection("guests")
            .whereEqualTo("host_username", username)
            .get();
        return query.get().getDocuments().stream().map(d -> d.getData()).collect(Collectors.toList());
    }

    public boolean createLog(Map<String, Object> log) {
        try {
            db.collection("access_logs").add(log).get();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}
