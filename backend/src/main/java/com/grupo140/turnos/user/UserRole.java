package com.grupo140.turnos.user;

/** Roles posibles de un {@link User}. Persistido como {@code varchar} + {@code CHECK} (ver esquema-bd.md). */
public enum UserRole {
    SUPERADMIN,
    COMPANY_ADMIN,
    CLIENT
}
