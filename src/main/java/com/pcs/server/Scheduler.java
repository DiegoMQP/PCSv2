package com.pcs.server;

import com.pcs.server.services.CodeService;
import com.pcs.server.services.GuestService;
import com.pcs.server.services.NotificationService;

import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class Scheduler {
    public static void startExpirationScheduler(GuestService guestService, CodeService codeService, NotificationService notifService) {
        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
        scheduler.scheduleAtFixedRate(() -> {
            try {
                // Expire guests
                List<Map<String, Object>> expiredGuests = guestService.getExpiredGuests();
                for (Map<String, Object> guest : expiredGuests) {
                    try {
                        guestService.markGuestExpired(guest.get("id"));
                        String host = guest.get("host_username") != null ? guest.get("host_username").toString() : null;
                        String name = guest.get("name") != null ? guest.get("name").toString() : "Visita";
                        if (host != null) {
                            notifService.addNotification(host, "El código de visita para " + name + " ha expirado.", "EXPIRATION");
                        }
                    } catch (Exception e) {
                        System.err.println("Error expiring guest " + guest.get("id") + ": " + e.getMessage());
                    }
                }

                // Expire codes
                List<Map<String, Object>> expiredCodes = codeService.getExpiredCodes();
                for (Map<String, Object> code : expiredCodes) {
                    try {
                        codeService.markCodeExpired(code.get("code") != null ? code.get("code").toString() : "");
                        String host = code.get("host_username") != null ? code.get("host_username").toString() : null;
                        String name = code.get("name") != null ? code.get("name").toString() : "Código";
                        if (host != null) {
                            notifService.addNotification(host, "El código personal '" + name + "' ha expirado.", "EXPIRATION");
                        }
                    } catch (Exception e) {
                        System.err.println("Error expiring code " + code.get("code") + ": " + e.getMessage());
                    }
                }

            } catch (Exception e) {
                System.err.println("Scheduler error: " + e.getMessage());
            }
        }, 1, 1, TimeUnit.MINUTES);
    }
}
