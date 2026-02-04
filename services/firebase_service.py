import os
import json
import firebase_admin
import cloudinary
import cloudinary.uploader
from firebase_admin import credentials, firestore, storage


class FirebaseService:
    def __init__(self):
        # Inicializar Firebase solo una vez
        if not firebase_admin._apps:
            cred_json = os.environ.get("FIREBASE_CREDENTIALS_JSON")
            if not cred_json:
                raise Exception("FIREBASE_CREDENTIALS_JSON not set")

            cred = credentials.Certificate(json.loads(cred_json))

            bucket_name = os.environ.get("FIREBASE_STORAGE_BUCKET")

            firebase_admin.initialize_app(
                cred,
                {
                    "storageBucket": bucket_name
                }
            )

        # Firestore siempre disponible
        self.db = firestore.client()

        # Inicializar Storage solo si hay bucket válido
        self.storage_provider = (os.environ.get("STORAGE_PROVIDER") or "firebase").strip().lower()
        bucket_name = os.environ.get("FIREBASE_STORAGE_BUCKET")

        if self.storage_provider == "cloudinary":
            # TODO: enable Firebase Storage in production
            cloudinary.config(
                cloud_name=os.environ.get("CLOUDINARY_CLOUD_NAME"),
                api_key=os.environ.get("CLOUDINARY_API_KEY"),
                api_secret=os.environ.get("CLOUDINARY_API_SECRET"),
                secure=True,
            )
            self.bucket = None
        else:
            if not bucket_name:
                self.bucket = None
            else:
                try:
                    self.bucket = storage.bucket(bucket_name)
                except Exception as e:
                    print("Error inicializando Firebase Storage:", e)
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
        if self.storage_provider == "cloudinary":
            public_id = self._cloudinary_public_id(destination_path)
            upload_result = cloudinary.uploader.upload(
                file_path,
                public_id=public_id,
                overwrite=False,
                resource_type="image",
            )
            return upload_result.get("secure_url") or upload_result.get("url")

        if not self.bucket:
            raise Exception("Firebase Storage no configurado")

        blob = self.bucket.blob(destination_path)

        if content_type:
            blob.content_type = content_type

        blob.upload_from_filename(file_path)
        blob.make_public()

        return blob.public_url

    def delete_file(self, file_path):
        if self.storage_provider == "cloudinary":
            public_id = self._cloudinary_public_id(file_path)
            cloudinary.uploader.destroy(public_id, invalidate=True)
            return

        if not self.bucket:
            raise Exception("Firebase Storage no configurado")

        self.bucket.blob(file_path).delete()

    def _cloudinary_public_id(self, destination_path):
        # Quita extensión para usar public_id consistente
        folder = os.path.dirname(destination_path)
        filename = os.path.basename(destination_path)
        public_name = os.path.splitext(filename)[0]
        return f"{folder}/{public_name}" if folder else public_name
