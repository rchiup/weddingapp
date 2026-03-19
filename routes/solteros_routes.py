"""
Rutas de solteros (modo irreversible)
====================================

Permite activar modo soltero por evento (irreversible) y acceder a:
- Lista de solteros
- Chat global de solteros
- DM 1:1 entre solteros

Todo acceso de lectura/escritura exige que el viewer esté en la lista de solteros
del evento (anti-sapeo).
"""

from flask import Blueprint, request, jsonify
from datetime import datetime, timezone

from services.firebase_service import FirebaseService

solteros_bp = Blueprint("solteros", __name__)
firebase_service = FirebaseService()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _singles_doc(event_id: str, user_id: str):
    return (
        firebase_service.db
        .collection("events")
        .document(event_id)
        .collection("singles")
        .document(user_id)
    )


def _require_single(event_id: str, viewer_id: str):
    if not viewer_id:
        return False
    return _singles_doc(event_id, viewer_id).get().exists


def _thread_id(a: str, b: str) -> str:
    a = (a or "").strip()
    b = (b or "").strip()
    return f"{a}_{b}" if a < b else f"{b}_{a}"


def _dm_doc(event_id: str, a: str, b: str):
    return (
        firebase_service.db
        .collection("events")
        .document(event_id)
        .collection("singles_dm")
        .document(_thread_id(a, b))
    )


def _global_chat_doc(event_id: str):
    return (
        firebase_service.db
        .collection("events")
        .document(event_id)
        .collection("singles_chat")
        .document("global")
    )


def _single_name(event_id: str, user_id: str, fallback: str = "Invitado") -> str:
    try:
        snap = _singles_doc(event_id, user_id).get()
        data = snap.to_dict() or {}
        return (data.get("name") or "").strip() or fallback
    except Exception:
        return fallback


@solteros_bp.route("/event/<event_id>/activate", methods=["POST"])
def activate_single(event_id):
    data = request.get_json(silent=True) or {}
    user_id = (data.get("userId") or "").strip()
    name = (data.get("name") or "").strip() or "Invitado"

    if not event_id or not user_id:
        return jsonify({"error": "eventId y userId son requeridos"}), 400

    try:
        ref = _singles_doc(event_id, user_id)
        snap = ref.get()
        if snap.exists:
            return jsonify({"ok": True, "already": True}), 200

        ref.set({
            "userId": user_id,
            "name": name,
            "nameLower": name.lower(),
            "activatedAt": _now_iso(),
        })
        return jsonify({"ok": True, "already": False}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/list", methods=["GET"])
def list_singles(event_id):
    viewer_id = (request.args.get("viewerId") or "").strip()
    q = (request.args.get("q") or "").strip().lower()

    if not event_id:
        return jsonify({"error": "eventId requerido"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403

    try:
        ref = firebase_service.db.collection("events").document(event_id).collection("singles")
        items = []
        for doc in ref.stream():
            data = doc.to_dict() or {}
            name = (data.get("name") or "").strip() or "Invitado"
            if q and q not in name.lower():
                continue
            items.append({
                "userId": doc.id,
                "name": name,
                "activatedAt": data.get("activatedAt") or "",
            })
        items.sort(key=lambda x: x.get("activatedAt") or "", reverse=True)
        return jsonify({"items": items}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/chat/messages", methods=["GET"])
def get_global_chat_messages(event_id):
    viewer_id = (request.args.get("viewerId") or "").strip()
    after = (request.args.get("after") or "").strip()
    limit = int(request.args.get("limit") or 60)
    limit = max(1, min(limit, 200))

    if not event_id:
        return jsonify({"error": "eventId requerido"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403

    try:
        ref = (
            firebase_service.db
            .collection("events")
            .document(event_id)
            .collection("singles_chat")
            .document("global")
            .collection("messages")
        )
        # Para mantenerlo simple (y por demo), traemos un rango acotado y filtramos por ISO string.
        raw = []
        for doc in ref.stream():
            data = doc.to_dict() or {}
            raw.append({
                "id": doc.id,
                "userId": data.get("userId", ""),
                "name": data.get("name", "Invitado"),
                "text": data.get("text", ""),
                "createdAt": data.get("createdAt") or "",
            })
        raw.sort(key=lambda x: x.get("createdAt") or "")
        if after:
            raw = [m for m in raw if (m.get("createdAt") or "") > after]
        raw = raw[-limit:]
        return jsonify({"items": raw}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/chat/messages", methods=["POST"])
def post_global_chat_message(event_id):
    data = request.get_json(silent=True) or {}
    viewer_id = (data.get("viewerId") or "").strip()
    text = (data.get("text") or "").strip()

    if not event_id or not viewer_id or not text:
        return jsonify({"error": "eventId, viewerId y text son requeridos"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403

    try:
        viewer_name = _single_name(event_id, viewer_id, fallback="Invitado")
        chat_doc = _global_chat_doc(event_id)
        ref = chat_doc.collection("messages").document()
        now = _now_iso()
        ref.set({
            "userId": viewer_id,
            "name": viewer_name,
            "text": text,
            "createdAt": now,
        })
        chat_doc.set({
            "lastMessage": text,
            "lastMessageAt": now,
            "lastSenderId": viewer_id,
            "lastReadAt": {
                viewer_id: now,
            },
        }, merge=True)
        return jsonify({"ok": True, "id": ref.id, "createdAt": now}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/chat/status", methods=["GET"])
def get_global_chat_status(event_id):
    viewer_id = (request.args.get("viewerId") or "").strip()

    if not event_id:
        return jsonify({"error": "eventId requerido"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403

    try:
        snap = _global_chat_doc(event_id).get()
        data = snap.to_dict() or {}
        last_message = (data.get("lastMessage") or "").strip()
        last_message_at = (data.get("lastMessageAt") or "").strip()
        last_sender_id = (data.get("lastSenderId") or "").strip()
        last_read_map = data.get("lastReadAt") or {}
        viewer_last_read = (last_read_map.get(viewer_id) or "").strip() if isinstance(last_read_map, dict) else ""
        if not last_message_at or not last_message:
            raw = []
            for doc in _global_chat_doc(event_id).collection("messages").stream():
                msg_data = doc.to_dict() or {}
                raw.append({
                    "text": (msg_data.get("text") or "").strip(),
                    "createdAt": (msg_data.get("createdAt") or "").strip(),
                    "userId": (msg_data.get("userId") or "").strip(),
                })
            raw.sort(key=lambda x: x.get("createdAt") or "")
            if raw:
                last = raw[-1]
                last_message = last_message or last.get("text") or ""
                last_message_at = last_message_at or last.get("createdAt") or ""
                last_sender_id = last_sender_id or last.get("userId") or ""
        unread = bool(last_message_at and last_sender_id and last_sender_id != viewer_id and last_message_at > viewer_last_read)
        return jsonify({
            "lastMessage": last_message,
            "lastMessageAt": last_message_at,
            "unreadCount": 1 if unread else 0,
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/chat/read", methods=["POST"])
def mark_global_chat_read(event_id):
    data = request.get_json(silent=True) or {}
    viewer_id = (data.get("viewerId") or "").strip()

    if not event_id or not viewer_id:
        return jsonify({"error": "eventId y viewerId son requeridos"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403

    try:
        chat_doc = _global_chat_doc(event_id)
        snap = chat_doc.get()
        base = snap.to_dict() or {}
        mark_at = (base.get("lastMessageAt") or "").strip() or _now_iso()
        chat_doc.set({
            "lastReadAt": {
                viewer_id: mark_at,
            },
        }, merge=True)
        return jsonify({"ok": True, "readAt": mark_at}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/dm/<other_user_id>/messages", methods=["GET"])
def get_dm_messages(event_id, other_user_id):
    viewer_id = (request.args.get("viewerId") or "").strip()
    after = (request.args.get("after") or "").strip()
    limit = int(request.args.get("limit") or 60)
    limit = max(1, min(limit, 200))

    if not event_id or not other_user_id:
        return jsonify({"error": "eventId y otherUserId son requeridos"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403
    if not _require_single(event_id, other_user_id):
        return jsonify({"error": "El usuario no está en modo soltero"}), 403

    try:
        ref = _dm_doc(event_id, viewer_id, other_user_id).collection("messages")
        raw = []
        for doc in ref.stream():
            data = doc.to_dict() or {}
            raw.append({
                "id": doc.id,
                "userId": data.get("userId", ""),
                "name": data.get("name", "Invitado"),
                "text": data.get("text", ""),
                "createdAt": data.get("createdAt") or "",
            })
        raw.sort(key=lambda x: x.get("createdAt") or "")
        if after:
            raw = [m for m in raw if (m.get("createdAt") or "") > after]
        raw = raw[-limit:]
        return jsonify({"items": raw}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/dm/<other_user_id>/messages", methods=["POST"])
def post_dm_message(event_id, other_user_id):
    data = request.get_json(silent=True) or {}
    viewer_id = (data.get("viewerId") or "").strip()
    text = (data.get("text") or "").strip()

    if not event_id or not other_user_id or not viewer_id or not text:
        return jsonify({"error": "eventId, otherUserId, viewerId y text son requeridos"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403
    if not _require_single(event_id, other_user_id):
        return jsonify({"error": "El usuario no está en modo soltero"}), 403

    try:
        viewer_name = _single_name(event_id, viewer_id, fallback="Invitado")
        thread_doc = _dm_doc(event_id, viewer_id, other_user_id)
        ref = thread_doc.collection("messages").document()
        now = _now_iso()
        ref.set({
            "userId": viewer_id,
            "name": viewer_name,
            "text": text,
            "createdAt": now,
        })
        thread_doc.set({
            "participantIds": [viewer_id, other_user_id],
            "participantNames": {
                viewer_id: viewer_name,
                other_user_id: _single_name(event_id, other_user_id),
            },
            "lastMessage": text,
            "lastMessageAt": now,
            "lastSenderId": viewer_id,
            "lastReadAt": {
                viewer_id: now,
            },
        }, merge=True)
        return jsonify({"ok": True, "id": ref.id, "createdAt": now}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/dm/<other_user_id>/read", methods=["POST"])
def mark_dm_read(event_id, other_user_id):
    data = request.get_json(silent=True) or {}
    viewer_id = (data.get("viewerId") or "").strip()

    if not event_id or not other_user_id or not viewer_id:
        return jsonify({"error": "eventId, otherUserId y viewerId son requeridos"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403
    if not _require_single(event_id, other_user_id):
        return jsonify({"error": "El usuario no está en modo soltero"}), 403

    try:
        thread_doc = _dm_doc(event_id, viewer_id, other_user_id)
        snap = thread_doc.get()
        base = snap.to_dict() or {}
        mark_at = (base.get("lastMessageAt") or "").strip() or _now_iso()
        thread_doc.set({
            "lastReadAt": {
                viewer_id: mark_at,
            },
        }, merge=True)
        return jsonify({"ok": True, "readAt": mark_at}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@solteros_bp.route("/event/<event_id>/conversations", methods=["GET"])
def get_dm_conversations(event_id):
    viewer_id = (request.args.get("viewerId") or "").strip()

    if not event_id:
        return jsonify({"error": "eventId requerido"}), 400
    if not _require_single(event_id, viewer_id):
        return jsonify({"error": "Solo disponible para solteros"}), 403

    try:
        ref = (
            firebase_service.db
            .collection("events")
            .document(event_id)
            .collection("singles_dm")
        )
        items = []
        for doc in ref.stream():
            data = doc.to_dict() or {}
            participant_ids = [str(x).strip() for x in (data.get("participantIds") or []) if str(x).strip()]
            if not participant_ids and "_" in doc.id:
                participant_ids = [part.strip() for part in doc.id.split("_") if part.strip()]
            if viewer_id not in participant_ids:
                continue
            other_user_id = next((uid for uid in participant_ids if uid != viewer_id), "")
            if not other_user_id:
                continue
            participant_names = data.get("participantNames") or {}
            other_name = ""
            if isinstance(participant_names, dict):
                other_name = (participant_names.get(other_user_id) or "").strip()
            other_name = other_name or _single_name(event_id, other_user_id)
            last_message_at = (data.get("lastMessageAt") or "").strip()
            last_message = (data.get("lastMessage") or "").strip()
            last_sender_id = (data.get("lastSenderId") or "").strip()
            last_read_map = data.get("lastReadAt") or {}
            viewer_last_read = (last_read_map.get(viewer_id) or "").strip() if isinstance(last_read_map, dict) else ""
            if not last_message_at or not last_message:
                raw = []
                for msg_doc in doc.reference.collection("messages").stream():
                    msg_data = msg_doc.to_dict() or {}
                    raw.append({
                        "text": (msg_data.get("text") or "").strip(),
                        "createdAt": (msg_data.get("createdAt") or "").strip(),
                        "userId": (msg_data.get("userId") or "").strip(),
                    })
                raw.sort(key=lambda x: x.get("createdAt") or "")
                if raw:
                    last = raw[-1]
                    last_message = last_message or last.get("text") or ""
                    last_message_at = last_message_at or last.get("createdAt") or ""
                    last_sender_id = last_sender_id or last.get("userId") or ""
            unread = bool(last_message_at and last_sender_id and last_sender_id != viewer_id and last_message_at > viewer_last_read)
            items.append({
                "threadId": doc.id,
                "otherUserId": other_user_id,
                "otherName": other_name or "Invitado",
                "lastMessage": last_message,
                "lastMessageAt": last_message_at,
                "unreadCount": 1 if unread else 0,
            })

        items.sort(key=lambda x: x.get("lastMessageAt") or "", reverse=True)
        return jsonify({"items": items}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

