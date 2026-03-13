# Wedding App - Frontend (Flutter)

Aplicación móvil Flutter para eventos de matrimonio.

## Módulos

### 🔐 Auth
- Login y registro
- Gestión de sesión
- Recuperación de contraseña

### 💕 Matches
- Conexión tipo Tinder entre solteros
- Sistema de likes/passes
- Lista de matches

### 💬 Chat
- Mensajería en tiempo real
- Lista de conversaciones
- Notificaciones de mensajes

### 🎉 Event
- Lista de eventos
- Detalles del evento
- Visualización de mesas e invitados

### 📸 Gallery
- Subida de fotos en tiempo real
- Feed de galería
- Likes en fotos

### ⚙️ Admin
- Gestión de invitados
- Configuración de mesas
- Permisos y roles

## Configuración

1. Instalar dependencias:
```bash
flutter pub get
```

2. Configurar Firebase:
   - Agregar archivos de configuración de Firebase
   - Configurar `firebase_options.dart`

3. Ejecutar:
```bash
flutter run
```

## Arquitectura

- **Providers**: Estado global (Provider pattern)
- **Services**: Lógica de negocio y Firebase
- **Models**: Modelos de datos tipados
- **Screens**: UI de cada módulo
- **Utils**: Utilidades reutilizables
