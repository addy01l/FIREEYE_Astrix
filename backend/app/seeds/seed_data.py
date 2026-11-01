from app.core.config import settings
from app.core.security import get_password_hash
from app.database import Base, SessionLocal
from app.models.household import Household
from app.models.profile import Profile
from app.models.risk_zone import RiskZone
from app.models.shelter import Shelter
from app.models.user import User
from sqlalchemy.orm import Session


def seed_hackathon_demo_data(db: Session, force_reset: bool = False):
    """
    Safely seed demo data.
    In production, destructive operations like drop_all() are strictly forbidden.
    Seeding is idempotent: existing records are preserved.
    """
    print(f"Checking database seed status (Environment: {settings.ENVIRONMENT})...")

    # Only create tables if they do not exist
    bind = db.get_bind()
    Base.metadata.create_all(bind=bind)

    # 1. Add Users for all 4 roles (if not already existing)
    existing_admin = db.query(User).filter(User.username == "admin").first()
    if not existing_admin:
        admin = User(
            username="admin",
            hashed_password=get_password_hash("securepassword"),
            role="ADMIN",
            full_name="System Administrator",
            email="admin@fire-eye.org",
            phone="+91-9876543210",
            is_active=True,
        )
        commander = User(
            username="commander",
            hashed_password=get_password_hash("securepassword"),
            role="RESCUE",
            full_name="Rescue Commander",
            email="commander@fire-eye.org",
            phone="+91-9876543211",
            is_active=True,
        )
        volunteer = User(
            username="volunteer1",
            hashed_password=get_password_hash("securepassword"),
            role="VOLUNTEER",
            full_name="Community Volunteer",
            email="volunteer@fire-eye.org",
            phone="+91-9876543212",
            is_active=True,
        )
        citizen = User(
            username="citizen1",
            hashed_password=get_password_hash("securepassword"),
            role="CITIZEN",
            full_name="Ramesh Sharma",
            email="citizen@fire-eye.org",
            phone="+91-9876543213",
            is_active=True,
        )
        db.add_all([admin, commander, volunteer, citizen])
        db.commit()
        print("Created demo users (admin, commander, volunteer1, citizen1).")
    else:
        print("Users already seeded, preserving existing accounts.")

    # Explicitly ensure profiles table has authoritative roles for existing Supabase users
    admin_prof = db.query(Profile).filter(Profile.id == "7900f312-14ea-49d0-9e1b-626228307084").first()
    if not admin_prof:
        db.add(Profile(id="7900f312-14ea-49d0-9e1b-626228307084", role="admin"))
    else:
        admin_prof.role = "admin"

    user_prof = db.query(Profile).filter(Profile.id == "38289592-1f93-498e-a862-5587b765da2e").first()
    if not user_prof:
        db.add(Profile(id="38289592-1f93-498e-a862-5587b765da2e", role="user"))
    else:
        user_prof.role = "user"
    db.commit()

    # 2. Add Risk Zones (idempotent by zone_code)
    existing_zone = db.query(RiskZone).filter(RiskZone.zone_code == "ZONE-04-NORTH").first()
    if not existing_zone:
        zone_4 = RiskZone(
            zone_code="ZONE-04-NORTH",
            name="Rudraprayag Sector 4 Hill Range",
            risk_level="LOW",
            risk_score=0.12,
            rainfall_24h=25.0,
            slope=38.0,
            elevation=1250.0,
            soil_type="Clay",
            population=1240,
            vulnerable_population=87,
            center_lat=30.2844,
            center_lng=78.9811,
            polygon=f"SRID=4326;POLYGON(({78.9811 - 0.01} {30.2844 - 0.01}, {78.9811 + 0.01} {30.2844 - 0.01}, {78.9811 + 0.01} {30.2844 + 0.01}, {78.9811 - 0.01} {30.2844 + 0.01}, {78.9811 - 0.01} {30.2844 - 0.01}))",
        )
        zone_2 = RiskZone(
            zone_code="ZONE-02-VALLEY",
            name="Kedarnath Valley Sector",
            risk_level="LOW",
            risk_score=0.08,
            rainfall_24h=25.0,
            slope=15.0,
            elevation=800.0,
            soil_type="Loamy",
            population=3050,
            vulnerable_population=210,
            center_lat=30.7352,
            center_lng=79.0669,
            polygon=f"SRID=4326;POLYGON(({79.0669 - 0.01} {30.7352 - 0.01}, {79.0669 + 0.01} {30.7352 - 0.01}, {79.0669 + 0.01} {30.7352 + 0.01}, {79.0669 - 0.01} {30.7352 + 0.01}, {79.0669 - 0.01} {30.7352 - 0.01}))",
        )
        db.add_all([zone_4, zone_2])
        db.commit()
        print("Created demo risk zones.")
    else:
        print("Risk zones already seeded.")

    # 3. Add Households (idempotent by household_code)
    existing_h = db.query(Household).filter(Household.household_code == "H101").first()
    if not existing_h:
        h101 = Household(
            household_code="H101",
            zone_id="ZONE-04-NORTH",
            address="42 Hilltop Ridge, Rudraprayag",
            latitude=30.2846,
            longitude=78.9815,
            location="SRID=4326;POINT(78.9815 30.2846)",
            elevation=1260.0,
            members_count=4,
            elderly_count=2,
            children_count=0,
            disabled_count=1,
            medical_needs="Oxygen Concentrator",
        )
        h101.vulnerability_score = h101.calculate_vulnerability()

        h102 = Household(
            household_code="H102",
            zone_id="ZONE-04-NORTH",
            address="15 Ridge View",
            latitude=30.2840,
            longitude=78.9805,
            location="SRID=4326;POINT(78.9805 30.2840)",
            elevation=1255.0,
            members_count=3,
            elderly_count=0,
            children_count=2,
            disabled_count=0,
            medical_needs=None,
        )
        h102.vulnerability_score = h102.calculate_vulnerability()
        db.add_all([h101, h102])
        db.commit()
        print("Created demo households.")
    else:
        print("Households already seeded.")

    # 4. Add Shelters (idempotent by shelter_code)
    existing_s = db.query(Shelter).filter(Shelter.shelter_code == "SHELTER-ST-MARY").first()
    if not existing_s:
        s1 = Shelter(
            shelter_code="SHELTER-ST-MARY",
            name="Rudraprayag District Shelter",
            facility_type="SHELTER",
            latitude=30.2900,
            longitude=78.9900,
            location="SRID=4326;POINT(78.9900 30.2900)",
            capacity=100,
            current_occupancy=58,
            operational_status="OPERATIONAL",
            has_medical_staff=True,
            has_power_backup=True,
            has_oxygen=True,
            is_safe=True,
            contact_phone="+91-1364-233201",
        )
        s2 = Shelter(
            shelter_code="SHELTER-BASE-CAMP",
            name="Kedarnath Safe Evacuation Center",
            facility_type="SHELTER",
            latitude=30.7400,
            longitude=79.0700,
            capacity=150,
            current_occupancy=30,
            operational_status="OPERATIONAL",
            has_medical_staff=True,
            has_power_backup=True,
            has_oxygen=True,
            is_safe=True,
            contact_phone="+91-1364-233202",
        )
        db.add_all([s1, s2])
        db.commit()
        print("Created demo shelters.")
    else:
        print("Shelters already seeded.")

    print("Database seeding check completed safely without destructive drops.")


if __name__ == "__main__":
    db = SessionLocal()
    try:
        seed_hackathon_demo_data(db)
    finally:
        db.close()
