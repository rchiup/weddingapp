import os
import json
import firebase_admin
from firebase_admin import credentials, firestore, storage


class FirebaseService:
    def __init__(self):
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

        # Storage ES OPCIONAL
        try:
            self.bucket = storage.bucket()
        except Exception:
            self.bucket = None

    # ---------- Firestore ----------

    def create_document(self, collection, data, doc_id=None):
        if doc_id:
            self.db.collection(collection).document(doc_id).set(data)
            return doc_id
        ref = self.db.collection(collection).add(data)
        return ref[1].id

    def get_document(self, collection, doc_id):
        doc = self.db.collection(collection).document(doc_id).get()
        return doc.to_dict() if doc.exists else None

    def update_document(self, collection, doc_id, data):
        self.db.collection(collection).document(doc_id).update(data)

    def delete_document(self, collection, doc_id):
        self.db.collection(collection).document(doc_id).delete()

    # ---------- Storage ----------

    def upload_file(self, file_path, destination_path, content_type=None):
        if not self.bucket:
            raise Exception("Firebase Storage no configurado")

        blob = self.bucket.blob(destination_path)
        if content_type:
            blob.content_type = content_type

        blob.upload_from_filename(file_path)
        blob.make_public()
        return blob.public_url

    def delete_file(self, file_path):
        if not self.bucket:
            raise Exception("Firebase Storage no configurado")

        self.bucket.blob(file_path).delete()
