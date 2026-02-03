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

@gallery_bp.route('/<event_id>/photos', methods=['GET'])
def get_photos(event_id):
    """
    Obtiene las fotos de un evento
    
    Headers:
        - Authorization: Bearer token
    
    Query params:
        - limit: number (opcional, default 20)
        - before: timestamp (opcional, para paginación)
    """
    try:
        # TODO: Validar token
        # TODO: Consultar fotos desde Firestore
        return jsonify({'photos': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@gallery_bp.route('/<event_id>/photos', methods=['POST'])
def upload_photo(event_id):
    """
    Sube una foto al evento
    
    Headers:
        - Authorization: Bearer token
    
    Body (multipart/form-data):
        - file: archivo de imagen
        - caption: string (opcional)
    """
    try:
        # TODO: Validar token
        # TODO: Validar archivo (tipo, tamaño)
        # TODO: Subir a Firebase Storage
        # TODO: Guardar metadatos en Firestore
        return jsonify({'photoId': '', 'message': 'Foto subida'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@gallery_bp.route('/upload', methods=['POST'])
def upload_gallery_image():
    """
    Sube una imagen a Firebase Storage y guarda metadata en Firestore.
    
    Body (multipart/form-data):
        - file: archivo de imagen
        - eventId: string
        - userId: string
    """
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

        if file.content_length and file.content_length > max_size_bytes:
            return jsonify({'error': 'Archivo excede 5MB'}), 400

        if request.content_length and request.content_length > max_size_bytes:
            return jsonify({'error': 'Archivo excede 5MB'}), 400

        allowed_types = {'image/jpeg', 'image/jpg', 'image/png'}
        if file.mimetype not in allowed_types:
            return jsonify({'error': 'Tipo de archivo inválido'}), 400

        file_ext = os.path.splitext(file.filename or '')[1].lower() or '.jpg'
        if file_ext not in {'.jpg', '.jpeg', '.png'}:
            return jsonify({'error': 'Extensión inválida'}), 400

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

        return jsonify({'photoId': photo_id, 'imageUrl': image_url}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@gallery_bp.route('/photos/<photo_id>', methods=['DELETE'])
def delete_photo(photo_id):
    """
    Elimina una foto
    
    Headers:
        - Authorization: Bearer token (requiere ser el autor o admin)
    """
    try:
        # TODO: Validar token y permisos
        # TODO: Eliminar de Firebase Storage
        # TODO: Eliminar documento de Firestore
        return jsonify({'message': 'Foto eliminada'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@gallery_bp.route('/photos/<photo_id>/like', methods=['POST'])
def like_photo(photo_id):
    """
    Da like a una foto
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token
        # TODO: Actualizar contador de likes en Firestore
        return jsonify({'message': 'Like registrado'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@gallery_bp.route('/event/<event_id>', methods=['GET'])
def get_event_photos(event_id):
    """
    Lista fotos de un evento

    TODO: enable auth in production
    """
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
