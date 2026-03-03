package com.pcs.server;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.Statement;

public class PostgresDatabase {

    private static HikariDataSource dataSource;

    private PostgresDatabase() {}

    public static boolean init() {
        String dbUrl = System.getenv("DATABASE_URL");
        if (dbUrl == null || dbUrl.isEmpty()) {
            System.out.println("[PostgresDB] DATABASE_URL not set — skipping PostgreSQL.");
            return false;
        }
        try {
            // Railway provides postgresql://user:pass@host:port/dbname
            // HikariCP needs jdbc:postgresql://...
            String jdbcUrl = dbUrl.startsWith("jdbc:") ? dbUrl
                    : dbUrl.replace("postgresql://", "jdbc:postgresql://");

            // Append sslmode=disable for Railway internal connections (no SSL needed)
            // This is safe: Railway internal network is already secure
            if (!jdbcUrl.contains("sslmode")) {
                jdbcUrl += (jdbcUrl.contains("?") ? "&" : "?") + "sslmode=disable";
            }

            HikariConfig config = new HikariConfig();
            config.setJdbcUrl(jdbcUrl);
            config.setMaximumPoolSize(10);
            config.setMinimumIdle(2);
            config.setConnectionTimeout(30_000);
            config.setIdleTimeout(600_000);
            config.setMaxLifetime(1_800_000);

            dataSource = new HikariDataSource(config);
            initSchema();
            System.out.println("[PostgresDB] Connected and schema initialized.");
            return true;
        } catch (Exception e) {
            System.err.println("[PostgresDB] Init failed: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public static Connection getConnection() throws Exception {
        if (dataSource == null) throw new IllegalStateException("PostgresDatabase not initialized");
        return dataSource.getConnection();
    }

    public static boolean isAvailable() {
        return dataSource != null;
    }

    private static void initSchema() throws Exception {
        try (Connection conn = dataSource.getConnection(); Statement st = conn.createStatement()) {
            st.execute(
                "CREATE TABLE IF NOT EXISTS users (" +
                "  username    VARCHAR(255) PRIMARY KEY," +
                "  password    TEXT NOT NULL," +
                "  name        VARCHAR(255)," +
                "  location    VARCHAR(255)," +
                "  role        VARCHAR(50)  DEFAULT 'user'," +
                "  created_at  BIGINT       DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT * 1000" +
                ")"
            );
            st.execute(
                "CREATE TABLE IF NOT EXISTS codes (" +
                "  code          VARCHAR(20)  PRIMARY KEY," +
                "  name          VARCHAR(255)," +
                "  host_username VARCHAR(255)," +
                "  status        VARCHAR(20)  DEFAULT 'ACTIVE'," +
                "  duration      VARCHAR(20)  DEFAULT 'permanent'," +
                "  qr_url        TEXT," +
                "  timestamp     BIGINT," +
                "  expires_at    BIGINT" +
                ")"
            );
            st.execute(
                "CREATE TABLE IF NOT EXISTS guests (" +
                "  id             SERIAL       PRIMARY KEY," +
                "  name           VARCHAR(255) NOT NULL," +
                "  host_username  VARCHAR(255)," +
                "  generated_code VARCHAR(20)," +
                "  encrypted_code TEXT," +
                "  qr_url         TEXT," +
                "  status         VARCHAR(20)  DEFAULT 'ACTIVE'," +
                "  access_type    VARCHAR(30)  DEFAULT 'TIME'," +
                "  duration       VARCHAR(20)," +
                "  max_uses       INTEGER," +
                "  usage_count    INTEGER      DEFAULT 0," +
                "  timestamp      BIGINT," +
                "  expires_at     BIGINT" +
                ")"
            );
            st.execute(
                "CREATE TABLE IF NOT EXISTS logs (" +
                "  id          SERIAL       PRIMARY KEY," +
                "  username    VARCHAR(255)," +
                "  code        VARCHAR(20)," +
                "  event_type  VARCHAR(50)," +
                "  message     TEXT," +
                "  timestamp   BIGINT       DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT * 1000" +
                ")"
            );
            st.execute(
                "CREATE TABLE IF NOT EXISTS notifications (" +
                "  id          SERIAL       PRIMARY KEY," +
                "  username    VARCHAR(255)," +
                "  type        VARCHAR(50)," +
                "  title       VARCHAR(255)," +
                "  message     TEXT," +
                "  read_status BOOLEAN      DEFAULT FALSE," +
                "  timestamp   BIGINT       DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT * 1000" +
                ")"
            );
        }
    }
}
