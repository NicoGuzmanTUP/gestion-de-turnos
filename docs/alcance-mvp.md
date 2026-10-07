# Alcance del MVP — recortes al roadmap

Registro de lo que se recorta, reduce o pospone respecto del roadmap de tareas (`tareas_v2.md`), y de las decisiones de diseño que salieron de esa revisión.

## Motivo

El objetivo es cerrar el proyecto a tiempo. Para eso se prioriza el núcleo que sostiene la defensa (aislamiento por empresa, disponibilidad, reserva sin doble turno) y se recortan las piezas que aportan poco a esa demostración.

Una historia que no figura acá se mantiene tal como está en el roadmap.

## Recortes

| Ítem del roadmap | Decisión | Alcance que queda | Responsable |
| :--- | :--- | :--- | :--- |
| US-03.7 — Admin recupera su contraseña | Pospuesta (opcional) | Se hace al final del Paso 3 solo si sobra tiempo. No bloquea ningún flujo: un admin sin acceso puede pedir ayuda al superadmin. | Nico |
| US-03.9 y US-03.10 | Unificadas con US-03.1/US-03.2 | Se entregan en un solo PR de autenticación: login, JWT, `companyId` de la sesión y formato único de error. Mismo alcance, menos ciclos de review. | Nico |
| US-04.6 — Dashboard del superadmin | Reducida | Dos indicadores: empresas activas/inactivas y cantidad total de turnos. Sin altas por mes, sin ranking por empresa, sin distribución por rubro y sin gráficos. | Brune (back) / Nico (front) |
| T-12.3 — Cobertura de tests por regla de negocio | Reducida | Tests solo de las reglas críticas: cálculo de disponibilidad (incluida la zona horaria), concurrencia y doble reserva, anticipación mínima y plazos de cancelación y reprogramación. No se recorre regla por regla. | Nico y Brune |
| Paso 13 — Documentación y pulido | Reducido | Se actualiza solo la documentación que haya quedado desfasada respecto de lo construido. Sin revisión cruzada completa por módulo. | Nico y Brune |

## Decisiones de diseño

- **Email único global para `COMPANY_ADMIN`.** El login del panel (`/login`) recibe solo email y contraseña, sin empresa. Como el índice de la base permite el mismo email en dos empresas, un mismo email podría ser admin de dos empresas y el login no sabría cuál elegir. Se resuelve validando en el alta de empresa (US-04.1) que el email del admin no exista como `COMPANY_ADMIN` en ninguna otra empresa. No requiere migración. Los clientes siguen con email único por empresa.
- **Un solo PR de autenticación.** US-03.1, US-03.2, US-03.9 y US-03.10 comparten infraestructura (Spring Security, JWT, manejador de errores) y se prueban juntas.

## Lo que no se recorta

Estas historias son el núcleo de la defensa y se mantienen completas:

| Historia | Motivo |
| :--- | :--- |
| US-03.9 — Aislamiento de datos por empresa | Es la regla de seguridad más importante del sistema multi-tenant. |
| US-05.5 — Cálculo de disponibilidad | Es la lógica central del producto, incluida la conversión con `company.timezone`. |
| US-07.3 — Sin doble reserva | Lock pesimista más constraint de exclusión: es la garantía más fuerte del modelo. |
| US-07.4 — Anticipación mínima | Regla configurable desde `PlatformSettings`, compartida con el cálculo de disponibilidad. |

## Pendiente de confirmar

- **Con Brune:** los recortes que afectan su parte (US-04.6, T-12.3, Paso 13) y la validación del email global de admin en el backend de US-04.1.
