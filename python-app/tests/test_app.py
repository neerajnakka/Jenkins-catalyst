"""pytest suite -- Jenkins publishes reports/junit.xml + coverage.xml."""
import pytest
from app import create_app


@pytest.fixture()
def client():
    app = create_app()
    app.config.update(TESTING=True)
    with app.test_client() as c:
        yield c


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"


def test_root(client):
    res = client.get("/")
    assert res.status_code == 200
    assert "version" in res.get_json()


def test_list_items(client):
    res = client.get("/api/items")
    assert res.status_code == 200
    assert res.get_json()["count"] >= 1


def test_create_item(client):
    res = client.post("/api/items", json={"name": "push-to-dockerhub"})
    assert res.status_code == 201
    assert res.get_json()["name"] == "push-to-dockerhub"


def test_create_item_invalid(client):
    res = client.post("/api/items", json={"name": "x"})
    assert res.status_code == 400
    assert "error" in res.get_json()


def test_get_unknown_item_404(client):
    assert client.get("/api/items/999999").status_code == 404


def test_delete_item(client):
    created = client.post("/api/items", json={"name": "temp-item"}).get_json()
    assert client.delete(f"/api/items/{created['id']}").status_code == 200


def test_unknown_route_returns_json_404(client):
    res = client.get("/does-not-exist")
    assert res.status_code == 404
    assert res.is_json
