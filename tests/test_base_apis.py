from fastapi import status


def test_root(client):
    resp = client.get("/")
    assert status.HTTP_200_OK == resp.status_code
    assert {"microservice-template": "up"} == resp.json()


def test_ping_returns_pong(client):
    resp = client.get("/ping")
    assert status.HTTP_200_OK == resp.status_code
    assert '"pong"' == resp.text
