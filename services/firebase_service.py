"""
Servicio de Firebase
====================

Encapsula toda la lógica de interacción con Firebase:
Firestore (base de datos) y Firebase Storage (archivos).
No debe contener lógica de negocio, solo operaciones CRUD.
"""

import firebase_admin
from firebase_admin import credentials, firestore, storage
import os

class FirebaseService:
    """Servicio para operaciones con Firebase"""
    
    def __init__(self):
        """Inicializa Firebase Admin SDK"""
        if not firebase_admin._apps:
            # TODO: Configurar credenciales desde variable de entorno
            # En producción, usar credenciales desde archivo o variable de entorno
            cred_path = os.environ.get('FIREBASE_CREDENTIALS_PATH')
            if cred_path:
                cred = credentials.Certificate(cred_path)
            else:
                # Para desarrollo local
                cred = credentials.ApplicationDefault()
            
            firebase_admin.initialize_app(cred)
        
        self.db = firestore.client()
        self.bucket = storage.bucket() if os.environ.get('FIREBASE_STORAGE_BUCKET') else None

    # ========== Operaciones de Firestore ==========
    
    def create_document(self, collection: str, data: dict, doc_id: str = None) -> str:
        """
        Crea un documento en Firestore
        
        Args:
            collection: Nombre de la colección
            data: Datos del documento
            doc_id: ID del documento (opcional, se genera automáticamente si no se proporciona)
        
        Returns:
            ID del documento creado
        """
        try:
            # TODO: Implementar creación de documento
            if doc_id:
                self.db.collection(collection).document(doc_id).set(data)
                return doc_id
            else:
                doc_ref = self.db.collection(collection).add(data)
                return doc_ref[1].id
        except Exception as e:
            raise Exception(f'Error creando documento: {e}')

    def get_document(self, collection: str, doc_id: str) -> dict:
        """
        Obtiene un documento de Firestore
        
        Args:
            collection: Nombre de la colección
            doc_id: ID del documento
        
        Returns:
            Datos del documento o None si no existe
        """
        try:
            # TODO: Implementar obtención de documento
            doc = self.db.collection(collection).document(doc_id).get()
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            raise Exception(f'Error obteniendo documento: {e}')

    def update_document(self, collection: str, doc_id: str, data: dict) -> None:
        """
        Actualiza un documento en Firestore
        
        Args:
            collection: Nombre de la colección
            doc_id: ID del documento
            data: Datos a actualizar
        """
        try:
            # TODO: Implementar actualización de documento
            self.db.collection(collection).document(doc_id).update(data)
        except Exception as e:
            raise Exception(f'Error actualizando documento: {e}')

    def delete_document(self, collection: str, doc_id: str) -> None:
        """
        Elimina un documento de Firestore
        
        Args:
            collection: Nombre de la colección
            doc_id: ID del documento
        """
        try:
            # TODO: Implementar eliminación de documento
            self.db.collection(collection).document(doc_id).delete()
        except Exception as e:
            raise Exception(f'Error eliminando documento: {e}')

    def query_collection(self, collection: str, filters: list = None, order_by: str = None, limit: int = None) -> list:
        """
        Consulta una colección con filtros
        
        Args:
            collection: Nombre de la colección
            filters: Lista de tuplas (campo, operador, valor)
            order_by: Campo para ordenar
            limit: Límite de resultados
        
        Returns:
            Lista de documentos
        """
        try:
            # TODO: Implementar consulta con filtros
            query = self.db.collection(collection)
            
            if filters:
                for field, operator, value in filters:
                    query = query.where(field, operator, value)
            
            if order_by:
                query = query.order_by(order_by)
            
            if limit:
                query = query.limit(limit)
            
            docs = query.stream()
            return [doc.to_dict() for doc in docs]
        except Exception as e:
            raise Exception(f'Error consultando colección: {e}')

    # ========== Operaciones de Storage ==========
    
    def upload_file(self, file_path: str, destination_path: str, content_type: str = None) -> str:
        """
        Sube un archivo a Firebase Storage
        
        Args:
            file_path: Ruta local del archivo
            destination_path: Ruta de destino en Storage
            content_type: Tipo MIME del archivo
        
        Returns:
            URL pública del archivo
        """
        try:
            # TODO: Implementar subida de archivo
            if not self.bucket:
                raise Exception('Firebase Storage no configurado')
            
            blob = self.bucket.blob(destination_path)
            if content_type:
                blob.content_type = content_type
            
            blob.upload_from_filename(file_path)
            blob.make_public()
            return blob.public_url
        except Exception as e:
            raise Exception(f'Error subiendo archivo: {e}')

    def delete_file(self, file_path: str) -> None:
        """
        Elimina un archivo de Firebase Storage
        
        Args:
            file_path: Ruta del archivo en Storage
        """
        try:
            # TODO: Implementar eliminación de archivo
            if not self.bucket:
                raise Exception('Firebase Storage no configurado')
            
            blob = self.bucket.blob(file_path)
            blob.delete()
        except Exception as e:
            raise Exception(f'Error eliminando archivo: {e}')
