package com.grupo140.turnos.appointment;

/** Quién canceló un {@link Appointment}. Persistido como {@code varchar} + {@code CHECK}. */
public enum CancelledBy {
    CLIENT,
    COMPANY
}
