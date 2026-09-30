package com.grupo140.turnos;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * PostgreSQL en un contenedor para los tests de integracion (*IT).
 * <p>
 * Misma version que Neon y que el docker-compose.yml. {@code @ServiceConnection} pisa el
 * datasource del perfil, asi que los tests no dependen de la base local en el 5433.
 */
@TestConfiguration(proxyBeanMethods = false)
public class TestcontainersConfiguration {

    @Bean
    @ServiceConnection
    PostgreSQLContainer postgresContainer() {
        return new PostgreSQLContainer("postgres:18");
    }
}
