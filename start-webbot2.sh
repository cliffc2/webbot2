#!/bin/bash

# WebBot 2.0 - Predictive Linguistics CLI
# TODO: Enable MyAllies API when account access granted - https://www.myallies.com/api/authentication/

set -e

# Get script directory for portability
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables from .env if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Set default reports directory
WEBBOT_OUTPUT_DIR="${WEBBOT_OUTPUT_DIR:-$SCRIPT_DIR/reports}"

# Always create reports directory 
/bin/mkdir -p "$WEBBOT_OUTPUT_DIR" || true

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM_CYAN='\033[2;36m'
NC='\033[0m'

BOLD='\033[1m'

show_banner() {
    clear
    echo
    echo "                                    ..           ..                      s                   "
    echo "   k.                             a\"           y\"                      :8      .--~**\$jc.    "
    echo "  88x.   .a.   .s.             \`t888       \`t888              e.      .88     lw     988lc  "
    echo "'8888X x888: x888       .p     E718   .    8888   .    ...ue888b    :888ooo d888b   \`8888d "
    echo " \`8888  888X '888k    88888.   98TX..clif  high..1000  888R Y888S -artbell1 ?8888>  98888M "
    echo "  X888  888X  888X :888'8888.  9888  888C  9888  888H  888R O888>   8888     \"**\"  x88888~ "
    echo "  X888  888X  888X d888 '88%\"  9888  888L  9888  888I  888R N888>   8888          d8888*\`  "
    echo "  X888  888X  888X 8888.+\"     9888  888I  9888  888G  888R I888>   8888        emc\"\`    : "
    echo " .X888  888X. 718~ 8888L       9888  888F  9888  888H  8888c1888   .8888Lu=   :?.....  cgf "
    echo " \`%88%\`\`\"*888Q\"    '8888Q. .+ .8888  888\" .8888  888\"  \"*88888\"    \`^*888*    C\"\"8888888888 "
    echo "   \`~     \`\`        \"88888%    \`%888*%\"    \`%888*%\"      'Y\"         'S\`\"     C:  \"cliffc2  "
    echo "                      //\"'        \`\`          \`\`                              \"\"    \"**\`  "
    echo
    
    echo -e "${GREEN}       Predictive Linguistics - Webbot2 CLI${NC}"
    echo -e "${YELLOW}       Inspired by @clif_high & spirittechie${NC}"
}

show_main_menu() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              M A I N   M E N U                       ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo "  [1] Webbot2 Scraper      (Scrapy - any URL → JSON data → LLM analysis)"
    echo "  [2] Analyze Local File   (Drag & Drop PDF/MD/JSON → Report)"
    echo "  [3] Run Webbot2          (AutoWebBot - Scrape → Analyze → Report)"
    echo "  [4] View Results         (Output folder)"
    echo "  [5] Configuration        (API keys, settings)"
    echo "  [6] Timeline Tracker     (BETA TEST - batch analyze → timeline view)"
    echo "  [0] Exit"
    echo
    echo -ne "  Enter choice [0-6]: "
    read -r choice
    
    while [[ ! "$choice" =~ ^[0-6]$ ]]; do
        echo "  Invalid. Enter 0-6:"
        echo -ne "  Enter choice [0-6]: "
        read -r choice
    done
    
    case $choice in
        1) web_scraper_menu ;;
        2) analyze_local_file ;;
        3) run_full_pipeline ;;
        4) view_output ;;
        5) configuration ;;
        6) timeline_tracker ;;
        0) echo -e "\n${GREEN}Goodbye!${NC}\n"; exit 0 ;;
        *) show_main_menu ;;
    esac
}

run_and_display() {
    local query=$1
    local limit=$2
    local platforms=$3
    
    query_slug=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -dc 'a-z0-9_' | cut -c1-15)
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_DIR=$WEBBOT_OUTPUT_DIR/${TIMESTAMP}_${query_slug}
    mkdir -p "$OUTPUT_DIR"
    
    echo
    echo -e "${CYAN}  [1/3] Scraping $platforms...${NC}"
    
    case $platforms in
        "Reddit")
            webbot2 scrape reddit --subreddit all --query "$query" --limit "$limit"
            data_file=$(ls -t $WEBBOT_OUTPUT_DIR/reddit_*.json 2>/dev/null | head -1)
            cp "$data_file" "$OUTPUT_DIR/data.json" 2>/dev/null
            ;;
        "All Platforms")
            webbot2 run-all --query "$query" --limit "$limit" 2>&1 | tail -10
            data_file=$(ls -t $WEBBOT_OUTPUT_DIR/analysis.json 2>/dev/null | head -1)
            ;;
    esac
    
    if [ -z "$data_file" ] || [ ! -f "$data_file" ]; then
        echo -e "${RED}  ✗ No data scraped${NC}"
        return 1
    fi
    
    # Check for mock data
    if grep -q '"mock_' "$data_file" 2>/dev/null; then
        echo -e "${YELLOW}  ⚠ WARNING: Some scrapers not connected - using mock data${NC}"
        echo
    fi
    
    echo -e "${CYAN}  [2/3] Analyzing with LLM (WebBot 2.0)...${NC}"
    webbot2 analyze llm "$data_file" --prompt-type webbot 2>&1 | tail -10
    
    if [ ! -f $WEBBOT_OUTPUT_DIR/analysis.json ]; then
        echo -e "${RED}  ✗ Analysis failed${NC}"
        return 1
    fi
    
    cp $WEBBOT_OUTPUT_DIR/analysis.json "$OUTPUT_DIR/analysis.json"
    
    echo -e "${CYAN}  [3/3] Generating report...${NC}"
    webbot2 report markdown "$OUTPUT_DIR/analysis.json" --output "$OUTPUT_DIR/report.md" 2>&1 | tail -3
    
    # Add header
    {
        echo "---"
        echo "search: $query"
        echo "limit: $limit"
        echo "timestamp: $TIMESTAMP"
        echo "platforms: $platforms"
        echo "---"
        echo ""
        cat "$OUTPUT_DIR/report.md"
    } > "$OUTPUT_DIR/report.md.tmp"
    mv "$OUTPUT_DIR/report.md.tmp" "$OUTPUT_DIR/report.md"
    
    ln -sf "$OUTPUT_DIR" $WEBBOT_OUTPUT_DIR/latest
    
    echo
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              R E P O R T                                      ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Query: ${GREEN}$query${NC}"
    echo -e "${CYAN}  Platforms: ${GREEN}$platforms${NC}"
    echo -e "${CYAN}  Timestamp: ${GREEN}$TIMESTAMP${NC}"
    echo
    cat "$OUTPUT_DIR/report.md"
    echo
    read -p "  Press Enter to continue..."
}

run_full_pipeline() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              R U N   P I P E L I N E                       ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}  Select:${NC}"
    echo "    [1] Reddit only     (works - real data)"
    echo "    [2] All platforms   (full)"
    echo -ne "${GREEN}  > Mode [1-2]: ${NC}"
    read -r mode
    
    while [[ ! "$mode" =~ ^[1-2]$ ]]; do
        echo "  Invalid. Enter 1-2:"
        echo -ne "  > Mode [1-2]: "
        read -r mode
    done
    
    echo
    echo -ne "${GREEN}  > Search query [future leaks]: ${NC}"
    read -r query
    query=${query:-"future leaks"}
    
    echo -ne "${GREEN}  > Limit [25]: ${NC}"
    read -r limit
    limit=${limit:-25}
    
    case $mode in
        1) run_and_display "$query" "$limit" "Reddit" ;;
        2) run_and_display "$query" "$limit" "All Platforms" ;;
    esac
    
    show_main_menu
}



# UNUSED - commented out
# analyze_data() {
#     show_banner
#     echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
#     echo -e "${YELLOW}              A N A L Y Z E   D A T A                        ${NC}"
#     echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
#     echo
#     
#     echo -e "${CYAN}  Select LLM model:${NC}"
#     echo "    [1] nvidia/nemotron-3-super-120b:a12b  (Largest)"
#     echo "    [2] minimax-minimax-m2.5:free          (Balanced)"
#     echo "    [3] openrouter/free                    (Auto)"
#     echo "    [4] google/gemma-3-4b-it:free          (Fast)"
#     echo "    [5] Use mock data                      (Skip API)"
#     echo -ne "${GREEN}  > Model [1-5]: ${NC}"
#     read -r model_choice
#     
#     while [[ ! "$model_choice" =~ ^[1-5]$ ]]; do
#         echo "  Invalid. Enter 1-5:"
#         echo -ne "${GREEN}  > Model [1-5]: ${NC}"
#         read -r model_choice
#     done
#     
#     case $model_choice in
#         1) model="nvidia/nemotron-3-super-120b-a12b:free" ;;
#         2) model="minimax/minimax-m2.5:free" ;;
#         3) model="openrouter/free" ;;
#         4) model="google/gemma-3-4b-it:free" ;;
#         5) model="skip" ;;
#         *) model="nvidia/nemotron-3-super-120b-a12b:free" ;;
#     esac
#     
#     echo
#     echo -e "${CYAN}  Select prompt type:${NC}"
#     echo "    [1] webbot       (WebBot 2.0 - Recommended)"
#     echo "    [2] event_stream (General patterns)"
#     echo "    [3] globe_pop    (Global populations)"
#     echo "    [4] us_pop       (US-specific)"
#     echo -ne "${GREEN}  > Prompt [1-4]: ${NC}"
#     read -r prompt_choice
#     
#     while [[ ! "$prompt_choice" =~ ^[1-4]$ ]]; do
#         echo "  Invalid. Enter 1-4:"
#         echo -ne "${GREEN}  > Prompt [1-4]: ${NC}"
#         read -r prompt_choice
#     done
#     
#     case $prompt_choice in
#         1) prompt_type="webbot" ;;
#         2) prompt_type="event_stream" ;;
#         3) prompt_type="globe_pop" ;;
#         4) prompt_type="us_pop" ;;
#         *) prompt_type="webbot" ;;
#     esac
#     
#     echo
#     echo -e "${CYAN}  Available data files:${NC}"
#     
#     json_files=$(ls -t $WEBBOT_OUTPUT_DIR/*.json 2>/dev/null)
#     total_files=$(echo "$json_files" | wc -l | tr -d ' ')
#     
#     if [ "$total_files" -gt 0 ] 2>/dev/null; then
#         i=1
#         for f in $json_files; do
#             echo -e "${CYAN}    [$i] $(basename "$f")${NC}"
#             i=$((i+1))
#         done
#     else
#         echo -e "${CYAN}    No files found${NC}"
#     fi
#     echo
#     
#     if [ "$total_files" -gt 0 ] 2>/dev/null; then
#         echo -ne "${GREEN}  > File [1-${total_files}]: ${NC}"
#         read -r file_choice
#         
#         while [[ ! "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total_files" ]; do
#             echo -e "${RED}  Invalid. Enter 1-${total_files}:${NC}"
#             echo -ne "${GREEN}  > File [1-${total_files}]: ${NC}"
#             read -r file_choice
#         done
#         
#         input_file=$(echo "$json_files" | sed -n "${file_choice}p")
#     else
#         input_file=""
#     fi
#     
#     if [ "$model" = "skip" ]; then
#         echo -e "${GREEN}  Analyzing with mock data...${NC}"
#     else
#         echo -e "${GREEN}  Analyzing with $model...${NC}"
#     fi
#     
#     if [ -n "$input_file" ] && [ -f "$input_file" ]; then
#         if [ "$model" = "skip" ]; then
#             echo -e "${YELLOW}  ⚠ Mock mode: API key required for real analysis${NC}"
#             echo -e "${YELLOW}  Set OPENROUTER_API_KEY in .env for free LLM access${NC}"
#         fi
#         webbot2 analyze llm "$input_file" --model "$model" --prompt-type "$prompt_type" 2>&1
#     else
#         echo -e "${RED}  ✗ No valid input file found. Run scrape first.${NC}"
#     fi
#     
#     echo
#     echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
#     echo -e "${GREEN}  ✓ Analysis complete!                                          ${NC}"
#     echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
#     echo
#     read -p "  Press Enter to continue..."
#     show_main_menu
# }

# UNUSED - commented out
# generate_reports() {
#     show_banner
#     echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
#     echo -e "${YELLOW}              G E N E R A T E   R E P O R T S               ${NC}"
#     echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
#     echo
#     echo -e "${CYAN}    Select report format:                                  ${CYAN}│${NC}"
#     echo 
#     echo "    [1] ▶ Markdown Report (.md)"
#     echo "    [2] ▶ JSON Report (.json)    "
#     echo "    [3] ▶ Audio/TTS (.mp3)     "
#     echo "    [4] ▶ All Formats        "
#     echo                    
# 
#     
#     
#     echo
#     echo -ne "${GREEN}  ➜ Enter choice [1-4]: ${NC}"
#     read -r format
#     
#     while [[ ! "$format" =~ ^[1-4]$ ]]; do
#         echo -e "${RED}  ✗ Invalid choice. Please enter 1, 2, 3, or 4:${NC}"
#         echo -ne "${GREEN}  ➜ Enter choice [1-4]: ${NC}"
#         read -r format
#     done
#     
#     echo
#     echo 
#     echo " Available analysis files: "
#     echo 
#     
#     analysis_files=$(ls -t $WEBBOT_OUTPUT_DIR/analysis*.json 2>/dev/null)
#     total_afiles=$(echo "$analysis_files" | wc -l | tr -d ' ')
#     
#     if [ "$total_afiles" -gt 0 ] 2>/dev/null; then
#         i=1
#         for f in $analysis_files; do
#             echo -e "${CYAN}  │${NC}    [$i] $(basename "$f")${CYAN}│${NC}"
#             i=$((i+1))
#         done
#     else
#         echo -e "    No analysis files - run pipeline first          "
#     fi
#     echo 
#     echo
#     
#     if [ "$total_afiles" -gt 0 ] 2>/dev/null; then
#         echo -ne "${GREEN}  ➜ Select file [1-${total_afiles}]: ${NC}"
#         read -r file_choice
#         
#         while [[ ! "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total_afiles" ]; do
#             echo -e "${RED}  ✗ Invalid. Enter 1-${total_afiles}:${NC}"
#             echo -ne "${GREEN}  ➜ Select file [1-${total_afiles}]: ${NC}"
#             read -r file_choice
#         done
#         
#         input_file=$(echo "$analysis_files" | sed -n "${file_choice}p")
#     else
#         input_file=""
#     fi
#     
#     if [ -z "$input_file" ] || [ ! -f "$input_file" ]; then
#         echo -e "${RED}  ✗ File not found or no files available${NC}"
#         read -p "  Press Enter to continue..."
#         show_main_menu
#         return
#     fi
#     
#     case $format in
#         1)
#             echo -e "\n${GREEN}Generating Markdown report...${NC}"
#             output_file=$(dirname "$input_file")/report.md
#             webbot2 report markdown "$input_file" --output "$output_file"
#             ;;
#         2)
#             echo -e "\n${GREEN}Generating JSON report...${NC}"
#             output_file=$(dirname "$input_file")/report.json
#             webbot2 report json "$input_file" --output "$output_file"
#             ;;
#         3)
#             echo -e "\n${CYAN}Select language:${NC}"
#             echo "1) English"
#             echo "2) Spanish" 
#             echo "3) French"
#             echo "4) German"
#             echo -ne "${GREEN}Select [1-4]: ${NC}"
#             read -r lang_choice
#             case $lang_choice in
#                 1) lang="en" ;;
#                 2) lang="es" ;;
#                 3) lang="fr" ;;
#                 4) lang="de" ;;
#                 *) lang="en" ;;
#             esac
#             echo -e "\n${GREEN}Generating Audio report...${NC}"
#             output_file=$(dirname "$input_file")/report.mp3
#             webbot2 report audio "$input_file" --lang "$lang" --output "$output_file"
#             ;;
#         4)
#             echo -e "\n${GREEN}Generating all reports...${NC}"
#             output_dir=$(dirname "$input_file")
#             webbot2 report markdown "$input_file" --output "$output_dir/report.md"
#             webbot2 report json "$input_file" --output "$output_dir/report.json"
#             webbot2 report audio "$input_file" --lang "en" --output "$output_dir/report.mp3"
#             ;;
#         *)
#             show_main_menu
#             ;;
#     esac
#     
#     echo
#     echo 
#     echo -e "${GREEN}  ✓ Reports generated successfully!                          ${NC}"
#     echo 
#     echo
#     echo -e "${CYAN}  Output location: ${YELLOW}$WEBBOT_OUTPUT_DIR/${NC}"
#     echo
#     read -p "  Press Enter to continue..."
#     show_main_menu
# }

view_output() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}             V I E W   O U T P U T   F I L E S          ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    # List all run folders
    echo -e "${CYAN}  Select a run:${NC}"
    echo
    
    # Get folders (not files), sorted by newest - only show those with reports
    run_folders=$(ls -td $WEBBOT_OUTPUT_DIR/*/ 2>/dev/null)
    total=$(echo "$run_folders" | wc -l | tr -d ' ')
    
    if [ "$total" -gt 0 ] && [ -n "$run_folders" ]; then
        i=1
        for folder in $run_folders; do
            name=$(basename "$folder")
            if [ -f "$folder/report.md" ]; then
                echo -e "${CYAN}    [$i] $name [report]${NC}"
                i=$((i+1))
            fi
        done
        # Update total to reflect only folders with reports
        total=$((i-1))
        if [ "$total" -eq 0 ]; then
            echo -e "${CYAN}    No reports found${NC}"
            echo
            echo -ne "${GREEN}  ➜ Press Enter to go back: ${NC}"
            read -r
            show_main_menu
            return
        fi
        echo -e "${CYAN}    [0] Back to main menu${NC}"
    else
        echo -e "${CYAN}    No runs found${NC}"
        echo
        echo -ne "${GREEN}  ➜ Press Enter to go back: ${NC}"
        read -r
        show_main_menu
        return
    fi
    echo
    
    if [ "$total" -gt 0 ]; then
        echo -ne "${GREEN}  ➜ Select run [0-$total]: ${NC}"
        read -r sel
        
        while [[ ! "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 0 ] || [ "$sel" -gt "$total" ]; do
            echo -e "${RED}  Invalid. Enter 0-$total:${NC}"
            echo -ne "${GREEN}  ➜ Select run [0-$total]: ${NC}"
            read -r sel
        done
        
        if [ "$sel" = "0" ]; then
            show_main_menu
            return
        fi
        
        SELECTED_DIR=$(echo "$run_folders" | sed -n "${sel}p")
        
        if [ -f "$SELECTED_DIR/report.md" ]; then
            echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  REPORT: $(basename "$SELECTED_DIR")${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"
            cat "$SELECTED_DIR/report.md"
        elif [ -f "$SELECTED_DIR/analysis.json" ]; then
            echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  ANALYSIS: $(basename "$SELECTED_DIR")${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"
            cat "$SELECTED_DIR/analysis.json" | python3 -m json.tool | head -100
        elif [ -f "$SELECTED_DIR/data.json" ]; then
            echo -e "${YELLOW}  Data only - no report. Run Quick Analysis to generate report.${NC}"
        else
            echo -e "${YELLOW}  Empty folder${NC}"
        fi
    fi
    
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

configuration() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              C O N F I G U R A T I O N                  ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo 
    echo -e "${CYAN}  ${NC}  Current Settings:                                      ${CYAN}│${NC}"
    echo 
    
    if [ -f ~/.webbot2.env ]; then
        while IFS= read -r line; do
            echo -e "${CYAN}  │${NC}    $line${CYAN}                                          │${NC}"
        done < ~/.webbot2.env
    else
        echo "       No config found (run setup)                          "
    fi
    echo 
    echo
    
    echo 
    echo  "  Options:                                            "
    echo  "                                                      "
    echo  "    [1] ▶ Set OpenRouter API Key                     "
    echo  "    [2] ▶ Set default LLM model                     "
    echo  "    [3] ▶ View available free models                 "
    echo  "    [4] ▶ Test API connection                        "
    echo  "    [0] ▶ Back to main menu                          "
    echo 
    echo
    echo -ne "${GREEN}  ➜ Select option [0-4]: ${NC}"
    read -r choice
    
    while [[ ! "$choice" =~ ^[0-4]$ ]]; do
        echo -e "${RED}  ✗ Invalid. Enter 0-4:${NC}"
        echo -ne "${GREEN}  ➜ Select option [0-4]: ${NC}"
        read -r choice
    done
    
    case $choice in
        1)
            echo -e "\n${CYAN}Enter your OpenRouter API key:${NC}"
            echo "(Get free key at https://openrouter.ai/keys)"
            read -r api_key
            if [ -n "$api_key" ]; then
                echo "OPENROUTER_API_KEY=$api_key" > ~/.webbot2.env
                echo -e "${GREEN}API key saved!${NC}"
            fi
            ;;
        2)
            echo -e "\n${CYAN}Available free models:${NC}"
            echo "1) nvidia/nemotron-3-super-120b-a12b:free"
            echo "2) minimax/minimax-m2.5:free"
            echo "3) openrouter/free"
            echo "4) google/gemma-3-4b-it:free"
            echo -ne "${GREEN}Select default [1-4]: ${NC}"
            read -r model_choice
            case $model_choice in
                1) model="nvidia/nemotron-3-super-120b-a12b:free" ;;
                2) model="minimax/minimax-m2.5:free" ;;
                3) model="openrouter/free" ;;
                4) model="google/gemma-3-4b-it:free" ;;
                *) model="nvidia/nemotron-3-super-120b-a12b:free" ;;
            esac
            echo "OPENROUTER_MODEL=$model" >> ~/.webbot2.env
            echo -e "${GREEN}Default model set to: $model${NC}"
            ;;
        3)
            echo -e "\n${CYAN}Recommended free models:${NC}"
            echo "1) qwen/qwen3.6-plus-preview:free - Recommended"
            echo "2) minimax/minimax-m2.5:free - Fast"
            echo "3) nvidia/nemotron-3-super-120b-a12b:free - Largest"
            echo "4) google/gemma-3-4b-it:free - Fastest (may be rate-limited)"
            ;;
        4)
            echo -e "\n${GREEN}Testing API key...${NC}"
            if [ -f ~/.webbot2.env ]; then
                source ~/.webbot2.env
                if [ -n "$OPENROUTER_API_KEY" ]; then
                    curl -s "https://openrouter.ai/api/v1/models" -H "Authorization: Bearer $OPENROUTER_API_KEY" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ API key valid!' if 'data' in d else '✗ Invalid key')" 2>/dev/null || echo "✗ Connection error"
                else
                    echo "✗ No API key found"
                fi
            else
                echo "✗ Config file not found"
            fi
            ;;
        5)
            echo -e "\n${CYAN}Enter alias name:${NC}"
            read -r alias_name
            echo -e "${CYAN}Enter query:${NC}"
            read -r alias_query
            echo -e "${CYAN}Enter limit:${NC}"
            read -r alias_limit
            echo "$alias_name|$alias_query|$alias_limit" >> ~/.webbot2_aliases
            echo -e "${GREEN}Alias saved!${NC}"
            ;;
        0)
            show_main_menu
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
    configuration
}

# UNUSED - commented out
# show_free_models() {
#     show_banner
#     echo -e "${YELLOW}=== AVAILABLE FREE LLM MODELS ===${NC}\n"
#     
#     if [ -f ~/.webbot2.env ]; then
#         source ~/.webbot2.env
#         if [ -n "$OPENROUTER_API_KEY" ]; then
#             echo -e "${GREEN}Fetching models from OpenRouter...${NC}\n"
#             curl -s "https://openrouter.ai/api/v1/models" -H "Authorization: Bearer $OPENROUTER_API_KEY" | python3 -c "
# import json,sys
# d = json.load(sys.stdin)
# print('Model ID'.ljust(60), 'Pricing')
# print('-' * 80)
# for m in d.get('data',[])[:30]:
#     price = m.get('pricing',{})
#     if price.get('prompt') == '0':
#         print(m['id'].ljust(60), 'FREE')
# " 2>/dev/null | head -20
#         else
#             echo "No API key configured. Showing default models:"
#         fi
#     fi
#     
#     echo -e "\n${CYAN}Recommended free models:${NC}"
#     echo "1) nvidia/nemotron-3-super-120b-a12b:free - Largest, slowest"
#     echo "2) minimax/minimax-m2.5:free - Good balance"
#     echo "3) openrouter/free - Auto-select"
#     echo "4) google/gemma-3-4b-it:free - Smaller, faster"
#     echo "5) stepfun/step-3.5-flash:free - Fast"
#     
#     echo
#     read -p "Press Enter to continue..."
#     configuration
# }

# UNUSED - commented out
# show_help() {
#     show_banner
#     echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
#     echo -e "${YELLOW}              H E L P   &   I N F O                          ${NC}"
#     echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
#     echo
#     
#     echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────────┐${NC}"
#     echo -e "${CYAN}  │${NC}  ┌─────────────────────────────────────────────────────┐${NC}"
#     echo -e "${CYAN}  │${NC}  │  WHAT IT DOES:                                      │${NC}"
#     echo -e "${CYAN}  │${NC}  │  • Scrapes Twitter, Reddit, YouTube, News           │${NC}"
#     echo -e "${CYAN}  │${NC}  │  • Detects metaphors, archetypes, emotional spikes  │${NC}"
#     echo -e "${CYAN}  │${NC}  │  • Finds \"future leak\" indicators                 │${NC}"
#     echo -e "${CYAN}  │${NC}  └─────────────────────────────────────────────────────┘${NC}"
#     echo
#     
#     echo -e "${CYAN}  │${NC}  ┌─────────────────────────────────────────────────────┐${NC}"
#     echo -e "${CYAN}  │${NC}  │  HOW IT WORKS (NO API KEYS NEEDED):                 │${NC}"
#     echo -e "${CYAN}  │${NC}  │  • Twitter:   Nitter (nitter.net)                   │${NC}"
#     echo -e "${CYAN}  │${NC}  │  • Reddit:    Old Reddit (old.reddit.com)           │${NC}"
#     echo -e "${CYAN}  │${NC}  │  • YouTube:   Invidious (yewtu.be)                  │${NC}"
#     echo -e "${CYAN}  │${NC}  │  • News:      RSS feeds (BBC, Reuters)              │${NC}"
#     echo -e "${CYAN}  │${NC}  └─────────────────────────────────────────────────────┘${NC}"
#     echo
#     
#     echo -e "${CYAN}  └─────────────────────────────────────────────────────────────┘${NC}"
#     echo
#     
#     echo -e "${YELLOW}  ┌─────────────────────────────────────────────────────────────┐${NC}"
#     echo -e "${YELLOW}  │${NC}  FREE LLM OPTIONS:                                   ${YELLOW}│${NC}"
#     echo -e "${YELLOW}  │${NC}  • OpenRouter: https://openrouter.ai/keys            ${YELLOW}│${NC}"
#     echo -e "${YELLOW}  │${NC}  • Local:       brew install ollama                  ${YELLOW}│${NC}"
#     echo -e "${YELLOW}  └─────────────────────────────────────────────────────────────┘${NC}"
#     echo
#     
#     echo -e "${GREEN}  Example Queries:${NC}"
#     echo "    • future leaks / future predictions"
#     echo "    • AI consciousness / artificial general intelligence"
#     echo "    • economic shift / market trends"
#     echo "    • political unrest / protests"
#     echo "    • emerging technology"
#     echo
#     
#     echo -e "${CYAN}  Output: ${GREEN}$WEBBOT_OUTPUT_DIR/${NC}"
#     echo
#     read -p "  Press Enter to continue..."
#     show_main_menu
# }

timeline_tracker() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}         T I M E L I N E   T R A C K E R                   ${NC}"
    echo -e "${YELLOW}         (Batch analyze ALTA reports → timeline)            ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    ANALYSIS_DIR="$HOME/Documents/clif-high-webbot/analysis_input"
    
    if [ ! -d "$ANALYSIS_DIR" ]; then
        echo -e "${RED}  ✗ Analysis directory not found: $ANALYSIS_DIR${NC}"
        echo
        read -p "  Press Enter to continue..."
        show_main_menu
        return
    fi
    
    # Find all PDFs
    pdf_files=$(find "$ANALYSIS_DIR" -name "*.pdf" -type f 2>/dev/null)
    total_pdfs=$(echo "$pdf_files" | wc -l | tr -d ' ')
    
    if [ "$total_pdfs" -eq 0 ]; then
        echo -e "${RED}  ✗ No PDF files found in $ANALYSIS_DIR${NC}"
        echo
        read -p "  Press Enter to continue..."
        show_main_menu
        return
    fi
    
    echo -e "${CYAN}  Found ${GREEN}$total_pdfs${CYAN} PDF files in analysis folder${NC}"
    echo
    echo -e "${CYAN}  Options:${NC}"
    echo "    [1] Analyze all PDFs (batch)"
    echo "    [2] Use existing analyses (faster)"
    echo "    [3] Build Correlation Graph (from existing analyses)"
    echo "    [0] Back"
    echo
    echo -ne "${GREEN}  > Choice [0-3]: ${NC}"
    read -r mode
    
    while [[ ! "$mode" =~ ^[0-3]$ ]]; do
        echo -e "${RED}  Invalid. Enter 0-3:${NC}"
        echo -ne "${GREEN}  > Choice [0-3]: ${NC}"
        read -r mode
    done
    
    if [ "$mode" = "0" ]; then
        show_main_menu
        return
    fi
    
    # Option 3: Build correlation graph
    if [ "$mode" = "3" ]; then
        show_banner
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}         C O R R E L A T I O N   G R A P H                 ${NC}"
        echo -e "${YELLOW}         (Build relational graph from predictions)          ${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo
        
        # Find all analysis folders with data
        analysis_folders=$(ls -td $WEBBOT_OUTPUT_DIR/20* 2>/dev/null | while read d; do
            if [ -f "$d/analysis.json" ]; then echo "$d"; fi
        done)
        total_folders=$(echo "$analysis_folders" | wc -l | tr -d ' ')
        
        if [ "$total_folders" -eq 0 ] || [ -z "$analysis_folders" ]; then
            echo -e "${RED}  No analysis folders found${NC}"
            read -p "  Press Enter to continue..."
            show_main_menu
            return
        fi
        
        echo -e "${CYAN}  Found ${GREEN}$total_folders${CYAN} analysis folders${NC}"
        echo
        
        # Create a temp dir for all analyses (with unique names)
        GRAPH_INPUT=$(mktemp -d)
        for folder in $analysis_folders; do
            folder_name=$(basename "$folder")
            cp "$folder/analysis.json" "$GRAPH_INPUT/${folder_name}_analysis.json" 2>/dev/null
        done
        
        echo -e "${CYAN}  Copied $(ls "$GRAPH_INPUT" | wc -l | tr -d ' ') analyses to temp dir${NC}"
        
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        GRAPH_OUTPUT=$WEBBOT_OUTPUT_DIR/${TIMESTAMP}_graph
        
        echo -e "${CYAN}  Building correlation graph...${NC}"
        
        python3 -m webbot2_cli.graph_builder "$GRAPH_INPUT/" --output "$GRAPH_OUTPUT.json" --format json 2>&1
        
        if [ -f "$GRAPH_OUTPUT.json" ]; then
            echo
            echo -e "${GREEN}  ✓ Graph created!${NC}"
            echo -e "${CYAN}  Output: $GRAPH_OUTPUT.json${NC}"
            echo
            echo -e "${CYAN}  Visualization options:${NC}"
            echo "    1) Open in browser (simple viewer)"
            echo "    2) Export as GraphML (for Gephi)"
            echo "    3) Both"
            echo "    0) Skip"
            echo
            echo -ne "${GREEN}  > Choice [0-3]: ${NC}"
            read -r vis_choice
            
            if [ "$vis_choice" = "1" ] || [ "$vis_choice" = "3" ]; then
                # Copy HTML viewer
                cp "$(dirname "$0")/src/webbot2_cli/graph_viewer.html" "$GRAPH_OUTPUT.html"
                # Embed graph data into HTML using Python
                python3 << PYEOF
import json, re, sys
with open("$GRAPH_OUTPUT.html", "r") as f:
    html = f.read()
with open("$GRAPH_OUTPUT.json", "r") as f:
    graph_data = json.load(f)
# Replace defaultData with actual data
json_str = json.dumps(graph_data)
html = re.sub(r"const defaultData = \{.*?\};", f"const defaultData = {json_str};", html, flags=re.DOTALL)
with open("$GRAPH_OUTPUT.html", "w") as f:
    f.write(html)
PYEOF
                open "$GRAPH_OUTPUT.html"
            fi
            
            if [ "$vis_choice" = "2" ] || [ "$vis_choice" = "3" ]; then
                python3 -m webbot2_cli.graph_builder "$GRAPH_INPUT/" --output "$GRAPH_OUTPUT.graphml" --format graphml 2>&1
                echo -e "${CYAN}  GraphML: $GRAPH_OUTPUT.graphml${NC}"
            fi
            
            if [ "$vis_choice" = "0" ]; then
                echo -e "${CYAN}  Graph saved to: $GRAPH_OUTPUT.json${NC}"
                echo -e "${CYAN}  Run with --format graphml for Gephi${NC}"
            fi
        else
            echo -e "${RED}  Graph generation failed${NC}"
        fi
        
        rm -rf "$GRAPH_INPUT"
        
        read -p "  Press Enter to continue..."
        show_main_menu
        return
    fi
    
    CURRENT_YEAR=$(date +%Y)
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_DIR=$WEBBOT_OUTPUT_DIR/${TIMESTAMP}_timeline
    mkdir -p "$OUTPUT_DIR"
    
    # Function to extract year from filename (e.g., ALTA_2015_December -> 2015)
    extract_year() {
        echo "$1" | grep -oE '[0-9]{4}' | head -1
    }
    
    # Function to normalize filename for matching
    normalize_filename() {
        local name=$(basename "$1" | sed 's/\.[^.]*$//')
        # Remove leading numbers and dots like "10. "
        name=$(echo "$name" | sed 's/^[0-9.]* *//')
        # Extract ALTA_YYYY part
        echo "$name" | grep -oE 'ALTA[_-]?[0-9]{4}[A-Za-z]*' | head -1
    }
    
    # Function to analyze a single PDF
    analyze_single_pdf() {
        local pdf_path=$1
        local filename=$(basename "$pdf_path" | sed 's/\.[^.]*$//')
        local pdf_year=$(extract_year "$filename")
        
        # Try to find matching analysis folder
        normalized=$(normalize_filename "$pdf_path")
        normalized_lower=$(echo "$normalized" | tr '[:upper:]' '[:lower:]')
        if [ -n "$normalized" ]; then
            # Search for any folder containing the normalized name
            existing_analysis=$(ls -t $WEBBOT_OUTPUT_DIR/*${normalized}*/analysis.json $WEBBOT_OUTPUT_DIR/*${normalized_lower}*/analysis.json 2>/dev/null | head -1)
        fi
        
        # Fallback: search all folders for analysis.json with matching year
        if [ -z "$existing_analysis" ]; then
            existing_analysis=$(ls -t $WEBBOT_OUTPUT_DIR/*${pdf_year}*/analysis.json 2>/dev/null | head -1)
        fi
        
        if [ -n "$existing_analysis" ] && [ -f "$existing_analysis" ]; then
            # Avoid duplicates - check if we already copied this analysis
            analysis_name=$(basename $(dirname "$existing_analysis"))
            if [ -f "$OUTPUT_DIR/${analysis_name}_analysis.json" ]; then
                return 0  # Already processed
            fi
            echo -e "${CYAN}  Using: $analysis_name${NC}"
            cp "$existing_analysis" "$OUTPUT_DIR/${analysis_name}_analysis.json"
            return 0
        fi
        
        if [ "$mode" = "2" ]; then
            echo -e "${YELLOW}  Skipping: $filename (no analysis found)${NC}"
            return 1
        fi
        
        echo -e "${CYAN}  Analyzing: $filename (year: $pdf_year)${NC}"
        
        # Extract text
        TMP_TEXT=/tmp/timeline_$$.txt
        python3 -c "
import sys
try:
    import PyPDF2
    with open('$pdf_path', 'rb') as f:
        reader = PyPDF2.PdfReader(f)
        text = ''
        for page in reader.pages:
            text += page.extract_text() or ''
    with open('$TMP_TEXT', 'w', encoding='utf-8') as out:
        out.write(text)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
        
        if [ ! -s "$TMP_TEXT" ]; then
            echo -e "${RED}  Failed: $filename${NC}"
            rm -f "$TMP_TEXT"
            return 1
        fi
        
        # Wrap in JSON and analyze
        python3 -c "
import json
with open('$TMP_TEXT', 'r', encoding='utf-8') as f:
    text = f.read()
data = {'source': '$(basename "$pdf_path")', 'text': text}
with open('$OUTPUT_DIR/data.json', 'w', encoding='utf-8') as out:
    json.dump(data, out)
"
        rm -f "$TMP_TEXT"
        
        # Run analysis
        webbot2 analyze llm "$OUTPUT_DIR/data.json" --prompt-type webbot 2>&1 | tail -3
        
        if [ -f $WEBBOT_OUTPUT_DIR/analysis.json ]; then
            cp $WEBBOT_OUTPUT_DIR/analysis.json "$OUTPUT_DIR/${filename}_analysis.json"
        fi
    }
    
    # Process all PDFs (with deduplication)
    echo
    echo -e "${YELLOW}  Processing PDFs...${NC}"
    
    set +e
    processed Analyses=""
    for pdf in $pdf_files; do
        analyze_single_pdf "$pdf" 2>/dev/null || true
    done
    set -e
    
    # Extract temporal data from all analyses
    echo
    echo -e "${YELLOW}  Building timeline...${NC}"
    echo -e "${CYAN}  Debug: Checking analysis files in $OUTPUT_DIR${NC}"
    
    # Collect all temporal anomalies into a single JSON
    cat > /tmp/timeline_extract.py << ENDPY
import json
import os
import re
import sys

current_year = %%CURRENT_YEAR%%
analyses_dir = "%%OUTPUT_DIR%%"
output_file = analyses_dir + '/timeline_data.json'

all_predictions = []

def get_doc_year(filename):
    match = re.search(r'[0-9]{4}', filename)
    return int(match.group()) if match else current_year

def get_temporal_data(data):
    raw = data.get('raw_analysis', '')
    if raw:
        try:
            start = raw.find('\`\`\`json')
            end = raw.find('\`\`\`', start + 7)
            if start >= 0 and end > start:
                inner = json.loads(raw[start+7:end])
                return inner.get('temporal_anomalies', []), inner.get('future_leaks', [])
        except Exception as e:
            pass
    return data.get('temporal_anomalies', []), data.get('future_leaks', [])

for f in os.listdir(analyses_dir):
    if f.endswith('_analysis.json'):
        try:
            with open(os.path.join(analyses_dir, f), 'r') as fp:
                data = json.load(fp)
            
            source = data.get('source', f.replace('_analysis.json', ''))
            doc_year = get_doc_year(source)
            
            temporal, future_leaks = get_temporal_data(data)
            
            for pred in temporal:
                ref = pred.get('future_reference', '')
                year_match = re.search(r'[0-9]{4}', ref)
                if year_match:
                    pred_year = int(year_match.group())
                    years_ahead = pred_year - doc_year
                else:
                    pred_year = doc_year
                    years_ahead = 0
                
                all_predictions.append({
                    'source': source,
                    'doc_year': doc_year,
                    'predicted_year': pred_year,
                    'actual_year': pred_year,
                    'years_ahead': years_ahead,
                    'description': pred.get('text', ''),
                    'indicator': ref,
                    'category': 'temporal_anomaly',
                    'status': 'pending'
                })
            
            for pred in future_leaks:
                ref = pred.get('indicator', '')
                year_match = re.search(r'[0-9]{4}', ref)
                if year_match:
                    pred_year = int(year_match.group())
                    years_ahead = pred_year - doc_year
                else:
                    timeline = pred.get('timeline', '')
                    years_ahead = 0
                    if 'month' in timeline.lower():
                        # Convert months to fractional years (use midpoint)
                        nums = re.findall(r'(\d+)', timeline)
                        if nums:
                            months = (int(nums[0]) + int(nums[-1])) / 2  # midpoint
                            years_ahead = months / 12
                            pred_year = doc_year + int(months / 12)
                        else:
                            pred_year = doc_year
                    elif 'year' in timeline.lower():
                        nums = re.findall(r'(\d+)', timeline)
                        if nums:
                            years_ahead = int(nums[0])
                            pred_year = doc_year + years_ahead
                        else:
                            pred_year = doc_year
                    else:
                        pred_year = doc_year
                
                all_predictions.append({
                    'source': source,
                    'doc_year': doc_year,
                    'predicted_year': pred_year,
                    'actual_year': pred_year,
                    'years_ahead': years_ahead,
                    'description': pred.get('supporting_evidence', []),
                    'indicator': ref,
                    'category': 'future_leak',
                    'status': 'pending'
                })
        except Exception as e:
            print(f'Error: {e}', file=sys.stderr)

if len(all_predictions) == 0:
    print('No predictions found')

all_predictions.sort(key=lambda x: x.get('actual_year', 9999))

for pred in all_predictions:
    years_diff = pred['actual_year'] - current_year
    if years_diff < 0:
        pred['timeline_position'] = 'PAST'
    elif years_diff == 0:
        pred['timeline_position'] = 'NOW'
    else:
        pred['timeline_position'] = 'FUTURE'

with open(output_file, 'w') as fp:
    json.dump({
        'current_year': current_year,
        'predictions': all_predictions,
        'total': len(all_predictions)
    }, fp, indent=2)

print(f'Extracted {len(all_predictions)} predictions')
ENDPY
    
    sed -i '' "s/%%CURRENT_YEAR%%/$CURRENT_YEAR/g" /tmp/timeline_extract.py
    sed -i '' "s|%%OUTPUT_DIR%%|$OUTPUT_DIR|g" /tmp/timeline_extract.py
    
    python3 /tmp/timeline_extract.py
    
    if [ ! -f "$OUTPUT_DIR/timeline_data.json" ]; then
        echo -e "${RED}  ✗ Failed to build timeline${NC}"
        read -p "  Press Enter to continue..."
        show_main_menu
        return
    fi
    
    # Display timeline
    echo
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}               T I M E L I N E   R E P O R T                  ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}  Current Year: ${GREEN}$CURRENT_YEAR${NC}"
    echo
    
    python3 -c "
import json

with open('$OUTPUT_DIR/timeline_data.json') as f:
    data = json.load(f)

predictions = data.get('predictions', [])
current_year = data.get('current_year', 2026)

past = [p for p in predictions if p.get('timeline_position') == 'PAST']
now = [p for p in predictions if p.get('timeline_position') == 'NOW']
future = [p for p in predictions if p.get('timeline_position') == 'FUTURE']

print(f\"  Total Predictions: {len(predictions)}\")
print(f\"  ├── PAST (should have happened): {len(past)}\")
print(f\"  ├── NOW (happening this year): {len(now)}\")
print(f\"  └── FUTURE (upcoming): {len(future)}\")
print()

if past:
    print('  ─────────────────────────────────────────────────────────────')
    print('  PAST PREDICTIONS (should have materialized by now):')
    print('  ─────────────────────────────────────────────────────────────')
    for p in past[:10]:
        print(f\"    • {p.get('actual_year')} | {p.get('source', 'unknown')[:25]}\")
        desc = p.get('description', p.get('indicator', ''))[:60]
        print(f\"      → {desc}\")
    if len(past) > 10:
        print(f\"    ... and {len(past) - 10} more\")
    print()

if now:
    print('  ─────────────────────────────────────────────────────────────')
    print('  CURRENT YEAR PREDICTIONS (2026):')
    print('  ─────────────────────────────────────────────────────────────')
    for p in now:
        print(f\"    • {p.get('source', 'unknown')[:30]}\")
        desc = p.get('description', p.get('indicator', ''))[:60]
        print(f\"      → {desc}\")
    print()

if future:
    print('  ─────────────────────────────────────────────────────────────')
    print('  FUTURE PREDICTIONS (upcoming):')
    print('  ─────────────────────────────────────────────────────────────')
    for p in future[:10]:
        print(f\"    • {p.get('actual_year')} | {p.get('source', 'unknown')[:25]}\")
        desc = p.get('description', p.get('indicator', ''))[:60]
        print(f\"      → {desc}\")
    if len(future) > 10:
        print(f\"    ... and {len(future) - 10} more\")
"
    
    # Save report
    {
        echo "# Timeline Report"
        echo ""
        echo "Generated: $(date)"
        echo "Current Year: $CURRENT_YEAR"
        echo ""
        python3 -c "
import json
with open('$OUTPUT_DIR/timeline_data.json') as f:
    data = json.load(f)
predictions = data.get('predictions', [])
past = [p for p in predictions if p.get('timeline_position') == 'PAST']
now = [p for p in predictions if p.get('timeline_position') == 'NOW']
future = [p for p in predictions if p.get('timeline_position') == 'FUTURE']
print(f'Total: {len(predictions)} | Past: {len(past)} | Now: {len(now)} | Future: {len(future)}')
"
        echo ""
        cat "$OUTPUT_DIR/timeline_data.json"
    } > "$OUTPUT_DIR/timeline_report.md"
    
    ln -sf "$OUTPUT_DIR" $WEBBOT_OUTPUT_DIR/latest
    
    echo
    echo -e "${GREEN}  ✓ Timeline complete!${NC}"
    echo -e "${CYAN}  Saved to: $OUTPUT_DIR/timeline_report.md${NC}"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

analyze_local_file() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}         A N A L Y Z E   L O C A L   F I L E               ${NC}"
    echo -e "${YELLOW}              (PDF, Markdown, or JSON files)                  ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  Enter path to file:${NC}"
    echo -e "${CYAN}  • PDF/MD  → extract text → analyze → report${NC}"
    echo -e "${CYAN}  • JSON    → analyze (or report if already analyzed)${NC}"
    echo -e "${CYAN}  Tip: Drag & drop file from Finder to get path${NC}"
    echo
    echo -ne "${GREEN}  > File path: ${NC}"
    read -r file_path
    
    # Expand ~ to home directory
    file_path="${file_path/#\~/$HOME}"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}  ✗ File not found: $file_path${NC}"
        echo
        read -p "  Press Enter to continue..."
        show_main_menu
        return
    fi
    
    # Determine file type
    ext="${file_path##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    if [ "$ext" != "pdf" ] && [ "$ext" != "md" ] && [ "$ext" != "markdown" ] && [ "$ext" != "json" ]; then
        echo -e "${RED}  ✗ Unsupported file type: .$ext${NC}"
        echo -e "${CYAN}  Supported: .pdf, .md, .markdown, .json${NC}"
        echo
        read -p "  Press Enter to continue..."
        show_main_menu
        return
    fi
    
    # Get file name for output folder
    filename=$(basename "$file_path" | sed 's/\.[^.]*$//')
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_DIR=$WEBBOT_OUTPUT_DIR/${TIMESTAMP}_${filename}
    mkdir -p "$OUTPUT_DIR"
    
    # Copy source file to output
    cp "$file_path" "$OUTPUT_DIR/source.${ext}"
    
    if [ "$ext" = "json" ]; then
        # JSON file - check if it's already analysis data or raw scrape data
        echo -e "${CYAN}  Checking JSON structure...${NC}"
        
        is_analysis=$(python3 -c "
import json
with open('$file_path') as f:
    d = json.load(f)
has_analysis = 'temporal_anomalies' in d or 'archetypes' in d or 'future_leaks' in d
print('yes' if has_analysis else 'no')
" 2>/dev/null)
        
        if [ "$is_analysis" = "yes" ]; then
            echo -e "${GREEN}  ✓ Already contains analysis data${NC}"
            cp "$file_path" "$OUTPUT_DIR/analysis.json"
            echo -e "${CYAN}  [1/1] Generating report from existing analysis...${NC}"
            webbot2 report markdown "$OUTPUT_DIR/analysis.json" --output "$OUTPUT_DIR/report.md" 2>&1 | tail -3
        else
            echo -e "${CYAN}  Contains raw data - running LLM analysis...${NC}"
            cp "$file_path" "$OUTPUT_DIR/data.json"
            echo -e "${CYAN}  [1/2] Analyzing with LLM (WebBot 2.0)...${NC}"
            
            if ! webbot2 analyze llm "$OUTPUT_DIR/data.json" --prompt-type webbot 2>&1 | tail -10; then
                echo -e "${RED}  ✗ Analysis failed${NC}"
                read -p "  Press Enter to continue..."
                show_main_menu
                return
            fi
            
            if [ ! -f "$WEBBOT_OUTPUT_DIR/analysis.json" ]; then
                echo -e "${RED}  ✗ Analysis failed - no output found${NC}"
                read -p "  Press Enter to continue..."
                show_main_menu
                return
            fi
            
            cp "$WEBBOT_OUTPUT_DIR/analysis.json" "$OUTPUT_DIR/analysis.json"
            
            echo -e "${CYAN}  [2/2] Generating report...${NC}"
            webbot2 report markdown "$OUTPUT_DIR/analysis.json" --output "$OUTPUT_DIR/report.md" 2>&1 | tail -3
        fi
    else
        # PDF or Markdown - extract text and analyze
        echo
        echo -e "${CYAN}  Extracting text from .$ext file...${NC}"
        
        # Create temp file for extracted text
        TMP_TEXT=/tmp/local_analyze_$$.txt
        
        if [ "$ext" = "pdf" ]; then
            python3 -c "
import sys
try:
    import PyPDF2
    with open('$file_path', 'rb') as f:
        reader = PyPDF2.PdfReader(f)
        text = ''
        for page in reader.pages:
            text += page.extract_text() or ''
    with open('$TMP_TEXT', 'w', encoding='utf-8') as out:
        out.write(text)
    print('OK')
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1
            if [ $? -ne 0 ] || [ ! -s "$TMP_TEXT" ]; then
                echo -e "${RED}  ✗ Failed to extract text from PDF${NC}"
                rm -f "$TMP_TEXT"
                read -p "  Press Enter to continue..."
                show_main_menu
                return
            fi
        else
            # Markdown - just copy
            cp "$file_path" "$TMP_TEXT"
        fi
        
        # Save extracted text as data.json (wrap in JSON format for LLM analyzer)
        filename_only=$(basename "$file_path")
        python3 -c "
import json
with open('$TMP_TEXT', 'r', encoding='utf-8') as f:
    text = f.read()
data = {'source': '$filename_only', 'text': text}
with open('$OUTPUT_DIR/data.json', 'w', encoding='utf-8') as out:
    json.dump(data, out)
"
        rm -f "$TMP_TEXT"
        
        echo -e "${CYAN}  Text extracted: $(wc -c < "$OUTPUT_DIR/data.json") bytes${NC}"
        echo
        echo -e "${CYAN}  [1/2] Analyzing with LLM (WebBot 2.0)...${NC}"
        
        # Run analysis on the extracted text
        if ! webbot2 analyze llm "$OUTPUT_DIR/data.json" --prompt-type webbot 2>&1 | tail -10; then
            echo -e "${RED}  ✗ Analysis failed${NC}"
            read -p "  Press Enter to continue..."
            show_main_menu
            return
        fi
        
        if [ ! -f "$WEBBOT_OUTPUT_DIR/analysis.json" ]; then
            echo -e "${RED}  ✗ Analysis failed - no output found${NC}"
            read -p "  Press Enter to continue..."
            show_main_menu
            return
        fi
        
        cp "$WEBBOT_OUTPUT_DIR/analysis.json" "$OUTPUT_DIR/analysis.json"
        
        echo -e "${CYAN}  [2/2] Generating report...${NC}"
        webbot2 report markdown "$OUTPUT_DIR/analysis.json" --output "$OUTPUT_DIR/report.md" 2>&1 | tail -3
    fi
    
    # Add header to report
    {
        echo "---"
        echo "source_file: $file_path"
        echo "file_type: $ext"
        echo "timestamp: $TIMESTAMP"
        echo "---"
        echo ""
        cat "$OUTPUT_DIR/report.md"
    } > "$OUTPUT_DIR/report.md.tmp"
    mv "$OUTPUT_DIR/report.md.tmp" "$OUTPUT_DIR/report.md"
    
    # Update latest symlink
    ln -sf "$OUTPUT_DIR" $WEBBOT_OUTPUT_DIR/latest
    
    echo
    echo -e "${GREEN}  ✓ Analysis complete!${NC}"
    echo -e "${CYAN}  Folder: $OUTPUT_DIR${NC}"
    echo
    
    # Show the report
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  R E P O R T                                      ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    cat "$OUTPUT_DIR/report.md"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

web_scraper_menu() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              W E B   S C R A P E R                        ${NC}"
    echo -e "${YELLOW}              (Scrapy - fetch any URL)                     ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}  Select mode:${NC}"
    echo "    [1] Single URL      (enter URL manually)"
    echo "    [2] Quick Presets   (popular sites)"
    echo "    [3] Extract Links   (get all URLs from a page)"
    echo "    [4] View History    (previous scrapes - analyze)"
    echo "    [5] View Report     (view saved reports)"
    echo "    [0] Back"
    echo
    echo -ne "${GREEN}  > Choice [0-5]: ${NC}"
    read -r mode
    
    while [[ ! "$mode" =~ ^[0-5]$ ]]; do
        echo -e "${RED}  Invalid. Enter 0-5:${NC}"
        echo -ne "${GREEN}  > Choice [0-5]: ${NC}"
        read -r mode
    done
    
    if [ "$mode" = "0" ]; then
        show_main_menu
        return
    fi
    
    # Add View Report option
    if [ "$mode" = "5" ]; then
        echo
        echo -e "${CYAN}  Scrapes with reports:${NC}"
        echo
        
        folders=()
        i=1
        for dir in $(ls -dt $WEBBOT_OUTPUT_DIR/*/ 2>/dev/null | head -20); do
            name=$(basename "$dir")
            if [ -f "$dir/report.md" ]; then
                echo "  [$i] $name [report]"
                folders+=("$name")
                i=$((i+1))
            fi
        done
        
        if [ ${#folders[@]} -eq 0 ]; then
            echo "  No reports found"
        else
            echo
            echo -ne "${GREEN}  > Select [1-${#folders[@]} or 0 to back]: ${NC}"
            read -r sel
            
            if [[ "$sel" =~ ^[1-9]+$ ]] && [ "$sel" -le ${#folders[@]} ] && [ "$sel" -gt 0 ]; then
                idx=$((sel - 1))
                SELECTED_DIR="$WEBBOT_OUTPUT_DIR/${folders[$idx]}"
                echo
                echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}  R E P O R T: ${folders[$idx]}${NC}"
                echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
                echo
                cat "$SELECTED_DIR/report.md"
            fi
        fi
        read -p "  Press Enter to continue..."
        web_scraper_menu
        return
    fi
    
    if [ "$mode" = "4" ]; then
        # View history - analyze
        echo
        echo -e "${CYAN}  Recent scrapes:${NC}"
        echo
        
        folders=()
        i=1
        for dir in $(ls -dt $WEBBOT_OUTPUT_DIR/*/ 2>/dev/null | head -20); do
            name=$(basename "$dir")
            has_report="[✓report]"
            [ ! -f "$dir/data.json" ] && has_report="[no data]"
            [ -f "$dir/report.md" ] && has_report="[report]"
            [ ! -f "$dir/report.md" ] && [ -f "$dir/analysis.json" ] && has_report="[analysis]"
            [ ! -f "$dir/report.md" ] && [ ! -f "$dir/analysis.json" ] && [ -f "$dir/data.json" ] && has_report="[data]"
            echo "  [$i] $name $has_report"
            folders+=("$name")
            i=$((i+1))
        done
        
        if [ ${#folders[@]} -eq 0 ]; then
            echo "  No scrapes found"
            read -p "  Press Enter to continue..."
            web_scraper_menu
            return
        fi
        
        echo
        echo -ne "${GREEN}  > Select [1-${#folders[@]} or 0 to back]: ${NC}"
        read -r sel
        
        if [[ "$sel" =~ ^[1-9]+$ ]] && [ "$sel" -le ${#folders[@]} ] && [ "$sel" -gt 0 ]; then
            idx=$((sel - 1))
            SELECTED_DIR="$WEBBOT_OUTPUT_DIR/${folders[$idx]}"
            echo
            echo -e "${CYAN}  Analyzing with LLM...${NC}"
            webbot2 analyze llm "$SELECTED_DIR/data.json" --prompt-type webbot 2>&1 | tail -10
            
            if [ -f $WEBBOT_OUTPUT_DIR/analysis.json ]; then
                cp $WEBBOT_OUTPUT_DIR/analysis.json "$SELECTED_DIR/analysis.json"
                
                echo -e "${CYAN}  Generating report...${NC}"
                webbot2 report markdown "$SELECTED_DIR/analysis.json" --output "$SELECTED_DIR/report.md" 2>&1 | tail -3
                
                ln -sf "$SELECTED_DIR" $WEBBOT_OUTPUT_DIR/latest
                
                echo
                echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}  R E P O R T                                      ${NC}"
                echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
                echo
                cat "$SELECTED_DIR/report.md"
            else
                echo -e "${RED}  ✗ Analysis failed - no output${NC}"
            fi
        fi
        read -p "  Press Enter to continue..."
        web_scraper_menu
        return
    fi
    
    if [ "$mode" = "2" ]; then
        # Presets
        show_banner
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}              Q U I C K   P R E S E T S                     ${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${CYAN}  Select a site:${NC}"
        echo "    [1] The Hacker News   (https://thehackernews.com/)"
        echo "    [2] Hacker News       (https://news.ycombinator.com/)"
        echo "    [3] Reddit r/all      (https://old.reddit.com/r/all/)"
        echo "    [4] BBC News         (https://www.bbc.com/news)"
        echo "    [5] Wired            (https://www.wired.com/)"
        echo "    [6] Ars Technica      (https://arstechnica.com/)"
        echo "    [0] Back"
        echo
        echo -ne "${GREEN}  > Choice [0-6]: ${NC}"
        read -r preset
        
        case $preset in
            1) url="https://thehackernews.com/" ;;
            2) url="https://news.ycombinator.com/" ;;
            3) url="https://old.reddit.com/r/all/" ;;
            4) url="https://www.bbc.com/news" ;;
            5) url="https://www.wired.com/" ;;
            6) url="https://arstechnica.com/" ;;
            0) web_scraper_menu; return ;;
            *) url="https://news.ycombinator.com/" ;;
        esac
    elif [ "$mode" = "3" ]; then
        # Extract links
        echo -e "${CYAN}  Enter URL to extract links from:${NC}"
        echo -ne "${GREEN}  > URL: ${NC}"
        read -r url
        url=${url:-"https://news.ycombinator.com/"}
    else
        # Single URL
        echo
        echo -e "${CYAN}  Enter a URL to scrape:${NC}"
        echo -e "${CYAN}  Example: https://news.ycombinator.com/${NC}"
        echo
        echo -ne "${GREEN}  > URL: ${NC}"
        read -r url
        
        url=${url:-"https://news.ycombinator.com/"}
    fi
    
    # Content limit (controls how much text to fetch before processing)
    echo
    echo -e "${CYAN}  Content limit:  (how much text to fetch before processing)${NC}"
    echo "    [1] 10 KB    (~10K chars - fast, cheap for LLM)"
    echo "    [2] 50 KB    (~50K chars - moderate)"
    echo "    [3] 100 KB   (~100K chars - larger articles)"
    echo "    [4] Unlimited"
    echo -ne "${GREEN}  > Choice [1-4]: ${NC}"
    read -r limit_choice
    case $limit_choice in
        1) char_limit=10240 ;;
        2) char_limit=51200 ;;
        3) char_limit=102400 ;;
        *) char_limit=1000000 ;;
    esac
    
    # Export format
    echo
    echo -e "${CYAN}  Export format:${NC}"
    echo "    [1] JSON         (recommended for LLM analysis)"
    echo "    [2] Plain Text   (.txt)"
    echo "    [3] Markdown    (.md)"
    echo -ne "${GREEN}  > Choice [1-3]: ${NC}"
    read -r format_choice
    
    echo
    echo -e "${CYAN}  Fetching: $url${NC}"
    echo
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    query_slug=$(echo "$url" | sed 's|https://||; s|http://||; s|www\.||' | cut -c1-20 | tr -dc 'a-z0-9')
    OUTPUT_DIR=$WEBBOT_OUTPUT_DIR/${TIMESTAMP}_${query_slug}
    mkdir -p "$OUTPUT_DIR"
    
    # Run Scrapy
    scrapy_output=$(scrapy fetch --nolog "$url" 2>&1) || true
    
    if [ -n "$scrapy_output" ]; then
        # Extract links mode
        if [ "$mode" = "3" ]; then
            echo "$scrapy_output" | grep -oE 'href="[^"]*"' | sed 's/href="//;s/"//' | grep -E '^https?://' > "$OUTPUT_DIR/links.txt"
            link_count=$(wc -l < "$OUTPUT_DIR/links.txt")
            echo -e "${GREEN}  ✓ Extracted $link_count links${NC}"
            echo
            echo -e "${YELLOW}  First 20 links:${NC}"
            head -20 "$OUTPUT_DIR/links.txt"
            read -p "  Press Enter to continue..."
            web_scraper_menu
            return
        fi
        
        # Save content based on format
        case $format_choice in
            2)
                # Plain text
                echo "$scrapy_output" > "$OUTPUT_DIR/scraped_content.txt"
                content_for_json=$(python3 -c "import json; print(json.dumps({'source': 'Scrapy', 'url': '$url', 'content': open('$OUTPUT_DIR/scraped_content.txt').read()[:$char_limit]}))")
                echo "$content_for_json" > "$OUTPUT_DIR/data.json"
                ;;
            3)
                # Markdown - convert HTML to basic markdown
                echo "$scrapy_output" | sed 's/<[^>]*>//g' | sed 's/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g' > "$OUTPUT_DIR/scraped_content.md"
                content_for_json=$(python3 -c "import json; print(json.dumps({'source': 'Scrapy', 'url': '$url', 'content': open('$OUTPUT_DIR/scraped_content.md').read()[:$char_limit]}))")
                echo "$content_for_json" > "$OUTPUT_DIR/data.json"
                ;;
            *)
                # JSON (default) - extract text from HTML
                python3 << PYEOF
import json
import re

content = """$scrapy_output"""

# Strip script and style tags first
content = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL | re.IGNORECASE)
content = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.DOTALL | re.IGNORECASE)

# Remove HTML tags
content = re.sub(r'<[^>]+>', ' ', content)

# Decode HTML entities
content = content.replace('&nbsp;', ' ')
content = content.replace('&amp;', '&')
content = content.replace('&lt;', '<')
content = content.replace('&gt;', '>')
content = content.replace('&quot;', '"')
content = content.replace('&#39;', "'")

# Clean up whitespace
content = re.sub(r'\s+', ' ', content)
content = content.strip()

if len(content) > $char_limit:
    content = content[:$char_limit]

data = {"source": "Scrapy Web Scraper", "url": "$url", "content": content}
with open("$OUTPUT_DIR/data.json", "w") as out:
    json.dump(data, out, indent=2)
PYEOF
                ;;
        esac
        
        echo
        echo -e "${GREEN}  ✓ Scraping complete!${NC}"
        echo -e "${CYAN}  Saved: $OUTPUT_DIR/data.json${NC}"
        
        if [ "$format_choice" = "2" ]; then
            echo -e "${CYAN}  Text: $OUTPUT_DIR/scraped_content.txt${NC}"
        elif [ "$format_choice" = "3" ]; then
            echo -e "${CYAN}  Markdown: $OUTPUT_DIR/scraped_content.md${NC}"
        fi
        
        echo
        echo -e "${YELLOW}  Preview (first 500 chars):${NC}"
        echo "---"
        python3 << PYEOF
import json
try:
    with open("$OUTPUT_DIR/data.json") as f:
        d = json.load(f)
    print(d.get('content', '')[:500])
except:
    with open("$OUTPUT_DIR/data.json") as f:
        print(f.read()[:500])
PYEOF
        echo
        echo "---"
        
        # Ask to analyze
        echo
        echo -e "${CYAN}  Analyze this content with LLM?${NC}"
        echo -e "${CYAN}    [1] Yes - analyze for predictions${NC}"
        echo -e "${CYAN}    [2] No - just save${NC}"
        echo -ne "${GREEN}  > Choice [1-2]: ${NC}"
        read -r analyze_choice
        
        if [ "$analyze_choice" = "1" ]; then
            echo -e "${CYAN}  Analyzing with LLM...${NC}"
            
            if ! webbot2 analyze llm "$OUTPUT_DIR/data.json" --prompt-type webbot 2>&1; then
                echo -e "${RED}  ✗ Analysis failed. Fix your API key and try again.${NC}"
                read -p "  Press Enter to continue..."
                web_scraper_menu
                return
            fi
            
            if [ -f "$WEBBOT_OUTPUT_DIR/analysis.json" ]; then
                cp "$WEBBOT_OUTPUT_DIR/analysis.json" "$OUTPUT_DIR/analysis.json"
                
                echo -e "${CYAN}  Generating report...${NC}"
                webbot2 report markdown "$OUTPUT_DIR/analysis.json" --output "$OUTPUT_DIR/report.md" 2>&1 | tail -3
                
                # Add header
                {
                    echo "---"
                    echo "url: $url"
                    echo "timestamp: $TIMESTAMP"
                    echo "source: Scrapy Web Scraper"
                    echo "format: $format_choice"
                    echo "---"
                    echo ""
                    cat "$OUTPUT_DIR/report.md"
                } > "$OUTPUT_DIR/report.md.tmp"
                mv "$OUTPUT_DIR/report.md.tmp" "$OUTPUT_DIR/report.md"
                
                ln -sf "$OUTPUT_DIR" $WEBBOT_OUTPUT_DIR/latest
                
                echo
                echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}  R E P O R T                                      ${NC}"
                echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
                echo
                cat "$OUTPUT_DIR/report.md"
            fi
        fi
    else
        echo -e "${RED}  ✗ Failed to fetch URL${NC}"
    fi
    
    echo
    read -p "  Press Enter to continue..."
    web_scraper_menu
}

show_main_menu