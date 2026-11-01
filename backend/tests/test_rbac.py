import pytest
from fastapi.testclient import TestClient


def test_admin_login(client):
    """1. Test Admin login returns 200, JWT token, and administrative role."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "securepassword"},
    )
    assert login_resp.status_code == 200
    data = login_resp.json()
    assert "access_token" in data
    assert data["role"].lower() in ["admin", "commander"]
    assert data["username"] == "admin"


def test_normal_user_login(client):
    """2. Test Normal User login returns 200, JWT token, and user role."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"username": "citizen1", "password": "securepassword"},
    )
    assert login_resp.status_code == 200
    data = login_resp.json()
    assert "access_token" in data
    assert data["role"].lower() in ["user", "citizen"]
    assert data["username"] == "citizen1"


def test_admin_access_to_admin_endpoints(client):
    """3. Test Admin has authorized access to admin dashboard and management endpoints."""
    # Log in as admin
    admin_login = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "securepassword"},
    )
    admin_token = admin_login.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # Admin access to User Management API
    users_resp = client.get("/api/v1/users/", headers=admin_headers)
    assert users_resp.status_code == 200
    users = users_resp.json()
    assert len(users) >= 1

    # Admin access to Priority Triage Queue
    prio_resp = client.get("/api/v1/priority/queue", headers=admin_headers)
    assert prio_resp.status_code == 200

    # Admin access to Audit Trail
    audit_resp = client.get("/api/v1/audit/events", headers=admin_headers)
    assert audit_resp.status_code == 200

    # Admin updates user role
    target = users[0]
    role_resp = client.patch(
        f"/api/v1/users/{target['id']}/role",
        headers=admin_headers,
        json={"role": "user"},
    )
    assert role_resp.status_code == 200
    assert role_resp.json()["role"] == "user"


def test_normal_user_receiving_403_on_admin_endpoints(client):
    """4. Test Normal User receives HTTP 403 Forbidden on all admin endpoints."""
    # Log in as normal citizen
    citizen_login = client.post(
        "/api/v1/auth/login",
        json={"username": "citizen1", "password": "securepassword"},
    )
    citizen_token = citizen_login.json()["access_token"]
    citizen_headers = {"Authorization": f"Bearer {citizen_token}"}

    # 403 on User Management list
    users_resp = client.get("/api/v1/users/", headers=citizen_headers)
    assert users_resp.status_code == 403
    assert "Admin" in users_resp.json().get("detail", "")

    # 403 on Role Update
    role_resp = client.patch(
        "/api/v1/users/1/role",
        headers=citizen_headers,
        json={"role": "admin"},
    )
    assert role_resp.status_code == 403

    # 403 on Priority Triage Queue
    prio_resp = client.get("/api/v1/priority/queue", headers=citizen_headers)
    assert prio_resp.status_code == 403

    # 403 on Audit Trail
    audit_resp = client.get("/api/v1/audit/events", headers=citizen_headers)
    assert audit_resp.status_code == 403

    # 403 on SOS Status Update
    status_resp = client.patch(
        "/api/v1/sos/SOS-NONEXISTENT/status",
        headers=citizen_headers,
        json={"status": "RESCUED"},
    )
    assert status_resp.status_code == 403

    # 403 on Team Assignment
    assign_resp = client.post(
        "/api/v1/sos/1/assign",
        headers=citizen_headers,
        json={"team_name": "NDRF Tactical Team"},
    )
    assert assign_resp.status_code == 403


def test_unauthenticated_request_receiving_401(client):
    """5. Test unauthenticated request receives HTTP 401 Unauthorized on protected endpoints."""
    no_auth_headers = {"Authorization": ""}

    # 401 on User Management
    res = client.get("/api/v1/users/", headers=no_auth_headers)
    assert res.status_code == 401

    # 401 on Current User Profile
    res = client.get("/api/v1/auth/me", headers=no_auth_headers)
    assert res.status_code == 401

    # 401 on Active SOS Queue
    res = client.get("/api/v1/sos/active", headers=no_auth_headers)
    assert res.status_code == 401

    # 401 on My SOS History
    res = client.get("/api/v1/sos/my", headers=no_auth_headers)
    assert res.status_code == 401


def test_user_accessing_their_own_sos(client):
    """6. Test User can create and view their own SOS report and history."""
    # Log in as normal citizen
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"username": "citizen1", "password": "securepassword"},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create an SOS report
    create_resp = client.post(
        "/api/v1/sos/",
        headers=headers,
        json={
            "latitude": 30.2846,
            "longitude": 78.9815,
            "emergency_type": "LANDSLIDE_TRAPPED",
            "severity": "CRITICAL",
            "notes": "Victim stranded on second floor",
        },
    )
    assert create_resp.status_code == 201
    sos_data = create_resp.json()
    sos_id = sos_data["id"]
    sos_code = sos_data["sos_code"]

    # Read own SOS by ID
    get_resp = client.get(f"/api/v1/sos/{sos_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["sos_code"] == sos_code

    # Read own SOS in /my history
    my_resp = client.get("/api/v1/sos/my", headers=headers)
    assert my_resp.status_code == 200
    my_codes = [s["sos_code"] for s in my_resp.json()]
    assert sos_code in my_codes


def test_user_attempting_to_access_another_users_sos(client):
    """7. Test User attempting to access another user's SOS receives 403 Forbidden."""
    # User A (victim) creates SOS
    user_a_login = client.post(
        "/api/v1/auth/login",
        json={"username": "citizen1", "password": "securepassword"},
    )
    token_a = user_a_login.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    create_resp = client.post(
        "/api/v1/sos/",
        headers=headers_a,
        json={
            "latitude": 30.2900,
            "longitude": 78.9900,
            "emergency_type": "FLASH_FLOOD",
            "severity": "HIGH",
            "notes": "User A private emergency notes",
        },
    )
    assert create_resp.status_code == 201
    user_a_sos_id = create_resp.json()["id"]

    # User B (volunteer / another citizen) registers and logs in
    reg_resp = client.post(
        "/api/v1/auth/register",
        json={
            "username": "userb_snooper",
            "password": "securepass123",
            "email": "userb@example.com",
            "role": "CITIZEN",
        },
    )
    assert reg_resp.status_code == 201

    login_b = client.post(
        "/api/v1/auth/login",
        json={"username": "userb_snooper", "password": "securepass123"},
    )
    token_b = login_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User B attempts to view User A's SOS -> Must return 403 Forbidden!
    snoop_resp = client.get(f"/api/v1/sos/{user_a_sos_id}", headers=headers_b)
    assert snoop_resp.status_code == 403
    assert "Access denied" in snoop_resp.json().get("detail", "")

    # Admin accesses User A's SOS -> Allowed with 200 OK
    admin_login = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "securepassword"},
    )
    token_admin = admin_login.json()["access_token"]
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    admin_resp = client.get(f"/api/v1/sos/{user_a_sos_id}", headers=headers_admin)
    assert admin_resp.status_code == 200
    assert admin_resp.json()["id"] == user_a_sos_id
