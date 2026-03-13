# Wedding App - Aplicación de Matrimonios

Aplicación completa tipo "Teamsder" para eventos de matrimonio con módulos adicionales:
- Conexión de solteros dentro del evento (matches tipo Tinder)
- Visualización de mesas e invitados
- Subida de fotos en tiempo real
- Chat entre matches

## Stack Tecnológico

- **Frontend**: Flutter (Dart)
- **Backend**: Python Flask
- **Base de datos**: Firebase Firestore
- **Storage**: Firebase Storage
- **Email**: Resend
- **Hosting**: 
  - Frontend: Vercel / Firebase Hosting
  - Backend: Render

## Estructura del Proyecto

```
/
├── app/                    # Aplicación Flutter
│   └── lib/
│       ├── auth/          # Módulo de autenticación
│       ├── matches/       # Módulo de conexiones
│       ├── chat/          # Módulo de mensajería
│       ├── event/         # Módulo de eventos
│       ├── gallery/       # Módulo de galería
│       ├── admin/         # Módulo de administración
│       ├── models/        # Modelos de datos
│       ├── services/      # Servicios (lógica de negocio)
│       ├── utils/         # Utilidades
│       └── main.dart      # Punto de entrada
│
└── backend/               # API Flask
    ├── routes/           # Endpoints por módulo
    ├── services/         # Servicios (Firebase, Resend, etc.)
    ├── app.py            # Aplicación principal
    └── requirements.txt  # Dependencias Python
```

## Arquitectura

### Frontend (Flutter)

La aplicación sigue una arquitectura modular con separación de responsabilidades:

- **Providers**: Gestión de estado usando Provider pattern
- **Services**: Lógica de negocio y comunicación con Firebase
- **Models**: Modelos de datos tipados
- **Screens**: Pantallas de UI
- **Utils**: Utilidades reutilizables

### Backend (Flask)

API RESTful organizada por módulos:

- **Routes**: Endpoints agrupados por funcionalidad (auth, events, matches, etc.)
- **Services**: Servicios encapsulados (Firebase, Resend)
- **Utils**: Funciones auxiliares (validación, decorators)

## Configuración Inicial

### Frontend (Flutter)

1. Instalar dependencias:
```bash
cd app
flutter pub get
```

2. Configurar Firebase:
   - Agregar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
   - Configurar `firebase_options.dart`

3. Ejecutar:
```bash
flutter run
```

### Backend (Flask)

1. Crear entorno virtual:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

2. Instalar dependencias:
```bash
pip install -r requirements.txt
```

3. Configurar variables de entorno:
   - Copiar `env.example` a `.env`
   - Configurar credenciales de Firebase y Resend

4. Ejecutar:
```bash
python app.py
```

## Estado del Proyecto

⚠️ **Estructura Base Completa**

Este proyecto contiene la estructura inicial con:
- ✅ Arquitectura modular y escalable
- ✅ Archivos base con funciones mock
- ✅ Comentarios explicativos en cada módulo
- ✅ Separación clara de responsabilidades
- ✅ Preparado para escalar sin volverse un monstruo

**Próximos pasos:**
- Implementar lógica de negocio en cada módulo
- Configurar Firebase y Resend
- Desarrollar UI completa
- Implementar autenticación
- Agregar tests

## Notas de Desarrollo

- Todos los módulos tienen funciones mock vacías listas para implementar
- La estructura está diseñada para mantenibilidad a largo plazo
- Cada módulo es independiente y puede desarrollarse en paralelo
- Los servicios encapsulan la lógica de negocio, no la UI

## Licencia

Proyecto privado - Todos los derechos reservados
