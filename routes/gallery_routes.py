"""
Rutas de galería
================

Endpoints para gestión de fotos del evento:
subir, listar, eliminar fotos.
"""

from flask import Blueprint, request, jsonify
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
