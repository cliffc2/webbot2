#!/bin/bash

set -e

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
    
    echo -e "${CYAN}"
    cat << 'EOF'
 ..          ..                       s                   
  kas                         .  YS"       .  MS"                      :8      .--~*jcc.    
 88x.   .a.   .s.             `t888       `t888              k.      .88     lC     988Lc  
'8888X.x888:.x888       .p     8888   .    8888   .    ...ue888b    :888ooo d888b   `8888> 
 `8888  888X '888k    88888.   9888..artB  988B..eLL8  888R Y888S -*c888888 ?8888>  98888F 
  X888  888X  888X :888'8888.  9888  888C  9888  888H  888R O888>   8888     "**"  x88888~ 
  X888  888X  888X d888 '88%"  9888  888L  9888  888I  888R N888>   8888          d8888*`  
  X888  888X  888X 8888.+"     9888  888I  9888  888G  888R I888>   8888        emc"`   : 
 .X888  888X. 888~ 8888L       9888  888F  9888  888H u8888cJ888   .8888Lu=   :?.....  cgf 
 `%88%``"*888J"    '8888c. .+ .8888  888" .8888  888"  "*888*B"    ^T888*    C""8888888888 
   `~     `"        "88888%    `%888*%"    `%888*%"      'Y"         'Y"     8:  "cliffc2  
                      "YS'        "`          "`                             ""    "**"` 
EOF

    echo -e "${NC}"
    echo
    echo -e "${GREEN}       Predictive Linguistics CLI${NC}"
    echo -e "${YELLOW}   Thanks @clif_high & @spirittechie${NC}"
    echo
}

show_main_menu() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                    M A I N   M E N U                       ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}  Select an option:${NC}"
    echo
    echo -e "${CYAN}    [1] Quick Analysis     (Twitter only - fastest)${NC}"
    echo -e "${CYAN}    [2] Run Pipeline      (choose platforms & analyze)${NC}"
    echo -e "${CYAN}    [3] Scrape Data       (just fetch data)${NC}"
    echo -e "${CYAN}    [4] Analyze Data      (run LLM analysis)${NC}"
    echo -e "${CYAN}    [5] Generate Reports  (Markdown/JSON/Audio)${NC}"
    echo -e "${CYAN}    [6] View Results     (check output files)${NC}"
    echo -e "${CYAN}    [7] Configuration    (API keys, models)${NC}"
    echo -e "${CYAN}    [0] Exit                                           ${NC}"
    echo
    echo -ne "${GREEN}  Enter choice [0-7]: ${NC}"
    read -r choice
    
    while [[ ! "$choice" =~ ^[0-7]$ ]]; do
        echo -e "${RED}  Invalid. Enter 0-7:${NC}"
        echo -ne "${GREEN}  Enter choice [0-7]: ${NC}"
        read -r choice
    done
    
    case $choice in
        1) quick_analysis ;;
        2) run_full_pipeline ;;
        3) scrape_data ;;
        4) analyze_data ;;
        5) generate_reports ;;
        6) view_output ;;
        7) configuration ;;
        3) analyze_data ;;
        4) generate_reports ;;
        5) view_output ;;
        6) configuration ;;
        7) show_help ;;
        0) echo -e "\n${GREEN}Goodbye!${NC}\n"; exit 0 ;;
        *) show_main_menu ;;
    esac
}

quick_analysis() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              Q U I C K   A N A L Y S I S                 ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}  One-shot Twitter analysis (defaults applied)${NC}"
    echo
    echo -ne "${GREEN}  > Search query: ${NC}"
    read -r query
    query=${query:-"future leaks"}
    
    echo -ne "${GREEN}  > Items to fetch [25]: ${NC}"
    read -r limit
    limit=${limit:-25}
    
    # Create timestamped output directory
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_DIR=~/.predictive-ling/output/$TIMESTAMP
    mkdir -p "$OUTPUT_DIR"
    
    echo
    echo -e "${GREEN}  Running... Twitter scrape + analyze + report${NC}"
    echo -e "${CYAN}  Output: $OUTPUT_DIR${NC}"
    echo
    
    # Scrape Twitter - save to timestamped dir
    echo -e "${CYAN}  [1/3] Scraping Twitter...${NC}"
    predictive-ling scrape twitter --query "$query" --limit "$limit" 2>&1 | tail -3
    
    # Get latest file and copy to timestamped dir
    twitter_file=$(ls -t ~/.predictive-ling/output/twitter_*.json 2>/dev/null | head -1)
    cp "$twitter_file" "$OUTPUT_DIR/data.json" 2>/dev/null
    
    if [ -n "$twitter_file" ] && [ -f "$twitter_file" ]; then
        echo -e "${CYAN}  [2/3] Analyzing with LLM...${NC}"
        cp "$twitter_file" /tmp/analyze_input.json
        predictive-ling analyze llm /tmp/analyze_input.json --prompt-type event_stream 2>&1 | tail -10
        
        # Copy analysis to timestamped dir
        if [ -f ~/.predictive-ling/output/analysis.json ]; then
            cp ~/.predictive-ling/output/analysis.json "$OUTPUT_DIR/analysis.json"
        fi
        
        echo -e "${CYAN}  [3/3] Generating report...${NC}"
        
        if [ -f "$OUTPUT_DIR/analysis.json" ]; then
            predictive-ling report markdown "$OUTPUT_DIR/analysis.json" --output "$OUTPUT_DIR/report.md" 2>&1 | tail -5
        fi
    else
        echo -e "${RED}  No data scraped${NC}"
    fi
    
    # Update latest symlink
    ln -sf "$OUTPUT_DIR" ~/.predictive-ling/output/latest
    
    echo
    echo -e "${GREEN}  ✓ Quick analysis complete!${NC}"
    echo -e "${CYAN}  Folder: $OUTPUT_DIR${NC}"
    echo -e "${CYAN}  Latest: ~/.predictive-ling/output/latest${NC}"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

run_full_pipeline() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              F U L L   P I P E L I N E                      ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  Pipeline mode:${NC}"
    echo "    [1] Twitter only     (fastest - recommended)"
    echo "    [2] Twitter + Reddit (Community discussions)"
    echo "    [3] All platforms   (full coverage)"
    echo -ne "${GREEN}  > Mode [1-3]: ${NC}"
    read -r mode
    
    while [[ ! "$mode" =~ ^[1-3]$ ]]; do
        echo -e "${RED}  Invalid. Enter 1-3:${NC}"
        echo -ne "${GREEN}  > Mode [1-3]: ${NC}"
        read -r mode
    done
    
    echo
    echo -e "${CYAN}  Search query${NC}"
    echo -e "${CYAN}    (e.g., future leaks, AI consciousness, bitcoin)${NC}"
    echo -ne "${GREEN}  > Query: ${NC}"
    read -r query
    query=${query:-"future leaks"}
    
    echo
    echo -ne "${GREEN}  > Limit: ${NC}"
    read -r limit
    limit=${limit:-25}
    
    echo
    echo -e "${YELLOW}  Running pipeline...${NC}"
    echo "    Query: $query"
    echo "    Limit: $limit"
    echo
    
    case $mode in
        1)
            echo -e "${GREEN}  [Twitter only]${NC}"
            predictive-ling scrape twitter --query "$query" --limit "$limit"
            twitter_file=$(ls -t ~/.predictive-ling/output/twitter_*.json 2>/dev/null | head -1)
            if [ -n "$twitter_file" ]; then
                predictive-ling analyze llm "$twitter_file" --prompt-type event_stream 2>&1 | tail -20
                predictive-ling report markdown ~/.predictive-ling/output/analysis.json 2>&1 | tail -10
            fi
            ;;
        2)
            echo -e "${GREEN}  [Twitter + Reddit]${NC}"
            predictive-ling scrape twitter --query "$query" --limit "$limit"
            predictive-ling scrape reddit --subreddit all --query "$query" --limit "$limit"
            ;;
        3)
            echo -e "${GREEN}  [Full pipeline]${NC}"
            predictive-ling run-all --query "$query" --limit "$limit" 2>&1 | tail -30
            ;;
    esac
    
    echo
    echo -e "${GREEN}  ✓ Pipeline complete!${NC}"
    echo -e "${CYAN}  Results: ~/.predictive-ling/output/${NC}"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

scrape_data() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              S C R A P E   D A T A                        ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  Select platform:${NC}"
    echo "    [1] Twitter/X   (recommended - active discussions)"
    echo "    [2] Reddit     (forums & communities)"
    echo "    [3] YouTube    (video comments)"
    echo "    [4] Run full pipeline   (all above)"
    echo "    [0] Back"
    echo -ne "${GREEN}  > Platform [0-4]: ${NC}"
    read -r platform
    
    while [[ ! "$platform" =~ ^[0-4]$ ]]; do
        echo -e "${RED}  Invalid. Enter 0-4:${NC}"
        echo -ne "${GREEN}  > Platform [0-4]: ${NC}"
        read -r platform
    done
    
    if [ "$platform" = "0" ]; then
        show_main_menu
        return
    fi
    
    echo
    echo -e "${CYAN}  Search query${NC}"
    echo -ne "${GREEN}  > Query: ${NC}"
    read -r query
    query=${query:-"future leaks"}
    
    echo
    echo -ne "${GREEN}  > Limit: ${NC}"
    read -r limit
    limit=${limit:-25}
    
    case $platform in
        1)
            echo -e "${GREEN}  Scraping Twitter...${NC}"
            predictive-ling scrape twitter --query "$query" --limit "$limit"
            ;;
        2)
            echo -e "${CYAN}  Subreddit [default: all]${NC}"
            echo -ne "${GREEN}  > Subreddit: ${NC}"
            read -r subreddit
            subreddit=${subreddit:-all}
            echo -e "${GREEN}  Scraping Reddit...${NC}"
            predictive-ling scrape reddit --subreddit "$subreddit" --query "$query" --limit "$limit"
            ;;
        3)
            echo -e "${GREEN}  Scraping YouTube...${NC}"
            predictive-ling scrape youtube --query "$query" --limit "$limit"
            ;;
        4)
            echo -e "${GREEN}  Running full pipeline...${NC}"
            predictive-ling run-all --query "$query" --limit "$limit" 2>&1 | head -30
            ;;
    esac
    
    echo
    echo -e "${GREEN}  ✓ Scraping complete!${NC}"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

analyze_data() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              A N A L Y Z E   D A T A                        ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  Select LLM model:${NC}"
    echo "    [1] nvidia/nemotron-3-super-120b:a12b  (Largest)"
    echo "    [2] minimax-minimax-m2.5:free          (Balanced)"
    echo "    [3] openrouter/free                   (Auto)"
    echo "    [4] google/gemma-3-4b-it:free         (Fast)"
    echo "    [5] Use mock data                    (Skip API)"
    echo -ne "${GREEN}  > Model [1-5]: ${NC}"
    read -r model_choice
    
    while [[ ! "$model_choice" =~ ^[1-5]$ ]]; do
        echo -e "${RED}  Invalid. Enter 1-5:${NC}"
        echo -ne "${GREEN}  > Model [1-5]: ${NC}"
        read -r model_choice
    done
    
    case $model_choice in
        1) model="nvidia/nemotron-3-super-120b-a12b:free" ;;
        2) model="minimax/minimax-m2.5:free" ;;
        3) model="openrouter/free" ;;
        4) model="google/gemma-3-4b-it:free" ;;
        5) model="skip" ;;
        *) model="nvidia/nemotron-3-super-120b-a12b:free" ;;
    esac
    
    echo
    echo -e "${CYAN}  Select prompt type:${NC}"
    echo "    [1] event_stream (General patterns)"
    echo "    [2] globe_pop    (Global populations)"
    echo "    [3] us_pop       (US-specific)"
    echo -ne "${GREEN}  > Prompt [1-3]: ${NC}"
    read -r prompt_choice
    
    while [[ ! "$prompt_choice" =~ ^[1-3]$ ]]; do
        echo -e "${RED}  Invalid. Enter 1-3:${NC}"
        echo -ne "${GREEN}  > Prompt [1-3]: ${NC}"
        read -r prompt_choice
    done
    
    case $prompt_choice in
        1) prompt_type="event_stream" ;;
        2) prompt_type="globe_pop" ;;
        3) prompt_type="us_pop" ;;
        *) prompt_type="event_stream" ;;
    esac
    
    echo
    echo -e "${CYAN}  Available data files:${NC}"
    
    json_files=$(ls -t ~/.predictive-ling/output/*.json 2>/dev/null)
    total_files=$(echo "$json_files" | wc -l | tr -d ' ')
    
    if [ "$total_files" -gt 0 ] 2>/dev/null; then
        i=1
        for f in $json_files; do
            echo -e "${CYAN}    [$i] $(basename "$f")${NC}"
            i=$((i+1))
        done
    else
        echo -e "${CYAN}    No files found${NC}"
    fi
    echo
    
    if [ "$total_files" -gt 0 ] 2>/dev/null; then
        echo -ne "${GREEN}  > File [1-${total_files}]: ${NC}"
        read -r file_choice
        
        while [[ ! "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total_files" ]; do
            echo -e "${RED}  Invalid. Enter 1-${total_files}:${NC}"
            echo -ne "${GREEN}  > File [1-${total_files}]: ${NC}"
            read -r file_choice
        done
        
        input_file=$(echo "$json_files" | sed -n "${file_choice}p")
    else
        input_file=""
    fi
    
    if [ "$model" = "skip" ]; then
        echo -e "${GREEN}  Analyzing with mock data...${NC}"
    else
        echo -e "${GREEN}  Analyzing with $model...${NC}"
    fi
    
    if [ -n "$input_file" ] && [ -f "$input_file" ]; then
        predictive-ling analyze llm "$input_file" --prompt-type "$prompt_type" 2>&1
    else
        echo -e "${RED}  ✗ No valid input file found. Run scrape first.${NC}"
    fi
    
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Analysis complete!                                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

generate_reports() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ║         G E N E R A T E   R E P O R T S              ║${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  Select report format:                                  ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                         ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [1] ▶ Markdown Report (.md)                         ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [2] ▶ JSON Report (.json)                          ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [3] ▶ Audio/TTS (.mp3)                             ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [4] ▶ All Formats                                  ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                         ${CYAN}│${NC}"
    echo -e "${CYAN}  └─────────────────────────────────────────────────────────┘${NC}"
    echo
    echo -ne "${GREEN}  ➜ Enter choice [1-4]: ${NC}"
    read -r format
    
    while [[ ! "$format" =~ ^[1-4]$ ]]; do
        echo -e "${RED}  ✗ Invalid choice. Please enter 1, 2, 3, or 4:${NC}"
        echo -ne "${GREEN}  ➜ Enter choice [1-4]: ${NC}"
        read -r format
    done
    
    echo
    echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  Available analysis files:                            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                         ${CYAN}│${NC}"
    
    analysis_files=$(ls -t ~/.predictive-ling/output/analysis*.json 2>/dev/null)
    total_afiles=$(echo "$analysis_files" | wc -l | tr -d ' ')
    
    if [ "$total_afiles" -gt 0 ] 2>/dev/null; then
        i=1
        for f in $analysis_files; do
            echo -e "${CYAN}  │${NC}    [$i] $(basename "$f")${CYAN}│${NC}"
            i=$((i+1))
        done
    else
        echo -e "${CYAN}  │${NC}    No analysis files - run pipeline first             ${CYAN}│${NC}"
    fi
    echo -e "${CYAN}  └─────────────────────────────────────────────────────────┘${NC}"
    echo
    
    if [ "$total_afiles" -gt 0 ] 2>/dev/null; then
        echo -ne "${GREEN}  ➜ Select file [1-${total_afiles}]: ${NC}"
        read -r file_choice
        
        while [[ ! "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total_afiles" ]; do
            echo -e "${RED}  ✗ Invalid. Enter 1-${total_afiles}:${NC}"
            echo -ne "${GREEN}  ➜ Select file [1-${total_afiles}]: ${NC}"
            read -r file_choice
        done
        
        input_file=$(echo "$analysis_files" | sed -n "${file_choice}p")
    else
        input_file=""
    fi
    
    if [ -z "$input_file" ] || [ ! -f "$input_file" ]; then
        echo -e "${RED}  ✗ File not found or no files available${NC}"
        read -p "  Press Enter to continue..."
        show_main_menu
        return
    fi
    
    case $format in
        1)
            echo -e "\n${GREEN}Generating Markdown report...${NC}"
            predictive-ling report markdown "$input_file"
            ;;
        2)
            echo -e "\n${GREEN}Generating JSON report...${NC}"
            predictive-ling report json "$input_file"
            ;;
        3)
            echo -e "\n${CYAN}Select language:${NC}"
            echo "1) English"
            echo "2) Spanish" 
            echo "3) French"
            echo "4) German"
            echo -ne "${GREEN}Select [1-4]: ${NC}"
            read -r lang_choice
            case $lang_choice in
                1) lang="en" ;;
                2) lang="es" ;;
                3) lang="fr" ;;
                4) lang="de" ;;
                *) lang="en" ;;
            esac
            echo -e "\n${GREEN}Generating Audio report...${NC}"
            predictive-ling report audio "$input_file" --lang "$lang"
            ;;
        4)
            echo -e "\n${GREEN}Generating all reports...${NC}"
            predictive-ling report markdown "$input_file"
            predictive-ling report json "$input_file"
            predictive-ling report audio "$input_file" --lang "en"
            ;;
        *)
            show_main_menu
            ;;
    esac
    
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Reports generated successfully!                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}  Output location: ${YELLOW}~/.predictive-ling/output/${NC}"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

view_output() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ║           V I E W   O U T P U T   F I L E S          ║${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  Output Directory: ~/.predictive-ling/output/            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                            ${CYAN}│${NC}"
    
    output_files=$(ls -t ~/.predictive-ling/output/ 2>/dev/null)
    total_files=$(echo "$output_files" | wc -l | tr -d ' ')
    
    if [ "$total_files" -gt 0 ] 2>/dev/null; then
        i=1
        for f in $output_files; do
            echo -e "${CYAN}  │${NC}    [$i] $(basename "$f")${CYAN}│${NC}"
            i=$((i+1))
        done
    else
        echo -e "${CYAN}  │${NC}    No files found                                          ${CYAN}│${NC}"
        total_files=0
    fi
    echo -e "${CYAN}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  Quick Actions:                                           ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [1] ▶ View report.md                                   ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [2] ▶ View report.json                                  ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [3] ▶ View latest analysis.json                         ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [4] ▶ Open in Finder                                     ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [5] ▶ Open report.md in terminal                        ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [0] ▶ Back to main menu                                 ${CYAN}│${NC}"
    echo -e "${CYAN}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo
    echo -ne "${GREEN}  ➜ Select option [0-5]: ${NC}"
    read -r choice
    
    while [[ ! "$choice" =~ ^[0-5]$ ]]; do
        echo -e "${RED}  ✗ Invalid. Enter 0-5:${NC}"
        echo -ne "${GREEN}  ➜ Select option [0-5]: ${NC}"
        read -r choice
    done
    
    case $choice in
        1)
            echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  ║                    R E P O R T . M D                    ║${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"
            cat ~/.predictive-ling/output/report.md 2>/dev/null || echo "File not found"
            ;;
        2)
            echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  ║                   R E P O R T . J S O N                 ║${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"
            cat ~/.predictive-ling/output/report.json 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "File not found"
            ;;
        3)
            echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  ║                 A N A L Y S I S . J S O N              ║${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"
            cat ~/.predictive-ling/output/analysis.json 2>/dev/null | python3 -m json.tool 2>/dev/null | head -80 || echo "File not found"
            ;;
        4)
            open ~/.predictive-ling/output/
            echo -e "${GREEN}  ✓ Opened Finder at ~/.predictive-ling/output/${NC}"
            ;;
        5)
            echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  ║                   R E P O R T . M D                    ║${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"
            tail -30 ~/.predictive-ling/output/report.md 2>/dev/null || echo "File not found"
            ;;
        0)
            show_main_menu
            ;;
    esac
    
    echo
    read -p "  Press Enter to continue..."
    view_output
}

configuration() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ║         C O N F I G U R A T I O N                  ║${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  Current Settings:                                      ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                            ${CYAN}│${NC}"
    
    if [ -f ~/.predictive-ling.env ]; then
        while IFS= read -r line; do
            echo -e "${CYAN}  │${NC}    $line${CYAN}                                          │${NC}"
        done < ~/.predictive-ling.env
    else
        echo -e "${CYAN}  │${NC}    No config found (run setup)                           ${CYAN}│${NC}"
    fi
    echo -e "${CYAN}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  Options:                                                 ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [1] ▶ Set OpenRouter API Key                          ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [2] ▶ Set default LLM model                          ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [3] ▶ View available free models                     ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [4] ▶ Test API connection                            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    [0] ▶ Back to main menu                             ${CYAN}│${NC}"
    echo -e "${CYAN}  └─────────────────────────────────────────────────────────────┘${NC}"
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
                echo "OPENROUTER_API_KEY=$api_key" > ~/.predictive-ling.env
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
            echo "OPENROUTER_MODEL=$model" >> ~/.predictive-ling.env
            echo -e "${GREEN}Default model set to: $model${NC}"
            ;;
        3)
            show_free_models
            ;;
        4)
            echo -e "\n${GREEN}Testing API key...${NC}"
            if [ -f ~/.predictive-ling.env ]; then
                source ~/.predictive-ling.env
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
            echo "$alias_name|$alias_query|$alias_limit" >> ~/.predictive-ling_aliases
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

show_free_models() {
    show_banner
    echo -e "${YELLOW}=== AVAILABLE FREE LLM MODELS ===${NC}\n"
    
    if [ -f ~/.predictive-ling.env ]; then
        source ~/.predictive-ling.env
        if [ -n "$OPENROUTER_API_KEY" ]; then
            echo -e "${GREEN}Fetching models from OpenRouter...${NC}\n"
            curl -s "https://openrouter.ai/api/v1/models" -H "Authorization: Bearer $OPENROUTER_API_KEY" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print('Model ID'.ljust(60), 'Pricing')
print('-' * 80)
for m in d.get('data',[])[:30]:
    price = m.get('pricing',{})
    if price.get('prompt') == '0':
        print(m['id'].ljust(60), 'FREE')
" 2>/dev/null | head -20
        else
            echo "No API key configured. Showing default models:"
        fi
    fi
    
    echo -e "\n${CYAN}Recommended free models:${NC}"
    echo "1) nvidia/nemotron-3-super-120b-a12b:free - Largest, slowest"
    echo "2) minimax/minimax-m2.5:free - Good balance"
    echo "3) openrouter/free - Auto-select"
    echo "4) google/gemma-3-4b-it:free - Smaller, faster"
    echo "5) stepfun/step-3.5-flash:free - Fast"
    
    echo
    read -p "Press Enter to continue..."
    configuration
}

show_help() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ║              H E L P   &   I N F O                  ║${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${CYAN}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  ┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  │  WHAT IT DOES:                                      │${NC}"
    echo -e "${CYAN}  │${NC}  │  • Scrapes Twitter, Reddit, YouTube, News          │${NC}"
    echo -e "${CYAN}  │${NC}  │  • Detects metaphors, archetypes, emotional spikes │${NC}"
    echo -e "${CYAN}  │${NC}  │  • Finds \"future leak\" indicators                  │${NC}"
    echo -e "${CYAN}  │${NC}  └─────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${CYAN}  │${NC}  ┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  │  HOW IT WORKS (NO API KEYS NEEDED):                 │${NC}"
    echo -e "${CYAN}  │${NC}  │  • Twitter:   Nitter (nitter.net)                   │${NC}"
    echo -e "${CYAN}  │${NC}  │  • Reddit:    Old Reddit (old.reddit.com)           │${NC}"
    echo -e "${CYAN}  │${NC}  │  • YouTube:   Invidious (yewtu.be)                  │${NC}"
    echo -e "${CYAN}  │${NC}  │  • News:      RSS feeds (BBC, Reuters)              │${NC}"
    echo -e "${CYAN}  │${NC}  └─────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${CYAN}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${YELLOW}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}  │${NC}  FREE LLM OPTIONS:                                   ${YELLOW}│${NC}"
    echo -e "${YELLOW}  │${NC}  • OpenRouter: https://openrouter.ai/keys            ${YELLOW}│${NC}"
    echo -e "${YELLOW}  │${NC}  • Local:       brew install ollama                  ${YELLOW}│${NC}"
    echo -e "${YELLOW}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${GREEN}  Example Queries:${NC}"
    echo "    • future leaks / future predictions"
    echo "    • AI consciousness / artificial general intelligence"
    echo "    • economic shift / market trends"
    echo "    • political unrest / protests"
    echo "    • emerging technology"
    echo
    
    echo -e "${CYAN}  Output: ${GREEN}~/.predictive-ling/output/${NC}"
    echo
    read -p "  Press Enter to continue..."
    show_main_menu
}

show_main_menu