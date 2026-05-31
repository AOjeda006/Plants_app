# Plants App — Red social de cuidado de plantas

> Aplicación full-stack para la gestión y el cuidado de plantas con comunidad social: un backend **Node.js + TypeScript (NestJS/Express + InversifyJS)** sobre **MongoDB**, con **Socket.IO** en tiempo real, y un cliente **Flutter** multiplataforma, ambos construidos sobre **Clean Architecture** con el mismo modelo de dominio espejado.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-20-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![NestJS](https://img.shields.io/badge/NestJS-11-E0234E?logo=nestjs&logoColor=white)](https://nestjs.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7-47A248?logo=mongodb&logoColor=white)](https://www.mongodb.com/)
[![Socket.IO](https://img.shields.io/badge/Socket.IO-Real--time-010101?logo=socketdotio&logoColor=white)](https://socket.io/)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-Images-3448C5?logo=cloudinary&logoColor=white)](https://cloudinary.com/)

---

## Tabla de contenidos

1. [Descripción](#descripción)
2. [Características](#características)
3. [Stack tecnológico](#stack-tecnológico)
4. [Arquitectura](#arquitectura)
5. [Estructura del proyecto](#estructura-del-proyecto)
6. [Modelo de datos](#modelo-de-datos)
7. [API REST y tiempo real](#api-rest-y-tiempo-real)
8. [Flujo de una operación de extremo a extremo](#flujo-de-una-operación-de-extremo-a-extremo)
9. [Diseño visual](#diseño-visual)
10. [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)
11. [Autenticación y acceso](#autenticación-y-acceso)
12. [Pruebas](#pruebas)
13. [Decisiones técnicas destacadas](#decisiones-técnicas-destacadas)
14. [Autor](#autor)

---

## Descripción

**Plants App** es una aplicación para que aficionados a la jardinería **cataloguen
sus plantas**, reciban **recordatorios de cuidado** (riego, poda, abonado, cosecha)
calculados a partir de la **especie** y el **clima local**, y participen en una
**comunidad social** con feed de publicaciones, comentarios, *likes*, mensajería
privada en tiempo real y un calendario anual de eventos por planta. Incluye además
un **panel de moderación** para administradores (gestión de reportes, baneos y
ejecución manual del cron de recordatorios).

El proyecto se ha desarrollado como Trabajo de Fin de Grado y pieza de portfolio para
demostrar el desarrollo **full-stack end-to-end** de una aplicación real con estado
compartido, comunicación bidireccional y trabajo offline: un backend en **Node.js +
TypeScript** con persistencia en MongoDB, reglas de negocio encapsuladas y una API
REST documentada con OpenAPI; y un cliente **Flutter** multiplataforma (Android, iOS,
web y escritorio) con autenticación, navegación declarativa, caché offline y una UI
cuidada con Material 3.

Lo más destacable del diseño es que **ambos lados aplican la misma Clean Architecture
y espejan el mismo modelo de dominio** (`User`, `Plant`, `PlantSpecies`, `Reminder`,
`Post`, `Conversation`, `Message`, `Notification`…): el backend lo implementa en
TypeScript y el cliente lo replica en Dart, manteniendo cliente y servidor alineados
a través de los DTOs del contrato REST y los eventos de Socket.IO.

El backend es la **fuente de verdad**: valida cada operación, calcula los
recordatorios con su propio motor y arbitra el chat y las notificaciones en tiempo
real. El cliente refleja ese estado de forma reactiva y mantiene una **cola offline**
que sincroniza las acciones pendientes al recuperar conexión.

---

## Características

### Gestión de plantas

- **Catálogo personal** de plantas con foto, especie, ubicación y notas; alta,
  edición, archivado y borrado lógico.
- **Catálogo de especies** precargado (siembra inicial) con metadatos de cuidado
  (frecuencias de riego, poda, abonado y cosecha) que alimentan el motor de
  recordatorios.
- **Recordatorios automáticos** por planta, derivados de la especie y ajustados por
  el clima local: una planta no necesita riego si ha llovido recientemente.
- **Historial de cuidados** (`ReminderHistory`) y **calendario anual** de eventos por
  planta, navegable por meses.
- **Avisos meteorológicos** (lluvia / tormenta) a partir de la ubicación del usuario,
  con caché de las consultas a la API del tiempo.

### Comunidad social

- **Feed de publicaciones** con imagen, texto y autor; creación, edición y borrado.
- **Comentarios** y **likes** sobre las publicaciones, con contadores reactivos.
- **Perfiles públicos** de usuario con sus publicaciones.
- **Mensajería privada en tiempo real** (Socket.IO): conversaciones 1 a 1, indicador
  de entrega y notificación push si el destinatario está desconectado.
- **Reportes** de contenido o usuarios, gestionados desde el panel de moderación.

### Notificaciones — sistema de tres capas

- **Capa 1 — MongoDB**: toda notificación se persiste como fuente de verdad
  (permanece hasta que el usuario la elimina).
- **Capa 2 — Socket.IO**: si el usuario está conectado, recibe el aviso en vivo
  (badge y lista se actualizan al instante).
- **Capa 3 — Firebase Cloud Messaging**: si la app está cerrada y hay token FCM
  registrado, llega un *push* al sistema operativo. Sin credenciales FCM el backend
  opera en **modo mock** y las capas 1 y 2 siguen funcionando.

### Administración

- **Panel de moderación**: listado y resolución de reportes, **baneo temporal** de
  usuarios (bloquea la escritura mientras `bannedUntil` esté vigente) y disparo
  manual del cron de recordatorios.

### Transversales

- **Autenticación** con JWT (sesión persistente híbrida con *refresh*) y *hashing* de
  contraseñas con bcrypt.
- **Trabajo offline**: caché local con Hive y **cola de acciones** que se sincroniza
  al volver la conexión.
- **Internacionalización** (español / inglés) mediante archivos `.arb`.
- **Tema Material 3** propio (claro y oscuro) con paleta corporativa verde.
- **Tareas programadas** (cron): recordatorios diarios, limpieza de caché de clima
  caducada y purga de registros con borrado lógico.

---

## Stack tecnológico

### Backend (`/BackEnd`)

| Categoría          | Tecnología                                                              |
| ------------------ | ----------------------------------------------------------------------- |
| Lenguaje           | **TypeScript 5.7** sobre **Node.js 20**                                 |
| Host web           | **NestJS 11** (`@nestjs/platform-express`) sobre Express                |
| Arquitectura       | Clean Architecture: `core` · `domain` · `data` · `presentation`         |
| Inyección de dep.  | **InversifyJS** (contenedor configurado manualmente)                    |
| Persistencia       | **MongoDB 7** con el driver nativo `mongodb`                            |
| Tiempo real        | **Socket.IO 4** (chat y notificaciones)                                 |
| Autenticación      | **JWT** (`jsonwebtoken`) + **bcryptjs** + `express-rate-limit`          |
| Imágenes           | **Cloudinary**                                                          |
| Clima              | **WeatherAPI.com** (con `MOCK_WEATHER_MODE` para desarrollo)            |
| Push               | **Firebase Cloud Messaging** (`firebase-admin`, opcional / modo mock)   |
| Tareas programadas | `node-cron` (recordatorios, limpieza de caché, purga)                   |
| Seguridad          | `helmet`, `cors`, sanitización y límite de payload                      |
| Logging            | **winston** (estructurado, JSON en producción)                          |
| Documentación      | **OpenAPI 3.0.3** (`openapi.yaml`)                                      |
| Pruebas            | **Jest** + `ts-jest` + `supertest`                                      |

### Frontend (`/FrontEnd`)

| Categoría          | Tecnología                                                              |
| ------------------ | ----------------------------------------------------------------------- |
| Lenguaje           | **Dart 3.11** (modo estricto)                                           |
| Framework          | **Flutter** (Android, iOS, web, escritorio)                             |
| UI                 | **Material 3** + tema propio (claro / oscuro)                           |
| Arquitectura       | Clean Architecture: `core` · `domain` · `data` · `presentation`         |
| Estado             | **MVVM** con `provider` (`ChangeNotifier` ViewModels)                   |
| Inyección de dep.  | **GetIt** (contenedor de *singletons* en `core/di`)                     |
| Red                | **Dio** (HTTP) + **socket_io_client** (tiempo real)                     |
| Offline            | **Hive** + `connectivity_plus` (caché y cola de sincronización)         |
| Sesión             | `flutter_secure_storage` + `shared_preferences`                         |
| Imágenes           | `image_picker` + `flutter_image_compress` + `cached_network_image`      |
| Push               | `firebase_messaging` + `flutter_local_notifications`                    |
| i18n               | `flutter_localizations` + `intl` + `.arb` (es / en)                     |
| Calendario         | `table_calendar`                                                        |
| Pruebas            | `flutter_test` + `integration_test`                                     |

---

## Arquitectura

Dos aplicaciones independientes que se comunican por una **API REST** (operaciones
puntuales) y un **hub de Socket.IO** (chat y notificaciones en vivo). El servidor es
autoritativo; el cliente refleja su estado y replica el mismo modelo de dominio.

```
        ┌───────────────────────────────┐         ┌───────────────────────────────┐
        │      CLIENTE (Flutter)         │         │      SERVIDOR (Node.js)        │
        │                                │  REST   │                                │
        │  presentation (MVVM + Provider)│ ──────► │  presentation (Controllers,    │
        │  domain (entidades + casos)    │  /api   │     Gateways, Jobs)            │
        │  data (DataSources + Repos)    │ ◄─────► │  domain (UseCases + entidades) │
        │  core (DI + red + offline)     │ Socket  │  data (MongoDB + Repos)        │
        └───────────────────────────────┘  .IO    │  core (DI + config + seguridad)│
                                                   └───────────────────────────────┘
                     mismo modelo de dominio espejado (User, Plant, Post, Message…)
```

Ambos lados siguen **Clean Architecture**: las dependencias apuntan siempre hacia el
dominio, que no conoce ni a MongoDB, ni a HTTP, ni a Socket.IO, ni a la UI.

### Backend — capas

- **`core`** — configuración por área (`auth`, `database`, `weather`, `cloudinary`,
  `firebase`, `ops`…), contenedor de inyección de dependencias (InversifyJS),
  *middlewares* (auth, ban, seguridad, sanitización, logging, errores), políticas y
  el servicio de notificaciones.
- **`domain`** — núcleo puro, sin dependencias de Express ni MongoDB:
  - **13 entidades** (`User`, `Plant`, `PlantSpecies`, `Reminder`, `ReminderHistory`,
    `Post`, `Comment`, `PostLike`, `Conversation`, `Message`, `Notification`,
    `Report`, `WeatherCache`).
  - **DTOs** e **interfaces** de repositorios y casos de uso (la fuente de verdad del
    contrato).
  - **~38 casos de uso** agrupados por agregado (`auth`, `plants`, `reminders`,
    `weather`, `community`, `chat`, `notifications`, `user`), cada uno con su lógica
    de negocio encapsulada.
- **`data`** — implementación de persistencia con MongoDB: conexión y creación de
  índices, *schemas* de validación, **12 repositorios** y *mappers* documento ↔
  entidad de dominio.
- **`presentation`** — **13 controladores** REST (routers de Express), el
  **`SocketGateway`** de Socket.IO, los **cron jobs** (`node-cron`), servicios de
  infraestructura (JWT, Socket, subida a Cloudinary…) y los validadores de entrada.

### Frontend — capas

- **`core`** — `ApiClient` (Dio) y `SocketClient`, contenedor de DI (GetIt), almacenamiento
  offline (Hive), servicios globales, errores y utilidades.
- **`domain`** — entidades espejo del servidor, interfaces de repositorios y casos de
  uso, y sus DTOs.
- **`data`** — *DataSources* (REST y Socket), repositorios y *mappers* DTO ↔ entidad.
- **`presentation`** — patrón **MVVM**: un `ViewModel` (`ChangeNotifier`) por área
  expone estado observable, las *pages* lo consumen vía `provider`, más los *widgets*
  reutilizables, las rutas y los validadores de formulario.

---

## Estructura del proyecto

```
Plants_app/
├── BackEnd/                         # API REST + Socket.IO (Node.js + TypeScript)
│   ├── src/
│   │   ├── core/                    # config, DI (InversifyJS), middleware, policies
│   │   ├── domain/                  # entities · dtos · interfaces · repositories · usecases
│   │   ├── data/                    # datasources (MongoDB) · repositories · mappers
│   │   ├── presentation/            # controllers · gateways · jobs · services · validators
│   │   ├── scripts/                 # seeds (species, locations, admin)
│   │   ├── app.module.ts
│   │   └── main.ts                  # bootstrap: DI → MongoDB → middlewares → rutas → listen
│   ├── test/                        # tests E2E
│   └── .env.example
│
├── FrontEnd/                        # App Flutter (Clean Architecture)
│   ├── lib/
│   │   ├── core/                    # network, di (GetIt), storage (Hive), services, utils
│   │   ├── domain/                  # entities · dtos · interfaces · repositories · usecases
│   │   ├── data/                    # datasources · repositories · models · mappers
│   │   ├── presentation/            # pages · widgets · viewmodels · routes · validators
│   │   ├── l10n/                    # localizaciones (es / en)
│   │   └── main.dart
│   ├── test/                        # tests unitarios y de widget
│   ├── integration_test/            # tests E2E
│   └── .env.example
│
├── Documentacion/                   # Memoria del TFG, diagramas y especificación OpenAPI
│   ├── Documentacion_TFG.pdf
│   ├── Diagramas/                   # casos de uso, clases, modelo físico de datos (SVG)
│   └── openapi.yaml                 # especificación OpenAPI 3.0.3 de la API
│
└── README.md
```

---

## Modelo de datos

Trece colecciones en MongoDB. Las relaciones se modelan por referencia (`ObjectId`) y
las operaciones de borrado emplean **borrado lógico** (`deletedAt`) con una purga
programada posterior:

```
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│    users     │ 1    * │   plants     │ *    1 │   species    │
├──────────────┤────────├──────────────┤────────├──────────────┤
│ _id          │        │ _id          │        │ _id          │
│ name         │        │ userId (FK)  │        │ commonName   │
│ email (U)    │        │ speciesId(FK)│        │ scientific   │
│ passwordHash │        │ nickname     │        │ wateringDays │
│ role         │        │ location     │        │ pruningDays  │
│ fcmToken     │        │ photoUrl     │        │ …cuidados    │
│ bannedUntil  │        │ deletedAt    │        └──────────────┘
│ preferences  │        └──────┬───────┘
└──────┬───────┘               │ 1
       │ 1                     ▼ *
       │              ┌──────────────┐        ┌────────────────┐
       │              │  reminders   │ ─────► │ reminderHistory│
       │              ├──────────────┤        └────────────────┘
       │              │ plantId (FK) │
       │              │ type         │        ┌──────────────┐
       │              │ dueDate      │        │ weatherCache │
       │              │ status       │        ├──────────────┤
       │              └──────────────┘        │ location     │
       │                                      │ cachedAt     │
       ├──── posts ── comments ── postLikes   └──────────────┘
       │
       ├──── conversations ──── messages
       │
       ├──── notifications
       │
       └──── reports
```

**Decisiones de modelado relevantes:**

- **`email` único** con índice en MongoDB: la unicidad la garantiza la base de datos,
  no la aplicación.
- **Contraseñas hasheadas** con bcrypt; `passwordHash` y `fcmToken` nunca se exponen
  al cliente (la entidad `User` ofrece un `sanitizeForPublic()`).
- **Recordatorios derivados**: la fecha de cada `Reminder` se calcula a partir de las
  frecuencias de cuidado de la especie y se reajusta con el clima cacheado.
- **Disponibilidad de cuidado climatizada**: la caché de clima (`weatherCache`) evita
  golpear la API externa en cada cálculo y guarda la marca temporal del último cron.
- **Borrado lógico** (`deletedAt`) en plantas y contenido de comunidad: nada se borra
  físicamente al instante; un **cron de purga** elimina los registros caducados.
- **Baneo por ventana temporal**: `User.bannedUntil` bloquea la escritura mientras la
  fecha siga vigente, verificado por un *middleware* de baneo.
- **Notificaciones persistentes**: cada aviso se guarda en `notifications` (capa 1),
  con Socket.IO (capa 2) y FCM (capa 3) como transportes volátiles encima.

---

## API REST y tiempo real

Base REST: `/`. Especificación interactiva completa en
[`Documentacion/openapi.yaml`](Documentacion/openapi.yaml) (**OpenAPI 3.0.3**, ~60
operaciones agrupadas por dominio). Importable directamente en
[editor.swagger.io](https://editor.swagger.io).

### Endpoints REST (resumen por área)

| Área            | Prefijo          | Operaciones principales                                      |
| --------------- | ---------------- | ------------------------------------------------------------ |
| Autenticación   | `/auth`          | registro, login, *refresh* de token                         |
| Plantas         | `/plants`        | CRUD de plantas del usuario                                  |
| Especies        | `/species`       | búsqueda en el catálogo de especies                         |
| Recordatorios   | `/reminders`     | listado y resolución de recordatorios                       |
| Clima           | `/weather`       | clima y avisos por ubicación                                |
| Ubicaciones     | `/locations`     | búsqueda de ubicaciones (capitales precargadas)             |
| Comunidad       | `/community`     | posts, comentarios y *likes*                                |
| Chat            | `/chat`          | conversaciones y mensajes (historial)                       |
| Usuarios        | `/users`         | perfil, preferencias, token FCM, cambio de contraseña       |
| Notificaciones  | `/notifications` | listado y marcado de notificaciones                         |
| Reportes        | `/reports`       | creación de reportes de contenido                           |
| Subida          | `/upload`        | subida de imágenes a Cloudinary                             |
| Administración  | `/admin`         | moderación, baneos y disparo del cron                       |
| Salud           | `/health`, `/ready` | *health check* enriquecido y *readiness*                 |

### Eventos de Socket.IO

El cliente abre una conexión autenticada al hub y el servidor emite eventos en
tiempo real:

| Evento (servidor → cliente) | Significado                                            |
| --------------------------- | ------------------------------------------------------ |
| `message:new`               | Mensaje nuevo en una conversación del usuario          |
| `notification:new`          | Notificación nueva (actualiza badge y lista en vivo)   |

---

## Flujo de una operación de extremo a extremo

Enviar un mensaje de chat recorre las dos aplicaciones, las cuatro capas de cada una
y combina REST con tiempo real:

```
 CLIENTE (Flutter)                                  SERVIDOR (Node.js)
 ─────────────────                                  ──────────────────
 ChatPage  (escribe y envía)
   └─ ChatViewModel.send(texto)
        └─ SendMessageUseCase
             └─ ChatRepository
                  └─ ApiDataSource ──HTTP POST /chat/…──►  ChatController.send(req)
                                                              └─ SendMessageUseCase
                                                                   ├─ persiste Message (MongoDB)
                                                                   ├─ crea Notification (capa 1)
                                                                   └─ ¿receptor conectado?
                       ◄──── 201 Created + MessageDTO ─────────────┘
                                                       sí ─► SocketGateway emite
                                                              "message:new" al receptor
                                                       no ─► NotificationService envía
                                                              push FCM (capa 3)

 El receptor (otro cliente) recibe "message:new" por Socket.IO; su ChatViewModel
 actualiza el estado observable y la conversación se re-renderiza sin recargar.
```

La actualización en la UI del receptor ocurre **reactivamente**: el `ViewModel`
(`ChangeNotifier`) recibe el evento de Socket.IO, actualiza su estado y `provider`
notifica a los *widgets* suscritos. Si el cliente está **sin conexión** al actuar, la
acción se encola en Hive y se reintenta automáticamente al recuperar la red.

---

## Diseño visual

Tema Material 3 personalizado, con soporte **claro y oscuro**, basado en una paleta
corporativa verde inspirada en la jardinería. Todos los *widgets* referencian
`AppColors` o el `Theme`, nunca colores literales:

| Token             | Hex       | Uso                                                |
| ----------------- | --------- | -------------------------------------------------- |
| `primary`         | `#2E8B57` | Verde bosque — logo, botones y acciones principales|
| `secondary`       | `#7BC47F` | Verde claro — apoyo, *chips*, *badges* activos     |
| `accent`          | `#FFD166` | Amarillo cálido — CTA, etiquetas destacables, FAB  |
| `backgroundLight` | `#F7F9F6` | Blanco roto — fondo de páginas                     |
| `surface`         | `#E8EDE6` | Gris con tinte verde — *cards* y superficies        |
| `textPrimary`     | `#263238` | Gris antracita — texto principal (WCAG AAA)        |
| `textSecondary`   | `#607D6B` | Gris cálido — texto secundario y *hints*           |
| `success`         | `#38C172` | Verde — éxito, riego completado                    |
| `warning`         | `#F0A030` | Ámbar — aviso, riego próximo                        |
| `error`           | `#E04F5F` | Rojo suave — error y acciones destructivas         |

La paleta cuida los contrastes **WCAG**: incluye variantes oscurecidas (`accentText`,
`errorText`) para los tonos que no son aptos como texto sobre fondos claros, y un
juego de neutros oscuros (`backgroundDark`, `surfaceDark`) para el tema oscuro.

---

## Cómo ejecutar el proyecto

Necesitas el **backend en marcha** y una base de datos accesible **antes** de arrancar
el cliente.

### Requisitos

- **Node.js 20+** y npm
- **Flutter 3.x** (Dart 3.11+)
- **MongoDB 7** (local o **MongoDB Atlas**)
- Cuentas gratuitas en **Cloudinary** y **WeatherAPI.com** (opcionales: en desarrollo
  pueden usarse en modo simulado)
- *Opcional:* proyecto **Firebase** con Cloud Messaging para *push* reales

### 1. Backend (Node.js)

```bash
cd BackEnd
npm install
cp .env.example .env        # y rellena los valores (ver más abajo)
```

Configura `BackEnd/.env` a partir de la plantilla. Los valores mínimos para arrancar
en local:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/plants
JWT_SECRET=cambia_esto_por_una_cadena_larga_y_segura
MOCK_WEATHER_MODE=true        # evita consumir cuota de WeatherAPI en desarrollo
# CLOUDINARY_URL, WEATHER_API_KEY y FCM_SERVICE_ACCOUNT_JSON son opcionales
```

> Las claves de Cloudinary, WeatherAPI y Firebase **no** se incluyen en el
> repositorio: el `.env` está en `.gitignore` y solo se versiona `.env.example` con
> *placeholders*. Sin esas claves el backend funciona en modo simulado.

Siembra el catálogo y el usuario admin (scripts idempotentes) y arranca:

```bash
npm run seed:species      # catálogo de especies
npm run seed:locations    # ubicaciones precargadas
npm run seed:admin        # usuario admin (lee ADMIN_EMAIL / ADMIN_PASSWORD del .env)

npm run start:dev         # desarrollo con recarga
# o: npm run build && npm run start:prod
```

La API queda disponible en `http://localhost:3000`. Verifícalo con
`GET http://localhost:3000/health`.

### 2. Frontend (Flutter)

```bash
cd FrontEnd
flutter pub get
cp .env.example .env        # apunta API_BASE_URL / SOCKET_URL a tu backend
flutter run
```

Por defecto el cliente apunta al backend desplegado. Para desarrollar contra un
backend local:

```bash
flutter run --dart-define=USE_LOCAL=true     # usa http://localhost:3000
```

> En el emulador de Android, `localhost` del host es `10.0.2.2`. Para un dispositivo
> físico por USB puedes redirigir el puerto con `adb reverse tcp:3000 tcp:3000`.

---

## Autenticación y acceso

El acceso se controla con **JWT**: el login devuelve un *access token* (sesión
persistente con *refresh*) que el cliente guarda de forma segura
(`flutter_secure_storage`) e inyecta como `Bearer` en cada petición REST y en la
conexión de Socket.IO. Las contraseñas se almacenan **hasheadas con bcrypt** y nunca
viajan de vuelta al cliente.

Un *middleware* protege las rutas autenticadas y otro verifica el **baneo temporal**
antes de cualquier escritura en comunidad o chat. El usuario administrador se crea con
`npm run seed:admin`, que lee `ADMIN_EMAIL` y `ADMIN_PASSWORD` de las variables de
entorno (con *defaults* pensados solo para desarrollo local — define una contraseña
segura antes de sembrar contra un entorno compartido).

---

## Pruebas

```bash
# Backend — Jest
cd BackEnd
npm test                  # suite completa
npm run test:coverage     # con informe de cobertura (coverage/)

# Frontend — flutter_test + integration_test
cd FrontEnd
flutter test              # unitarios y de widget
flutter test integration_test/   # E2E (requiere backend en localhost:3000)
```

La estrategia es **piramidal**: se testean exhaustivamente los **casos de uso de
dominio** y los **ViewModels** (donde vive la lógica de negocio y de presentación), y
se delega la verificación de controladores, *datasources*, *mappers* y DI a los
**tests E2E** ejecutados contra un backend real. En total el proyecto reúne **cerca de
500 pruebas automatizadas** entre ambos lados.

---

## Decisiones técnicas destacadas

- **Clean Architecture espejada en ambos lados**: el mismo modelo y la misma
  separación de capas (dominio → datos → presentación) se implementan en TypeScript y
  en Dart, comunicados por DTOs. El dominio nunca depende de MongoDB, HTTP, Socket.IO
  ni la UI.
- **Inyección de dependencias explícita**: el backend cablea el contenedor de
  InversifyJS a mano en `core/container.ts` (NestJS solo actúa de *host* sobre
  Express); el frontend registra sus *singletons* con GetIt. El ciclo de vida de las
  dependencias queda a la vista, sin magia oculta.
- **Notificaciones en tres capas**: persistencia en MongoDB (fuente de verdad),
  entrega en vivo por Socket.IO y *push* por FCM. El sistema degrada con elegancia: sin
  credenciales FCM las dos primeras capas siguen operativas (modo mock).
- **Recordatorios climatizados**: el motor calcula las fechas de cuidado a partir de
  la especie y las ajusta con el clima local cacheado, evitando avisar de un riego
  innecesario tras la lluvia.
- **Trabajo offline real**: el cliente cachea datos en Hive y mantiene una **cola de
  acciones** que se reintenta al recuperar conexión, detectada con `connectivity_plus`.
- **Borrado lógico + purga programada**: el contenido se marca como borrado y un cron
  lo elimina después, evitando borrados destructivos inmediatos y permitiendo
  recuperación.
- **Tiempo real autenticado y robusto**: la conexión de Socket.IO viaja con el token
  JWT; el gateway emite solo a los destinatarios pertinentes y el cliente sobrevive a
  reconexiones sin duplicar *handlers*.
- **Despliegue en *free tier* consciente**: backend en Render y base de datos en
  MongoDB Atlas; un *health check* enriquecido (`/health`) reporta el estado de
  MongoDB, WeatherAPI y FCM, y un cron externo "despierta" el contenedor antes de la
  tarea nocturna de recordatorios para mitigar el *cold start*.
- **Seguridad por defecto**: `helmet`, CORS, sanitización de entrada, *rate limiting*,
  límite de payload, baneo por ventana temporal y *hashing* bcrypt; los secretos viven
  solo en variables de entorno y nunca se versionan.

---

## Autor

**Andrés Ojeda Rodríguez**
[andresojedarodriguez@gmail.com](mailto:andresojedarodriguez@gmail.com)


---

## Licencia

Este proyecto está licenciado bajo la **PolyForm Noncommercial License 1.0.0**.
Puedes ver, ejecutar, estudiar y modificar el código con fines **no comerciales**
(estudio personal, educación, evaluación), pero **cualquier uso comercial requiere
permiso escrito del autor**. Consulta el archivo [LICENSE.md](LICENSE.md) para los
términos completos.

© 2026 Andrés Ojeda Rodríguez. Todos los derechos no concedidos expresamente quedan reservados.
