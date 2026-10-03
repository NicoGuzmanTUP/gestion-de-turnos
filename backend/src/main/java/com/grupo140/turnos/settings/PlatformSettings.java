package com.grupo140.turnos.settings;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import org.hibernate.annotations.UpdateTimestamp;

/**
 * Parámetros de negocio configurables a nivel global de la plataforma, editables por el
 * {@code SUPERADMIN}. Mapea la tabla física {@code platform_settings}, de una sola fila
 * ({@code id = 1}), insertada por la migración V1 y nunca creada por la aplicación.
 */
@Entity
@Table(name = "platform_settings")
public class PlatformSettings {

    public static final short SINGLETON_ID = 1;

    @Id
    private Short id;

    @Column(name = "min_booking_notice_minutes", nullable = false)
    private Integer minBookingNoticeMinutes;

    @Column(name = "cancellation_deadline_hours", nullable = false)
    private Integer cancellationDeadlineHours;

    @Column(name = "max_reschedule_count", nullable = false)
    private Integer maxRescheduleCount;

    @Column(name = "max_booking_advance_days", nullable = false)
    private Integer maxBookingAdvanceDays;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PlatformSettings() {
        // JPA
    }

    public Short getId() {
        return id;
    }

    public Integer getMinBookingNoticeMinutes() {
        return minBookingNoticeMinutes;
    }

    public void setMinBookingNoticeMinutes(Integer minBookingNoticeMinutes) {
        this.minBookingNoticeMinutes = minBookingNoticeMinutes;
    }

    public Integer getCancellationDeadlineHours() {
        return cancellationDeadlineHours;
    }

    public void setCancellationDeadlineHours(Integer cancellationDeadlineHours) {
        this.cancellationDeadlineHours = cancellationDeadlineHours;
    }

    public Integer getMaxRescheduleCount() {
        return maxRescheduleCount;
    }

    public void setMaxRescheduleCount(Integer maxRescheduleCount) {
        this.maxRescheduleCount = maxRescheduleCount;
    }

    public Integer getMaxBookingAdvanceDays() {
        return maxBookingAdvanceDays;
    }

    public void setMaxBookingAdvanceDays(Integer maxBookingAdvanceDays) {
        this.maxBookingAdvanceDays = maxBookingAdvanceDays;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
