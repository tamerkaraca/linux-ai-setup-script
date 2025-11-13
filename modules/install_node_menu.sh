#!/bin/bash
set -euo pipefail

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${REMOTE_MODULE_DIR:=}"

if ! declare -f run_module >/dev/null 2>&1; then
    run_module() {
        local module_name="$1"
        local module_url="${BASE_URL}/${module_name}.sh"
        shift
        if [ -f "./modules/${module_name}.sh" ]; then
            PKG_MANAGER="${PKG_MANAGER:-}" UPDATE_CMD="${UPDATE_CMD:-}" INSTALL_CMD="${INSTALL_CMD:-}" bash "./modules/${module_name}.sh" "$@"
        else
            curl -fsSL "$module_url" | PKG_MANAGER="${PKG_MANAGER:-}" UPDATE_CMD="${UPDATE_CMD:-}" INSTALL_CMD="${INSTALL_CMD:-}" bash -s -- "$@"
        fi
    }
fi

show_node_menu() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║%*s║${NC}\n" -43 " $(translate node_menu_title) "
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "$(translate node_menu_subtitle)\n"
    echo -e "  ${GREEN}1${NC} - $(translate node_option1)"
    echo -e "  ${GREEN}2${NC} - $(translate node_option2)"
    echo -e "  ${GREEN}3${NC} - $(translate node_option3)"
    echo -e "  ${GREEN}4${NC} - $(translate node_option4)"
    echo -e "  ${RED}0${NC} - $(translate node_option0)"
    echo -e "\n${YELLOW}$(translate menu_multi_hint)${NC}\n"
}

run_node_choice() {
    local option="$1"
    case "$option" in
        1)
            run_module "install_nodejs_tools" "--node-only"
            ;;
        2)
            run_module "install_nodejs_tools" "--bun-only"
            ;;
        3)
            run_module "install_nodejs_tools" "--extras-only"
            ;;
        4)
            run_module "install_nodejs_tools"
            ;;
        *)
            echo -e "${YELLOW}$(translate warning_invalid_choice): $option${NC}"
            ;;
    esac
}

main() {
    local auto_run="${1:-}"
    if [ "$auto_run" = "all" ]; then
        run_node_choice 4
        return
    fi

    while true; do
        show_node_menu
        read -r -p "${YELLOW}$(translate prompt_choice):${NC} " selection </dev/tty
        if [ -z "$(echo "$selection" | tr -d '[:space:]')" ]; then
            echo -e "${YELLOW}$(translate warning_no_selection)${NC}"
            sleep 1
            continue
        fi

        if [ "$selection" = "0" ]; then
            echo -e "${GREEN}$(translate info_returning)${NC}"
            break
        fi

        local batch_context=false
        IFS=',' read -ra choices <<< "$selection"
        [ "${#choices[@]}" -gt 1 ] && batch_context=true

        for raw in "${choices[@]}"; do
            local choice="$(echo "$raw" | tr -d '[:space:]')"
            [ -z "$choice" ] && continue
            if [ "$choice" = "0" ]; then
                batch_context=false
                break
            fi
            run_node_choice "$choice"
        done

        if [ "$batch_context" = false ]; then
            read -r -p "${YELLOW}$(translate prompt_press_enter)${NC}" _tmp </dev/tty || true
        fi
    done
}

main "$@"
