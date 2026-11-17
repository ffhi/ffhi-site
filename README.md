# ffhi-site
[![FFHI Gluon Build](https://github.com/ffhi/ffhi-site/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/ffhi/ffhi-site/actions/workflows/build.yml)

Gluon Site config for Freifunk Hildesheim


Beschreibung der Domains: (https://wiki.freieslabor.org/wiki/Freifunk:Domains)


WireGuard Branch

Push Test

## Mesh-VPN (WireGuard)

Die Knoten verbinden sich per WireGuard mit dem Gateway `gw01.freifunk-hildesheim.de`. Pro Domain gibt es einen eigenen UDP-Port: **51800 plus Domain-Nummer**
(nordstadt = 51821). Nummern, Ports und Netze pro Domain stehen im Repo `ffhi-gateway` (`domains.json`) und müssen mit `domains/*.conf` übereinstimmen.
Der Public Key des Gateways steht in jeder Domain-Datei unter `mesh_vpn.wireguard.peers`. Ein Router, der in einer anderen Domain als `nordstadt` steht,
sendet an einen anderen Port als der, auf dem das Gateway lauscht.

Einen neuen Knoten schaltest du frei, indem ein Mitglied der Organisation seinen Public Key als Datei per Pull-Request in das private Repo `ffhi-peers` legt.
Der Key steht am Ende der Einrichtung auf der Seite des Routers.

## Firmware bauen und veröffentlichen

- **Bauen:** Der Workflow *FFHI Gluon Build* läuft bei jedem Push auf `main` und lässt sich von Hand starten (Actions, "Run workflow"). Mit dem Feld `target`
  (z. B. `ramips-mt7621`) baut er nur ein Gluon-Target, sonst alle. Gebaut wird auf `ubuntu-24.04` mit dem festen Gluon-Stand aus `build.yml` (`GLUON_REF`).
  Das Datum im Release (`site.mk`, `BUILD_DATE`) legt der Workflow einmal für alle Jobs fest.
- **Veröffentlichen:** Nur ein vollständiger Lauf auf `main` (ohne `target`) lädt die Images hoch. Der Job `push_artifacts` erzeugt das Manifest für den Zweig
  `experimental`, signiert es mit dem CI-Schlüssel und kopiert alles per `rsync` auf den Update-Mirror (`firmware.freifunk-hildesheim.de`, Ordner `experimental`).
  Läufe auf anderen Branches und Läufe mit einzelnem Target liefern nur Artefakte.
- **Zweige:** `experimental` füllt die CI. `testing` und `stable` bekommen nie automatisch etwas. Die Übernahme dorthin ist ein eigener, von Hand signierter
  Schritt (noch nicht automatisiert, Aufgabe 8.4 im OpenSpec-Change `migrate-to-wireguard`). Die Knoten akzeptieren pro Zweig nur Manifeste mit einer
  Signatur der in `site.conf` eingetragenen Schlüssel (`good_signatures = 1`).

### Secrets in GitHub (Settings, Secrets and variables, Actions)

| Secret | Inhalt |
|---|---|
| `FIRMWARE_SSH_KEY` | Privater SSH-Schlüssel des Benutzers `ffhi-firmware` auf dem Mirror. Der Benutzer darf nur per `rsync` in den Mirror-Ordner schreiben (`rrsync`), keine Shell, kein Lesen. |
| `FIRMWARE_SIGN_KEY` | Privater ecdsa-Schlüssel (64 Hex-Zeichen), der das Manifest von `experimental` signiert. Der passende Public Key steht in `site.conf` nur beim Zweig `experimental`. |

Die Schlüssel gehören nicht ins Repo. Der Host-Schlüssel des Mirrors steht öffentlich in `push_artifacts.yml` (`FIRMWARE_HOST_KEY`): Ein anderer Server wird abgelehnt.
Ändert sich der Mirror-Server, muss dieser Wert angepasst werden.

### Was ein Knoten nach dem Update tut

Ein Router im Zweig `experimental` holt `http://firmware.freifunk-hildesheim.de/experimental/sysupgrade/experimental.manifest` (HTTP ohne Weiterleitung, der Mirror
liefert diesen Pfad auch per HTTP aus) und installiert das Image nur, wenn die Signatur zu einem Schlüssel aus `site.conf` passt. Ein Image, das **vor**
dem Eintrag des CI-Schlüssels gebaut wurde, kennt ihn nicht und nimmt das Manifest nicht an. Es braucht einmal ein neues Image von Hand.

