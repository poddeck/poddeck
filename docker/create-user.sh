#!/bin/sh
set -e

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

DB_USERNAME="${DB_USERNAME:-poddeck}"
DB_DATABASE="${DB_DATABASE:-poddeck}"
DB_PASSWORD="${DB_PASSWORD}"

if [ -z "$DB_PASSWORD" ]; then
  echo "Error: DB_PASSWORD is required (set in .env or as environment variable)"
  exit 1
fi

printf "Name: "
read -r NAME

printf "Email: "
read -r EMAIL

printf "Password: "
stty -echo
read -r PASSWORD
stty echo
echo

printf "Confirm password: "
stty -echo
read -r PASSWORD_CONFIRM
stty echo
echo

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
  echo "Error: Passwords do not match"
  exit 1
fi

HASH=$(docker run --rm -e USER_PASSWORD="$PASSWORD" python:3-alpine sh -c '
pip install -q argon2-cffi 2>/dev/null
python3 -c "
import os
from argon2 import PasswordHasher, Type
ph = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=1, type=Type.I)
print(ph.hash(os.environ[\"USER_PASSWORD\"]))
"')

if [ -z "$HASH" ]; then
  echo "Error: Failed to hash password"
  exit 1
fi

ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen || python3 -c "import uuid; print(uuid.uuid4())")
NOW=$(($(date +%s) * 1000))

ESCAPED_HASH=$(printf '%s' "$HASH" | sed "s/'/''/g")
ESCAPED_NAME=$(printf '%s' "$NAME" | sed "s/'/''/g")
ESCAPED_EMAIL=$(printf '%s' "$EMAIL" | sed "s/'/''/g")

docker compose exec -e PGPASSWORD="$DB_PASSWORD" postgres \
  psql -U "$DB_USERNAME" -d "$DB_DATABASE" -c \
  "INSERT INTO member (id, name, email, password, language, joined_at) VALUES ('$ID', '$ESCAPED_NAME', '$ESCAPED_EMAIL', '$ESCAPED_HASH', 'en_US', $NOW);"

echo "User '$NAME' ($EMAIL) created successfully."
