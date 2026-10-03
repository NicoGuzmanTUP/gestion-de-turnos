package com.grupo140.turnos.auth;

/** Tipos de {@link UserToken}. Persistido como {@code varchar} + {@code CHECK} (ver esquema-bd.md). */
public enum TokenType {
    ACTIVATION,
    PASSWORD_RESET
}
