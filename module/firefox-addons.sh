#!/usr/bin/env bash

if [ -z "$RED" ]; then
    RED='\e[31m'
    GREEN='\e[32m'
    YELLOW='\e[33m'
    BLUE='\e[34m'
    CYAN='\e[36m'
    MAGENTA='\e[35m'
    RESET='\e[0m'
fi

FIREFOX_ADDON_NAMES=(
    "rep+ -burp-firefox-inspect"
    "Endpoint Hunter"
    "Enhanced Network Tab"
    "dark-reader"
    "wappalyzer"
    "FoxyProxy Standard"
    "HackTools"
    "Cookie-Editor"
    "Link Gopher"
    "TWP - Translate Web Pages"
    "retire.js"
    "FoxyRecon-soc"
)

# Corresponding Add-on ID
FIREFOX_ADDON_IDS=(
    "rep-plus@extension"
    "@endpoint-hunter.carlesreig"
    "{b457d19f-fbad-4782-9cc0-6b62bd27beb4}"
    "addon@darkreader.org"
    "wappalyzer@crunchlabz.com"
    "foxyproxy@eric.h.jung"
    "{f1423c11-a4e2-4709-a0f8-6d6a68c83d08}"
    "{c3c10168-4186-445c-9c5b-63f12b8e2c87}"
    "linkgopher@oooninja.com"
    "{036a55b4-5e72-4d05-a06c-cba2dfcc134a}"
    "@retire.js"
    "{b9aafb59-62cc-4c97-a9b1-260d51e70730}"
)

FIREFOX_ADDON_URLS=(
    "https://addons.mozilla.org/firefox/downloads/file/4660587/rep-1.3.1.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4655849/endpoint_hunter-0.3.0.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4841354/enhanced_network_tab-1.9.0.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/darkreader/addon-424282-latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4854417/wappalyzer-6.12.3.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4472757/foxyproxy_standard-9.2.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/3901885/hacktools-0.4.0.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4241002/cookie_editor-1.13.0.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4183832/link_gopher-2.6.2.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4455681/traduzir_paginas_web-10.1.1.1.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4830348/retire_js-2.3.2.xpi"
    "https://addons.mozilla.org/firefox/downloads/file/4851039/foxyrecon-0.25.0.xpi"

)

get_addon_index() {
    local name="$1"
    for i in "${!FIREFOX_ADDON_NAMES[@]}"; do
        if [ "${FIREFOX_ADDON_NAMES[$i]}" = "$name" ]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
    return 1
}

get_addon_count() {
    echo "${#FIREFOX_ADDON_NAMES[@]}"
}

get_firefox_profile() {
    local profile_dir
    
 
    if [ -f "$HOME/.mozilla/firefox/profiles.ini" ]; then
        local default_profile
        default_profile=$(grep -A2 "\[Profile[0-9]\]" "$HOME/.mozilla/firefox/profiles.ini" | grep -E "Default=1|Default=yes" -B1 | grep "Path=" | cut -d'=' -f2)
        
        if [ -n "$default_profile" ]; then
            profile_dir="$HOME/.mozilla/firefox/$default_profile"
            if [ -d "$profile_dir" ]; then
                echo "$profile_dir"
                return 0
            fi
        fi
    fi
    
    profile_dir=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -name "*.default-esr" -type d | head -1 2>/dev/null)
    
    if [ -n "$profile_dir" ]; then
        echo "$profile_dir"
        return 0
    fi
    
    profile_dir=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -name "*.default" -type d | head -1 2>/dev/null)
    
    echo "$profile_dir"
}

install_firefox_addon() {
    local addon_name="$1"
    local index
    index=$(get_addon_index "$addon_name")
    
    if [ "$index" = "-1" ]; then
        echo -e "${RED}❌ Add-on '$addon_name' not found in configuration${RESET}"
        return 1
    fi
    
    local addon_id="${FIREFOX_ADDON_IDS[$index]}"
    local download_url="${FIREFOX_ADDON_URLS[$index]}"
    
    local profile_dir
    profile_dir=$(get_firefox_profile)
    
    if [ -z "$profile_dir" ]; then
        echo -e "${RED}❌ Firefox profile not found${RESET}"
        return 1
    fi
    
    mkdir -p "$profile_dir/extensions"
    local xpi_path="${profile_dir}/extensions/${addon_id}.xpi"
    
    if [ -f "$xpi_path" ]; then
        echo -e "${GREEN}✅ $addon_name already installed${RESET}"
        return 0
    fi
    
    echo -e "${CYAN}📥 Downloading $addon_name...${RESET}"
    
    if wget -q --show-progress "$download_url" -O "$xpi_path" 2>/dev/null; then

        if [ -s "$xpi_path" ]; then
            echo -e "${GREEN}✅ $addon_name installed successfully${RESET}"
            return 0
        else
            echo -e "${RED}❌ Downloaded file is empty for $addon_name${RESET}"
            rm -f "$xpi_path" 2>/dev/null
            return 1
        fi
    else
        echo -e "${RED}❌ Download failed for $addon_name${RESET}"
        echo -e "${RED}🛜 Check internet and retry ${RESET}"
        echo -e "${YELLOW}   URL: $download_url${RESET}"
        rm -f "$xpi_path" 2>/dev/null
        return 1
    fi
}

install_firefox_addons_batch() {
    local addons=("$@")
    local success_count=0
    local fail_count=0
    local failed_addons=()
    
    if [ ${#addons[@]} -eq 0 ]; then
        echo -e "${YELLOW}ℹ️ No add-ons specified${RESET}"
        return 0
    fi
    
    if ! command -v firefox >/dev/null 2>&1; then
        echo -e "${RED}❌ Firefox is not installed${RESET}"
        return 1
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    set +e
    
    for addon in "${addons[@]}"; do
        echo -e "🧩 ${MAGENTA}$addon${RESET}"
        
        install_firefox_addon "$addon"
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            ((success_count++))
            #echo -e "${GREEN}✅ Successfully installed: $addon${RESET}"
        else
            ((fail_count++))
            failed_addons+=("$addon")
            echo -e "${RED}❌ Failed to install: $addon${RESET}"
        fi
        echo ""
    done
    
    set -e
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}🧩 $success_count installed | ${RED}❌ $fail_count failed${RESET}"
    
    if [ $fail_count -gt 0 ]; then
        echo -e 
        echo -e "${YELLOW}Failed add-ons:${RESET}"
        for addon in "${failed_addons[@]}"; do
            echo -e "  ${RED}❌ $addon${RESET}"
        done
        echo ""
        echo -e "${YELLOW}💡 You can try installing failed add-ons individually${RESET}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    if [ $success_count -gt 0 ]; then
        echo -e "${YELLOW}💡 Restart Firefox for changes to take effect${RESET}"
        echo -e "${RED}💡 extensions -> Manage-extensions -> enable all addons(manually)${RESET}"
    fi
    
    return 0
}
# Menu Function
install_all_firefox_addons() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}🧩 Installing ALL Firefox add-ons${RESET}"
    
    
    install_firefox_addons_batch "${FIREFOX_ADDON_NAMES[@]}"
}

install_by_number() {
    
    local total_addons
    total_addons=$(get_addon_count)
    
    if [ "$total_addons" -eq 0 ]; then
        echo -e "${RED}❌ No add-ons available!${RESET}"
        return 1
    fi
    
    while true; do
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${YELLOW}🧩 Available add-ons:${RESET}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        
        local profile_dir
        profile_dir=$(get_firefox_profile)
        
        for i in "${!FIREFOX_ADDON_NAMES[@]}"; do
            local addon_name="${FIREFOX_ADDON_NAMES[$i]}"
            local addon_id="${FIREFOX_ADDON_IDS[$i]}"
            
            # Check if installed
            local status="${RED}🔴 Not installed${RESET}"
            
            if [ -n "$profile_dir" ] && [ -f "${profile_dir}/extensions/${addon_id}.xpi" ]; then
                status="${GREEN}🟢 Installed${RESET}"
            fi
            
            printf "${GREEN}%2d${RESET} %-30s %b\n" "$((i+1))" "$addon_name" "$status"
        done
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${YELLOW}Enter numbers, ranges, or combinations:${RESET}"
        echo -e "${CYAN}Examples:${RESET}${YELLOW} 1,3,5  |  1-5  |  1-3,7,9-11  |  1,3-7,10${RESET}"
        echo -e "${YELLOW}Or enter '0' to cancel and return to main menu${RESET}"
        echo -e
        echo -ne "${MAGENTA}Choice: ${RESET}"
        
        read -r selection
        
        if [[ -z "$selection" ]] || [[ "$selection" == "0" ]]; then
            echo -e "${YELLOW}ℹ️ Cancelled - Returning to main menu${RESET}"
            return 0
        fi
        
        local selected_addons=()
        local seen_numbers=()
        
        selection=$(echo "$selection" | tr -d ' ')
        
        IFS=',' read -ra parts <<< "$selection"
        
        for part in "${parts[@]}"; do

            if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                local start="${BASH_REMATCH[1]}"
                local end="${BASH_REMATCH[2]}"
                if [ "$start" -gt "$end" ]; then
                    echo -e "${RED}❌ Invalid range: $start-$end (start > end)${RESET}"
                    continue
                fi

                for ((num=start; num<=end; num++)); do
                    if [ "$num" -ge 1 ] && [ "$num" -le "$total_addons" ]; then
                        local already_added=false
                        for seen in "${seen_numbers[@]}"; do
                            if [ "$seen" -eq "$num" ]; then
                                already_added=true
                                break
                            fi
                        done
                        
                        if [ "$already_added" = false ]; then
                            local index=$((num-1))
                            selected_addons+=("${FIREFOX_ADDON_NAMES[$index]}")
                            seen_numbers+=("$num")
                        fi
                    else
                        echo -e "${YELLOW}⚠️ Number $num out of range (1-$total_addons)${RESET}"
                    fi
                done
                
            elif [[ "$part" =~ ^[0-9]+$ ]]; then
                local num="$part"
                
                if [ "$num" -ge 1 ] && [ "$num" -le "$total_addons" ]; then
            
                    local already_added=false
                    for seen in "${seen_numbers[@]}"; do
                        if [ "$seen" -eq "$num" ]; then
                            already_added=true
                            break
                        fi
                    done
                    
                    if [ "$already_added" = false ]; then
                        local index=$((num-1))
                        selected_addons+=("${FIREFOX_ADDON_NAMES[$index]}")
                        seen_numbers+=("$num")
                    fi
                else
                    echo -e 
                fi
            else
                echo -e "${RED}❌ Invalid input: $part${RESET}"
            fi
        done
        
        if [ ${#selected_addons[@]} -gt 0 ]; then
            echo ""
            echo -e "${CYAN}🧩 Selected ${#selected_addons[@]} add-on(s):${RESET}"
            for addon in "${selected_addons[@]}"; do
                echo -e "  - $addon"
            done
            echo ""
            
            echo -ne "${YELLOW}Continue with installation? (y/N): ${RESET}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                install_firefox_addons_batch "${selected_addons[@]}"
                echo -e "${MAGENTA}Press Enter to continue ${RESET}"
                read -r continue_choice
                if [[ "$continue_choice" =~ ^[Qq]$ ]]; then
                    return 0
                fi
                
            else
                echo -e "${RED}ℹ️ Installation cancelled${RESET}"
                echo -e "${MAGENTA}Press Enter to continue${RESET}"
                read -r continue_choice
                if [[ "$continue_choice" =~ ^[Qq]$ ]]; then
                    return 0
                fi
           
            fi
        else
            echo -e "${RED}❌ No valid add-ons selected${RESET}"
            echo -e "${MAGENTA}Press Enter to try again${RESET}"
            read -r continue_choice
            if [[ "$continue_choice" =~ ^[Qq]$ ]]; then
                return 0
            fi
       
        fi
    done
}
firefox_addons_manager() {
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW} 🦊 Firefox Add-ons ${RESET}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    # Check Firefox installation
    if ! command -v firefox >/dev/null 2>&1; then
        echo -e "${RED}❌ Firefox is not installed${RESET}"
        echo -e "${YELLOW}Please install Firefox first${RESET}"
        echo
        read -rp "Press Enter to continue..."
        return 1
    fi
    
    # Check profile
    local profile_dir
    profile_dir=$(get_firefox_profile)
    if [ -z "$profile_dir" ]; then
        echo -e "${YELLOW}⚠️ No Firefox profile found. Firefox may not have been run yet.${RESET}"
        echo -e "${YELLOW}Please run Firefox once to create a profile, then try again.${RESET}"
        echo
        read -rp "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}✅ Firefox found: $(command -v firefox)${RESET}"
    echo -e "${GREEN}🦊 Profile: $profile_dir${RESET}"
    
    local total_addons
    total_addons=$(get_addon_count)
    echo -e "${CYAN}🧩 $total_addons add-ons available${RESET}"
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    while true; do
        echo -e "${CYAN}Select installation method:${RESET}"
        echo -e "${YELLOW}[1]${RESET} ${GREEN}Install ALL Firefox add-ons${RESET}"
        echo -e "${YELLOW}[2]${RESET} ${GREEN}Select by number (choose specific add-ons)${RESET}"
        echo -e "${YELLOW}[0]${RESET} ${GREEN}Back to main menu${RESET}"
        echo -e 
        echo -ne "${MAGENTA}Choice: ${RESET}"
        
        read -r choice
        
        case "$choice" in
            1)
                install_all_firefox_addons
                echo
                read -rp "Press Enter to continue..."
                ;;
            2)
                install_by_number
                
                ;;
            0|"")
                return 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice${RESET}"
                sleep 1
                ;;
        esac
    done
}

export -f firefox_addons_manager
export -f install_firefox_addon
export -f install_firefox_addons_batch
export -f install_all_firefox_addons
export -f install_by_number
export -f get_firefox_profile
export -f get_addon_count

echo -e "${GREEN}✅ Firefox Add-ons Module loaded${RESET}"
echo -e "${CYAN}🧩 $(get_addon_count) add-ons available${RESET}"
