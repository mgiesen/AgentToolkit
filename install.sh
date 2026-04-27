#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Agentic Collection – Installer
# https://github.com/mgiesen/Agentic-Collection
# ──────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"
VENV_DIR="$REPO_DIR/.venv"
RULES_SCRIPT="$REPO_DIR/permissions/install_rules.py"

# Farben
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Agent-Konfiguration
AGENT_NAMES=("Claude Code" "Codex" "Gemini CLI" "OpenCode")
AGENT_PATHS=("$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.gemini/skills" "$HOME/.opencode/skills")

# ──────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║      Agentic Collection Installer    ║${RESET}"
    echo -e "${CYAN}${BOLD}  ║               ${DIM}@mgiesen${RESET}${CYAN}${BOLD}               ║${RESET}"
    echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════╝${RESET}"
    echo ""
}

get_skills() {
    for dir in "$SKILLS_DIR"/*/; do
        if [[ -f "$dir/SKILL.md" ]]; then
            basename "$dir"
        fi
    done
}

# ──────────────────────────────────────────────────────────────
# Setup: Venv + Dependencies
# ──────────────────────────────────────────────────────────────

setup_venv() {
    echo -e "  ${BOLD}Python Venv${RESET}"

    if [[ -f "$VENV_DIR/bin/python3" ]]; then
        echo -e "  ${GREEN}✓${RESET} Venv vorhanden"
    else
        echo -e "  ${YELLOW}→${RESET} Erstelle Venv..."
        python3 -m venv "$VENV_DIR"
        echo -e "  ${GREEN}✓${RESET} Venv erstellt"
    fi

    echo -e "  ${YELLOW}→${RESET} Installiere Python-Dependencies..."
    "$VENV_DIR/bin/pip" install -q -r "$REPO_DIR/requirements.txt"
    echo -e "  ${GREEN}✓${RESET} Dependencies aktuell"
    echo ""
}

check_tools() {
    echo -e "  ${BOLD}CLI Tools${RESET}"
    local missing=0

    local tools=("magick:brew install imagemagick"
                 "cpdf:brew install cpdf"
                 "qpdf:brew install qpdf"
                 "gs:brew install ghostscript"
                 "tesseract:brew install tesseract"
                 "yt-dlp:brew install yt-dlp"
                 "gh:brew install gh"
                 "qrencode:brew install qrencode"
                 "pandoc:brew install pandoc"
                 "crwl:pipx install crawl4ai")

    for entry in "${tools[@]}"; do
        local cmd="${entry%%:*}"
        local hint="${entry#*:}"
        if command -v "$cmd" &>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} $cmd"
        else
            echo -e "  ${RED}✗${RESET} $cmd ${DIM}($hint)${RESET}"
            missing=$((missing + 1))
        fi
    done

    echo ""
    if [[ $missing -gt 0 ]]; then
        echo -e "  ${YELLOW}$missing Tools fehlen (optional, nur fuer betroffene Skills)${RESET}"
        echo ""
    fi
}

# ──────────────────────────────────────────────────────────────
# Skills
# ──────────────────────────────────────────────────────────────

do_install() {
    local agent="$1"
    local target="$2"
    local installed=0 skipped=0

    mkdir -p "$target"

    for skill in $(get_skills); do
        local link="$target/$skill"
        local source="$SKILLS_DIR/$skill"

        if [[ -L "$link" ]]; then
            skipped=$((skipped + 1))
        else
            rm -rf "$link" 2>/dev/null || true
            ln -s "$source" "$link"
            echo -e "  ${GREEN}✓${RESET} $skill"
            installed=$((installed + 1))
        fi
    done

    if [[ $installed -eq 0 ]]; then
        echo -e "  ${DIM}Bereits aktuell ($skipped Skills)${RESET}"
    else
        echo -e "  ${GREEN}$installed installiert${RESET}, $skipped bereits vorhanden"
    fi
}

do_uninstall() {
    local agent="$1"
    local target="$2"
    local removed=0

    for skill in $(get_skills); do
        local link="$target/$skill"
        if [[ -L "$link" ]]; then
            rm "$link"
            echo -e "  ${RED}✗${RESET} $skill"
            removed=$((removed + 1))
        fi
    done

    if [[ $removed -eq 0 ]]; then
        echo -e "  ${DIM}Nichts installiert${RESET}"
    else
        echo -e "  ${RED}$removed entfernt${RESET}"
    fi
}

do_status() {
    local total
    total=$(get_skills | wc -l | tr -d ' ')
    echo -e "  ${BOLD}$total Skills${RESET} im Repo"
    echo ""

    for i in "${!AGENT_NAMES[@]}"; do
        local agent="${AGENT_NAMES[$i]}"
        local target="${AGENT_PATHS[$i]}"
        local installed=0 broken=0

        if [[ -d "$target" ]]; then
            for skill in $(get_skills); do
                local link="$target/$skill"
                if [[ -L "$link" ]]; then
                    if [[ -e "$link" ]]; then
                        installed=$((installed + 1))
                    else
                        broken=$((broken + 1))
                    fi
                fi
            done
        fi

        if [[ $installed -eq $total && $broken -eq 0 && $total -gt 0 ]]; then
            echo -e "  ${GREEN}●${RESET} ${BOLD}$agent${RESET} – $installed/$total Skills"
        elif [[ $installed -gt 0 ]]; then
            local extra=""
            [[ $broken -gt 0 ]] && extra=", ${RED}$broken broken${RESET}"
            echo -e "  ${YELLOW}●${RESET} ${BOLD}$agent${RESET} – $installed/$total Skills$extra"
        else
            echo -e "  ${DIM}○ $agent – nicht installiert${RESET}"
        fi
    done
}

# ──────────────────────────────────────────────────────────────
# Permissions
# ──────────────────────────────────────────────────────────────

install_rules() {
    echo -e "  ${BOLD}Permissions${RESET}"
    "$VENV_DIR/bin/python3" "$RULES_SCRIPT" install "$@"
    echo ""
}

uninstall_rules() {
    echo -e "  ${BOLD}Permissions${RESET}"
    "$VENV_DIR/bin/python3" "$RULES_SCRIPT" uninstall "$@"
    echo ""
}

status_rules() {
    echo ""
    echo -e "  ${BOLD}Permissions${RESET}"
    "$VENV_DIR/bin/python3" "$RULES_SCRIPT" status
}

# ──────────────────────────────────────────────────────────────
# Agent-Auswahl
# ──────────────────────────────────────────────────────────────

select_agents() {
    echo ""
    echo -e "  ${BOLD}Fuer welche Agents?${RESET}"
    echo ""
    for i in "${!AGENT_NAMES[@]}"; do
        echo -e "  ${BOLD}$((i+1))${RESET}) ${AGENT_NAMES[$i]}"
    done
    echo -e "  ${BOLD}A${RESET}) Alle"
    echo ""
    read -rp "  Auswahl (z.B. 1,3 oder A): " selection

    SELECTED=()

    if [[ "${selection}" == "a" || "${selection}" == "A" ]]; then
        for i in "${!AGENT_NAMES[@]}"; do
            SELECTED+=("$i")
        done
    else
        IFS=',' read -ra choices <<< "$selection"
        for choice in "${choices[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#AGENT_NAMES[@]} )); then
                SELECTED+=("$((choice-1))")
            fi
        done
    fi

    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        echo -e "\n  ${RED}Keine gueltige Auswahl${RESET}"
        exit 1
    fi
}

# ──────────────────────────────────────────────────────────────
# Hauptmenue
# ──────────────────────────────────────────────────────────────

main() {
    banner

    echo -e "  ${BOLD}1${RESET}) Skills installieren"
    echo -e "  ${BOLD}2${RESET}) Skills deinstallieren"
    echo -e "  ${BOLD}3${RESET}) Permissions hinzufuegen"
    echo -e "  ${BOLD}4${RESET}) Permissions entfernen"
    echo -e "  ${BOLD}5${RESET}) Status anzeigen"
    echo -e "  ${BOLD}6${RESET}) Dependencies pruefen"
    echo -e "  ${BOLD}q${RESET}) Beenden"
    echo ""
    read -rp "  Auswahl: " action

    case "$action" in
        1)
            select_agents
            echo ""
            setup_venv
            local rule_agents=()
            for i in "${SELECTED[@]}"; do
                echo -e "  ${CYAN}${BOLD}${AGENT_NAMES[$i]}${RESET} → ${DIM}${AGENT_PATHS[$i]}${RESET}"
                do_install "${AGENT_NAMES[$i]}" "${AGENT_PATHS[$i]}"
                rule_agents+=("${AGENT_NAMES[$i]}")
                echo ""
            done
            install_rules "${rule_agents[@]}"
            ;;
        2)
            select_agents
            echo ""
            local rule_agents=()
            for i in "${SELECTED[@]}"; do
                echo -e "  ${CYAN}${BOLD}${AGENT_NAMES[$i]}${RESET}"
                do_uninstall "${AGENT_NAMES[$i]}" "${AGENT_PATHS[$i]}"
                rule_agents+=("${AGENT_NAMES[$i]}")
                echo ""
            done
            uninstall_rules "${rule_agents[@]}"
            ;;
        3)
            select_agents
            echo ""
            setup_venv
            local rule_agents=()
            for i in "${SELECTED[@]}"; do
                rule_agents+=("${AGENT_NAMES[$i]}")
            done
            install_rules "${rule_agents[@]}"
            ;;
        4)
            select_agents
            echo ""
            local rule_agents=()
            for i in "${SELECTED[@]}"; do
                rule_agents+=("${AGENT_NAMES[$i]}")
            done
            uninstall_rules "${rule_agents[@]}"
            ;;
        5)
            echo ""
            do_status
            status_rules
            echo ""
            ;;
        6)
            echo ""
            setup_venv
            check_tools
            ;;
        q|Q)
            exit 0
            ;;
        *)
            echo -e "\n  ${RED}Ungueltige Auswahl${RESET}"
            exit 1
            ;;
    esac
}

# CLI-Modus
case "${1:-}" in
    --all)
        banner
        setup_venv
        for i in "${!AGENT_NAMES[@]}"; do
            echo -e "  ${CYAN}${BOLD}${AGENT_NAMES[$i]}${RESET} → ${DIM}${AGENT_PATHS[$i]}${RESET}"
            do_install "${AGENT_NAMES[$i]}" "${AGENT_PATHS[$i]}"
            echo ""
        done
        install_rules "${AGENT_NAMES[@]}"
        exit 0
        ;;
    --status)
        banner
        do_status
        status_rules
        echo ""
        exit 0
        ;;
    --uninstall)
        banner
        for i in "${!AGENT_NAMES[@]}"; do
            echo -e "  ${CYAN}${BOLD}${AGENT_NAMES[$i]}${RESET}"
            do_uninstall "${AGENT_NAMES[$i]}" "${AGENT_PATHS[$i]}"
            echo ""
        done
        uninstall_rules "${AGENT_NAMES[@]}"
        exit 0
        ;;
    --check)
        banner
        setup_venv
        check_tools
        exit 0
        ;;
esac

main
