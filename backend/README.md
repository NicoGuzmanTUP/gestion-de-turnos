# Backend — API

API REST del sistema de gestión de turnos. Java + Spring Boot + PostgreSQL.

> Documentación de negocio y modelo de datos: [`/docs`](../docs). Convenciones transversales (idiomas, git, calidad): [`convenciones.md`](../docs/tecnologias/convenciones.md).

## Puesta en marcha

> ⏳ *A completar cuando exista el proyecto.*

- Requisitos: JDK (versión a definir), Maven/Gradle (a definir), PostgreSQL.
- Variables de entorno: documentar en un `.env.example` versionado. El `.env` real nunca se commitea.
- Comando de arranque local.
- Comando de tests.

## Estructura de paquetes

> 💬 **Propuesta a confirmar entre ambos antes de escribir la primera clase.** Es la decisión más cara de revertir después.

Organización **por feature**, con las capas adentro de cada una. Con dos personas trabajando en paralelo reduce bastante los conflictos de merge: cada uno toca su carpeta.

```
src/main/java/com/<grupo>/turnos/
├── config/            # configuración de Spring, seguridad, CORS, beans
├── common/            # excepciones, respuestas de error, utilidades compartidas
├── auth/              # login, JWT, activación de cuenta, recuperar contraseña
├── company/           # Company: CRUD, alta transaccional, activar/desactivar
├── catalog/           # Service: catálogo de servicios de cada empresa
├── schedule/          # BusinessHours + cálculo de disponibilidad
├── appointment/       # Appointment: reserva, cancelación, reprogramación
└── notification/      # NotificationService desacoplado del canal
```

Dentro de cada feature:

```
appointment/
├── AppointmentController.java
├── AppointmentService.java
├── AppointmentRepository.java
├── Appointment.java           # entidad JPA
└── dto/                       # requests y responses
```

### ⚠️ Choque de nombres: `Service`

La entidad de dominio se llama `Service` (ver [diccionario de datos](../docs/tecnologias/diccionario-datos.md)) y choca con el sufijo `Service` de la capa de negocio — `ServiceService` no es aceptable.

**Propuesta:** el paquete se llama `catalog`, las clases de aplicación son `CatalogController` / `CatalogService`, y la entidad JPA mantiene el nombre `Service`.

## Regla de capas

**Ésta es la regla que evita el código spaghetti. Si se respeta, casi todo lo demás se acomoda solo.**

```
Controller  ──►  Service  ──►  Repository
```

| Capa | Responsabilidad | Qué NO hace |
| :--- | :--- | :--- |
| **Controller** | Solo HTTP: recibir el request, validar formato, mapear DTOs, devolver códigos de estado. | No contiene lógica de negocio. |
| **Service** | Reglas de negocio y transacciones (`@Transactional`). Único lugar donde vive la lógica. | No conoce nada de HTTP (ni `HttpServletRequest`, ni códigos de estado). |
| **Repository** | Acceso a datos. | No contiene lógica de negocio. |

Reglas duras:

- ❌ Un controller **nunca** llama directo a un repository.
- ❌ Las entidades JPA **no salen** de la capa de service: el controller recibe y devuelve DTOs.
- ❌ Nada de lógica de negocio en los controllers, ni en las entidades.
- ✅ Las validaciones de negocio (superposición de turnos, anticipación mínima, plazos de cancelación) viven en services, con sus tests unitarios.

## Convenciones de nombres

- **Endpoints:** REST en inglés, sustantivos en plural — `GET /api/companies/{id}/services`. Versionado a definir.
- **Clases:** `<Feature>Controller`, `<Feature>Service`, `<Feature>Repository`.
- **DTOs:** `CreateAppointmentRequest`, `AppointmentResponse`.
- **Tests:** `<ClaseTesteada>Test` para unitarios, `<ClaseTesteada>IT` para integración.
- **Métodos de test:** nombre descriptivo del caso, en inglés.

## Testing

> ⏳ *Herramientas a confirmar; la estrategia ya está definida.*

**Unitarios** — el grueso de la suite. Services aislados con Mockito, sin levantar el contexto de Spring. Prioridad sobre la lógica crítica:

- Cálculo de disponibilidad (intervalos vs. duración del servicio).
- Validación de superposición de turnos.
- Anticipación mínima para reservar y plazo máximo de cancelación/reprogramación.

**Integración** — `@SpringBootTest` sobre repositories y flujos completos. Punto clave a cubrir: el **lock pesimista** en la reserva concurrente, que no se puede validar con un test unitario.

**Pendiente:** elegir entre Testcontainers (Postgres real, más fiel) o H2 en memoria (más rápido, menos fiel), y definir si se exige una cobertura mínima en CI.

## Seeds y datos de prueba

> ⏳ *A definir.*

Necesarios para levantar el entorno con un superadmin, un par de empresas de ejemplo con servicios y horarios cargados, y turnos en distintos estados. A resolver: mecanismo (`data.sql`, un `CommandLineRunner` por perfil, o migraciones) y cómo se aísla del entorno productivo.

## Pendiente de definir

- Maven o Gradle.
- Estrategia de migraciones de base de datos (Flyway / Liquibase / `ddl-auto`).
- Formatter y linter (Spotless, Checkstyle) integrados en CI.
- Manejo centralizado de errores (`@RestControllerAdvice`) y formato del cuerpo de error.
- Documentación de la API (Swagger / OpenAPI).
