def test_caller_in_log(caplog, client):
    client.get("/ping")

    assert "Received request from testclient" in caplog.messages[0]
    assert (
        "Finished request from testclient: GET @ http://testserver//ping; took"
        in caplog.messages[1]
    )
