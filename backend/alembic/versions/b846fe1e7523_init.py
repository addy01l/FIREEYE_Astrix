"""Init FIRE-EYE schema

Revision ID: b846fe1e7523
Revises: 
Create Date: 2026-10-07 15:28:59.259723

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'b846fe1e7523'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema safely preserving PostGIS and extensions."""
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("CREATE EXTENSION IF NOT EXISTS postgis;")

    # 1. users
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(length=50), nullable=False),
        sa.Column('email', sa.String(length=100), nullable=True),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('role', sa.String(length=20), nullable=False, server_default='CITIZEN'),
        sa.Column('full_name', sa.String(length=100), nullable=True),
        sa.Column('phone', sa.String(length=20), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True, server_default=sa.true()),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)

    # 2. households
    op.create_table(
        'households',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('household_code', sa.String(length=50), nullable=False),
        sa.Column('zone_id', sa.String(length=50), nullable=False),
        sa.Column('address', sa.String(length=255), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('location', sa.String(), nullable=True),
        sa.Column('elevation', sa.Float(), nullable=True, server_default='1000.0'),
        sa.Column('members_count', sa.Integer(), nullable=True, server_default='1'),
        sa.Column('elderly_count', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('children_count', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('disabled_count', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('medical_needs', sa.String(length=255), nullable=True),
        sa.Column('vulnerability_score', sa.Float(), nullable=True, server_default='0.0'),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_households_id'), 'households', ['id'], unique=False)
    op.create_index(op.f('ix_households_household_code'), 'households', ['household_code'], unique=True)
    op.create_index(op.f('ix_households_zone_id'), 'households', ['zone_id'], unique=False)

    # 3. risk_zones
    op.create_table(
        'risk_zones',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('zone_code', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('risk_level', sa.String(length=20), nullable=True, server_default='LOW'),
        sa.Column('risk_score', sa.Float(), nullable=True, server_default='0.15'),
        sa.Column('rainfall_24h', sa.Float(), nullable=True, server_default='20.0'),
        sa.Column('cumulative_rainfall_7d', sa.Float(), nullable=True, server_default='50.0'),
        sa.Column('slope', sa.Float(), nullable=True, server_default='30.0'),
        sa.Column('elevation', sa.Float(), nullable=True, server_default='1100.0'),
        sa.Column('soil_type', sa.String(length=50), nullable=True, server_default='clay_loam'),
        sa.Column('historical_disasters', sa.Integer(), nullable=True, server_default='1'),
        sa.Column('population', sa.Integer(), nullable=True, server_default='500'),
        sa.Column('vulnerable_population', sa.Integer(), nullable=True, server_default='40'),
        sa.Column('center_lat', sa.Float(), nullable=False),
        sa.Column('center_lng', sa.Float(), nullable=False),
        sa.Column('polygon', sa.String(), nullable=True),
        sa.Column('polygon_geojson', sa.Text(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_risk_zones_id'), 'risk_zones', ['id'], unique=False)
    op.create_index(op.f('ix_risk_zones_zone_code'), 'risk_zones', ['zone_code'], unique=True)

    # 4. shelters
    op.create_table(
        'shelters',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('shelter_code', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('facility_type', sa.String(length=50), nullable=True, server_default='SHELTER'),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('location', sa.String(length=255), nullable=True),
        sa.Column('capacity', sa.Integer(), nullable=True, server_default='100'),
        sa.Column('current_occupancy', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('operational_status', sa.String(length=30), nullable=True, server_default='OPERATIONAL'),
        sa.Column('has_medical_staff', sa.Boolean(), nullable=True, server_default=sa.true()),
        sa.Column('has_power_backup', sa.Boolean(), nullable=True, server_default=sa.true()),
        sa.Column('has_oxygen', sa.Boolean(), nullable=True, server_default=sa.true()),
        sa.Column('is_safe', sa.Boolean(), nullable=True, server_default=sa.true()),
        sa.Column('contact_phone', sa.String(length=20), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_shelters_id'), 'shelters', ['id'], unique=False)
    op.create_index(op.f('ix_shelters_shelter_code'), 'shelters', ['shelter_code'], unique=True)

    # 5. sos_requests
    op.create_table(
        'sos_requests',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('sos_code', sa.String(length=50), nullable=False),
        sa.Column('idempotency_key', sa.String(length=100), nullable=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('household_code', sa.String(length=50), nullable=True),
        sa.Column('sender_device_id', sa.String(length=50), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('location', sa.String(length=255), nullable=True),
        sa.Column('source_type', sa.String(length=20), nullable=True, server_default='MOBILE'),
        sa.Column('emergency_type', sa.String(length=50), nullable=True, server_default='LANDSLIDE_TRAPPED'),
        sa.Column('severity', sa.String(length=20), nullable=True, server_default='HIGH'),
        sa.Column('status', sa.String(length=20), nullable=True, server_default='PENDING'),
        sa.Column('priority_score', sa.Float(), nullable=True, server_default='50.0'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('assigned_team_id', sa.String(length=50), nullable=True),
        sa.Column('assigned_shelter_id', sa.String(length=50), nullable=True),
        sa.Column('via_mesh', sa.String(length=20), nullable=True, server_default='FALSE'),
        sa.Column('hops_count', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('resolved_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_sos_requests_id'), 'sos_requests', ['id'], unique=False)
    op.create_index(op.f('ix_sos_requests_sos_code'), 'sos_requests', ['sos_code'], unique=True)
    op.create_index(op.f('ix_sos_requests_idempotency_key'), 'sos_requests', ['idempotency_key'], unique=True)
    op.create_index(op.f('ix_sos_requests_household_code'), 'sos_requests', ['household_code'], unique=False)

    # 6. rescue_assignments
    op.create_table(
        'rescue_assignments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('sos_id', sa.Integer(), sa.ForeignKey('sos_requests.id'), nullable=False),
        sa.Column('sos_code', sa.String(length=50), nullable=False),
        sa.Column('responder_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('responder_username', sa.String(length=50), nullable=True),
        sa.Column('team_name', sa.String(length=100), nullable=True),
        sa.Column('status', sa.String(length=30), nullable=True, server_default='ASSIGNED'),
        sa.Column('assigned_at', sa.DateTime(), nullable=True),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_rescue_assignments_id'), 'rescue_assignments', ['id'], unique=False)
    op.create_index(op.f('ix_rescue_assignments_sos_id'), 'rescue_assignments', ['sos_id'], unique=False)
    op.create_index(op.f('ix_rescue_assignments_sos_code'), 'rescue_assignments', ['sos_code'], unique=False)

    # 7. mesh_messages
    op.create_table(
        'mesh_messages',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('message_id', sa.String(length=100), nullable=False),
        sa.Column('sender_id', sa.String(length=50), nullable=False),
        sa.Column('message_type', sa.String(length=30), nullable=True, server_default='SOS'),
        sa.Column('household_code', sa.String(length=50), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=True),
        sa.Column('longitude', sa.Float(), nullable=True),
        sa.Column('severity', sa.String(length=20), nullable=True),
        sa.Column('ttl', sa.Integer(), nullable=True, server_default='8'),
        sa.Column('hops_trail', sa.Text(), nullable=True),
        sa.Column('raw_payload', sa.Text(), nullable=True),
        sa.Column('sync_state', sa.String(length=30), nullable=True, server_default='RECEIVED'),
        sa.Column('received_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_mesh_messages_id'), 'mesh_messages', ['id'], unique=False)
    op.create_index(op.f('ix_mesh_messages_message_id'), 'mesh_messages', ['message_id'], unique=True)

    # 8. audit_events
    op.create_table(
        'audit_events',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('actor_username', sa.String(length=50), nullable=True),
        sa.Column('actor_role', sa.String(length=30), nullable=True),
        sa.Column('action', sa.String(length=100), nullable=False),
        sa.Column('resource_type', sa.String(length=50), nullable=True),
        sa.Column('resource_id', sa.String(length=100), nullable=True),
        sa.Column('details', sa.Text(), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=True, server_default='SUCCESS'),
        sa.Column('timestamp', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_audit_events_id'), 'audit_events', ['id'], unique=False)
    op.create_index(op.f('ix_audit_events_actor_username'), 'audit_events', ['actor_username'], unique=False)
    op.create_index(op.f('ix_audit_events_action'), 'audit_events', ['action'], unique=False)
    op.create_index(op.f('ix_audit_events_timestamp'), 'audit_events', ['timestamp'], unique=False)


def downgrade() -> None:
    """Downgrade schema dropping ONLY application tables in reverse dependency order."""
    op.drop_table('audit_events')
    op.drop_table('mesh_messages')
    op.drop_table('rescue_assignments')
    op.drop_table('sos_requests')
    op.drop_table('shelters')
    op.drop_table('risk_zones')
    op.drop_table('households')
    op.drop_table('users')
