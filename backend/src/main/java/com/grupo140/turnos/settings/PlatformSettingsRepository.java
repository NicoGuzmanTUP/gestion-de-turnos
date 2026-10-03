package com.grupo140.turnos.settings;

import org.springframework.data.jpa.repository.JpaRepository;

/** Acceso a la fila única de {@link PlatformSettings}. */
public interface PlatformSettingsRepository extends JpaRepository<PlatformSettings, Short> {}
