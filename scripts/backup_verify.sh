#!/usr/bin/env bash
# Kontrollib viimast varukoopiat: loetavus, failide arv ja taastetest.

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$BASE_DIR/config/settings.conf"

latest=$(ls -t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | head -1)

if [ -z "$latest" ]; then
    echo "Varukoopiaid ei leitud. Tee kõigepealt varukoopia (valik 5)."
    exit 1
fi

echo "Kontrollin: $latest"

if ! tar -tzf "$latest" > /dev/null 2>&1; then
    echo "VIGA: arhiiv ei ole korrektne tar.gz."
    exit 1
fi

src_count=$(find "$BACKUP_SOURCE" -type f | wc -l)
arc_count=$(tar -tzf "$latest" | grep -vc '/$')
echo "Faile allikas: $src_count, arhiivis: $arc_count"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tar -xzf "$latest" -C "$tmp"

if [ "$src_count" -eq "$arc_count" ] && diff -r "$BACKUP_SOURCE" "$tmp" > /dev/null; then
    echo "OK: varukoopia on taastatav ja sisu ühtib allikaga."
    exit 0
else
    echo "VIGA: taastatud sisu erineb allikast."
    exit 1
fi
