package com.grupo140.turnos;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

/**
 * Levanta el contexto completo contra un PostgreSQL real: Flyway aplica todas las migraciones
 * sobre una base limpia y Hibernate las valida contra las entidades (ddl-auto: validate).
 */
@SpringBootTest
@Import(TestcontainersConfiguration.class)
class TurnosApplicationIT {

    @Test
    void contextLoads() {}
}
