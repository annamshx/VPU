import pytest

from fastapi.testclient import TestClient

from microservice_template.app import app


@pytest.fixture()
def client():
    return TestClient(app)
