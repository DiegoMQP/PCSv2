package com.pcs.server;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;

import java.io.ByteArrayOutputStream;
import java.util.EnumMap;
import java.util.Map;

public class CloudinaryService {

    private final Cloudinary cloudinary;

    public CloudinaryService() {
        String cloudName = System.getenv().getOrDefault("CLOUDINARY_CLOUD_NAME", "pcs");
        String apiKey    = System.getenv().getOrDefault("CLOUDINARY_API_KEY",    "653746155777456");
        String apiSecret = System.getenv().getOrDefault("CLOUDINARY_API_SECRET", "y2GPBVa5lBBxUZ4d1r6MO2fE5gE");

        cloudinary = new Cloudinary(ObjectUtils.asMap(
            "cloud_name", cloudName,
            "api_key",    apiKey,
            "api_secret", apiSecret,
            "secure",     true
        ));
    }

    /**
     * Generates a QR code PNG for {@code data} and uploads it to Cloudinary.
     * @param data      the content to encode (the 6-digit access code)
     * @param publicId  stable Cloudinary public_id so the same code always overwrites
     * @return          secure HTTPS URL of the uploaded image, or null on error
     */
    public String generateAndUpload(String data, String publicId) {
        try {
            byte[] pngBytes = renderQrPng(data, 400);

            @SuppressWarnings("unchecked")
            Map<String, Object> result = cloudinary.uploader().upload(pngBytes, ObjectUtils.asMap(
                "public_id",  "pcs_qr/" + publicId,
                "overwrite",  true,
                "format",     "png",
                "resource_type", "image"
            ));
            return (String) result.get("secure_url");
        } catch (Exception e) {
            System.err.println("[Cloudinary] Upload failed for " + publicId + ": " + e.getMessage());
            return null;
        }
    }

    // ── internal QR renderer ──────────────────────────────────────────────────
    private byte[] renderQrPng(String content, int size) throws Exception {
        EnumMap<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
        hints.put(EncodeHintType.MARGIN, 2);
        hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");

        QRCodeWriter writer = new QRCodeWriter();
        BitMatrix matrix = writer.encode(content, BarcodeFormat.QR_CODE, size, size, hints);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        MatrixToImageWriter.writeToStream(matrix, "PNG", baos);
        return baos.toByteArray();
    }
}
