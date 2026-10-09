# Arvestustöö raport

Nimi: Mattias Kingo  
Variant: A  
Kuupäev: 2026-10-09  

## Probleem 1
- Skript: scripts/backup.sh
- Mida skript näiliselt tegi: Teatas "Varukoopia valmis" ja lõi faili `backup_*.tar.gz`.
- Mis oli tegelikult vale: `find ... > $ARCHIVE` kirjutas lihtsalt failinimede nimekirja tekstifaili. Päris arhiivi ei tekkinud ja failide sisu ei salvestunud. Kontroll `-s` nägi ainult, et fail pole tühi.
- Kuidas vea avastasin: Faili laiend ei vastanud sisule.
- Millise käsuga kontrollisin: `file backups/backup_*.tar.gz` (ASCII text) ja `tar -tzf` (not in gzip format).
- Parandus: `tar -czf "$ARCHIVE" -C "$BACKUP_SOURCE" .` ning pärast `tar -tzf` kontroll; ebaõnnestumisel kustutatakse katkine fail ja exit 1.
- Kuidas kontrollisin pärast parandust: `file` näitab "gzip compressed data", `tar -tzf` loetleb ka `important data.txt` (tühikuga nimi säilib).
- Exit code enne / pärast: enne alati 0; pärast 0 ainult kui arhiiv on loetav, muidu 1.

## Probleem 2
- Skript: scripts/disk_check.sh
- Mida skript näiliselt tegi: Kuvas "Kettakasutus: N%" ja võrdles limiidiga 80.
- Mis oli tegelikult vale: `awk '{print $4}'` võtab df veeru Avail (vaba ruum), mitte Use%. `tr -dc '0-9'` eemaldas ühiku, nii et "23G" sai "23%".
- Kuidas vea avastasin: Skript näitas 23%, aga `df -h /` näitab Use% 21%.
- Millise käsuga kontrollisin: `df -h /` ja `bash -x scripts/disk_check.sh`.
- Parandus: `df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'` ja numbrikontroll.
- Kuidas kontrollisin pärast parandust: Skripti number ühtib `df -h /` Use% veeruga.
- Exit code enne / pärast: enne alati 0 (vale number), pärast 0 alla limiidi ja 1 üle limiidi.

## Probleem 3
- Skript: scripts/system_info.sh (hostname ja kasutaja)
- Mida skript näiliselt tegi: Kuvas hostname'i ja kasutaja.
- Mis oli tegelikult vale: `Hostname: $(whoami)` ja `Kasutaja: $(hostname)` olid vahetatud.
- Kuidas vea avastasin: Hostname'i kohal oli kasutajanimi.
- Millise käsuga kontrollisin: `hostname`, `whoami`.
- Parandus: Vahetasin käsud omavahel.
- Kuidas kontrollisin pärast parandust: Väljund ühtib `hostname` ja `whoami` tulemusega.

## Probleem 4
- Skript: scripts/system_info.sh (kernel ja uptime)
- Mida skript näiliselt tegi: Kuvas kerneli versiooni ja uptime'i.
- Mis oli tegelikult vale: `uname -m` annab arhitektuuri (x86_64), mitte kernelit. "Uptime" oli `date` ehk kellaaeg.
- Kuidas vea avastasin: Kernel: x86_64 ja Uptime oli kellaaeg.
- Millise käsuga kontrollisin: `uname -r`, `uptime -p`.
- Parandus: `uname -r` ja `uptime -p`.
- Kuidas kontrollisin pärast parandust: Väljund ühtib nende käskude otsese väljundiga.

## Probleem 5
- Skript: scripts/system_info.sh (mälu)
- Mida skript näiliselt tegi: Kuvas "Mälu kokku".
- Mis oli tegelikult vale: `awk '/Swap:/'` võttis swapi mahu, mitte RAM-i.
- Kuidas vea avastasin: Tulemus ei klappinud `free -m` Mem rea kogumahuga.
- Millise käsuga kontrollisin: `free -m`.
- Parandus: `awk '/^Mem:/ {print $2}'`.
- Kuidas kontrollisin pärast parandust: Kuvatud väärtus = `free -m` Mem total.

## Probleem 6
- Skript: scripts/user_check.sh
- Mida skript näiliselt tegi: Kontrollis, kas kasutaja eksisteerib.
- Mis oli tegelikult vale: `grep -c "$username" /etc/group` otsib grupifailist osalist vastet ja tingimus `-ge 0` on alati tõene. Skript vastas alati "eksisteerib" (ka olematu ja tühja nime korral), exit code oli alati 0.
- Kuidas vea avastasin: Proovisin olematut kasutajat ja tühja sisendit.
- Millise käsuga kontrollisin: `bash scripts/user_check.sh nosuchuser`, `echo $?`, `getent passwd nosuchuser`.
- Parandus: `getent passwd "$username"` ja tühja sisendi kontroll (exit 2).
- Kuidas kontrollisin pärast parandust: root → eksisteerib (0); olematu → ei leitud (1); "" → viga (2).
- Exit code enne / pärast: enne alati 0; pärast 0 / 1 / 2.

## Probleem 7
- Skript: scripts/service_check.sh
- Mida skript näiliselt tegi: Teatas, kas teenus töötab.
- Mis oli tegelikult vale: `systemctl list-unit-files` näitab ainult, et unit-fail on olemas, mitte et teenus töötab. Tühja sisendit ei käsitletud.
- Kuidas vea avastasin: Skripti kommentaar ja loogika kontrollisid olemasolu, mitte olekut.
- Millise käsuga kontrollisin: `systemctl is-active <teenus>`.
- Parandus: `systemctl is-active --quiet "${service}.service"` ja tühja sisendi kontroll (exit 2).
- Kuidas kontrollisin pärast parandust: Töötav teenus → 0, peatatud või olematu → 1, tühi → 2.

## Uus funktsionaalsus
- Mida lisasin: `scripts/backup_verify.sh` ja menüüvalik 6 "Varukoopia kontroll". Kontrollib viimast arhiivi: loetavus, failide arv ja taastamine ajutisse kausta koos `diff -r`.
- Kuidas käivitada: `bash main.sh` ja valik 6, või `bash scripts/backup_verify.sh` pärast varukoopiat.
- Kuidas kontrollisin, et tulemus on õige: Terve arhiiv → OK (0); varukoopiat pole → teade (1); rikutud arhiiv → VIGA (1).
