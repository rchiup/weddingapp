import importlib.util
import sys
import types
from pathlib import Path

from flask import Flask


class Snapshot:
    def __init__(self, reference, data):
        self.reference = reference
        self.id = reference.id
        self._data = data

    @property
    def exists(self):
        return self._data is not None

    def to_dict(self):
        return dict(self._data or {})


class Document:
    def __init__(self, store, path):
        self.store = store
        self.path = tuple(path)
        self.id = self.path[-1]

    def get(self):
        return Snapshot(self, self.store.get(self.path))

    def set(self, data, merge=False):
        current = dict(self.store.get(self.path) or {}) if merge else {}
        current.update(data)
        self.store[self.path] = current

    def delete(self):
        self.store.pop(self.path, None)

    def collection(self, name):
        return Collection(self.store, (*self.path, name))


class Collection:
    def __init__(self, store, path):
        self.store = store
        self.path = tuple(path)

    def document(self, document_id):
        return Document(self.store, (*self.path, document_id))

    def stream(self):
        expected_length = len(self.path) + 1
        return [Snapshot(Document(self.store, path), data) for path, data in list(self.store.items()) if len(path) == expected_length and path[:-1] == self.path]


class Database:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        return Collection(self.store, (name,))


def load_routes():
    fake_service_module = types.ModuleType("services.firebase_service")
    fake_service_module.FirebaseService = lambda: types.SimpleNamespace(db=Database())
    sys.modules["services.firebase_service"] = fake_service_module
    route_path = Path(__file__).parents[1] / "routes" / "match_routes.py"
    spec = importlib.util.spec_from_file_location("match_routes_under_test", route_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_reciprocal_like_creates_match_conversation_and_qa_reset():
    routes = load_routes()
    app = Flask(__name__)
    app.register_blueprint(routes.match_bp, url_prefix="/api/matches")
    event_id = "QA_EVENT"
    user_a = "qa_run_a"
    user_b = "qa_run_b"
    singles = routes._event_collection(event_id, "singles")
    singles.document(user_a).set({"name": "Vale QA", "activatedAt": "2026-01-01T00:00:00Z"})
    singles.document(user_b).set({"name": "Nico QA", "activatedAt": "2026-01-02T00:00:00Z"})

    client = app.test_client()
    potential = client.get(f"/api/matches/{event_id}/potential?viewerId={user_a}")
    assert potential.status_code == 200
    assert [item["userId"] for item in potential.get_json()["users"]] == [user_b]

    first_like = client.post(f"/api/matches/{event_id}/like", json={"userId": user_a, "targetUserId": user_b})
    assert first_like.status_code == 200
    assert first_like.get_json()["matched"] is False

    second_like = client.post(f"/api/matches/{event_id}/like", json={"userId": user_b, "targetUserId": user_a})
    assert second_like.status_code == 200
    assert second_like.get_json()["matched"] is True

    matches = client.get(f"/api/matches/{event_id}?viewerId={user_a}").get_json()["matches"]
    assert matches[0]["otherUserId"] == user_b
    thread_id = routes._thread_id(user_a, user_b)
    assert routes._event_collection(event_id, "singles_dm").document(thread_id).get().exists

    state = client.get(f"/api/matches/{event_id}/qa/state?userA={user_a}&userB={user_b}").get_json()
    assert state == {
        "profilesActive": [True, True],
        "aLikesB": True,
        "bLikesA": True,
        "matched": True,
        "conversationExists": True,
        "messageCount": 0,
    }

    reset = client.post(f"/api/matches/{event_id}/qa/reset", json={"userIds": [user_a, user_b]})
    assert reset.status_code == 200
    clean_state = client.get(f"/api/matches/{event_id}/qa/state?userA={user_a}&userB={user_b}").get_json()
    assert clean_state["profilesActive"] == [False, False]
    assert clean_state["matched"] is False
    assert clean_state["conversationExists"] is False
