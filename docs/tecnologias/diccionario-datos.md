# 📚 5. Diccionario de Datos

Este documento define el modelo de datos relacional del sistema, detallando los atributos, tipos de datos, claves foráneas y restricciones de negocio para cada entidad.

---

## 👥 Entidad: `Usuario`

Representa a todos los actores del sistema (Superadministradores, Administradores de Empresa y Clientes).

> ⚠️ **Regla de Aislamiento de Clientes:** Un cliente que reserva en dos empresas distintas posee dos registros independientes de `Usuario`, manteniendo el aislamiento total por `empresaId`.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único del usuario. |
| `nombre` | `String` | Not Null | Nombre del usuario. |
| `apellido` | `String` | Not Null | Apellido del usuario. |
| `email` | `String` | Not Null | Credencial de login. Único por empresa. *(Para `SUPERADMIN` es único global).* |
| `contraseña` | `String` | Not Null | Hash de la contraseña (nunca en texto plano). |
| `rol` | `Enum` | Not Null | Valore posibles: `SUPERADMIN`, `ADMIN_EMPRESA`, `CLIENTE`. |
| `empresaId` | `UUID` / `Long` | **FK** (`Empresa`), Nullable | Nulo **solo** para `SUPERADMIN`. Atado a la empresa correspondiente. |
| `estado` | `Enum` | Not Null | Valores posibles: `PENDIENTE_ACTIVACION`, `ACTIVO`, `INACTIVO`. |

---

## 🏢 Entidad: `Empresa`

Representa cada uno de los negocios o comercios dados de alta en la plataforma.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único de la empresa. |
| `nombre` | `String` | Not Null | Nombre comercial de la empresa. |
| `slug` | `String` | Not Null, **Único** | Identificador de URL pública (`plataforma.com/{slug}`). No editable. |
| `descripcion` | `String` | Nullable | Descripción pública del negocio. |
| `direccion` | `String` | Nullable | Dirección física del comercio. |
| `telefono` | `String` | Nullable | Teléfono principal de contacto. |
| `emailContacto` | `String` | Nullable | Correo electrónico de contacto institucional. |
| `rubro` | `String` / `Enum` | Nullable | Categoría del negocio (ej. Peluquería, Veterinaria, Consultorio). |
| `logoUrl` | `String` | Nullable | URL de la imagen del logo (requiere *storage* externo). |
| `colorPrimario` | `String` | Nullable | Código HEX para personalización de marca (`#HEX`). |
| `estado` | `Enum` | Not Null | Valores posibles: `ACTIVA`, `INACTIVA`. *(Borrado lógico).* |

---

## ✂️ Entidad: `Servicio`

Catálogo de prestaciones ofrecidas por cada empresa.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único del servicio. |
| `empresaId` | `UUID` / `Long` | **FK** (`Empresa`), Not Null | Empresa a la que pertenece el servicio. |
| `nombre` | `String` | Not Null | Nombre del servicio. |
| `descripcion` | `String` | Nullable | Detalle o alcance del servicio. |
| `precio` | `Decimal` | Not Null | Costo del servicio. |
| `duracionMinutos` | `Int` | Not Null | Tiempo estimado en minutos (clave para la disponibilidad). |
| `estado` | `Enum` | Not Null | Valores posibles: `ACTIVO`, `INACTIVO`. |

> 💡 **Nota de Inmutabilidad:** Desactivar un servicio (`INACTIVO`) no altera ni elimina los turnos previamente reservados con dicho servicio.

---

## 🕐 Entidad: `HorarioAtencion`

Configuración de la franja horaria hábil de la empresa.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único de la regla de horario. |
| `empresaId` | `UUID` / `Long` | **FK** (`Empresa`), Not Null | Empresa a la que pertenece el horario. |
| `diaSemana` | `Enum` | Not Null | Días de la semana (`LUNES` a `DOMINGO`). |
| `horaInicio` | `Time` | Not Null | Hora de apertura/inicio de atención. |
| `horaFin` | `Time` | Not Null | Hora de cierre/fin de atención. |
| `intervaloMinutos` | `Int` | Not Null | Frecuencia en minutos para ofrecer inicio de turnos. |

---

## 📅 Entidad: `Turno`

Registro de las citas o reservas solicitadas en el sistema.

| Atributo | Tipo de Dato | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` / `Long` | **PK**, Not Null | Identificador único del turno. |
| `empresaId` | `UUID` / `Long` | **FK** (`Empresa`), Not Null | Empresa en la que se efectúa la reserva. |
| `servicioId` | `UUID` / `Long` | **FK** (`Servicio`), Not Null | Servicio reservado (define duración y precio). |
| `clienteId` | `UUID` / `Long` | **FK** (`Usuario`), Nullable | Usuario cliente que reserva. Nulo si es reserva manual admin. |
| `nombreClienteManual` | `String` | Nullable | Usado solo si `clienteId` es `NULL` (carga telefónica/manual). |
| `telefonoClienteManual` | `String` | Nullable | Teléfono de contacto para clientes sin cuenta registrada. |
| `fechaHoraInicio` | `Instant` / `OffsetDateTime` | Not Null | Fecha y hora exacta de inicio del turno (UTC). |
| `fechaHoraAnterior` | `Instant` / `OffsetDateTime` | Nullable | Horario previo en caso de haber sido reprogramado. |
| `estado` | `Enum` | Not Null | Valores: `PENDIENTE`, `ATENDIDO`, `CANCELADO`, `REPROGRAMADO`. |
| `canceladoPor` | `Enum` | Nullable | Quién canceló el turno: `CLIENTE` o `NEGOCIO`. |
| `motivoCancelacion` | `String` | Nullable | Explicación en texto libre sobre el motivo del borrado. |

---

## 🔗 Diagrama Simplificado de Relaciones (ER)

```text
 ┌──────────────┐         1:N         ┌──────────────────┐
 │   Empresa    ├────────────────────►│  HorarioAtencion │
 └──────┬───────┘                     └──────────────────┘
        │
        │ 1:N
        ├───► ┌──────────────┐        1:N         ┌──────────────┐
        │     │   Servicio   ├───────────────────►│    Turno     │
        │     └──────────────┘                    └──────┬───────┘
        │                                                │
        │ 1:N                                            │ N:1 (Nullable)
        └───► ┌──────────────┐                           │
              │   Usuario    │◄──────────────────────────┘
              └──────────────┘

```