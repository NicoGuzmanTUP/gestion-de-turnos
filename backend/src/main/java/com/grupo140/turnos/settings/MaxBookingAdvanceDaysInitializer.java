package com.grupo140.turnos.settings;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * Aplica, al arrancar, el override de {@code max_booking_advance_days} por variable de entorno
 * ({@code MAX_BOOKING_ADVANCE_DAYS}). Si la variable no está definida, la fila queda con el
 * valor que insertó la migración V1 ({@value PlatformSettings#SINGLETON_ID} → default 90 días).
 *
 * <p>El valor sigue viviendo en la tabla (lo edita el superadmin desde su panel), no en
 * {@code application.yml}: esto solo sirve para fijar el valor inicial en un deploy nuevo sin
 * tener que entrar a editarlo a mano.
 */
@Component
public class MaxBookingAdvanceDaysInitializer implements ApplicationRunner {

    private final PlatformSettingsRepository repository;
    private final Integer override;

    public MaxBookingAdvanceDaysInitializer(
            PlatformSettingsRepository repository, @Value("${MAX_BOOKING_ADVANCE_DAYS:#{null}}") Integer override) {
        this.repository = repository;
        this.override = override;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (override == null) {
            return;
        }
        repository.findById(PlatformSettings.SINGLETON_ID).ifPresent(settings -> {
            settings.setMaxBookingAdvanceDays(override);
            repository.save(settings);
        });
    }
}
