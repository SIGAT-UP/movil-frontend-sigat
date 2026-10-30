# 🍑 SIGAT Móvil — Vigilancia fitosanitaria del durazno

Aplicación móvil del sistema **SIGAT (Sistema de Información para la Gestión y Análisis Territorial)**, orientada al seguimiento fitosanitario del cultivo de durazno y al monitoreo de la mosca del Mediterráneo (*Ceratitis capitata*).

Desarrollada con **Flutter y Dart**, permite gestionar y consultar información relacionada con la vigilancia de cultivos, inspección de trampas, actividades de campo y seguimiento fitosanitario.

La aplicación forma parte de una plataforma integral que conecta los procesos realizados desde dispositivos móviles con los servicios del backend y la plataforma web de SIGAT.

## 🎯 Objetivo del proyecto

Facilitar el registro, consulta y seguimiento de información fitosanitaria en campo, proporcionando herramientas digitales para apoyar las actividades de técnicos, productores y agrónomos.

SIGAT Móvil busca centralizar la información del cultivo, mejorar el seguimiento de las actividades realizadas y facilitar el acceso a los datos necesarios para la vigilancia fitosanitaria.

## 👥 Perfiles de usuario

La aplicación organiza sus funcionalidades de acuerdo con los diferentes perfiles:

- **Técnico:** realiza actividades de campo, inspecciones, identificación de trampas y registro de lecturas y evidencias.
- **Productor:** consulta información relacionada con su cultivo y registra actividades productivas, como aplicaciones y cosechas.
- **Agrónomo:** consulta información fitosanitaria, revisa registros y participa en actividades de planificación y seguimiento.

Cada perfil cuenta con opciones de navegación y funcionalidades según sus responsabilidades dentro del sistema.

## ✨ Funcionalidades principales

- **Autenticación:** inicio y cierre de sesión, validación de credenciales y recuperación de sesiones.
- **Gestión de lotes:** acceso a la información de los lotes asociados a las actividades de vigilancia.
- **Monitoreo de trampas:** identificación y seguimiento de trampas utilizadas en el control fitosanitario.
- **Registro de lecturas:** captura de información obtenida durante las inspecciones.
- **Visitas de campo:** seguimiento de las actividades realizadas durante las jornadas de inspección.
- **Evidencias fotográficas:** captura y selección de imágenes para respaldar los registros.
- **Actividades del productor:** registro de aplicaciones y cosechas.
- **Planificación:** consulta y gestión de actividades asignadas.
- **Revisiones:** consulta y seguimiento de registros realizados en campo.
- **Notificaciones:** bandeja de avisos relacionados con las actividades del sistema.
- **Sincronización:** gestión de registros locales pendientes de enviar al servidor.

## 🌱 Características de la aplicación

- Interfaz organizada y adaptable a dispositivos móviles.
- Navegación diferenciada según el perfil de usuario.
- Formularios con validaciones para facilitar el registro de información.
- Lectura de códigos QR para identificar trampas.
- Captura y selección de fotografías como evidencia.
- Consulta de estados de conexión.
- Almacenamiento local de registros pendientes.
- Manejo de mensajes de confirmación, advertencias y errores.
- Integración con los servicios centrales de SIGAT.

## 🛠️ Tecnologías

- **Flutter:** framework para el desarrollo de aplicaciones multiplataforma.
- **Dart:** lenguaje de programación utilizado en el proyecto.
- **HTTP:** comunicación con los servicios REST del backend.
- **flutter_secure_storage:** almacenamiento seguro de información de sesión.
- **shared_preferences:** persistencia de información local.
- **connectivity_plus:** detección del estado de conectividad.
- **mobile_scanner:** lectura de códigos QR.
- **image_picker:** captura y selección de fotografías.
- **file_selector:** selección de documentos.
- **pdf / printing:** generación y visualización de documentos PDF.

## 🏗️ Arquitectura del proyecto

La aplicación está organizada por módulos y capas para facilitar su mantenimiento, evolución e integración con los demás componentes de SIGAT.

La interfaz móvil se comunica con los repositorios, que gestionan las solicitudes al backend. El servidor procesa las operaciones y se comunica con la base de datos.

```text
┌──────────────────────────────┐
│         SIGAT MÓVIL          │
│                              │
│ Técnico · Productor          │
│          · Agrónomo          │
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│       CAPA DE DATOS          │
│                              │
│ Modelos · Repositorios       │
│ Almacenamiento local         │
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│         API SIGAT            │
│                              │
│ Autenticación y servicios    │
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│        BASE DE DATOS         │
└──────────────────────────────┘
```

La aplicación móvil no accede directamente a la base de datos. La comunicación y validación de las operaciones se realizan mediante el backend.

## 📁 Estructura del proyecto

```text
vigilancia_durazno/
│
├── android/                 # Configuración de Android
├── ios/                     # Configuración de iOS
│
├── assets/
│   └── images/              # Logos e imágenes de la aplicación
│
├── lib/
│   ├── app/                 # Configuración y navegación
│   ├── core/                # Tema, configuración y utilidades
│   ├── data/
│   │   ├── api/             # Comunicación con el backend
│   │   ├── local/           # Almacenamiento local
│   │   ├── models/          # Modelos de información
│   │   └── repositories/    # Acceso a los datos
│   │
│   ├── features/            # Módulos y funcionalidades
│   └── shared/              # Elementos compartidos
│
├── test/                    # Pruebas automatizadas
│
├── pubspec.yaml             # Dependencias y configuración
├── pubspec.lock             # Versiones de dependencias
└── README.md                # Documentación del proyecto
```

## 🚀 Instalación y uso en local

Sigue estos pasos para ejecutar el proyecto en tu entorno de desarrollo.

### Requisitos previos

- **Flutter 3.47** o superior.
- **Dart** compatible con la versión instalada de Flutter.
- **Android Studio** y Android SDK.
- **Git** para clonar el repositorio.
- Emulador Android o dispositivo físico.
- Acceso al backend de SIGAT para utilizar las funcionalidades que requieren conexión al servidor.

### Pasos de instalación

**1. Clonar el repositorio**

```bash
git clone <URL_DEL_REPOSITORIO>
cd vigilancia_durazno
```

**2. Instalar las dependencias**

```bash
flutter pub get
```

**3. Configurar la conexión con el backend**

La aplicación utiliza la variable `API_URL` para establecer la dirección del servidor.

Para ejecutar en un emulador Android:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1
```

Para ejecutar en un dispositivo físico conectado a la misma red:

```bash
flutter run --dart-define=API_URL=http://192.168.1.50:8000/api/v1
```

Reemplaza la dirección de ejemplo por la IP correspondiente al equipo donde se ejecuta el backend.

**4. Ejecutar la aplicación**

```bash
flutter run
```

**5. Ejecutar las pruebas**

```bash
flutter analyze
flutter test
```

**6. Generar APK de depuración**

```bash
flutter build apk --debug
```

El archivo APK se genera en:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## 🔐 Seguridad y protección de información

La aplicación incorpora mecanismos para proteger la información de sesión y controlar el acceso a las funcionalidades.

- Almacenamiento seguro de tokens de autenticación.
- Control de acceso según el perfil del usuario.
- Separación de registros locales por usuario.
- Validación de información antes de guardar registros.
- Uso de HTTPS en compilaciones de producción.
- Protección de archivos de configuración y claves privadas.

Las credenciales y claves de firma deben configurarse localmente y nunca publicarse en el repositorio.

## 🔄 Integración con el backend

SIGAT Móvil se comunica con el backend central del sistema para consultar información y realizar operaciones.

Algunas funcionalidades ya cuentan con integración, mientras que otras dependen de la implementación y disponibilidad de los servicios correspondientes en el servidor.

Los registros que todavía no han sido enviados se conservan como pendientes en el dispositivo. Solo se consideran sincronizados cuando el servidor confirma correctamente la operación.

## 🧪 Pruebas y calidad

El proyecto cuenta con pruebas automatizadas orientadas a verificar el comportamiento de sus principales funcionalidades.

Entre los aspectos evaluados se encuentran:

- Autenticación y gestión de sesiones.
- Comunicación con los servicios del backend.
- Validación de datos.
- Almacenamiento local.
- Gestión de registros pendientes.
- Reglas de acceso y separación de información por usuario.
- Validación de imágenes y documentos.

Para comprobar el proyecto se pueden ejecutar los comandos:

```bash
flutter analyze
flutter test
```

## 📌 Estado del proyecto

SIGAT Móvil se encuentra en desarrollo e integración con los demás componentes de la plataforma SIGAT.

La disponibilidad de determinadas funciones depende de los servicios implementados en el backend. La aplicación contempla esta situación mediante estados informativos y conserva como pendientes los registros que todavía no han sido confirmados por el servidor.

---

**SIGAT Móvil — Vigilancia fitosanitaria del cultivo de durazno.**