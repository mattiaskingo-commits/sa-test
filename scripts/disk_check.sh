#!/usr/bin/env bash

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$BASE_DIR/config/settings.conf"

usage=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')

if ! [[ "$usage" =~ ^[0-9]+$ ]]; then
    echo "Viga: kettakasutuse lugemine ebaõnnestus."
    exit 2
fi

echo "Kettakasutus: ${usage}%"

if [ "$usage" -lt "$DISK_LIMIT" ]; then
    echo "OK: kettaruumi kasutus on normis."
    exit 0
else
    echo "HOIATUS: kettaruumi kasutus on liiga suur."
    exit 1
fi
