#!/bin/bash

source ../.env

PGPASSWORD="$DATABASE_PASSWORD" psql \
    -h "$DATABASE_IP" \
    -U "$DATABASE_USERNAME" \
    -d "$DATABASE_NAME" \
    -p "$DATABASE_PORT" \
    -c "TRUNCATE TABLE review, incident;"