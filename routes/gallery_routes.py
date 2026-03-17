"""
Rutas de galería
================

Endpoints para gestión de fotos del evento:
subir, listar, eliminar fotos.
"""

from flask import Blueprint, request, jsonify
import os
import tempfile
import uuid
from datetime import datetime, timezone

from services.firebase_service import FirebaseService

gallery_bp = Blueprint('gallery', __name__)
firebase_service = FirebaseService()


def _expected_admin_code(event_id: str) -> str:
    # Código simple para demo: EVENTID-NOVIOS (case-insensitive)
    return f"{(event_id or '').strip().upper()}-NOVIOS"


def _is_valid_registry_url(url: str) -> bool:
    if not url:
        return False
    u = url.strip().lower()
    return u.startswith('http://') or u.startswith('https://')


@gallery_bp.route('/<event_id>/photos', methods=['GET'])
def get_photos(event_id):
    try:
        return jsonify({'photos': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@gallery_bp.route('/<event_id>/photos', methods=['POST'])
def upload_photo(event_id):
    try:
        return jsonify({'photoId': '', 'message': 'Foto subida'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@gallery_bp.route('/upload', methods=['POST'])
def upload_gallery_image():

    try:

        max_size_bytes = 5 * 1024 * 1024

        if 'file' not in request.files:
            return jsonify({'error': 'Archivo requerido (file)'}), 400

        file = request.files['file']
        event_id = request.form.get('eventId')
        user_id = request.form.get('userId')

        if not event_id or not user_id:
            return jsonify({'error': 'eventId y userId son requeridos'}), 400

        if not file.filename:
            return jsonify({'error': 'Nombre de archivo inválido'}), 400

        allowed_types = {'image/jpeg', 'image/jpg', 'image/png'}
        if file.mimetype not in allowed_types:
            return jsonify({'error': 'Tipo de archivo inválido'}), 400

        file_ext = os.path.splitext(file.filename or '')[1].lower() or '.jpg'

        image_id = str(uuid.uuid4())

        destination_path = f'gallery/{event_id}/{user_id}/{image_id}{file_ext}'

        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            file.save(temp_file.name)
            temp_path = temp_file.name

        try:
            image_url = firebase_service.upload_file(
                temp_path,
                destination_path,
                content_type=file.mimetype,
            )
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

        doc_data = {
            'imageUrl': image_url,
            'userId': user_id,
            'eventId': event_id,
            'createdAt': datetime.now(timezone.utc).isoformat(),
        }

        photo_id = firebase_service.create_document('gallery', doc_data)

        return jsonify({
            'photoId': photo_id,
            'imageUrl': image_url
        }), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 400


@gallery_bp.route('/photos/<photo_id>', methods=['DELETE'])
def delete_photo(photo_id):

    try:
        return jsonify({'message': 'Foto eliminada'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@gallery_bp.route('/photos/<photo_id>/likes/toggle', methods=['POST'])
def toggle_photo_like(photo_id):
    """
    Toggle de like sobre una foto.

    Capa de backend: escribe/borra en:
      gallery/{photoId}/likes/{userId}
    para evitar depender del estado offline del SDK web.

    Body JSON esperado:
    {
      "userId": "...",
      "name": "Nombre a mostrar (opcional)"
    }
    """
    data = request.get_json(silent=True) or {}
    user_id = data.get('userId')
    name = (data.get('name') or '').strip() or 'Invitado'

    if not user_id:
        return jsonify({'error': 'userId requerido'}), 400

    try:
        likes_ref = (
            firebase_service.db
            .collection('gallery')
            .document(photo_id)
            .collection('likes')
        )

        user_like_ref = likes_ref.document(user_id)
        snap = user_like_ref.get()

        if snap.exists:
            # Ya tenía like -> eliminar (unlike)
            user_like_ref.delete()
            liked = False
        else:
            # No tenía like -> crear
            user_like_ref.set({
                'name': name,
                'timestamp': datetime.now(timezone.utc).isoformat(),
            })
            liked = True

        # Recontar likes actuales
        count = sum(1 for _ in likes_ref.stream())

        return jsonify({
            'liked': liked,
            'count': count,
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 400


@gallery_bp.route('/event/<event_id>', methods=['GET'])
def get_event_photos(event_id):

    if not event_id:
        return jsonify({'error': 'eventId requerido'}), 400

    try:

        query = (
            firebase_service.db
            .collection('gallery')
            .where('eventId', '==', event_id)
            .order_by('createdAt', direction='DESCENDING')
            .limit(200)
        )

        items = []

        for doc in query.stream():

            data = doc.to_dict() or {}
            created_at = data.get('createdAt')

            if hasattr(created_at, 'isoformat'):
                created_at = created_at.isoformat()

            items.append({
                'photoId': doc.id,
                'imageUrl': data.get('imageUrl', ''),
                'eventId': data.get('eventId', ''),
                'userId': data.get('userId', ''),
                'createdAt': created_at,
            })

        return jsonify({'items': items}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ------------------------------
# ENDPOINT PARA CONSULTAR LIKES
# ------------------------------

@gallery_bp.route('/photos/<photo_id>/likes', methods=['GET'])
def get_photo_likes(photo_id):
    """
    Devuelve número de likes y si un usuario concreto dio like.

    Parámetros de query:
      - userId (opcional): si se pasa, se evalúa userLiked.

    Respuesta:
    {
      "count": <int>,
      "userLiked": <bool>
    }
    """
    user_id = request.args.get('userId')

    try:
        likes_ref = (
            firebase_service.db
            .collection('gallery')
            .document(photo_id)
            .collection('likes')
        )

        count = sum(1 for _ in likes_ref.stream())
        user_liked = False

        if user_id:
            user_liked = likes_ref.document(user_id).get().exists

        return jsonify({
            'count': count,
            'userLiked': user_liked,
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ------------------------------
# COMENTARIOS POR FOTO (gallery/{photoId}/comments)
# ------------------------------

@gallery_bp.route('/photos/<photo_id>/comments', methods=['POST'])
def add_photo_comment(photo_id):
    """
    Agrega un comentario a una foto en:
      gallery/{photoId}/comments/{autoId}

    Body JSON:
    {
      "userId": "...",
      "name": "Nombre",
      "message": "Texto del comentario"
    }
    """
    data = request.get_json(silent=True) or {}
    user_id = (data.get('userId') or '').strip()
    name = (data.get('name') or '').strip() or 'Invitado'
    message = (data.get('message') or '').strip()

    if not photo_id or not user_id or not message:
        return jsonify({'error': 'photoId, userId y message son requeridos'}), 400

    try:
        comments_ref = (
            firebase_service.db
            .collection('gallery')
            .document(photo_id)
            .collection('comments')
        )

        doc_ref = comments_ref.document()
        doc_ref.set({
            'userId': user_id,
            'name': name,
            'message': message,
            'timestamp': datetime.now(timezone.utc).isoformat(),
        })

        return jsonify({'id': doc_ref.id}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 400


@gallery_bp.route('/photos/<photo_id>/comments', methods=['GET'])
def get_photo_comments(photo_id):
    """
    Lista comentarios de una foto:
      gallery/{photoId}/comments

    Devuelve lista ordenada por timestamp ascendente.
    """
    try:
        comments_ref = (
            firebase_service.db
            .collection('gallery')
            .document(photo_id)
            .collection('comments')
        )

        items = []
        for doc in comments_ref.stream():
            data = doc.to_dict() or {}
            items.append({
                'id': doc.id,
                'userId': data.get('userId', ''),
                'name': data.get('name', 'Invitado'),
                'message': data.get('message', ''),
                'timestamp': data.get('timestamp'),
            })

        items.sort(key=lambda x: x.get('timestamp') or '')

        return jsonify(items), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@gallery_bp.route('/photos/<photo_id>/comments/count', methods=['GET'])
def get_photo_comments_count(photo_id):
    """
    Devuelve el número de comentarios de una foto sin traerlos.

    Respuesta:
    { "count": <int> }
    """
    try:
        comments_ref = (
            firebase_service.db
            .collection('gallery')
            .document(photo_id)
            .collection('comments')
        )

        count = sum(1 for _ in comments_ref.stream())
        return jsonify({'count': count}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ------------------------------
# CHECK-IN / LLEGADAS (events/{eventId}/...)
# ------------------------------

@gallery_bp.route('/event/<event_id>/checkin', methods=['POST'])
def event_checkin(event_id):
    """
    Marca llegada de un usuario al evento.

    Escribe en:
      - events/{eventId}/checkins/{userId}
      - events/{eventId}/guests/{userId} (merge status=arrived)

    Body JSON:
    {
      "userId": "...",
      "name": "Nombre"
    }
    """
    data = request.get_json(silent=True) or {}
    user_id = (data.get('userId') or '').strip()
    name = (data.get('name') or '').strip() or 'Invitado'

    if not event_id or not user_id:
        return jsonify({'error': 'eventId y userId son requeridos'}), 400

    try:
        now_iso = datetime.now(timezone.utc).isoformat()

        firebase_service.db.collection('events').document(event_id).collection('checkins').document(user_id).set({
            'name': name,
            'timestamp': now_iso,
        })

        firebase_service.db.collection('events').document(event_id).collection('guests').document(user_id).set({
            'name': name,
            'nameLower': name.lower(),
            'status': 'arrived',
            'arrivalAt': now_iso,
            'tableNumber': '',
        }, merge=True)

        return jsonify({'ok': True, 'arrivalAt': now_iso}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@gallery_bp.route('/event/<event_id>/arrivals', methods=['GET'])
def event_arrivals(event_id):
    """
    Lista quiénes ya llegaron (para demo).

    Query:
      - q (opcional): filtra por nombre (contiene)

    Respuesta:
      { "items": [ { "userId", "name", "arrivalAt" }, ... ] }
    """
    q = (request.args.get('q') or '').strip().lower()

    if not event_id:
        return jsonify({'error': 'eventId requerido'}), 400

    try:
        guests_ref = firebase_service.db.collection('events').document(event_id).collection('guests')
        # Firestore no soporta contains; para demo filtramos en servidor.
        stream = guests_ref.where('status', '==', 'arrived').stream()

        items = []
        for doc in stream:
            data = doc.to_dict() or {}
            name = (data.get('name') or '').strip()
            arrival_at = data.get('arrivalAt') or data.get('timestamp')
            row = {
                'userId': doc.id,
                'name': name or 'Invitado',
                'arrivalAt': arrival_at,
            }
            if q:
                if q not in (name.lower() if name else ''):
                    continue
            items.append(row)

        # Orden: más recientes primero si se puede
        items.sort(key=lambda x: x.get('arrivalAt') or '', reverse=True)

        return jsonify({'items': items}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ------------------------------
# LISTA DE NOVIOS (events/{eventId}/settings)
# ------------------------------

@gallery_bp.route('/event/<event_id>/registry', methods=['GET'])
def get_event_registry(event_id):
    """
    Devuelve la URL pública de lista de regalos del evento.

    Lee desde:
      events/{eventId}/settings (doc) -> registryUrl
    """
    if not event_id:
        return jsonify({'error': 'eventId requerido'}), 400

    try:
        doc = (
            firebase_service.db
            .collection('events')
            .document(event_id)
            .collection('settings')
            .document('public')
            .get()
        )
        data = doc.to_dict() or {}
        return jsonify({'registryUrl': data.get('registryUrl', '')}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@gallery_bp.route('/event/<event_id>/registry', methods=['POST'])
def set_event_registry(event_id):
    """
    Setea la URL de la lista de regalos (solo novios).

    Body JSON:
      { "adminCode": "...", "registryUrl": "https://..." }
    """
    data = request.get_json(silent=True) or {}
    admin_code = (data.get('adminCode') or '').strip().upper()
    registry_url = (data.get('registryUrl') or '').strip()

    if not event_id:
        return jsonify({'error': 'eventId requerido'}), 400
    if admin_code != _expected_admin_code(event_id):
        return jsonify({'error': 'Código de novios inválido'}), 403
    if not _is_valid_registry_url(registry_url):
        return jsonify({'error': 'URL inválida'}), 400

    try:
        firebase_service.db.collection('events').document(event_id).collection('settings').document('public').set({
            'registryUrl': registry_url,
            'updatedAt': datetime.now(timezone.utc).isoformat(),
        }, merge=True)
        return jsonify({'ok': True}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500