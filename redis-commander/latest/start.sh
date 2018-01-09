#!/bin/sh

redis-commander \
    --redis-host "$REDIS_HOST" \
    --redis-port "$REDIS_PORT" \
    --sentinel-host "$SENTINEL_HOST" \
    --sentinel-port "$SENTINEL_PORT" \
    --redis-password $REDIS_PASSWORD \
    --redis-db $REDIS_DB \
    --http-auth-username $HTTP_USERNAME \
    --http-auth-password $HTTP_PASSWORD \
    --port 8080
