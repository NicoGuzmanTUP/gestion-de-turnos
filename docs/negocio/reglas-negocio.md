## 4. Reglas de negocio

### Autenticación y cuentas
1. Existen dos sistemas de login separados: uno para superadmin y admins de empresa (panel de sistema), y uno propio por cada empresa para sus clientes (dentro de plataforma.com/{slug}). No comparten pantalla ni JWT entre sí.
2. Una cuenta de cliente pertenece a una única empresa. Un mismo email puede repetirse en distintas empresas (son cuentas independientes); lo que no puede repetirse es el email dentro de una misma empresa.
3. La página pública de cada empresa es visible sin login (consulta de servicios y horarios), pero reservar un turno requiere estar logueado como cliente de esa empresa puntual.
4. El JWT no tiene refresh token y expira a las 24 horas; pasado ese tiempo el usuario (de cualquiera de los dos sistemas de login) debe volver a loguearse.

### Empresas

5. Dar de baja una empresa significa desactivarla, nunca eliminar el registro. Al desactivar: se bloquea el login de su admin, la página pública muestra un estado de "no disponible", los turnos pendientes se cancelan automáticamente notificando a cada cliente afectado, y el historial se conserva por si se reactiva. 
6. Reactivar una empresa es lo inverso: vuelve a estado `ACTIVE`, se desbloquea el login del admin (sin necesitar un nuevo link de activación si ya tenía contraseña definida) y la página pública vuelve a aceptar reservas con la configuración de servicios/horarios que ya tenía cargada. Los turnos cancelados durante la baja quedan cancelados — no se recrean automáticamente.

### Disponibilidad y concurrencia
7. Un turno reservado no puede superponerse con otro del mismo negocio en la misma franja horaria (validado por rango, no por horario exacto, dado que los servicios tienen duración variable).
8. La validación de superposición y el guardado del turno ocurren dentro de una misma transacción con lock pesimista (SELECT ... FOR UPDATE / @Lock(PESSIMISTIC_WRITE)), para evitar doble reserva ante requests simultáneos.
9. No se puede reservar un turno con menos de 30 minutos de anticipación sobre el horario elegido (valor inicial ajustable), ni en horarios ya pasados.

### Cancelación y reprogramación
10. El cliente puede cancelar o reprogramar su turno hasta 3 horas antes (valor inicial ajustable). Pasado ese plazo, debe contactar al negocio por fuera del sistema; el admin puede cancelar ese turno desde su turnero sin restricción horaria, liberando el horario para otra persona.
11. El admin de empresa puede cancelar cualquier turno de su negocio sin restricción horaria, dejando registrado quién lo canceló (`CLIENT` o `COMPANY`) y un motivo en texto libre opcional.
12. Reprogramar un turno actualiza el mismo registro (nueva fecha/hora, se conserva la fecha anterior, estado = `RESCHEDULED`), en vez de crear un turno nuevo y cancelar el anterior.
13. Un turno cancelado no puede reactivarse desde "Mis turnos" del cliente; si quiere el mismo horario debe reservarlo de nuevo (sujeto a disponibilidad).

### Turnos manuales (sin cuenta)
14. Al cargar un turno manualmente, el admin indica si el cliente tiene cuenta en la plataforma. Si tiene, lo busca y selecciona desde un desplegable, y el turno queda vinculado a su `clientId` — después puede loguearse y autogestionarlo desde "Mis turnos" como cualquier otro. Si no tiene cuenta, el admin carga sus datos sueltos (nombre, teléfono) sin `clientId`; en ese caso, para cancelarlo debe contactar al negocio, y es el admin quien lo cancela desde el turnero.

### Servicios y horarios
15. Desactivar un servicio con turnos futuros asociados no cancela esos turnos: dejan de ofrecerse a nuevas reservas, pero los ya reservados se mantienen y se atienden con normalidad. Cancelarlos, si el admin lo decide, es una acción manual aparte.
16. Editar la configuración de horarios de una empresa no afecta a los turnos ya reservados fuera del nuevo rango: se mantienen igual, el sistema solo avisa al admin de cuántos turnos quedan en esa situación.

### Notificaciones
17. Se envía notificación por WhatsApp cuando: se confirma una reserva (online o manual), se cancela un turno (por cliente o negocio), o se reprograma un turno. La notificación es informativa — el turno ya queda confirmado en el sistema en el momento de guardarse, no depende de que el cliente confirme el aviso.

### Alcance
18. No se maneja dinero dentro del sistema (sin señas ni pagos online): se descartó explícitamente por el riesgo de reintroducir conflictos de doble reserva mientras se espera confirmación de un pago externo.
19. Fechas/horas de los turnos se almacenan en UTC (Instant/OffsetDateTime en el backend); la conversión a hora local se hace en el frontend.
20. No se manejan múltiples empleados/profesionales por empresa en esta versión: la disponibilidad es a nivel de negocio, no de persona.

### Historial
21. Un job programado pasa automáticamente los turnos `PENDING`/`RESCHEDULED` a `COMPLETED` una vez que su `startDateTime` ya pasó. `CANCELLED` es un estado terminal y nunca pasa a `COMPLETED`. "Mis turnos" no tiene una sección de historial aparte: lista todo, ordenable/filtrable por estado, y los turnos `COMPLETED` cumplen esa función.
