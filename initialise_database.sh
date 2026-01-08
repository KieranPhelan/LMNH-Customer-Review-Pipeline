#!/bin/bash

source .env
export PGPASSWORD="$DATABASE_PASSWORD"

psql -h "$DATABASE_IP" -U "$DATABASE_USERNAME" -tc "SELECT 1 FROM pg_database WHERE datname = 'museum'" | grep -q 1 || \
psql -h "$DATABASE_IP" -U "$DATABASE_USERNAME" -c "CREATE DATABASE museum"

psql -h "$DATABASE_IP" -U "$DATABASE_USERNAME" -d museum -f schema.sql