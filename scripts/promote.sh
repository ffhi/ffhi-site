#!/usr/bin/env bash
# Übernimmt den Stand von `experimental` nach `testing` oder `stable` auf dem Update-Mirror.
#
# Läuft von Hand auf dem Rechner einer Person mit Signaturschlüssel (ffhi1 oder Basti) und Admin-Zugang zu `ffhi`.
# Der CI-Schlüssel darf das nicht: er ist nur in `site.conf` für `experimental` eingetragen, und ein Push startet diesen
# Schritt nie.
#
#   scripts/promote.sh [-n] [-y] <testing|stable> <schlüsseldatei>
#
# Ablauf: Manifest von experimental holen, BRANCH-Zeile ersetzen, alte Signaturen verwerfen, neu signieren (ecdsasign).
# Auf dem Mirror die Images per rsync von experimental/ in den Zielzweig kopieren, das Manifest zuletzt (atomar) ablegen,
# damit kein Knoten ein Manifest ohne die zugehörigen Images sieht.
#
# Umgebung: MIRROR_SSH (Standard: ffhi), MIRROR_DIR (Standard: /opt/ffhi-services/caddy/site/firmware),
#           MIRROR_URL (Standard: https://firmware.freifunk-hildesheim.de)
set -euo pipefail

DRY=0; YES=0
while getopts "ny" o; do case $o in n) DRY=1 ;; y) YES=1 ;; *) exit 2 ;; esac; done
shift $((OPTIND - 1))
TARGET="${1:-}"; KEY="${2:-}"
SRC=experimental
MIRROR_SSH="${MIRROR_SSH:-ffhi}"
MIRROR_DIR="${MIRROR_DIR:-/opt/ffhi-services/caddy/site/firmware}"
MIRROR_URL="${MIRROR_URL:-https://firmware.freifunk-hildesheim.de}"

case "$TARGET" in testing|stable) ;; *) echo "Aufruf: $0 [-n] [-y] <testing|stable> <schlüsseldatei>" >&2; exit 2 ;; esac
[ -r "$KEY" ] || { echo "Schlüsseldatei nicht lesbar: ${KEY:-<leer>}" >&2; exit 2; }
command -v ecdsasign >/dev/null || { echo "ecdsasign fehlt (Paket ecdsautils)" >&2; exit 2; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

curl -fsS "$MIRROR_URL/$SRC/sysupgrade/$SRC.manifest" -o "$work/src.manifest"
grep -q '^BRANCH=experimental$' "$work/src.manifest" || { echo "Manifest von $SRC hat keine BRANCH-Zeile experimental" >&2; exit 1; }
grep -q '^---$' "$work/src.manifest" || { echo "Manifest von $SRC enthält keine Signaturtrennung" >&2; exit 1; }

# Inhalt bis vor `---`, Zweig ersetzen
sed '/^---$/,$d' "$work/src.manifest" | sed "s/^BRANCH=experimental$/BRANCH=$TARGET/" > "$work/body"
n=$(grep -cE '^[^=]+ [^ ]+ [0-9a-f]{64} ' "$work/body" || true)
[ "$n" -gt 0 ] || { echo "Manifest enthält keine Images" >&2; exit 1; }

{ cat "$work/body"; echo '---'; ecdsasign "$work/body" < "$KEY"; } > "$work/$TARGET.manifest"
sig=$(sed -n '/^---$/,$p' "$work/$TARGET.manifest" | grep -cE '^[0-9a-f]{128}$' || true)
[ "$sig" -eq 1 ] || { echo "Signatur fehlt oder ist ungültig" >&2; exit 1; }

echo "Manifest: $n Images, Zweig $TARGET, DATE=$(sed -n 's/^DATE=//p' "$work/body"), signiert"
if [ "$DRY" = 1 ]; then echo "Trockenlauf: nichts auf den Mirror geschrieben"; exit 0; fi
if [ "$YES" != 1 ]; then
  read -r -p "$SRC -> $TARGET auf $MIRROR_SSH übernehmen? Der Zweig $TARGET wird ersetzt. [ja/N] " a
  [ "$a" = ja ] || { echo abgebrochen; exit 1; }
fi

scp -q "$work/$TARGET.manifest" "$MIRROR_SSH:$MIRROR_DIR/$TARGET/sysupgrade/.$TARGET.manifest.new"
ssh "$MIRROR_SSH" "set -e; cd '$MIRROR_DIR'
  rsync -a --delete-after --exclude='*.manifest' --exclude='.*.manifest.new' '$SRC/' '$TARGET/'
  chown -R --reference='$SRC' '$TARGET' 2>/dev/null || true
  mv '$TARGET/sysupgrade/.$TARGET.manifest.new' '$TARGET/sysupgrade/$TARGET.manifest'"
curl -fsS "$MIRROR_URL/$TARGET/sysupgrade/$TARGET.manifest" | cmp -s - "$work/$TARGET.manifest" \
  && echo "OK: $MIRROR_URL/$TARGET/sysupgrade/$TARGET.manifest ist veröffentlicht" \
  || { echo "Prüfung fehlgeschlagen: Mirror liefert ein anderes Manifest" >&2; exit 1; }
