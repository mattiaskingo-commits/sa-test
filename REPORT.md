# Arvestustöö raport

Nimi: Mattias Kingo  
Variant: A  
Kuupäev: 2026-10-09  

Töö käik: lugesin iga skripti koodi läbi, käivitasin algsed skriptid ja võrdlesin nende väljundit vastavate Linuxi käskude tulemustega. Töö tegemisel kasutasin abina tehisintellekti (Claude), kuid kontrollisin tulemusi ise oma masinas.

## Probleem 1
- Skript: scripts/backup.sh
- Mida skript näiliselt tegi: Teatas "Varukoopia valmis" ja lõi faili `backup_*.tar.gz`.
- Mis oli tegelikult vale: `find ... > $ARCHIVE` kirjutas failinimede nimekirja tekstifaili. Päris arhiivi ei tekkinud ja failide sisu ei salvestunud. Kontroll `-s` kontrollib ainult, et fail pole tühi.
- Kuidas vea avastasin: Koodist nägin, et arhiivi tegemisel ei kasutata `tar`-i, vaid `find` väljundit suunatakse faili. Käivitasin skripti ja kontrollisin tekkinud faili.
- Millise käsuga kontrollisin: `file backups/*.tar.gz` näitas "ASCII text" ja `tar -tzf` andis vea "gzip: stdin: not in gzip format".
- Parandus: `tar -czf "$ARCHIVE" -C "$BACKUP_SOURCE" .` ning pärast `tar -tzf` kontroll. Ebaõnnestumisel kustutatakse katkine fail ja exit 1.
- Kuidas kontrollisin pärast parandust: `file` näitab "gzip compressed data" ja `tar -tzf` loetleb ka `important data.txt` (tühikuga nimi säilib).
- Exit code enne / pärast: enne alati 0 (kui nimekiri polnud tühi). Pärast 0 ainult kui arhiiv on loetav, muidu 1.

## Probleem 2
- Skript: scripts/disk_check.sh
- Mida skript näiliselt tegi: Kuvas "Kettakasutus: N%" ja võrdles limiidiga 80.
- Mis oli tegelikult vale: `awk '{print $4}'` võtab df veeru Avail (vaba ruum), mitte Use%. `tr -dc '0-9'` eemaldas ühiku, nii et "23G" sai "23%".
- Kuidas vea avastasin: Käivitasin skripti ja võrdlesin väljundit käsuga `df -h /`. Skript näitas 23%, aga Use% oli 21%. `bash -x` väljundist nägin, et kasutati `awk` veergu `$4`.
- Millise käsuga kontrollisin: `df -h /` ja `bash -x scripts/disk_check.sh`.
- Parandus: `df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'` ja numbrikontroll.
- Kuidas kontrollisin pärast parandust: Skripti number (21%) ühtib `df -h /` Use% veeruga.
- Exit code enne / pärast: enne alati 0 (vale number). Pärast 0 alla limiidi ja 1 üle limiidi.

## Probleem 3
- Skript: scripts/system_info.sh (hostname ja kasutaja)
- Mida skript näiliselt tegi: Kuvas hostname'i ja kasutaja.
- Mis oli tegelikult vale: `Hostname: $(whoami)` ja `Kasutaja: $(hostname)` olid vahetatud.
- Kuidas vea avastasin: Märkasin koodi lugedes, et sildid ja käsud ei klapi. Käivitasin skripti: see näitas "Hostname: mattias" ja "Kasutaja: sv-mattias", aga `hostname` ütles sv-mattias ja `whoami` ütles mattias.
- Millise käsuga kontrollisin: `hostname`, `whoami`.
- Parandus: Vahetasin käsud omavahel.
- Kuidas kontrollisin pärast parandust: Väljund ühtib `hostname` ja `whoami` tulemusega.

## Probleem 4
- Skript: scripts/system_info.sh (kernel ja uptime)
- Mida skript näiliselt tegi: Kuvas kerneli versiooni ja uptime'i.
- Mis oli tegelikult vale: `uname -m` annab arhitektuuri, mitte kernelit. "Uptime" oli `date`, ehk praegune kellaaeg.
- Kuidas vea avastasin: Skript näitas "Kernel: x86_64" ja "Uptime: 07:14:14". Võrdlesin neid käskudega `uname -r` (6.12.107+deb13-amd64) ja `uptime -p` (up 3 hours, 16 minutes).
- Millise käsuga kontrollisin: `uname -r`, `uptime -p`.
- Parandus: `uname -r` ja `uptime -p`.
- Kuidas kontrollisin pärast parandust: Väljund ühtib nende käskude otsese väljundiga.

## Probleem 5
- Skript: scripts/system_info.sh (mälu)
- Mida skript näiliselt tegi: Kuvas "Mälu kokku".
- Mis oli tegelikult vale: `awk '/Swap:/'` võttis swapi mahu, mitte RAM-i.
- Kuidas vea avastasin: Skript näitas 1721 MB, aga `free -m` Mem rida näitas 3917 MB. 1721 MB oli Swap rea väärtus.
- Millise käsuga kontrollisin: `free -m`.
- Parandus: `awk '/^Mem:/ {print $2}'`.
- Kuidas kontrollisin pärast parandust: Kuvatud väärtus ühtib `free -m` Mem rea kogumahuga (3917 MB).

## Probleem 6
- Skript: scripts/user_check.sh
- Mida skript näiliselt tegi: Kontrollis, kas kasutaja eksisteerib.
- Mis oli tegelikult vale: `grep -c "$username" /etc/group` otsib grupifailist osalist vastet ja tingimus `-ge 0` on alati tõene. Skript vastas alati "eksisteerib", ka olematu ja tühja nime korral, ning exit code oli alati 0.
- Kuidas vea avastasin: Koodist nägin, et kasutatakse `/etc/group` faili ja tingimus on alati tõene. Käivitasin skripti olematu kasutaja `nosuchuser` ja tühja sisendiga: mõlemal korral ütles skript "eksisteerib" ja exit code oli 0. Käsk `getent passwd nosuchuser` andis exit code 2 (ei leitud).
- Millise käsuga kontrollisin: `bash scripts/user_check.sh nosuchuser; echo $?`, `bash scripts/user_check.sh ""; echo $?` ja `getent passwd nosuchuser; echo $?`.
- Parandus: `getent passwd "$username"` ja tühja sisendi kontroll (exit 2).
- Kuidas kontrollisin pärast parandust: root → eksisteerib (0), olematu → ei leitud (1), tühi → viga (2).
- Exit code enne / pärast: enne alati 0. Pärast 0 / 1 / 2.

## Probleem 7
- Skript: scripts/service_check.sh
- Mida skript näiliselt tegi: Teatas, kas teenus töötab.
- Mis oli tegelikult vale: `systemctl list-unit-files` näitab ainult, et unit-fail on olemas, mitte et teenus töötab. Tühja sisendit ei käsitletud.
- Kuidas vea avastasin: Koodist nägin, et kontrollitakse unit-failide nimekirja, mitte teenuse olekut. Leidsin käsuga `systemctl list-units --type=service --all --state=inactive` teenuse `apt-daily`, mis on olemas, aga ei tööta. Käivitasin selle vastu algse skripti.
- Millise käsuga kontrollisin: `systemctl is-active apt-daily` ütles `inactive`, aga algne `bash scripts/service_check.sh apt-daily` ütles "Teenus apt-daily töötab." ja exit code oli 0.
- Parandus: `systemctl is-active --quiet "${service}.service"` ja tühja sisendi kontroll (exit 2).
- Kuidas kontrollisin pärast parandust: `bash scripts/service_check.sh apt-daily` ütleb nüüd "Teenus apt-daily ei tööta." ja exit code on 1. Töötava teenuse (`cron`, `systemctl is-active` = active) korral ütleb skript "töötab" ja exit code on 0.
- Exit code enne / pärast: enne apt-daily puhul 0 (vale), pärast 1.

## Uus funktsionaalsus
- Mida lisasin: `scripts/backup_verify.sh` ja menüüvalik 6 "Varukoopia kontroll". Kontrollib viimast arhiivi: loetavus, failide arv ja taastamine ajutisse kausta koos `diff -r`.
- Kuidas käivitada: `bash main.sh` ja valik 6, või `bash scripts/backup_verify.sh` pärast varukoopiat.
- Kuidas kontrollisin, et tulemus on õige: Terve arhiiv → "OK: varukoopia on taastatav ja sisu ühtib allikaga." (exit 0).
