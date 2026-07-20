"""Likes, passes y matches del módulo Solteros."""

import hashlib
from datetime import datetime, timezone

from flask import Blueprint, jsonify, request

from services.firebase_service import FirebaseService


match_bp = Blueprint("matches", __name__)
firebase_service = FirebaseService()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _event_collection(event_id: str, name: str):
    return firebase_service.db.collection("events").document(event_id).collection(name)


def _single_doc(event_id: str, user_id: str):
    return _event_collection(event_id, "singles").document(user_id)


def _single_data(event_id: str, user_id: str):
    snapshot = _single_doc(event_id, user_id).get()
    return (snapshot.to_dict() or {}) if snapshot.exists else None


def _action_id(actor_id: str, target_id: str) -> str:
    return hashlib.sha256(f"{actor_id}\0{target_id}".encode("utf-8")).hexdigest()


def _thread_id(first_id: str, second_id: str) -> str:
    first_id, second_id = sorted((first_id.strip(), second_id.strip()))
    return f"{first_id}_{second_id}"


def _match_payload(event_id: str, first_id: str, second_id: str):
    first = _single_data(event_id, first_id) or {}
    second = _single_data(event_id, second_id) or {}
    return {
        "participantIds": [first_id, second_id],
        "participantNames": {
            first_id: (first.get("name") or "Invitado").strip(),
            second_id: (second.get("name") or "Invitado").strip(),
        },
    }


def _require_pair(event_id: str, user_id: str, target_id: str):
    if not event_id or not user_id or not target_id:
        return "eventId, userId y targetUserId son requeridos"
    if user_id == target_id:
        return "No puedes interactuar contigo mismo"
    if _single_data(event_id, user_id) is None:
        return "El usuario no está activo en Solteros"
    if _single_data(event_id, target_id) is None:
        return "La otra persona no está activa en Solteros"
    return None


@match_bp.route("/<event_id>/potential", methods=["GET"])
def get_potential_matches(event_id):
    viewer_id = (request.args.get("viewerId") or "").strip()
    limit = max(1, min(int(request.args.get("limit") or 20), 100))
    if not viewer_id or _single_data(event_id, viewer_id) is None:
        return jsonify({"error": "Solo disponible para solteros activos"}), 403

    try:
        seen = set()
        for collection_name in ("singles_likes", "singles_passes"):
            for snapshot in _event_collection(event_id, collection_name).stream():
                data = snapshot.to_dict() or {}
                if data.get("actorId") == viewer_id:
                    seen.add((data.get("targetId") or "").strip())

        users = []
        for snapshot in _event_collection(event_id, "singles").stream():
            if snapshot.id == viewer_id or snapshot.id in seen:
                continue
            data = snapshot.to_dict() or {}
            users.append({
                "userId": snapshot.id,
                "name": (data.get("name") or "Invitado").strip(),
                "activatedAt": data.get("activatedAt") or "",
            })
        users.sort(key=lambda item: item.get("activatedAt") or "", reverse=True)
        return jsonify({"users": users[:limit]}), 200
    except Exception as error:
        return jsonify({"error": str(error)}), 500


@match_bp.route("/<event_id>/like", methods=["POST"])
def like_user(event_id):
    data = request.get_json(silent=True) or {}
    user_id = (data.get("userId") or "").strip()
    target_id = (data.get("targetUserId") or "").strip()
    validation_error = _require_pair(event_id, user_id, target_id)
    if validation_error:
        return jsonify({"error": validation_error}), 400

    try:
        likes = _event_collection(event_id, "singles_likes")
        like_id = _action_id(user_id, target_id)
        now = _now_iso()
        likes.document(like_id).set({
            "actorId": user_id,
            "targetId": target_id,
            "createdAt": now,
        }, merge=True)

        reciprocal = likes.document(_action_id(target_id, user_id)).get().exists
        match_id = _thread_id(user_id, target_id)
        if reciprocal:
            payload = _match_payload(event_id, user_id, target_id)
            match_ref = _event_collection(event_id, "singles_matches").document(match_id)
            if not match_ref.get().exists:
                match_ref.set({**payload, "matchedAt": now})
            # El mismo thread alimenta la lista real de conversaciones.
            _event_collection(event_id, "singles_dm").document(match_id).set({
                **payload,
                "matchedAt": now,
                "lastMessage": "",
                "lastMessageAt": "",
                "lastSenderId": "",
                "lastReadAt": {},
            }, merge=True)

        return jsonify({
            "liked": True,
            "matched": reciprocal,
            "matchId": match_id if reciprocal else "",
        }), 200
    except Exception as error:
        return jsonify({"error": str(error)}), 500


@match_bp.route("/<event_id>/pass", methods=["POST"])
def pass_user(event_id):
    data = request.get_json(silent=True) or {}
    user_id = (data.get("userId") or "").strip()
    target_id = (data.get("targetUserId") or "").strip()
    validation_error = _require_pair(event_id, user_id, target_id)
    if validation_error:
        return jsonify({"error": validation_error}), 400

    try:
        now = _now_iso()
        _event_collection(event_id, "singles_passes").document(_action_id(user_id, target_id)).set({
            "actorId": user_id,
            "targetId": target_id,
            "createdAt": now,
        }, merge=True)
        _event_collection(event_id, "singles_likes").document(_action_id(user_id, target_id)).delete()
        return jsonify({"passed": True}), 200
    except Exception as error:
        return jsonify({"error": str(error)}), 500


@match_bp.route("/<event_id>", methods=["GET"])
def get_matches(event_id):
    viewer_id = (request.args.get("viewerId") or "").strip()
    if not viewer_id or _single_data(event_id, viewer_id) is None:
        return jsonify({"error": "Solo disponible para solteros activos"}), 403

    try:
        matches = []
        for snapshot in _event_collection(event_id, "singles_matches").stream():
            data = snapshot.to_dict() or {}
            participant_ids = [str(value) for value in data.get("participantIds") or []]
            if viewer_id not in participant_ids:
                continue
            other_id = next((value for value in participant_ids if value != viewer_id), "")
            names = data.get("participantNames") or {}
            matches.append({
                "matchId": snapshot.id,
                "otherUserId": other_id,
                "otherName": names.get(other_id) or "Invitado" if isinstance(names, dict) else "Invitado",
                "matchedAt": data.get("matchedAt") or "",
            })
        matches.sort(key=lambda item: item.get("matchedAt") or "", reverse=True)
        return jsonify({"matches": matches}), 200
    except Exception as error:
        return jsonify({"error": str(error)}), 500


def _delete_collection_documents(collection, predicate):
    deleted = 0
    for snapshot in list(collection.stream()):
        data = snapshot.to_dict() or {}
        if predicate(snapshot, data):
            snapshot.reference.delete()
            deleted += 1
    return deleted


@match_bp.route("/<event_id>/qa/reset", methods=["POST"])
def reset_qa_social_state(event_id):
    data = request.get_json(silent=True) or {}
    user_ids = [str(value).strip() for value in data.get("userIds") or [] if str(value).strip()]
    if not user_ids or len(user_ids) > 10 or any(not value.startswith("qa_") for value in user_ids):
        return jsonify({"error": "Sólo se pueden reiniciar perfiles con prefijo qa_"}), 400
    qa_ids = set(user_ids)

    try:
        deleted = {"singles": 0, "actions": 0, "matches": 0, "conversations": 0, "messages": 0}
        for user_id in qa_ids:
            ref = _single_doc(event_id, user_id)
            if ref.get().exists:
                ref.delete(); deleted["singles"] += 1

        for name in ("singles_likes", "singles_passes"):
            deleted["actions"] += _delete_collection_documents(
                _event_collection(event_id, name),
                lambda _, item: item.get("actorId") in qa_ids or item.get("targetId") in qa_ids,
            )
        deleted["matches"] += _delete_collection_documents(
            _event_collection(event_id, "singles_matches"),
            lambda _, item: bool(qa_ids.intersection(str(value) for value in item.get("participantIds") or [])),
        )
        for thread in list(_event_collection(event_id, "singles_dm").stream()):
            thread_data = thread.to_dict() or {}
            participants = {str(value) for value in thread_data.get("participantIds") or []}
            if not qa_ids.intersection(participants):
                continue
            deleted["messages"] += _delete_collection_documents(thread.reference.collection("messages"), lambda *_: True)
            thread.reference.delete(); deleted["conversations"] += 1

        return jsonify({"ok": True, "deleted": deleted}), 200
    except Exception as error:
        return jsonify({"error": str(error)}), 500


@match_bp.route("/<event_id>/qa/state", methods=["GET"])
def get_qa_social_state(event_id):
    user_ids = [(request.args.get("userA") or "").strip(), (request.args.get("userB") or "").strip()]
    if any(not value.startswith("qa_") for value in user_ids):
        return jsonify({"error": "Perfiles QA inválidos"}), 400
    user_a, user_b = user_ids
    try:
        thread = _event_collection(event_id, "singles_dm").document(_thread_id(user_a, user_b))
        return jsonify({
            "profilesActive": [_single_doc(event_id, value).get().exists for value in user_ids],
            "aLikesB": _event_collection(event_id, "singles_likes").document(_action_id(user_a, user_b)).get().exists,
            "bLikesA": _event_collection(event_id, "singles_likes").document(_action_id(user_b, user_a)).get().exists,
            "matched": _event_collection(event_id, "singles_matches").document(_thread_id(user_a, user_b)).get().exists,
            "conversationExists": thread.get().exists,
            "messageCount": sum(1 for _ in thread.collection("messages").stream()),
        }), 200
    except Exception as error:
        return jsonify({"error": str(error)}), 500
