#!/bin/bash
# ============================================================
#   CPU SCHEDULING SIMULATOR - Pure Bash Version
#   Run: chmod +x cpu_scheduling.sh && ./cpu_scheduling.sh
# ============================================================

# Colors
RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
MAGENTA="\033[1;35m"
BLUE="\033[1;34m"
WHITE="\033[1;37m"

# Global arrays
PID=()
ARRIVAL=()
BURST=()
PRIORITY=()
COMPLETION=()
TAT=()
WT=()
RESPONSE=()
REMAINING=()

GANTT_PID=()
GANTT_START=()
GANTT_END=()

N=0
GANTT_SIZE=0

# ════════════════════════════════════════════════════════════
# UTILITY
# ════════════════════════════════════════════════════════════

clear_screen() { clear; }

print_line() {
    local char=$1 len=$2
    local line=""
    for ((i=0; i<len; i++)); do line+="$char"; done
    echo "$line"
}

press_enter() {
    echo -e "${YELLOW}\n  Press Enter to return to menu...${RESET}"
    read -r
}

reset_arrays() {
    PID=(); ARRIVAL=(); BURST=(); PRIORITY=()
    COMPLETION=(); TAT=(); WT=(); RESPONSE=(); REMAINING=()
    GANTT_PID=(); GANTT_START=(); GANTT_END=()
    N=0; GANTT_SIZE=0
}

# ════════════════════════════════════════════════════════════
# INPUT
# ════════════════════════════════════════════════════════════

input_processes() {
    local need_priority=$1
    echo -e "${CYAN}"
    echo -e "  Enter number of processes: ${RESET}\c"
    read -r N

    if [[ ! "$N" =~ ^[0-9]+$ ]] || [ "$N" -le 0 ] || [ "$N" -gt 50 ]; then
        echo -e "${RED}  Invalid number! Must be 1-50.${RESET}"
        press_enter; return 1
    fi

    echo -e "${GREEN}\n  Enter process details:\n${RESET}"

    for ((i=0; i<N; i++)); do
        echo -e "${WHITE}  ── Process $((i+1)) ──────────────────${RESET}"

        echo -e "    PID          : \c"; read -r pid_val
        echo -e "    Arrival Time : \c"; read -r arr_val
        echo -e "    Burst Time   : \c"; read -r bst_val

        PID[$i]=$pid_val
        ARRIVAL[$i]=$arr_val
        BURST[$i]=$bst_val
        REMAINING[$i]=$bst_val
        RESPONSE[$i]=-1

        if [ "$need_priority" -eq 1 ]; then
            echo -e "    Priority     : \c"; read -r pri_val
            PRIORITY[$i]=$pri_val
        else
            PRIORITY[$i]=0
        fi
        echo ""
    done
}

# ════════════════════════════════════════════════════════════
# GANTT CHART
# ════════════════════════════════════════════════════════════

print_gantt() {
    echo -e "${YELLOW}"
    echo -e "  ┌─ GANTT CHART ──────────────────────────────────────────┐"
    echo -e "${RESET}"

    local top="  +"
    local mid="  |"
    local bot="  +"
    local times="  "

    for ((i=0; i<GANTT_SIZE; i++)); do
        local dur=$(( GANTT_END[$i] - GANTT_START[$i] ))
        local w=$(( dur < 3 ? 5 : dur * 2 + 1 ))
        local label="${GANTT_PID[$i]}"
        local llen=${#label}
        local pad=$(( (w - llen) / 2 ))
        local rpad=$(( w - llen - pad ))

        # top/bot border
        local dashes=""
        for ((j=0; j<w; j++)); do dashes+="-"; done
        top+="-${dashes}+"
        bot+="-${dashes}+"

        # label
        local spaces_l="" spaces_r=""
        for ((j=0; j<pad; j++)); do spaces_l+=" "; done
        for ((j=0; j<rpad; j++)); do spaces_r+=" "; done

        if [ "$label" = "IDLE" ]; then
            mid+="\033[1;30m|${spaces_l}${label}${spaces_r}\033[0m"
        else
            # cycle color by hash of pid
            local h=0
            for ((c=0; c<${#label}; c++)); do
                h=$(( h + $(printf '%d' "'${label:$c:1}") ))
            done
            local cidx=$(( h % 6 ))
            local colors=("\033[42m" "\033[46m" "\033[43m" "\033[45m" "\033[44m" "\033[41m")
            mid+="${colors[$cidx]}\033[30m|${spaces_l}${label}${spaces_r}\033[0m"
        fi

        # time label
        local tstr="${GANTT_START[$i]}"
        local tw=$(( w + 1 ))
        times+="${tstr}"
        local tpad=$(( tw - ${#tstr} ))
        for ((j=0; j<tpad; j++)); do times+=" "; done
    done

    times+="${GANTT_END[$((GANTT_SIZE-1))]}"

    echo -e "$top"
    echo -e "$mid|"
    echo -e "$bot"
    echo -e "${CYAN}${times}${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
# RESULTS
# ════════════════════════════════════════════════════════════

print_results() {
    local show_priority=$1

    echo -e "${YELLOW}"
    echo -e "  ┌─ PROCESS DETAILS ──────────────────────────────────────┐"
    echo -e "${RESET}"

    # Header
    if [ "$show_priority" -eq 1 ]; then
        printf "${GREEN}  %-8s %-10s %-10s %-10s %-12s %-14s %-13s %-13s${RESET}\n" \
            "PID" "Arrival" "Burst" "Priority" "Completion" "Turnaround" "Waiting" "Response"
    else
        printf "${GREEN}  %-8s %-10s %-10s %-12s %-14s %-13s %-13s${RESET}\n" \
            "PID" "Arrival" "Burst" "Completion" "Turnaround" "Waiting" "Response"
    fi

    echo -e "  $(print_line '-' 85)"

    local total_wt=0 total_tat=0 total_burst=0

    for ((i=0; i<N; i++)); do
        if [ "$show_priority" -eq 1 ]; then
            printf "  ${WHITE}%-8s${RESET} %-10s %-10s %-10s ${CYAN}%-12s${RESET} ${GREEN}%-14s${RESET} ${YELLOW}%-13s${RESET} ${MAGENTA}%-13s${RESET}\n" \
                "${PID[$i]}" "${ARRIVAL[$i]}" "${BURST[$i]}" "${PRIORITY[$i]}" \
                "${COMPLETION[$i]}" "${TAT[$i]}" "${WT[$i]}" "${RESPONSE[$i]}"
        else
            printf "  ${WHITE}%-8s${RESET} %-10s %-10s ${CYAN}%-12s${RESET} ${GREEN}%-14s${RESET} ${YELLOW}%-13s${RESET} ${MAGENTA}%-13s${RESET}\n" \
                "${PID[$i]}" "${ARRIVAL[$i]}" "${BURST[$i]}" \
                "${COMPLETION[$i]}" "${TAT[$i]}" "${WT[$i]}" "${RESPONSE[$i]}"
        fi
        total_wt=$(( total_wt + WT[$i] ))
        total_tat=$(( total_tat + TAT[$i] ))
        total_burst=$(( total_burst + BURST[$i] ))
    done

    echo -e "  $(print_line '-' 85)"

    # Averages (using awk for float division)
    local avg_wt avg_tat
    avg_wt=$(awk "BEGIN {printf \"%.2f\", $total_wt / $N}")
    avg_tat=$(awk "BEGIN {printf \"%.2f\", $total_tat / $N}")

    local last_end=${GANTT_END[$((GANTT_SIZE-1))]}
    local first_start=${GANTT_START[0]}
    local total_time=$(( last_end - first_start ))
    local util
    util=$(awk "BEGIN {printf \"%.2f\", ($total_burst / $total_time) * 100}")

    echo -e "${YELLOW}"
    echo -e "  ┌─ PERFORMANCE METRICS ──────────────────────────────────┐"
    echo -e "${RESET}"
    echo -e "${GREEN}  ► Average Waiting Time     : ${WHITE}${avg_wt}${RESET}"
    echo -e "${CYAN}  ► Average Turnaround Time  : ${WHITE}${avg_tat}${RESET}"
    echo -e "${YELLOW}  ► CPU Utilization          : ${WHITE}${util}%${RESET}"
    echo -e "${BLUE}  ► Total Processes          : ${WHITE}${N}${RESET}"
    echo -e "${MAGENTA}  ► Total Time Span          : ${WHITE}${total_time} units${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
# SORT by arrival (bubble sort)
# ════════════════════════════════════════════════════════════

sort_by_arrival() {
    for ((i=0; i<N-1; i++)); do
        for ((j=0; j<N-1-i; j++)); do
            if [ "${ARRIVAL[$j]}" -gt "${ARRIVAL[$((j+1))]}" ]; then
                # swap all fields
                for arr in PID ARRIVAL BURST PRIORITY REMAINING RESPONSE; do
                    eval "tmp=\${${arr}[$j]}"
                    eval "${arr}[$j]=\${${arr}[$((j+1))]}"
                    eval "${arr}[$((j+1))]=\$tmp"
                done
            fi
        done
    done
}

# ════════════════════════════════════════════════════════════
# 1. FCFS
# ════════════════════════════════════════════════════════════

run_fcfs() {
    clear_screen
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"
    echo -e "${CYAN}  CPU SCHEDULING  >>  FCFS  (First Come First Serve)${RESET}"
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"

    input_processes 0 || return

    sort_by_arrival

    local time=0
    GANTT_SIZE=0

    for ((i=0; i<N; i++)); do
        if [ "$time" -lt "${ARRIVAL[$i]}" ]; then
            GANTT_PID[$GANTT_SIZE]="IDLE"
            GANTT_START[$GANTT_SIZE]=$time
            GANTT_END[$GANTT_SIZE]=${ARRIVAL[$i]}
            GANTT_SIZE=$(( GANTT_SIZE + 1 ))
            time=${ARRIVAL[$i]}
        fi
        RESPONSE[$i]=$(( time - ARRIVAL[$i] ))
        GANTT_PID[$GANTT_SIZE]="${PID[$i]}"
        GANTT_START[$GANTT_SIZE]=$time
        GANTT_END[$GANTT_SIZE]=$(( time + BURST[$i] ))
        GANTT_SIZE=$(( GANTT_SIZE + 1 ))
        time=$(( time + BURST[$i] ))
        COMPLETION[$i]=$time
        TAT[$i]=$(( COMPLETION[$i] - ARRIVAL[$i] ))
        WT[$i]=$(( TAT[$i] - BURST[$i] ))
    done

    print_gantt
    print_results 0
    press_enter
}

# ════════════════════════════════════════════════════════════
# 2. SJF (Non-Preemptive)
# ════════════════════════════════════════════════════════════

run_sjf() {
    clear_screen
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"
    echo -e "${CYAN}  CPU SCHEDULING  >>  SJF  (Shortest Job First)${RESET}"
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"

    input_processes 0 || return

    local time=0 done=0
    GANTT_SIZE=0
    local completed=()
    for ((i=0; i<N; i++)); do completed[$i]=0; done

    while [ "$done" -lt "$N" ]; do
        local idx=-1 min_burst=999999

        for ((i=0; i<N; i++)); do
            if [ "${completed[$i]}" -eq 0 ] && [ "${ARRIVAL[$i]}" -le "$time" ]; then
                if [ "${BURST[$i]}" -lt "$min_burst" ]; then
                    min_burst=${BURST[$i]}
                    idx=$i
                elif [ "${BURST[$i]}" -eq "$min_burst" ] && [ "$idx" -ge 0 ] && [ "${ARRIVAL[$i]}" -lt "${ARRIVAL[$idx]}" ]; then
                    idx=$i
                fi
            fi
        done

        if [ "$idx" -eq -1 ]; then
            # find next arrival
            local next_arr=999999
            for ((i=0; i<N; i++)); do
                if [ "${completed[$i]}" -eq 0 ] && [ "${ARRIVAL[$i]}" -lt "$next_arr" ]; then
                    next_arr=${ARRIVAL[$i]}
                fi
            done
            GANTT_PID[$GANTT_SIZE]="IDLE"
            GANTT_START[$GANTT_SIZE]=$time
            GANTT_END[$GANTT_SIZE]=$next_arr
            GANTT_SIZE=$(( GANTT_SIZE + 1 ))
            time=$next_arr
            continue
        fi

        RESPONSE[$idx]=$(( time - ARRIVAL[$idx] ))
        GANTT_PID[$GANTT_SIZE]="${PID[$idx]}"
        GANTT_START[$GANTT_SIZE]=$time
        GANTT_END[$GANTT_SIZE]=$(( time + BURST[$idx] ))
        GANTT_SIZE=$(( GANTT_SIZE + 1 ))
        time=$(( time + BURST[$idx] ))
        COMPLETION[$idx]=$time
        TAT[$idx]=$(( COMPLETION[$idx] - ARRIVAL[$idx] ))
        WT[$idx]=$(( TAT[$idx] - BURST[$idx] ))
        completed[$idx]=1
        done=$(( done + 1 ))
    done

    print_gantt
    print_results 0
    press_enter
}

# ════════════════════════════════════════════════════════════
# 3. Priority (Non-Preemptive)
# ════════════════════════════════════════════════════════════

run_priority() {
    clear_screen
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"
    echo -e "${CYAN}  CPU SCHEDULING  >>  PRIORITY  (Non-Preemptive)${RESET}"
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"
    echo -e "${YELLOW}  Note: Lower priority number = Higher priority${RESET}"

    input_processes 1 || return

    local time=0 done=0
    GANTT_SIZE=0
    local completed=()
    for ((i=0; i<N; i++)); do completed[$i]=0; done

    while [ "$done" -lt "$N" ]; do
        local idx=-1 min_pri=999999

        for ((i=0; i<N; i++)); do
            if [ "${completed[$i]}" -eq 0 ] && [ "${ARRIVAL[$i]}" -le "$time" ]; then
                if [ "${PRIORITY[$i]}" -lt "$min_pri" ]; then
                    min_pri=${PRIORITY[$i]}
                    idx=$i
                elif [ "${PRIORITY[$i]}" -eq "$min_pri" ] && [ "$idx" -ge 0 ] && [ "${ARRIVAL[$i]}" -lt "${ARRIVAL[$idx]}" ]; then
                    idx=$i
                fi
            fi
        done

        if [ "$idx" -eq -1 ]; then
            local next_arr=999999
            for ((i=0; i<N; i++)); do
                if [ "${completed[$i]}" -eq 0 ] && [ "${ARRIVAL[$i]}" -lt "$next_arr" ]; then
                    next_arr=${ARRIVAL[$i]}
                fi
            done
            GANTT_PID[$GANTT_SIZE]="IDLE"
            GANTT_START[$GANTT_SIZE]=$time
            GANTT_END[$GANTT_SIZE]=$next_arr
            GANTT_SIZE=$(( GANTT_SIZE + 1 ))
            time=$next_arr
            continue
        fi

        RESPONSE[$idx]=$(( time - ARRIVAL[$idx] ))
        GANTT_PID[$GANTT_SIZE]="${PID[$idx]}"
        GANTT_START[$GANTT_SIZE]=$time
        GANTT_END[$GANTT_SIZE]=$(( time + BURST[$idx] ))
        GANTT_SIZE=$(( GANTT_SIZE + 1 ))
        time=$(( time + BURST[$idx] ))
        COMPLETION[$idx]=$time
        TAT[$idx]=$(( COMPLETION[$idx] - ARRIVAL[$idx] ))
        WT[$idx]=$(( TAT[$idx] - BURST[$idx] ))
        completed[$idx]=1
        done=$(( done + 1 ))
    done

    print_gantt
    print_results 1
    press_enter
}

# ════════════════════════════════════════════════════════════
# 4. Round Robin
# ════════════════════════════════════════════════════════════

run_rr() {
    clear_screen
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"
    echo -e "${CYAN}  CPU SCHEDULING  >>  ROUND ROBIN${RESET}"
    echo -e "${CYAN}$(print_line '=' 65)${RESET}"

    echo -e "${CYAN}\n  Enter Time Quantum: ${RESET}\c"
    read -r QUANTUM

    input_processes 0 || return

    sort_by_arrival

    local time=0 done=0
    GANTT_SIZE=0
    local completed=()
    local in_queue=()
    for ((i=0; i<N; i++)); do completed[$i]=0; in_queue[$i]=0; REMAINING[$i]=${BURST[$i]}; done

    # Queue as array
    local queue=()

    # Enqueue processes that arrive at time 0
    for ((i=0; i<N; i++)); do
        if [ "${ARRIVAL[$i]}" -le "$time" ]; then
            queue+=($i)
            in_queue[$i]=1
        fi
    done

    local safety=0
    while [ "$done" -lt "$N" ] && [ "$safety" -lt 100000 ]; do
        safety=$(( safety + 1 ))

        if [ "${#queue[@]}" -eq 0 ]; then
            # CPU idle - find next arrival
            local next_arr=999999
            for ((i=0; i<N; i++)); do
                if [ "${completed[$i]}" -eq 0 ] && [ "${ARRIVAL[$i]}" -lt "$next_arr" ]; then
                    next_arr=${ARRIVAL[$i]}
                fi
            done
            if [ "$next_arr" -eq 999999 ]; then break; fi
            GANTT_PID[$GANTT_SIZE]="IDLE"
            GANTT_START[$GANTT_SIZE]=$time
            GANTT_END[$GANTT_SIZE]=$next_arr
            GANTT_SIZE=$(( GANTT_SIZE + 1 ))
            time=$next_arr
            for ((i=0; i<N; i++)); do
                if [ "${completed[$i]}" -eq 0 ] && [ "${ARRIVAL[$i]}" -le "$time" ] && [ "${in_queue[$i]}" -eq 0 ]; then
                    queue+=($i)
                    in_queue[$i]=1
                fi
            done
            continue
        fi

        # Dequeue front
        local idx=${queue[0]}
        queue=("${queue[@]:1}")

        # Set response time on first execution
        if [ "${RESPONSE[$idx]}" -eq -1 ]; then
            RESPONSE[$idx]=$(( time - ARRIVAL[$idx] ))
        fi

        # Execute for min(quantum, remaining)
        local exec=$QUANTUM
        if [ "${REMAINING[$idx]}" -lt "$QUANTUM" ]; then
            exec=${REMAINING[$idx]}
        fi

        # Add to gantt (merge if same pid continues)
        if [ "$GANTT_SIZE" -gt 0 ] && \
           [ "${GANTT_PID[$((GANTT_SIZE-1))]}" = "${PID[$idx]}" ] && \
           [ "${GANTT_END[$((GANTT_SIZE-1))]}" -eq "$time" ]; then
            GANTT_END[$((GANTT_SIZE-1))]=$(( time + exec ))
        else
            GANTT_PID[$GANTT_SIZE]="${PID[$idx]}"
            GANTT_START[$GANTT_SIZE]=$time
            GANTT_END[$GANTT_SIZE]=$(( time + exec ))
            GANTT_SIZE=$(( GANTT_SIZE + 1 ))
        fi

        time=$(( time + exec ))
        REMAINING[$idx]=$(( REMAINING[$idx] - exec ))

        # Enqueue newly arrived processes
        for ((i=0; i<N; i++)); do
            if [ "${completed[$i]}" -eq 0 ] && [ "${ARRIVAL[$i]}" -le "$time" ] && [ "${in_queue[$i]}" -eq 0 ]; then
                queue+=($i)
                in_queue[$i]=1
            fi
        done

        if [ "${REMAINING[$idx]}" -gt 0 ]; then
            queue+=($idx)
        else
            COMPLETION[$idx]=$time
            TAT[$idx]=$(( COMPLETION[$idx] - ARRIVAL[$idx] ))
            WT[$idx]=$(( TAT[$idx] - BURST[$idx] ))
            completed[$idx]=1
            done=$(( done + 1 ))
        fi
    done

    print_gantt
    print_results 0
    press_enter
}

# ════════════════════════════════════════════════════════════
# MAIN MENU
# ════════════════════════════════════════════════════════════

show_menu() {
    clear_screen
    echo -e "${CYAN}"
    print_line '═' 65
    echo "       ██████╗██████╗ ██╗   ██╗    ███████╗ ██████╗██╗  ██╗"
    echo "      ██╔════╝██╔══██╗██║   ██║    ██╔════╝██╔════╝██║  ██║"
    echo "      ██║     ██████╔╝██║   ██║    ███████╗██║     ███████║"
    echo "      ██║     ██╔═══╝ ██║   ██║    ╚════██║██║     ██╔══██║"
    echo "      ╚██████╗██║     ╚██████╔╝    ███████║╚██████╗██║  ██║"
    echo "       ╚═════╝╚═╝      ╚═════╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝"
    print_line '═' 65
    echo -e "${RESET}"
    echo -e "${YELLOW}       PROCESS SCHEDULING SIMULATOR  |  BASH VERSION${RESET}"
    echo -e "${CYAN}$(print_line '─' 65)${RESET}"
    echo -e "${GREEN}\n    Select Scheduling Algorithm:\n${RESET}"
    echo -e "${WHITE}      [ 1 ]  ${RESET}FCFS           - First Come First Serve"
    echo -e "${WHITE}      [ 2 ]  ${RESET}SJF            - Shortest Job First (Non-Preemptive)"
    echo -e "${WHITE}      [ 3 ]  ${RESET}PRIORITY       - Priority Scheduling (Non-Preemptive)"
    echo -e "${WHITE}      [ 4 ]  ${RESET}ROUND ROBIN    - Round Robin (with Time Quantum)"
    echo -e "${RED}\n      [ 5 ]  EXIT${RESET}"
    echo -e "${CYAN}\n$(print_line '─' 65)${RESET}"
    echo -e "${CYAN}    Enter your choice: ${RESET}\c"
}

# ════════════════════════════════════════════════════════════
# ENTRY POINT
# ════════════════════════════════════════════════════════════

while true; do
    reset_arrays
    show_menu
    read -r choice

    case $choice in
        1) run_fcfs     ;;
        2) run_sjf      ;;
        3) run_priority ;;
        4) run_rr       ;;
        5)
            echo -e "${GREEN}\n  Exiting CPU Scheduler. Goodbye!\n${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}\n  Invalid choice!${RESET}"
            sleep 1
            ;;
    esac
done
