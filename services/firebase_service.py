"""
Servicio de Firebase
====================

Encapsula toda la lógica de interacción con Firebase:
- Firestore (base de datos)
- Firebase Storage (archivos)

No contiene lógica de negocio, solo operaciones CRUD.
"""

import os
import json
import firebase_admin
from firebase_admin import credentials, firestore, storage


class FirebaseService:
    """Servicio para operaciones con Firebase"""

    def __init__(self):
        """Inicializa Firebase Admin SDK (Render / Producción)"""
        if not firebase_admin._apps:
            cred_json = os.environ.get("FIREBASE_CREDENTIALS_JSON")
            if not cred_json:
                raise Exception("FIREBASE_CREDENTIALS_JSON not set")

            cred = credentials.Certificate(json.loads(cred_json))

            firebase_admin.initialize_app(
                cred,
                {
                    "storageBucket": os.environ.get("FIREBASE_STORAGE_BUCKET")
                }
            )

        self.db = firestore.client()
        self.bucket = storage.bucket()

    # ========== Operaciones de Firestore ==========

    def create_document(self, collection: str, data: dict, doc_id: str = None) -> str:
        try:
            if doc_id:
                self.db.collection(collection).document(doc_id).set(data)
                return doc_id
            else:
                doc_ref = self.db.collection(collection).add(data)
                return doc_ref[1].id
        except Exception as e:
            raise Exception(f"Error creando documento: {e}")

    def get_document(self, collection: str, doc_id: str) -> dict | None:
        try:
            doc = self.db.collection(collection).document(doc_id).get()
            return doc.to_dict() if doc.exists else None
        except Exception as e:
            raise Exception(f"Error obteniendo documento: {e}")

    def update_document(self, collection: str, doc_id: str, data: dict) -> None:
        try:
            self.db.collection(collection).document(doc_id).update(data)
        except Exception as e:
            raise Exception(f"Error actualizando documento: {e}")

    def delete_document(self, collection: str, doc_id: str) -> None:
        try:
            self.db.collection(collection).document(doc_id).delete()
        except Exception as e:
            raise Exception(f"Error eliminando documento: {e}")

    def query_collection(
        self,
        collection: str,
        filters: list = None,
        order_by: str = None,
        limit: int = None
    ) -> list:
        try:
            query = self.db.collection(collection)

            if filters:
                for field, operator, value in filters:
                    query = query.where(field, operator, value)

            if order_by:
                query = query.order_by(order_by)

            if limit:
                query = query.limit(limit)

            return [doc.to_dict() for doc in query.stream()]
        except Exception as e:
            raise Exception(f"Error consultando colección: {e}")

    # ========== Operaciones de Storage ==========

    def upload_file(
        self,
        file_path: str,
        destination_path: str,
        content_type: str = None
    ) -> str:
        try:
            blob = self.bucket.blob(destination_path)
            if content_type:
                blob.content_type = content_type

            blob.upload_from_filename(file_path)
            blob.make_public()
            return blob.public_url
        except Exception as e:
            raise Exception(f"Error subiendo archivo: {e}")

    def delete_file(self, file_path: str) -> None:
        try:
            blob = self.bucket.blob(file_path)
            blob.delete()
        except Exception as e:
            raise Exception(f"Error eliminando archivo: {e}")
