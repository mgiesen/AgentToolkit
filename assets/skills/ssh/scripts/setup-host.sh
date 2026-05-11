#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# AgentToolkit – SSH Host Setup
# Interaktives Setup für neue SSH-Verbindungen.
# Wird in einem eigenen Terminal-Fenster gestartet.
# ──────────────────────────────────────────────────────────────

RESULT_FILE="/tmp/agenttoolkit-ssh-setup.json"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
KEY_FILE="$SSH_DIR/id_ed25519"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────

ALIAS="" HOST="" USER_NAME="" DESC=""

write_result() {
    local status="$1"
    cat > "$RESULT_FILE" <<-JSON
{"alias":"$ALIAS","host":"$HOST","user":"$USER_NAME","description":"$DESC","os":"${OS_INFO:-}","status":"$status"}
JSON
}

fail() {
    echo ""
    echo -e "  ${RED}✗ $1${RESET}"
    write_result "failed"
    echo ""
    read -rp "  Enter zum Schließen... "
    exit 1
}

# ── Init ──────────────────────────────────────────────────────

rm -f "$RESULT_FILE"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

clear

# ── Einleitung ────────────────────────────────────────────────

echo ""
echo -e "  ${CYAN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "  ${CYAN}${BOLD}║         SSH-Verbindung einrichten                ║${RESET}"
echo -e "  ${CYAN}${BOLD}║                 ${DIM}AgentToolkit${RESET}${CYAN}${BOLD}                         ║${RESET}"
echo -e "  ${CYAN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Was ist SSH?${RESET}"
echo ""
echo -e "  SSH (Secure Shell) verbindet deinen Computer sicher"
echo -e "  mit einem entfernten System — z.B. einem Server,"
echo -e "  Raspberry Pi oder Proxmox-Container."
echo ""
echo -e "  ${BOLD}Was ist ein SSH-Schlüssel?${RESET}"
echo ""
echo -e "  Statt jedes Mal ein Passwort einzugeben, erstellen"
echo -e "  wir einen digitalen Schlüssel. Er besteht aus zwei Teilen:"
echo ""
echo -e "  ${CYAN}🔑 Privater Schlüssel${RESET}  →  bleibt auf deinem Computer"
echo -e "  ${CYAN}🔓 Öffentlicher Schlüssel${RESET}  →  wird auf dem Zielsystem abgelegt"
echo ""
echo -e "  Danach erkennt dich das Zielsystem automatisch."
echo ""
echo -e "  ${BOLD}Was ist die SSH-Config?${RESET}"
echo ""
echo -e "  Eine Datei auf deinem Computer (${DIM}~/.ssh/config${RESET}),"
echo -e "  in der Verbindungen gespeichert werden — Name, Adresse"
echo -e "  und Benutzername. So reicht danach ein kurzer Befehl"
echo -e "  wie ${BOLD}ssh proxmox${RESET} statt der vollen IP-Adresse."
echo ""
echo -e "  ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}"
echo -e "  ${BOLD}⚡ Alles, was jetzt passiert, läuft direkt zwischen${RESET}"
echo -e "  ${BOLD}   deinem Computer und dem Zielsystem.${RESET}"
echo -e "  ${BOLD}   Keine Daten werden an eine KI übermittelt.${RESET}"
echo -e "  ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}"
echo ""

# ── Eingabe ───────────────────────────────────────────────────

echo -e "  ${BOLD}Verbindungsdaten eingeben${RESET}"
echo ""
read -rp "  Name für die Verbindung (z.B. proxmox): " ALIAS
read -rp "  Kurze Beschreibung (z.B. Proxmox VE Hauptserver): " DESC
read -rp "  IP-Adresse oder Hostname (z.B. 192.168.1.50): " HOST
read -rp "  Benutzername (z.B. root): " USER_NAME
echo ""

if [[ -z "$ALIAS" || -z "$HOST" || -z "$USER_NAME" ]]; then
    fail "Name, Host und Benutzername sind erforderlich"
fi

# ── Bestehenden Eintrag prüfen ────────────────────────────────

if [[ -f "$SSH_CONFIG" ]] && grep -q "^Host ${ALIAS}$" "$SSH_CONFIG" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ Verbindung '${ALIAS}' existiert bereits${RESET}"
    read -rp "  Überschreiben? (j/n): " OVERWRITE
    echo ""
    if [[ "$OVERWRITE" != "j" && "$OVERWRITE" != "J" ]]; then
        echo -e "  ${DIM}Abgebrochen${RESET}"
        rm -f "$RESULT_FILE"
        echo ""
        read -rp "  Enter zum Schließen... "
        exit 0
    fi
fi

# ── SSH-Schlüssel ─────────────────────────────────────────────

echo -e "  ${BOLD}Schritt 1: SSH-Schlüssel${RESET}"
echo ""

if [[ -f "$KEY_FILE" ]]; then
    echo -e "  ${GREEN}✓${RESET} Schlüssel vorhanden (${DIM}${KEY_FILE}${RESET})"
else
    echo -e "  ${YELLOW}→${RESET} Erstelle neuen Schlüssel..."
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -q
    echo -e "  ${GREEN}✓${RESET} Schlüssel erstellt"
fi
echo ""

# ── Erreichbarkeit prüfen ────────────────────────────────────

echo -e "  ${BOLD}Schritt 2: Erreichbarkeit prüfen${RESET}"
echo ""

if ! nc -z -w 5 "$HOST" 22 2>/dev/null; then
    fail "Host ${HOST} ist nicht erreichbar (Port 22 geschlossen oder Netzwerkfehler)"
fi
echo -e "  ${GREEN}✓${RESET} ${HOST}:22 erreichbar"
echo ""

# ── Schlüssel übertragen ──────────────────────────────────────

echo -e "  ${BOLD}Schritt 3: Schlüssel übertragen${RESET}"
echo ""
echo -e "  Der öffentliche Schlüssel wird jetzt auf das Zielsystem"
echo -e "  kopiert. ${BOLD}Gib dein Passwort für ${USER_NAME}@${HOST} ein.${RESET}"
echo -e "  ${DIM}Das ist das letzte Mal — danach ist kein Passwort mehr nötig.${RESET}"
echo ""

if ! ssh-copy-id -i "${KEY_FILE}.pub" -o StrictHostKeyChecking=accept-new "${USER_NAME}@${HOST}"; then
    fail "Schlüssel konnte nicht übertragen werden — prüfe Passwort und Benutzername"
fi
echo ""

# ── Verbindung testen ─────────────────────────────────────────

echo -e "  ${BOLD}Schritt 4: Verbindung testen${RESET}"
echo ""

OS_INFO=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "${USER_NAME}@${HOST}" "uname -sr" 2>/dev/null || echo "unbekannt")

if [[ "$OS_INFO" == "unbekannt" ]]; then
    fail "Schlüssel wurde kopiert, aber die passwortlose Verbindung funktioniert nicht"
fi

echo -e "  ${GREEN}✓${RESET} Verbindung erfolgreich — ${BOLD}${OS_INFO}${RESET}"
echo ""

# ── SSH-Config schreiben ──────────────────────────────────────

echo -e "  ${BOLD}Schritt 5: SSH-Config aktualisieren${RESET}"
echo ""

touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

# Bestehenden Eintrag entfernen (falls Überschreiben gewählt)
if grep -q "^Host ${ALIAS}$" "$SSH_CONFIG" 2>/dev/null; then
    python3 -c "
import re
text = open('$SSH_CONFIG').read()
text = re.sub(r'\n*(#[^\n]*\n)?Host ${ALIAS}\n(?:[ \t]+[^\n]*\n)*', '\n', text)
open('$SSH_CONFIG', 'w').write(text.strip() + '\n' if text.strip() else '')
"
fi

# Neuen Eintrag anhängen
{
    echo ""
    echo "# ${DESC}"
    echo "Host ${ALIAS}"
    echo "    HostName ${HOST}"
    echo "    User ${USER_NAME}"
    echo "    IdentityFile ${KEY_FILE}"
} >> "$SSH_CONFIG"

echo -e "  ${GREEN}✓${RESET} Verbindung '${ALIAS}' gespeichert"
echo ""

# ── Ergebnis ──────────────────────────────────────────────────

write_result "success"

echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "  ${GREEN}${BOLD}║  Einrichtung abgeschlossen                      ║${RESET}"
echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Verbindung ${BOLD}${ALIAS}${RESET} ist bereit."
echo -e "  Du kannst dieses Terminal jetzt schließen"
echo -e "  und zum Agenten zurückkehren."
echo ""
read -rp "  Enter zum Schließen... "
