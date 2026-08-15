## 7. Detalle de flujos por rol

### 7.1 Dos sistemas de login separados

**Panel de sistema** (`/login`): acá se loguean superadmin y admins de empresa, en una URL propia que no pertenece a ninguna empresa en particular. El backend valida contra `User` y devuelve un JWT con `userId`, `role` y `companyId` (si es `COMPANY_ADMIN`). El frontend redirige:

- `SUPERADMIN` → `/superadmin/dashboard`
- `COMPANY_ADMIN` → `/company/dashboard`

El admin de empresa **no se autoregistra**: su cuenta la crea el superadmin al dar de alta la empresa, con un link de activación.

**Link de activación:** el link contiene un token único de un solo uso (ej. UUID) asociado a ese `User` admin recién creado, con vencimiento (ej. 48hs). Al abrirlo, el admin ve un formulario de "definí tu contraseña"; al confirmarla, el `User` pasa de `PENDING_ACTIVATION` a `ACTIVE` y ya puede loguearse normalmente. Si el token vence sin usarse, el superadmin puede reenviarlo desde el detalle de la empresa. Se envía por el mismo canal definido para las notificaciones (ver 7.6).

**Login/registro por empresa** (dentro de `plataforma.com/{slug}`): exclusivo para el cliente que quiere sacar un turno en esa empresa — no lo usa nadie del lado del negocio. El cliente se registra o inicia sesión con email y contraseña, siempre en el contexto de esa empresa puntual. El JWT que recibe incluye `companyId` fijo a esa empresa — ese token solo sirve para operar dentro de esa página pública. Si el mismo email ya está registrado como cliente de otra empresa, no hay conflicto: son cuentas independientes, la unicidad de email es por empresa, no global.

> Consecuencia práctica: no existe ningún punto del sistema donde una sesión de cliente "cruce" entre empresas. Cada `plataforma.com/{slug}` es, en términos de sesión, un compartimento aislado.

---

### 7.2 ¿Qué ve el superadmin?

Al loguearse ve `/superadmin/dashboard` con:

- Empresas activas vs. inactivas.
- Altas de empresas por mes.
- Ranking de empresas por cantidad de turnos generados.
- Distribución por rubro.

**Ranking por cantidad de turnos:** es un `COUNT(*)` sobre la tabla `Appointment` agrupado por `companyId`:

\`\`\`sql
SELECT companyId, COUNT(*)
FROM Appointment
GROUP BY companyId
ORDER BY COUNT(*) DESC
\`\`\`

No hace falta que el superadmin vea el detalle de cada turno — el conteo alcanza, y no expone datos de clientes ni de ingresos de cada negocio. "Generados" cuenta todos los turnos creados, sin importar el estado, porque mide actividad/uso de la plataforma, no rendimiento del negocio.

#### CRUD de empresas, en detalle

- **Alta (Create):** un formulario con los datos de la empresa (nombre, descripción, dirección, teléfono, email de contacto, rubro, logo) y los datos del futuro admin (nombre, apellido, email, teléfono). Al confirmar, en una sola transacción: se genera el slug a partir del nombre (validando que no exista, agregando un sufijo si hace falta), se crea `Company` en estado `ACTIVE`, se crea el `User` admin en estado `PENDING_ACTIVATION`, y se dispara el link de activación (ver 7.1). La URL pública `plataforma.com/{slug}` ya resuelve desde ese momento, mostrando el estado de "todavía sin servicios cargados".
- **Baja (Delete lógico):** desactivar la empresa (`estado = INACTIVE`), nunca eliminar el registro. Esto dispara: se bloquea el login del admin (su `User` también pasa a inactivo), la página pública deja de mostrar servicios/reserva y en su lugar informa que el negocio no está disponible por este medio, y los turnos pendientes se cancelan automáticamente notificando a cada cliente afectado. El historial (turnos pasados) se conserva por si la empresa se reactiva más adelante.
- **Reactivación:** desde el mismo listado, un botón inverso vuelve la empresa a `ACTIVE` y reactiva el login del admin. Como servicios y horarios no se borran al desactivar, la página pública queda funcionando de nuevo sin que el admin tenga que volver a cargar nada — salvo los turnos que se cancelaron durante la baja, que quedan cancelados.
- **Edición (Update):** campos editables sin mayor riesgo: nombre, descripción, dirección, teléfono, email de contacto, logo, rubro. El slug (URL pública) **no** se hace editable desde este formulario — cambiarlo rompe cualquier link ya compartido; si en algún momento hace falta cambiarlo, que sea una acción aparte y explícita.
- **Consulta (Read):** vista simple con los datos de la empresa y un link directo a "Ver página pública".

> Sobre el cambio de contraseña del admin una vez activada la cuenta: alcanza con un flujo estándar de "olvidé mi contraseña" (mismo mecanismo de link con token, disparado por el propio admin desde el login) — no hace falta nada más sofisticado para el alcance de la tesis.

Al entrar a "Ver página pública" desde el CRUD, el superadmin la ve como cualquier visitante sin loguear: puede mirar servicios y horarios, pero para reservar necesitaría loguearse ahí como cliente de esa empresa, igual que cualquier persona — el login de sistema y el de cliente son mundos separados, no hay sesión que se filtre de uno a otro.

---

### 7.3 ¿Qué ve el admin de empresa?

Al loguearse ve `/company/dashboard`, con navegación a: Dashboard, Servicios, Horarios, Turnos, Clientes, Mi página pública.

#### CRUD de Servicios y baja con turnos pendientes

Al desactivar un servicio, si tiene turnos futuros asociados, la opción más simple es la mejor: el servicio deja de estar disponible para nuevas reservas, pero los turnos ya reservados no se tocan — se atienden con normalidad, como si el servicio siguiera activo para esos casos puntuales. Esto evita disparar una notificación masiva a cada cliente avisando que "su servicio fue dado de baja", porque nadie pierde su turno. Si el admin específicamente quiere cancelar esos turnos, lo hace como una acción aparte, turno por turno, desde el turnero — no como consecuencia automática de dar de baja el servicio. Igual tiene sentido un `confirm` antes de desactivar, mostrando cuántos turnos futuros tiene ese servicio.

#### CRUD de Horarios, en detalle

No es un listado de turnos, es la configuración general de disponibilidad. El admin define, por día de la semana, un rango horario y un intervalo. Por ejemplo:

| Día | Desde | Hasta | Intervalo |
|---|---|---|---|
| Lunes a viernes | 09:00 | 18:00 | 30 min |
| Sábado | 09:00 | 13:00 | 30 min |
| Domingo | — sin configurar (cerrado) — | | |

El CRUD acá es sobre esas filas: crear un rango para un día, editarlo, o eliminarlo (equivale a decir "no atiendo ese día"). No se cargan turnos ni horarios sueltos a mano — esta configuración es el insumo que el sistema usa después para calcular disponibilidad.

La configuración se hace **una sola vez**: es una plantilla recurrente por día de la semana ("todos los lunes de 9 a 18"), no algo que se cargue semana a semana. Rige indefinidamente hacia adelante hasta que el admin la edite. El sistema, al calcular disponibilidad para una fecha puntual, mira qué día de la semana es y aplica la configuración correspondiente.

**Qué pasa con turnos existentes al editar esta tabla:** no se tocan. El `Appointment` guarda su propia fecha/hora ya confirmada, independiente de la configuración de horarios. Si el admin achica el rango (ej. cierra los sábados) y hay turnos ya reservados en sábado, esos turnos quedan como están — el sistema solo avisa: *"tenés X turnos ya reservados fuera del nuevo horario, van a mantenerse igual"*, y el admin decide si los cancela a mano o los deja.

#### Cálculo de disponibilidad, con ejemplo concreto

El sistema no guarda una tabla de "horarios disponibles"; la calcula al vuelo cada vez que alguien elige un servicio. Con el ejemplo de arriba (lunes a viernes 09:00-18:00, intervalo 30 min) y un servicio de 90 minutos (ej. "Color"):

1. Genera los horarios de inicio candidatos según el intervalo: 09:00, 09:30, 10:00, 10:30...
2. Para cada candidato, calcula el rango que ocuparía el servicio elegido (ej. eligiendo 10:00 → ocuparía 10:00 a 11:30).
3. Descarta los candidatos cuyo rango se superpone con un turno ya reservado en esa franja.
4. Devuelve al frontend solo los horarios de inicio que quedan libres para ese servicio puntual.

Por eso un servicio corto (ej. "Corte", 30 min) puede tener disponible un horario que un servicio largo (ej. "Color", 90 min) no puede ocupar, aunque ambos usen la misma configuración de horarios.

#### Turnero — reserva manual del admin

Es una vista parecida a la del cliente (mismo selector de servicio/horario), pero en vez de que el cliente cargue sus datos, los carga el admin (nombre, teléfono del cliente que llamó o vino personalmente). Al guardar, se dispara la misma notificación de confirmación que en una reserva online. **La cancelación del turno se hace desde acá, desde el turnero del panel.**

> **Problema detectado:** si el admin carga un turno con nombre/teléfono de alguien que nunca se registró en la web, ese cliente no tiene cuenta, así que no puede entrar a "Mis turnos" para cancelarlo por su cuenta.
>
> **Solución para el MVP:** el admin cancela desde el turnero. Un link con token en el mensaje de confirmación para autogestionar la cancelación sin cuenta es técnicamente simple de agregar (un UUID en la URL, no requiere cuenta), pero queda anotado como **mejora post-MVP** para no sumar otro flujo de cancelación distinto al ya definido. Por eso, en esta versión, el mensaje de confirmación **no lleva ningún link**.

El mensaje de confirmación es puramente informativo (tipo *"reservaste tal turno, gracias"*), no requiere que el cliente confirme nada: el turno queda guardado como `PENDING` en el momento en que se completa el flujo de reserva (con el lock pesimista), no cuando llega el mensaje.

#### Mi página pública

El admin no la edita directamente campo por campo; se arma sola a partir de lo que carga en Servicios/Horarios/datos de empresa. Solo tiene un link de acceso para verla como la ve un cliente.

---

### 7.4 Página pública y flujo de reserva del cliente

La página pública (`plataforma.com/{slug}`) es visible sin login: cualquiera ve servicios y puede explorar horarios. Todas las empresas comparten el mismo componente de página (card de servicio, selector de horario, formulario de reserva), instanciado con los datos propios de cada una vía slug — solo cambia logo, color y contenido, no la estructura.

**Flujo:**

1. El visitante ve los servicios de la empresa.
2. Elige un servicio → el sistema calcula la disponibilidad real.
3. Elige un horario disponible.
4. Si no está logueado como cliente de esa empresa, se le pide login/registro (propio de ese `{slug}`) antes de confirmar.
5. Confirma la reserva en un modal de verificación.
6. El turno se guarda —con **lock pesimista**: el sistema bloquea esa franja horaria a nivel de base de datos mientras se confirma, para que dos personas no puedan quedarse con el mismo horario si reservan casi al mismo tiempo— y aparece en "Mis turnos". Se dispara la notificación de confirmación.

---

### 7.5 Mis turnos, cancelación y reprogramación

"Mis turnos" es una tabla simple: fecha, servicio, empresa, estado. Sin secciones separadas de "historial" — el mismo listado, filtrable, cubre turnos futuros y pasados.

- **Cancelar:** disponible hasta **3 horas antes** del turno (valor inicial ajustable). El turno pasa a estado `CANCELLED` y se muestra en gris, sin acción de reactivación desde ahí.
- **Reprogramar:** dentro del mismo plazo, el cliente elige un nuevo horario disponible; se actualiza el mismo registro de turno (no se crea uno nuevo), guardando la fecha anterior y estado `RESCHEDULED`.
- **Pasado el plazo**, el cliente ya no puede autogestionar el cambio desde "Mis turnos" — el botón queda deshabilitado. Si necesita cancelar igual, contacta al negocio por fuera del sistema (WhatsApp, teléfono); ahí es el admin quien cancela desde su turnero (sin restricción horaria), liberando el horario automáticamente para que otra persona lo reserve. El mismo mecanismo aplica para los turnos cargados manualmente sin cuenta (ver 7.3).
- **Anticipación mínima para reservar:** no se puede reservar un turno con menos de **30 minutos** de anticipación sobre el horario elegido (además de no dejar reservar en horarios ya pasados). Evita reservas de último segundo que el negocio no llega a ver a tiempo. Valor ajustable.

---

### 7.6 Notificaciones

La idea de "desacoplado" es esta: el código que reserva/cancela/reprograma un turno no sabe ni le importa por qué canal se avisa al cliente. Cuando pasa uno de esos eventos, simplemente le dice al `NotificationService` "avisale al cliente X que pasó Y con su turno Z", y es el `NotificationService` el que decide cómo armar y mandar ese mensaje. Si mañana cambia el canal, no hace falta tocar la lógica de reservas — solo el servicio de notificaciones.

**Eventos que disparan una notificación:**
- Reserva confirmada (online o cargada manualmente por el admin).
- Cancelación (por cliente o por admin).
- Reprogramación (nueva fecha confirmada).

**Canal:** el objetivo es WhatsApp (vía alguna API de WhatsApp Business — proveedor aún sin definir). Es una decisión de proyecto, no un fallback en tiempo real: si llegado el momento no da el tiempo o la complejidad para integrar WhatsApp, se implementa el mismo `NotificationService` mandando por mail en su lugar. No se contempla tener ambos canales activos con reintento automático — eso implicaría implementar las dos integraciones más una lógica de detección de fallos, fuera del alcance definido.

---

### 7.7 Autenticación — resumen técnico

- Dos JWT distintos según el sistema de login: uno para el panel de sistema (superadmin/admin de empresa) y uno por sesión de cliente, atado a un único `companyId`.
- Ambos tokens llevan `role` y `companyId` (si aplica) para que el backend valide permisos en cada endpoint sin volver a consultar la base en cada request.
- **Expiración:** sin refresh token (no suma la complejidad extra al alcance de la tesis). El JWT expira a las **24 horas**; pasado ese tiempo, hay que volver a loguearse, no hay renovación automática.
- Login con email + contraseña en ambos sistemas.