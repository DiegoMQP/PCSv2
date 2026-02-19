package com.pcs.server;

import com.pcs.server.services.CodeService;
import com.pcs.server.services.GuestService;
import com.pcs.server.services.NotificationService;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.QuerySnapshot;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class Scheduler {
    public static void startExpirationScheduler(GuestService guestService, CodeService codeService, NotificationService notifService) {
        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
        scheduler.scheduleAtFixedRate(() -> {
            try {
                long now = System.currentTimeMillis();

                ApiFuture<QuerySnapshot> guestQuery = Database.get().collection("guests")
                    .whereEqualTo("status", "ACTIVE")
                    .whereLessThan("expires_at", now)
                    .get();

                for (com.google.cloud.firestore.DocumentSnapshot doc : guestQuery.get().getDocuments()) {
                    doc.getReference().update("status", "EXPIRED");
                    String host = doc.getString("host_username");
                    String visitor = doc.getString("visitor_name");
                    if (host != null) {
                        notifService.addNotification(host, "El código de visita para " + visitor + " ha expirado.", "EXPIRATION");
                    }
                }

                ApiFuture<QuerySnapshot> codeQuery = Database.get().collection("fractionation_codes")
                    .whereEqualTo("status", "ACTIVE")
                    .whereLessThan("expires_at", now)
                    .get();

                for (com.google.cloud.firestore.DocumentSnapshot doc : codeQuery.get().getDocuments()) {
                    doc.getReference().delete();
                    String host = doc.getString("host_username");
                    String name = doc.getString("name");
                    if (host != null) {
                        notifService.addNotification(host, "El código personal '" + name + "' ha sido eliminado por expiración.", "EXPIRATION");
                    }
                }

            } catch (com.google.api.gax.rpc.FailedPreconditionException fpe) {
                // Firestore requires a composite index for some queries (e.g. equality + range).
                System.err.println("Firestore index required for scheduled query: " + fpe.getMessage());
                try {
                    java.util.regex.Matcher m = java.util.regex.Pattern
                        .compile("https?://[^\\s]*indexes\\?create_composite=[^\\s]+")
                        .matcher(fpe.getMessage());
                    if (m.find()) {
                        System.err.println("Create the index here: " + m.group());
                    }
                } catch (Exception ex) {
                    // ignore parsing issues
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, 1, 1, TimeUnit.MINUTES);
    }
}
