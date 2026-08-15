## 3. Requerimientos funcionales

### Superadmin
- Login (panel de sistema).
- CRUD de empresas (alta, consulta, edición, desactivación — nunca eliminación física).
- Alta de empresa: formulario único que crea en la misma transacción la `Company` (estado `ACTIVE`) y el `User` admin asociado (estado `PENDING_ACTIVATION`), generando el slug de la URL pública y disparando el link de activación (WhatsApp o mail).
- Reenviar el link de activación si el admin no lo usó a tiempo.
- Ver dashboard general de la plataforma (empresas activas/inactivas, altas por mes, ranking de empresas por cantidad de turnos generados, distribución por rubro).
- Ver la página pública de cualquier empresa (botón "Ver página pública"), sin poder reservar con esa sesión.

### Admin de empresa
- Login (panel de sistema).
- Definir su contraseña la primera vez, vía link de activación.
- Ver dashboard de su propio negocio (turnos de hoy, próximos turnos).
- CRUD de servicios (nombre, descripción, precio, duración, estado activo/inactivo). Al desactivar un servicio con turnos futuros, éstos se mantienen y se atienden con normalidad.
- CRUD de horarios de atención: configuración recurrente por día de la semana (rango horario + intervalo), configurada una sola vez y editable cuando haga falta. Al editarla, si hay turnos ya reservados fuera del nuevo rango, el sistema avisa que se mantienen igual (no se cancelan solos).
- Personalización básica de su página pública (logo, color).
- Ver turnero/agenda de su empresa, filtrable por estado.
- Reservar un turno manualmente con los datos del cliente que llamó o vino personalmente (nombre, teléfono), sin requerir que ese cliente tenga cuenta.
- Cancelar cualquier turno de su empresa (reservado online o cargado manualmente), sin restricción horaria, dejando registrado el motivo.
- Ver "Mi página pública" (solo lectura, se arma sola con lo que carga acá).

### Cliente
- Registro/login, dentro de la página pública de una empresa puntual.
- Ver la página pública de una empresa (servicios y disponibilidad) sin necesidad de login.
- Reservar un turno (requiere estar logueado como cliente de esa empresa), respetando la anticipación mínima permitida.
- Ver "Mis turnos" (listado propio de esa empresa).
- Cancelar un turno propio, dentro del plazo permitido.
- Reprogramar un turno propio, dentro del plazo permitido.
- Recibir notificación ante confirmación, cancelación o reprogramación de sus turnos.

### Sistema
- Cálculo automático de disponibilidad en el momento (horario + intervalo − duración del servicio − turnos ya ocupados), sin persistir una tabla de slots. (slots = cada horario de inicio candidato que el sistema podría ofrecer )
- Control de superposición de turnos con locking pesimista (evita doble reserva concurrente).
- Validación de anticipación mínima (no reservar con menos de 30 min de anticipación) y de plazo máximo de cancelación/reprogramación (3hs antes).
- Envío de notificaciones automáticas (NotificationService desacoplado del canal) ante reserva confirmada, cancelación y reprogramación.
- Cancelación automática de turnos pendientes y notificación a los clientes afectados cuando una empresa se desactiva.
