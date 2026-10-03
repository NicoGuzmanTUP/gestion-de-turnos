package com.grupo140.turnos.appointment;

/** Estados posibles de un {@link Appointment}. Persistido como {@code varchar} + {@code CHECK}. */
public enum AppointmentStatus {
    PENDING,
    COMPLETED,
    CANCELLED
}
