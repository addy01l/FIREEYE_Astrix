def test_user_login_success(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "commander", "password": "securepassword"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["role"] == "RESCUE"
    assert data["username"] == "commander"


def test_user_login_invalid_password(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "commander", "password": "wrongpassword"},
    )
    assert response.status_code == 401


def test_user_register_and_me(client):
    reg_payload = {
        "username": "newcitizen",
        "password": "mypassword123",
        "email": "newcitizen@example.com",
        "role": "CITIZEN",
        "full_name": "New Citizen User",
        "phone": "+91-9999988888",
    }
    reg_resp = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_resp.status_code == 201
    user_data = reg_resp.json()
    assert user_data["username"] == "newcitizen"
    assert user_data["role"] == "CITIZEN"

    # Login with new credentials
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"username": "newcitizen", "password": "mypassword123"},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    refresh_token = login_resp.json()["refresh_token"]

    # Access /auth/me with Bearer token
    me_resp = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_resp.status_code == 200
    assert me_resp.json()["username"] == "newcitizen"

    # Test Refresh Token
    refresh_resp = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 200
    assert "access_token" in refresh_resp.json()

