package com.grupo140.turnos.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.CreationTimestamp;

/**
 * Token de un solo uso para activación de cuenta y recuperación de contraseña (ver
 * detalles-flujos.md 7.1). Mapea la tabla física {@code user_token}.
 *
 * <p>{@code userId} se guarda como UUID plano, igual que el resto de las referencias del
 * dominio: la integridad la garantiza la FK de {@code user_token.user_id} en la migración.
 */
@Entity
@Table(name = "user_token")
public class UserToken {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    // Nunca se guarda el token en claro, solo su hash.
    @Column(name = "token_hash", nullable = false, unique = true)
    private String tokenHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TokenType type;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    // Nulo mientras no se usó. Al usarse se sella, garantizando el "un solo uso".
    @Column(name = "used_at")
    private Instant usedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected UserToken() {
        // JPA
    }

    public UserToken(UUID userId, String tokenHash, TokenType type, Instant expiresAt) {
        this.userId = userId;
        this.tokenHash = tokenHash;
        this.type = type;
        this.expiresAt = expiresAt;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getTokenHash() {
        return tokenHash;
    }

    public TokenType getType() {
        return type;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public Instant getUsedAt() {
        return usedAt;
    }

    public void markUsed(Instant usedAt) {
        this.usedAt = usedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
