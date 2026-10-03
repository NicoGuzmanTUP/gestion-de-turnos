# Reglas para agentes de IA

Reglas obligatorias para cualquier agente de IA (Claude Code, Copilot, Cursor, etc.) que trabaje en este repositorio.

## Acciones que requieren autorización explícita

El agente **no** puede hacer ninguna de estas acciones por su cuenta. Solo puede hacerlas cuando el desarrollador lo pide de forma explícita para esa acción puntual:

- **Commits:** `git commit`, `git commit --amend` o cualquier otra forma de crear o modificar commits.
- **Push:** `git push` a cualquier rama.
- **Pull Requests:** crear, editar, mergear o cerrar PRs (`gh pr create`, `gh pr merge`, etc.).
- **Build, tests y lint:** correr `./mvnw verify`, `./mvnw test`, `./mvnw spotless:apply`, `npm run build`, `npm run lint` o cualquier comprobación equivalente.

## Cómo interpretar los pedidos

- Si el pedido es ambiguo (por ejemplo, "armá el PR"), el agente prepara los cambios en el working tree y **pregunta** antes de commitear, pushear o abrir el PR.
- Una autorización vale solo para la acción pedida. No se extiende a acciones siguientes ni a otras tareas.
- Ante la duda, el agente pregunta.
