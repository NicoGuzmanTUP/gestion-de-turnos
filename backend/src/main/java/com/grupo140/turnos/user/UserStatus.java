package com.grupo140.turnos.user;

/** Estados posibles de un {@link User}. Persistido como {@code varchar} + {@code CHECK} (ver esquema-bd.md). */
public enum UserStatus {
    PENDING_ACTIVATION,
    ACTIVE,
    INACTIVE
}
