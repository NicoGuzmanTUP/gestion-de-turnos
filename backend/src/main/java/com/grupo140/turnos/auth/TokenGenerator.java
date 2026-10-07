package com.grupo140.turnos.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import org.springframework.stereotype.Component;

/**
 * Genera los tokens de un solo uso de activación y recuperación de contraseña (US-03.4, US-03.7).
 *
 * <p>El valor en claro existe una sola vez, al armar el link; en {@code user_token.token_hash} se guarda
 * su SHA-256 (ver arquitectura.md). Se usa SHA-256 y no BCrypt porque el token entrante se busca por su
 * hash ({@code token_hash} es {@code UNIQUE}), y BCrypt da un hash distinto en cada llamada. Con 256 bits
 * aleatorios no hace falta un hash lento: no hay diccionario contra el que probar.
 */
@Component
public class TokenGenerator {

    private static final int TOKEN_BYTES = 32;

    private final SecureRandom random = new SecureRandom();

    public GeneratedToken generate() {
        byte[] bytes = new byte[TOKEN_BYTES];
        random.nextBytes(bytes);
        // base64url sin padding: viaja en la URL del link sin escapar nada.
        String plainValue = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        return new GeneratedToken(plainValue, hash(plainValue));
    }

    // Hex de 64 caracteres; entra en token_hash varchar(100).
    public String hash(String plainValue) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(plainValue.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            // Toda JVM está obligada a soportar SHA-256.
            throw new IllegalStateException(e);
        }
    }

    /** Token recién generado: {@code plainValue} va al link, {@code hash} a la base. */
    public record GeneratedToken(String plainValue, String hash) {}
}
