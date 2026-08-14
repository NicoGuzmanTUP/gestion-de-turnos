# gestion-de-turnos

## 1. Resumen del proyecto

Plataforma web donde múltiples empresas de servicios por turno (barberías, centros de estética, consultorios, veterinarias, etc.) gestionan sus servicios, horarios y turnos desde un panel propio, y cada una cuenta con una página pública independiente (plataforma.com/{slug}) donde sus clientes pueden reservar, cancelar o reprogramar turnos.

El cliente final también tiene cuenta y se loguea, pero esto no significa un login único para toda la plataforma: hay dos sistemas de login separados.
- **Panel interno de sistema:** ahí se loguean superadmin y admins de empresa, en una URL propia (no pública, no vinculada a ninguna empresa en particular).
- **Página pública de cada empresa** (plataforma.com/{slug}): ahí se registra/loguea el cliente, de forma independiente por empresa. Si una persona quiere sacar turno en dos negocios distintos de la plataforma, se registra por separado en cada uno — no existe una cuenta de cliente compartida entre empresas.

**Problema que resuelve:** hoy estos negocios coordinan turnos por WhatsApp, llamadas o agenda en papel/Excel, lo que genera turnos duplicados, tiempo perdido respondiendo mensajes uno por uno, y falta de aviso claro ante cambios (cancelaciones, reprogramaciones).

**Valor agregado:** el sistema bloquea automáticamente un horario apenas se reserva (evitando la doble reserva que hoy depende de que el dueño esté atento) y notifica automáticamente ante cualquier cambio de estado del turno.

## 2. Estructura del repositorio

```
.
├── backend/      # API (Java + Spring Boot) — ver su README
├── frontend/     # Cliente web (React + TypeScript) — ver su README
└── docs/
    ├── negocio/       # Especificación funcional
    └── tecnologias/   # Arquitectura y decisiones técnicas
```

La documentación está dividida según su ciclo de vida: en `docs/` vive **el qué y el por qué** (negocio, modelo de datos, decisiones transversales), que cambia cuando cambia el producto. En el README de cada proyecto vive **el cómo** (estructura, capas, tests, setup), que cambia cuando cambia el código.

## 3. Documentación

### Proyectos
- [Backend](backend/README.md) — estructura de paquetes, regla de capas, testing, seeds.
- [Frontend](frontend/README.md) — estructura de carpetas, regla de capas, testing.

### Negocio
- [Requerimientos funcionales](docs/negocio/requerimientos-funcionales.md)
- [Casos de uso](docs/negocio/casos-usos.md)
- [Reglas de negocio](docs/negocio/reglas-negocio.md)
- [Detalle de flujos por rol](docs/negocio/detalles-flujos.md)

### Tecnologías
- [Arquitectura y stack](docs/tecnologias/arquitectura.md)
- [Diccionario de datos](docs/tecnologias/diccionario-datos.md)
- [Convenciones técnicas](docs/tecnologias/convenciones.md)

## 4. Stack

Java + Spring Boot (backend), React + TypeScript (frontend), PostgreSQL. Detalle completo y justificación en [arquitectura y stack](docs/tecnologias/arquitectura.md).

## 5. Estado del proyecto

En etapa de documentación y diseño previo al desarrollo. `backend/` y `frontend/` todavía no tienen código.
