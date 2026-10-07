package com.grupo140.turnos.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Encoder único de contraseñas del sistema. Lo usan el login (US-03.1), la activación (US-03.4) y el
 * seed de dev (T-02.4): si cada uno hasheara por su cuenta, las contraseñas sembradas no validarían.
 *
 * <p>BCrypt genera hashes de 60 caracteres ({@code app_user.password} es {@code varchar(100)}) y
 * rechaza contraseñas de más de 72 bytes: el DTO de entrada tiene que limitar el largo antes.
 */
@Configuration
public class PasswordEncoderConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
