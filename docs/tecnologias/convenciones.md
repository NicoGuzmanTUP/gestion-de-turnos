# Convenciones técnicas

Convenciones **transversales** a todo el proyecto. Lo específico de cada stack vive en el README de su propia carpeta:

- [Backend](../../backend/README.md) — estructura de paquetes, capas, tests, seeds.
- [Frontend](../../frontend/README.md) — estructura de carpetas, componentes, tests.

## Idiomas

- **Todo el código en inglés:** nombres de clases, métodos, funciones, variables, enums, endpoints, entidades y atributos.
- **Comentarios en el código:** español.
- **Todo lo que ve el usuario final:** español — mensajes de error, textos de la interfaz y cualquier respuesta de la API visible para el usuario.
- **Documentación:** español.

## Nomenclatura del modelo de datos

- **Entidades y atributos en el código:** inglés, `PascalCase` para clases y `camelCase` para atributos, según el [diccionario de datos](diccionario-datos.md).
- **Tablas y columnas en PostgreSQL:** `snake_case` (`company_id`, `start_date_time`). Es la convención estándar del motor; Hibernate hace la traducción automáticamente con su estrategia de nombres por defecto, así que no hace falta anotar cada columna a mano.
- **Enums:** `SCREAMING_SNAKE_CASE` en inglés (`PENDING_ACTIVATION`, `COMPANY_ADMIN`).
- **Enums en la base:** se persisten como `varchar` + `CHECK`, con `@Enumerated(EnumType.STRING)` en la entidad JPA. No se usan los tipos `ENUM` nativos de PostgreSQL: requieren manejo especial en Hibernate y un `ALTER TYPE` para agregar cada valor. Detalle en [esquema de base de datos](esquema-bd.md).

## Flujo de trabajo con Git

- `main` se mantiene siempre estable y desplegable. No se commitea directo sobre `main`.
- **Ramas:** `<tipo>/<descripción-corta>` en kebab-case — ej. `feat/appointment-booking`, `fix/overlap-validation`.
- **Commits:** formato [Conventional Commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- **Pull Requests:** ningún merge a `main` sin revisión del otro desarrollador. La documentación afectada se actualiza en el mismo PR que el código.

## Calidad de código

Lo que efectivamente evita el código spaghetti, en orden de impacto:

1. **Respetar la regla de capas** definida en el README de cada proyecto. Es la regla más importante y la que más desorden previene.
2. **Formatter y linter corriendo en CI**, bloqueando el merge si fallan. Una regla que verifica una máquina vale más que una escrita.
3. **Code review mutuo** en cada PR.

Los principios SOLID se aplican como consecuencia de la regla de capas (responsabilidad única por clase, dependencias hacia adentro), no como una checklist aparte.

## Pendiente de definir

- Herramientas de formato/linter por proyecto y su integración en CI.
- Estrategia de branching (trunk-based vs. GitFlow simplificado).
- Manejo de logs: nivel, formato e idioma.
- Política de versionado de la API (`/api/v1/...`).
