import pytest

from app import app as app_module


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setattr(app_module, "DATABASE", str(tmp_path / "test.db"))
    app_module.init_db()
    app_module.app.config["TESTING"] = True
    with app_module.app.test_client() as c:
        yield c


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_create_and_list_tasks(client):
    resp = client.post("/tasks", json={"title": "Préparer le TP", "owner": "alice"})
    assert resp.status_code == 201
    tasks = client.get("/tasks?owner=alice").get_json()
    assert len(tasks) == 1
    assert tasks[0]["title"] == "Préparer le TP"


def test_create_user(client):
    resp = client.post("/users", json={"username": "bob", "password": "s3cret"})
    assert resp.status_code == 201

def test_echec_volontaire():
    assert 1 == 1