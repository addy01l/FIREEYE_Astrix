# Real device demo setup

The app now authenticates with Supabase Auth and sends its Supabase access token to the API. The API accepts Supabase HS256 access tokens only when its project URL and JWT secret are configured. Privileged roles are read from the signed `app_metadata.role` claim; values are `rescuer` and `command_center`. Public sign-up creates a citizen account. Assign privileged roles through a trusted server-side Supabase Admin API process; never put a service-role key in the mobile app.

## Configure services

Set these backend environment variables:

```text
ENVIRONMENT=production
SECRET_KEY=<unique random backend signing secret>
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_JWT_SECRET=<project JWT signing secret>
DATABASE_URL=<managed PostgreSQL URL>
CORS_ALLOW_ORIGINS=<comma-separated trusted web origins>
SEED_DEMO_DATA=false
```

The API currently validates Supabase's HS256 JWTs. If the project uses asymmetric signing keys, add JWKS validation before switching the project signing key. Add real shelter records and any required operational users through an authorized administrative workflow. Do not enable demo seeding in a real deployment.

Build the Android app with the public Supabase project URL and anon key. For a controlled BLE demo, provision the same random 32-byte-or-longer `MESH_HMAC_KEY` into both builds through your deployment secret manager. It is embedded in the app binary, so this shared-key scheme is not suitable for a hostile production environment; production needs per-device keys and a managed key-rotation/provisioning design.

```text
flutter build apk --dart-define=BACKEND_BASE_URL=https://<api-host> --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<public-anon-key> --dart-define=MESH_HMAC_KEY=<secret-from-build-secret-manager>
```

The anon key is intended for client use; table access still needs Supabase RLS. Do not ship the service-role key. Grant `app_metadata.role` using a trusted server-side Supabase Admin API process; client-editable `user_metadata` is never used for authorization.

The old unauthenticated HTML citizen/commander pages are no longer routed by FastAPI. Use the Flutter app dashboard so its Supabase session is sent with the protected rescue queue, mesh ingestion, audit, household, and status APIs.

## Two-phone BLE check

Install the same Android build on both physical phones. Sign in on the online phone as a `command_center` or `rescuer` account and start its mesh listener. On the offline phone, disable cellular data and Wi-Fi while keeping Bluetooth and Location enabled, grant the requested Android nearby-device permissions, wait for a real GPS fix, and send an SOS. The offline device queues the SOS locally and advertises it; the online device should receive it and forward it to the configured API. Verify the returned SOS record in the authenticated dashboard and inspect API logs for mesh ingestion.

The current implementation does not contain offline map tiles or a downloaded road graph. A phone without internet can transmit an SOS over BLE, but it cannot fetch live OSM tiles or calculate a new road-safe shelter route until a connected gateway/API is reachable. The route screen reports that failure explicitly. A field deployment needs licensed/offline map data, routing graph updates, and tested device background-service behavior before claiming full offline evacuation navigation.
