# 📚 5. Diccionario de Datos

Este documento define el modelo de datos relacional del sistema, detallando los atributos, tipos de datos, claves foráneas y restricciones de negocio para cada entidad.

> 📝 **Nota de nomenclatura:** los nombres de entidades, atributos y enums están en inglés, según lo definido en [convenciones técnicas](convenciones.md). Las descripciones se mantienen en español.

---

## 👥 Entidad: `User`

Representa a todos los actores del sistema (Superadministradores, Administradores de Empresa y Clientes).

> ⚠️ **Regla de Aislamiento de Clientes:** Un cliente que reserva en dos empresas distintas posee dos registros independientes de `User`, manteniendo el aislamiento total por `companyId`.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único del usuario. |
| `firstName` | `String` | Not Null | Nombre del usuario. |
| `lastName` | `String` | Not Null | Apellido del usuario. |
| `email` | `String` | Not Null | Credencial de login. Único por empresa. *(Para `SUPERADMIN` es único global).* |
| `password` | `String` | Not Null | Hash de la contraseña (nunca en texto plano). |
| `role` | `Enum` | Not Null | Valores posibles: `SUPERADMIN`, `COMPANY_ADMIN`, `CLIENT`. |
| `companyId` | `UUID` / `Long` | **FK** (`Company`), Nullable | Nulo **solo** para `SUPERADMIN`. Atado a la empresa correspondiente. |
| `status` | `Enum` | Not Null | Valores posibles: `PENDING_ACTIVATION`, `ACTIVE`, `INACTIVE`. |

---

## 🏢 Entidad: `Company`

Representa cada uno de los negocios o comercios dados de alta en la plataforma.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único de la empresa. |
| `name` | `String` | Not Null | Nombre comercial de la empresa. |
| `slug` | `String` | Not Null, **Único** | Identificador de URL pública (`plataforma.com/{slug}`). No editable. |
| `description` | `String` | Nullable | Descripción pública del negocio. |
| `address` | `String` | Nullable | Dirección física del comercio. |
| `phone` | `String` | Nullable | Teléfono principal de contacto. |
| `contactEmail` | `String` | Nullable | Correo electrónico de contacto institucional. |
| `category` | `String` / `Enum` | Nullable | Rubro del negocio (ej. Peluquería, Veterinaria, Consultorio). |
| `logoUrl` | `String` | Nullable | URL de la imagen del logo (requiere *storage* externo). |
| `primaryColor` | `String` | Nullable | Código HEX para personalización de marca (`#HEX`). |
| `status` | `Enum` | Not Null | Valores posibles: `ACTIVE`, `INACTIVE`. *(Borrado lógico).* |

---

## ✂️ Entidad: `Service`

Catálogo de prestaciones ofrecidas por cada empresa.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único del servicio. |
| `companyId` | `UUID` / `Long` | **FK** (`Company`), Not Null | Empresa a la que pertenece el servicio. |
| `name` | `String` | Not Null | Nombre del servicio. |
| `description` | `String` | Nullable | Detalle o alcance del servicio. |
| `price` | `Decimal` | Not Null | Costo del servicio. |
| `durationMinutes` | `Int` | Not Null | Tiempo estimado en minutos (clave para la disponibilidad). |
| `status` | `Enum` | Not Null | Valores posibles: `ACTIVE`, `INACTIVE`. |

> 💡 **Nota de Inmutabilidad:** Desactivar un servicio (`INACTIVE`) no altera ni elimina los turnos previamente reservados con dicho servicio.

---

## 🕐 Entidad: `BusinessHours`

Configuración de la franja horaria hábil de la empresa.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único de la regla de horario. |
| `companyId` | `UUID` / `Long` | **FK** (`Company`), Not Null | Empresa a la que pertenece el horario. |
| `dayOfWeek` | `Enum` | Not Null | Días de la semana (`MONDAY` a `SUNDAY`). |
| `startTime` | `Time` | Not Null | Hora de apertura/inicio de atención. |
| `endTime` | `Time` | Not Null | Hora de cierre/fin de atención. |
| `intervalMinutes` | `Int` | Not Null | Frecuencia en minutos para ofrecer inicio de turnos. |

---

## 📅 Entidad: `Appointment`

Registro de las citas o reservas solicitadas en el sistema.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único del turno. |
| `companyId` | `UUID` / `Long` | **FK** (`Company`), Not Null | Empresa en la que se efectúa la reserva. |
| `serviceId` | `UUID` / `Long` | **FK** (`Service`), Not Null | Servicio reservado (define duración y precio). |
| `clientId` | `UUID` / `Long` | **FK** (`User`), Nullable | Usuario cliente que reserva. Nulo si es reserva manual del admin. |
| `manualClientName` | `String` | Nullable | Usado solo si `clientId` es `NULL` (carga telefónica/manual). |
| `manualClientPhone` | `String` | Nullable | Teléfono de contacto para clientes sin cuenta registrada. |
| `startDateTime` | `Instant` / `OffsetDateTime` | Not Null | Fecha y hora exacta de inicio del turno (UTC). |
| `previousStartDateTime` | `Instant` / `OffsetDateTime` | Nullable | Horario previo en caso de haber sido reprogramado. |
| `status` | `Enum` | Not Null | Valores: `PENDING`, `CANCELLED`, `RESCHEDULED`. |
| `cancelledBy` | `Enum` | Nullable | Quién canceló el turno: `CLIENT` o `COMPANY`. |
| `cancellationReason` | `String` | Nullable | Explicación en texto libre sobre el motivo de la cancelación. |

---

## 🔗 Diagrama Simplificado de Relaciones (ER)

```text
 ┌──────────────┐         1:N         ┌──────────────────┐
 │   Company    ├────────────────────►│  BusinessHours   │
 └──────┬───────┘                     └──────────────────┘
        │
        │ 1:N
        ├───► ┌──────────────┐        1:N         ┌──────────────┐
        │     │   Service    ├───────────────────►│ Appointment  │
        │     └──────────────┘                    └──────┬───────┘
        │                                                │
        │ 1:N                                            │ N:1 (Nullable)
        └───► ┌──────────────┐                           │
              │     User     │◄──────────────────────────┘
              └──────────────┘

```
