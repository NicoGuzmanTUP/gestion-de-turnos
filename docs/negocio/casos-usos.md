## 6. Casos de uso

### UC1 - Alta de empresa
**Actor:** Superadmin

El superadmin completa datos de la empresa y del futuro admin. El sistema crea `Company` + `User` admin (estado `PENDING_ACTIVATION`) en una sola transacción, genera el slug de la URL pública y envía un link de activación (WhatsApp o mail) para que el admin defina su contraseña. La URL pública queda disponible desde el primer momento, mostrando un estado de "todavía sin servicios cargados".

### UC2 - Configurar servicios y horarios
**Actor:** Admin de empresa

El admin crea/edita servicios (nombre, precio, duración) y define, una sola vez, su horario habitual por día de semana + intervalo. El sistema usa esos datos para calcular disponibilidad real en cada reserva. Si más adelante edita el horario y hay turnos ya reservados fuera del nuevo rango, el sistema le avisa pero no los toca.

### UC3 - Registro/login de cliente 
**Actor:** Cliente

Desde la página pública de una empresa puntual, una persona se registra o inicia sesión con email y contraseña. Esa cuenta solo sirve para reservar turnos en esa empresa; si quiere sacar turno en otra empresa de la plataforma, se registra de nuevo ahí (aunque use el mismo email, es una cuenta distinta).

### UC4 - Reservar un turno
**Actor:** Cliente

El cliente entra a la página pública de una empresa, elige un servicio, ve los horarios disponibles (ya filtrados por duración y por la anticipación mínima permitida), confirma la reserva y el turno queda guardado como `PENDING` de inmediato. Recibe una notificación informativa de confirmación; no necesita confirmar nada más. El turno queda visible en "Mis turnos".

### UC5 - Cancelar o reprogramar un turno propio
**Actor:** Cliente

Desde "Mis turnos", dentro del plazo permitido, el cliente cancela (el turno queda marcado como cancelado, visible en gris, sin reactivación posible) o reprograma (se actualiza el mismo turno con la nueva fecha, conservando la anterior).

### UC6 - El negocio cancela un turno
**Actor:** Admin de empresa

Desde el turnero de su panel, el admin cancela un turno (reservado online o cargado manualmente) sin restricción horaria, registrando el motivo. El cliente recibe notificación del cambio, si tiene forma de recibirla.

### UC7 - Desactivar una empresa
**Actor:** Superadmin

El superadmin desactiva una empresa. Se bloquea el login de su admin, la página pública deja de ofrecer reservas, y los turnos pendientes se cancelan automáticamente notificando a cada cliente afectado.

### UC8 - Reservar un turno manualmente
**Actor:** Admin de empresa

El admin usa el mismo turnero para cargar un turno con los datos del cliente que llamó o vino personalmente (nombre, teléfono). Al guardar, se dispara la misma notificación de confirmación que en una reserva online. Si ese cliente no tiene cuenta en la plataforma, no podrá autogestionar el turno desde "Mis turnos" — para cancelar debe contactar al negocio y es el admin quien lo hace desde el turnero.

### UC9 - Dar de baja un servicio con turnos pendientes
**Actor:** Admin de empresa

El admin desactiva un servicio. El sistema le muestra cuántos turnos futuros tiene ese servicio antes de confirmar. Al desactivarlo, el servicio deja de ofrecerse para nuevas reservas, pero los turnos ya reservados no se cancelan automáticamente; se atienden con normalidad salvo que el admin los cancele a mano, turno por turno.

### UC10 - Editar horarios con turnos ya reservados
**Actor:** Admin de empresa

El admin modifica el rango horario de un día (por ejemplo, deja de atender los sábados). El sistema detecta si hay turnos futuros reservados fuera del nuevo rango y se lo informa antes de guardar, pero no los cancela ni los modifica de forma automática.

### UC11 - Reactivar una empresa
**Actor:** Superadmin

El superadmin reactiva una empresa previamente desactivada. Vuelve a estado `ACTIVE`, se desbloquea el login de su admin y la página pública vuelve a mostrar servicios/horarios y aceptar reservas, con la configuración que ya tenía cargada. Los turnos que se habían cancelado al desactivar no se recuperan. 
