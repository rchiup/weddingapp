# Wedding App - Backend (Flask)

API RESTful para la aplicación de matrimonios.

## Endpoints

### 🔐 Auth (`/api/auth`)
- `POST /register` - Registro de usuario
- `POST /login` - Inicio de sesión
- `POST /logout` - Cerrar sesión
- `GET /me` - Obtener usuario actual
- `POST /reset-password` - Reset de contraseña

### 🎉 Events (`/api/events`)
- `GET /` - Listar eventos
- `POST /` - Crear evento
- `GET /<event_id>` - Detalles del evento
- `GET /<event_id>/tables` - Obtener mesas
- `POST /<event_id>/tables` - Crear/actualizar mesa
- `GET /<event_id>/guests` - Obtener invitados
- `POST /<event_id>/guests` - Invitar usuario

### 💕 Matches (`/api/matches`)
- `GET /<event_id>/potential` - Usuarios potenciales
- `POST /<event_id>/like` - Dar like
- `POST /<event_id>/pass` - Rechazar usuario
- `GET /<event_id>` - Obtener matches

### 💬 Chat (`/api/chat`)
- `GET /conversations` - Listar conversaciones
- `GET /<chat_id>/messages` - Obtener mensajes
- `POST /<chat_id>/messages` - Enviar mensaje
- `POST /create` - Crear/obtener chat
- `POST /<chat_id>/read` - Marcar como leído

### 📸 Gallery (`/api/gallery`)
- `GET /<event_id>/photos` - Listar fotos
- `POST /<event_id>/photos` - Subir foto
- `DELETE /photos/<photo_id>` - Eliminar foto
- `POST /photos/<photo_id>/like` - Like a foto

## Configuración

1. Crear entorno virtual:
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

2. Instalar dependencias:
```bash
pip install -r requirements.txt
```

3. Configurar variables de entorno:
   - Copiar `env.example` a `.env`
   - Configurar credenciales

4. Ejecutar:
```bash
python app.py
```

## Servicios

- **FirebaseService**: Operaciones con Firestore y Storage
- **ResendService**: Envío de emails
- **Utils**: Validación y helpers
