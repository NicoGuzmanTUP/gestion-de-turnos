# 🛠️ 2. Tecnologías y Arquitectura

A continuación se detallan las herramientas, marcos de trabajo e infraestructura seleccionados para el desarrollo del proyecto, junto con la justificación técnica de cada elección:

## 📋 Matriz de Stack Tecnológico

| Capa | Tecnología | Motivo / Justificación Técnica |
| :--- | :--- | :--- |
| **Backend** | **Java + Spring Boot** | Stack ya utilizado en la cursada; ecosistema robusto y maduro para autenticación (`Spring Security` + `JWT`), manejo de transacciones y validaciones de negocio. |
| **Frontend** | **React + TypeScript (Vite)** | Arquitectura basada en componentes reutilizables (ideal para las páginas públicas de cada empresa); tipado fuerte para modelar las entidades del dominio de forma segura. |
| **Base de Datos** | **PostgreSQL** *(ej. Neon)* | Motor relacional idóneo por las relaciones estrictas entre empresas, servicios, usuarios y turnos, garantizando la integridad referencial necesaria al validar la disponibilidad. |
| **ORM** | **Spring Data JPA / Hibernate** | Abstracción para el manejo de entidades y soporte de *locking* pesimista para evitar carreras de condición (*race conditions*) en reservas concurrentes. |
| **Autenticación** | **JWT (Spring Security)** | Dos JWT *stateless* independientes: uno para el panel de sistema (`SUPERADMIN` / `COMPANY_ADMIN`) y uno por sesión de cliente, atado a una `companyId` puntual. |
| **Notificaciones** | **NotificationService** *(Desacoplado)* | Canal objetivo: WhatsApp (proveedor a definir). Si no se llega a implementar a tiempo, se reemplaza por mail — es una decisión de proyecto, no un fallback en tiempo real. |
| **Deploy Backend** | **Render** *(Free Tier)* | Plataforma de despliegue gratuita adecuada para el alcance de la tesis. |
| **Deploy Frontend** | **Vercel** | Despliegue continuo de alto rendimiento y sin complicaciones de configuración para la escala del proyecto. |
| **CI/CD** | **GitHub Actions** | Automatización de flujos de trabajo para la ejecución de tests automáticos en cada *Pull Request*. |

---

## 🔍 Detalle por Componente del Sistema

### ⚙️ Backend & Persistencia
* **Framework:** Java + Spring Boot
* **ORM:** Spring Data JPA / Hibernate
* **Base de Datos:** PostgreSQL
* **Estrategia de Concurrencia:** 
  $$\text{Locking Pesimista} \longrightarrow \text{Evita superposición de turnos simultáneos}$$

### 🎨 Frontend & Interfaz de Usuario
* **Librería/Framework:** React
* **Lenguaje:** TypeScript
* **Bundler/Tooling:** Vite
* **Enfoque de UI:** Componentes modulares reutilizados entre el panel administrativo y las *landings* públicas por empresa.

### 🔐 Seguridad & Control de Acceso
* **Esquema:** JSON Web Tokens (JWT) vía Spring Security
* **Roles del Sistema:**
  1. `SUPERADMIN` — Gestión global de empresas y plataforma.
  2. `COMPANY_ADMIN` — Administración de agenda, precios, servicios y horarios propios.
  3. `CLIENT` — Consulta de disponibilidad y reserva/gestión de citas.

### 🔔 Servicio de Notificaciones
```text
[ Evento: Reserva / Cancelación / Reprogramación ]
               │
               ▼
   NotificationService (Desacoplado)
               │
               ▼
          [ WhatsApp ]
        (canal objetivo)

```

### 🚀 Infraestructura & Integración Continua (DevOps)

* **Control de Versiones & CI/CD:** GitHub + GitHub Actions *(Ejecución automática de suites de prueba en PRs)*.
* **Hosting Frontend:** Vercel
* **Hosting Backend:** Render
