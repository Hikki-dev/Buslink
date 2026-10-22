#!/usr/bin/env bash
# Fills the LOCAL Firebase emulators with routes, schedules, trips, three demo accounts,
# some bookings, a refund request and feedback. Start the emulators first:
#   npx firebase-tools emulators:start --only auth,firestore --project demo-buslink
# It refuses to run unless it is pointed at the emulators, because the master seed script
# wipes routes, schedules and trips before it writes them.
set -euo pipefail
cd "$(dirname "$0")/.."
export FIRESTORE_EMULATOR_HOST=${FIRESTORE_EMULATOR_HOST:-127.0.0.1:8080}
export FIREBASE_AUTH_EMULATOR_HOST=${FIREBASE_AUTH_EMULATOR_HOST:-127.0.0.1:9099}
export GCLOUD_PROJECT=demo-buslink

case "$FIRESTORE_EMULATOR_HOST" in
  127.0.0.1:*|localhost:*) ;;
  *) echo "FIRESTORE_EMULATOR_HOST must point at this computer. Stopping."; exit 1 ;;
esac

cd scripts
npm install --no-audit --no-fund >/dev/null
# The scripts ask for a service account file. The emulator does not check it, so a throwaway key will do.
if [ ! -f service-account.json ]; then
  openssl genrsa -out /tmp/buslink-demo.pem 2048 2>/dev/null
  python3 - <<'PY'
import json
key = open('/tmp/buslink-demo.pem').read()
json.dump({"type": "service_account", "project_id": "demo-buslink", "private_key_id": "demo", "private_key": key,
           "client_email": "demo@demo-buslink.iam.gserviceaccount.com", "client_id": "1",
           "token_uri": "https://oauth2.googleapis.com/token"}, open('service-account.json', 'w'))
PY
  trap 'rm -f service-account.json /tmp/buslink-demo.pem' EXIT
fi

node seed_master_data.js      # 40 routes, 400 schedules
node generate_trips.js        # trips for the next 30 days
NODE_PATH="$PWD/node_modules" node ../demo/seed-emulator.js # accounts, bookings, a refund, feedback
