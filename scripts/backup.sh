#!/usr/bin/env bash

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$BASE_DIR/config/settings.conf"

DATE=$(date '+%Y%m%d_%H%M%S')
ARCHIVE="$BACKUP_DIR/backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

if [ ! -d "$BACKUP_SOURCE" ]; then
    echo "Viga: allikakausta $BACKUP_SOURCE ei ole (käivita setup.sh)."
    exit 1
fi

echo "Varukoopia loomine..."

if ! tar -czf "$ARCHIVE" -C "$BACKUP_SOURCE" .; then
    echo "Varukoopia ebaõnnestus (tar viga)."
    rm -f "$ARCHIVE"
    exit 1
fi

if tar -tzf "$ARCHIVE" > /dev/null 2>&1; then
    echo "Varukoopia valmis: $ARCHIVE"
    echo "Failide arv arhiivis: $(tar -tzf "$ARCHIVE" | grep -vc '/$')"
    exit 0
else
    echo "Varukoopia ebaõnnestus: arhiiv ei ole loetav."
    exit 1
fi
