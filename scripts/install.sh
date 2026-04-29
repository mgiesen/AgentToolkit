#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# AgentBox – Installer
# https://github.com/mgiesen/AgentBox
# ──────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_DIR/assets/skills"
AGENTS_DIR="$REPO_DIR/assets/agents"
VENV_DIR="$REPO_DIR/.venv"
RULES_SCRIPT="$REPO_DIR/assets/permissions/install_rules.py"

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
AGENT_SKILL_PATHS=("$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.gemini/skills" "$HOME/.opencode/skills")
AGENT_AGENT_PATHS=("$HOME/.claude/agents" "$HOME/.codex/agents" "$HOME/.gemini/agents" "$HOME/.opencode/agents")

# Instructions-Konfiguration (Agent → Zieldatei)
INSTRUCTIONS_SOURCE="$REPO_DIR/assets/instructions/AGENTS.md"
INSTRUCTIONS_TARGETS=(
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.codex/AGENTS.md"
    "$HOME/.gemini/GEMINI.md"
    "$HOME/.config/opencode/AGENTS.md"
)

# Asset-Typen
ASSET_NAMES=("Skills" "Agents" "Instructions" "Permissions")

# ──────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║          AgentBox Installer          ║${RESET}"
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

get_agents() {
    for file in "$AGENTS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            basename "$file"
        fi
    done
}

all_indices() {
    for i in "${!AGENT_NAMES[@]}"; do echo "$i"; done
}

# ──────────────────────────────────────────────────────────────
# Auswahl
# ──────────────────────────────────────────────────────────────

# Einzelauswahl: gibt den gewaehlten String zurueck
choose_one() {
    local prompt="$1"
    shift
    local options=("$@")

    echo "" >&2
    echo -e "  ${BOLD}$prompt${RESET}" >&2
    echo "" >&2
    for i in "${!options[@]}"; do
        echo -e "  ${BOLD}$((i+1))${RESET}) ${options[$i]}" >&2
    done
    echo "" >&2
    read -rp "  Auswahl: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
        echo "${options[$((choice-1))]}"
    fi
}

# Mehrfachauswahl: gibt gewaehlte Strings zurueck (eine pro Zeile)
choose_multi() {
    local prompt="$1"
    shift
    local options=("$@")

    echo "" >&2
    echo -e "  ${BOLD}$prompt${RESET}" >&2
    echo "" >&2
    for i in "${!options[@]}"; do
        echo -e "  ${BOLD}$((i+1))${RESET}) ${options[$i]}" >&2
    done
    echo -e "  ${BOLD}A${RESET}) Alle" >&2
    echo "" >&2
    read -rp "  Auswahl (z.B. 1,3 oder A): " selection

    if [[ "${selection}" == "a" || "${selection}" == "A" ]]; then
        printf '%s\n' "${options[@]}"
    else
        IFS=',' read -ra choices <<< "$selection"
        for choice in "${choices[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
                echo "${options[$((choice-1))]}"
            fi
        done
    fi
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

setup_brew() {
    echo -e "  ${BOLD}Homebrew Tools${RESET}"

    if ! command -v brew &>/dev/null; then
        echo -e "  ${RED}✗${RESET} Homebrew nicht installiert ${DIM}(https://brew.sh)${RESET}"
        echo ""
        return 1
    fi

    echo -e "  ${YELLOW}→${RESET} Installiere fehlende Brew-Pakete..."
    brew bundle --file="$REPO_DIR/Brewfile" --quiet
    echo -e "  ${GREEN}✓${RESET} Brew-Pakete aktuell"
    echo ""
}

# ──────────────────────────────────────────────────────────────
# Skills
# ──────────────────────────────────────────────────────────────

install_skills() {
    local target="$1"
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
            echo -e "    ${GREEN}✓${RESET} $skill"
            installed=$((installed + 1))
        fi
    done

    if [[ $installed -eq 0 ]]; then
        echo -e "    ${DIM}Bereits aktuell ($skipped Skills)${RESET}"
    else
        echo -e "    ${GREEN}$installed installiert${RESET}, $skipped bereits vorhanden"
    fi
}

uninstall_skills() {
    local target="$1"
    local removed=0

    for skill in $(get_skills); do
        local link="$target/$skill"
        if [[ -L "$link" ]]; then
            rm "$link"
            removed=$((removed + 1))
        fi
    done

    if [[ $removed -eq 0 ]]; then
        echo -e "    ${DIM}Keine Skills installiert${RESET}"
    else
        echo -e "    ${GREEN}$removed entfernt${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# Agents
# ──────────────────────────────────────────────────────────────

install_agents() {
    local target="$1"
    local installed=0 skipped=0

    local agent_files
    agent_files=$(get_agents)
    if [[ -z "$agent_files" ]]; then
        echo -e "    ${DIM}Keine Agents im Repo${RESET}"
        return
    fi

    mkdir -p "$target"

    for file in $agent_files; do
        local link="$target/$file"
        local source="$AGENTS_DIR/$file"

        if [[ -L "$link" ]]; then
            skipped=$((skipped + 1))
        else
            rm -rf "$link" 2>/dev/null || true
            ln -s "$source" "$link"
            echo -e "    ${GREEN}✓${RESET} $file"
            installed=$((installed + 1))
        fi
    done

    if [[ $installed -eq 0 ]]; then
        echo -e "    ${DIM}Bereits aktuell ($skipped Agents)${RESET}"
    else
        echo -e "    ${GREEN}$installed installiert${RESET}, $skipped bereits vorhanden"
    fi
}

uninstall_agents() {
    local target="$1"
    local removed=0

    for file in $(get_agents); do
        local link="$target/$file"
        if [[ -L "$link" ]]; then
            rm "$link"
            removed=$((removed + 1))
        fi
    done

    if [[ $removed -eq 0 ]]; then
        echo -e "    ${DIM}Keine Agents installiert${RESET}"
    else
        echo -e "    ${GREEN}$removed entfernt${RESET}"
    fi
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

# ──────────────────────────────────────────────────────────────
# Instructions
# ──────────────────────────────────────────────────────────────

install_instructions() {
    echo -e "  ${BOLD}Instructions${RESET}"
    local installed=0 skipped=0

    for idx in "$@"; do
        local target="${INSTRUCTIONS_TARGETS[$idx]}"
        local agent="${AGENT_NAMES[$idx]}"
        local target_dir
        target_dir="$(dirname "$target")"

        mkdir -p "$target_dir"

        if [[ -L "$target" && "$(readlink "$target")" == "$INSTRUCTIONS_SOURCE" ]]; then
            skipped=$((skipped + 1))
        else
            if [[ -e "$target" && ! -L "$target" ]]; then
                echo -e "  ${YELLOW}⚠${RESET} $agent: ${DIM}$target existiert bereits (uebersprungen)${RESET}"
                skipped=$((skipped + 1))
                continue
            fi
            rm -f "$target" 2>/dev/null || true
            ln -s "$INSTRUCTIONS_SOURCE" "$target"
            echo -e "  ${GREEN}✓${RESET} $agent"
            installed=$((installed + 1))
        fi
    done

    if [[ $installed -eq 0 ]]; then
        echo -e "  ${DIM}Bereits aktuell ($skipped Agents)${RESET}"
    else
        echo -e "  ${GREEN}$installed installiert${RESET}, $skipped bereits vorhanden"
    fi
    echo ""
}

uninstall_instructions() {
    echo -e "  ${BOLD}Instructions${RESET}"
    local removed=0

    for idx in "$@"; do
        local target="${INSTRUCTIONS_TARGETS[$idx]}"
        local agent="${AGENT_NAMES[$idx]}"

        if [[ -L "$target" && "$(readlink "$target")" == "$INSTRUCTIONS_SOURCE" ]]; then
            rm "$target"
            echo -e "  ${GREEN}✓${RESET} $agent"
            removed=$((removed + 1))
        fi
    done

    if [[ $removed -eq 0 ]]; then
        echo -e "  ${DIM}Nichts installiert${RESET}"
    fi
    echo ""
}

# ──────────────────────────────────────────────────────────────
# Status
# ──────────────────────────────────────────────────────────────

show_status() {
    local skill_total agent_total
    skill_total=$(get_skills | wc -l | tr -d ' ')
    agent_total=$(get_agents | wc -l | tr -d ' ')

    echo -e "  ${BOLD}Repo${RESET}: $skill_total Skills, $agent_total Agents"
    echo ""

    for i in "${!AGENT_NAMES[@]}"; do
        local name="${AGENT_NAMES[$i]}"
        local skill_path="${AGENT_SKILL_PATHS[$i]}"
        local agent_path="${AGENT_AGENT_PATHS[$i]}"
        local instr_target="${INSTRUCTIONS_TARGETS[$i]}"

        local skills_ok=0 skills_broken=0
        if [[ -d "$skill_path" ]]; then
            for skill in $(get_skills); do
                local link="$skill_path/$skill"
                if [[ -L "$link" ]]; then
                    if [[ -e "$link" ]]; then
                        skills_ok=$((skills_ok + 1))
                    else
                        skills_broken=$((skills_broken + 1))
                    fi
                fi
            done
        fi

        local agents_ok=0
        if [[ -d "$agent_path" ]]; then
            for file in $(get_agents); do
                local link="$agent_path/$file"
                if [[ -L "$link" && -e "$link" ]]; then
                    agents_ok=$((agents_ok + 1))
                fi
            done
        fi

        local instr="✗"
        if [[ -L "$instr_target" && "$(readlink "$instr_target")" == "$INSTRUCTIONS_SOURCE" ]]; then
            instr="${GREEN}✓${RESET}"
        elif [[ -e "$instr_target" ]]; then
            instr="${YELLOW}eigene${RESET}"
        fi

        local installed=$((skills_ok + agents_ok))
        local total=$((skill_total + agent_total))

        if [[ $installed -eq $total && $total -gt 0 ]]; then
            echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET}"
        elif [[ $installed -gt 0 ]]; then
            echo -e "  ${YELLOW}●${RESET} ${BOLD}$name${RESET}"
        else
            echo -e "  ${DIM}○ ${BOLD}$name${RESET}"
        fi

        local broken_hint=""
        [[ $skills_broken -gt 0 ]] && broken_hint=" ${RED}($skills_broken broken)${RESET}"
        echo -e "    Skills: $skills_ok/$skill_total$broken_hint  Agents: $agents_ok/$agent_total  Instructions: $instr"
    done

    echo ""
    echo -e "  ${BOLD}Permissions${RESET}"
    "$VENV_DIR/bin/python3" "$RULES_SCRIPT" status
}

# ──────────────────────────────────────────────────────────────
# Installieren / Deinstallieren
# ──────────────────────────────────────────────────────────────

parse_args() {
    PARSED_INDICES=()
    PARSED_ASSETS=()

    local parsing_indices=true
    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            parsing_indices=false
            continue
        fi
        if $parsing_indices; then
            PARSED_INDICES+=("$arg")
        else
            PARSED_ASSETS+=("$arg")
        fi
    done

    # Default: alle Assets
    if [[ ${#PARSED_ASSETS[@]} -eq 0 ]]; then
        PARSED_ASSETS=("Skills" "Agents" "Instructions" "Permissions")
    fi
}

has_asset() {
    local needle="$1"
    for a in "${PARSED_ASSETS[@]}"; do
        [[ "$a" == "$needle" ]] && return 0
    done
    return 1
}

do_install() {
    parse_args "$@"

    if has_asset "Skills" || has_asset "Permissions"; then
        setup_venv
    fi
    if has_asset "Skills"; then
        setup_brew
    fi

    for i in "${PARSED_INDICES[@]}"; do
        echo -e "  ${CYAN}${BOLD}${AGENT_NAMES[$i]}${RESET}"
        if has_asset "Skills"; then
            echo -e "  ${DIM}Skills${RESET}"
            install_skills "${AGENT_SKILL_PATHS[$i]}"
        fi
        if has_asset "Agents"; then
            echo -e "  ${DIM}Agents${RESET}"
            install_agents "${AGENT_AGENT_PATHS[$i]}"
        fi
        echo ""
    done

    local rule_agents=()
    for i in "${PARSED_INDICES[@]}"; do rule_agents+=("${AGENT_NAMES[$i]}"); done

    if has_asset "Permissions"; then
        install_rules "${rule_agents[@]}"
    fi
    if has_asset "Instructions"; then
        install_instructions "${PARSED_INDICES[@]}"
    fi
}

do_uninstall() {
    parse_args "$@"

    if has_asset "Permissions"; then
        setup_venv
    fi

    for i in "${PARSED_INDICES[@]}"; do
        echo -e "  ${CYAN}${BOLD}${AGENT_NAMES[$i]}${RESET}"
        if has_asset "Skills"; then
            echo -e "  ${DIM}Skills${RESET}"
            uninstall_skills "${AGENT_SKILL_PATHS[$i]}"
        fi
        if has_asset "Agents"; then
            echo -e "  ${DIM}Agents${RESET}"
            uninstall_agents "${AGENT_AGENT_PATHS[$i]}"
        fi
        echo ""
    done

    local rule_agents=()
    for i in "${PARSED_INDICES[@]}"; do rule_agents+=("${AGENT_NAMES[$i]}"); done

    if has_asset "Permissions"; then
        uninstall_rules "${rule_agents[@]}"
    fi
    if has_asset "Instructions"; then
        uninstall_instructions "${PARSED_INDICES[@]}"
    fi
}

# ──────────────────────────────────────────────────────────────
# Interaktive Auswahl
# ──────────────────────────────────────────────────────────────

select_agents() {
    local selected
    selected=$(choose_multi "Agents auswaehlen" "${AGENT_NAMES[@]}")

    SELECTED=()
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        for i in "${!AGENT_NAMES[@]}"; do
            if [[ "${AGENT_NAMES[$i]}" == "$name" ]]; then
                SELECTED+=("$i")
                break
            fi
        done
    done <<< "$selected"

    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        echo -e "\n  ${RED}Keine gueltige Auswahl${RESET}"
        exit 1
    fi
}

select_assets() {
    local selected
    selected=$(choose_multi "Assets auswaehlen" "${ASSET_NAMES[@]}")

    SELECTED_ASSETS=()
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        SELECTED_ASSETS+=("$name")
    done <<< "$selected"

    if [[ ${#SELECTED_ASSETS[@]} -eq 0 ]]; then
        echo -e "\n  ${RED}Keine gueltige Auswahl${RESET}"
        exit 1
    fi
}

# ──────────────────────────────────────────────────────────────
# Hauptmenue
# ──────────────────────────────────────────────────────────────

main() {
    banner

    local action
    action=$(choose_one "Aktion" "Installieren" "Deinstallieren" "Status" "Dependencies" "Beenden")

    case "$action" in
        Installieren)
            select_assets
            select_agents
            echo ""
            do_install "${SELECTED[@]}" -- "${SELECTED_ASSETS[@]}"
            ;;
        Deinstallieren)
            select_assets
            select_agents
            echo ""
            do_uninstall "${SELECTED[@]}" -- "${SELECTED_ASSETS[@]}"
            ;;
        Status)
            echo ""
            show_status
            echo ""
            ;;
        Dependencies)
            echo ""
            setup_venv
            setup_brew
            ;;
        Beenden)
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
        do_install $(all_indices)
        exit 0
        ;;
    --status)
        banner
        show_status
        echo ""
        exit 0
        ;;
    --uninstall)
        banner
        do_uninstall $(all_indices)
        exit 0
        ;;
    --check)
        banner
        setup_venv
        setup_brew
        exit 0
        ;;
esac

main
