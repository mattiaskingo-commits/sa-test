#!/usr/bin/env bash

service="$1"

if [ -z "$service" ]; then
    echo "Viga: teenuse nimi puudub. Kasutus: $0 <teenus>"
    exit 2
fi

if systemctl is-active --quiet "${service}.service" 2>/dev/null; then
    echo "Teenus $service töötab."
    exit 0
else
    echo "Teenus $service ei tööta."
    exit 1
fi
