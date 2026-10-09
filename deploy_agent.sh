#!/bin/bash

PROJECT_NAME=""
BASE_DIR=""
ARCHIVE_NAME=""

cleanup_on_interrupt() {
    echo ""
    echo "[!] Deployment interrupted by signal (Ctrl+C / Ctrl+Z). Archiving..."
    if [ -n "$BASE_DIR" ] && [ -d "$BASE_DIR" ]; then
        ARCHIVE_NAME="${BASE_DIR}_archive.zip"
        echo "[*] Zipping incomplete project $BASE_DIR -> $ARCHIVE_NAME"
        zip -r "$ARCHIVE_NAME" "$BASE_DIR" >/dev/null 2>&1
        if [ -f "$ARCHIVE_NAME" ]; then
            echo "[✓] Archived incomplete project to $ARCHIVE_NAME"
        fi
        echo "[*] Cleaning up incomplete directory $BASE_DIR"
        rm -rf "$BASE_DIR"
        echo "[✓] Cleaned up. Workspace not cluttered."
    else
        echo "[*] No directory to archive yet."
    fi
    trap - SIGINT SIGTSTP
    exit 1
}

trap cleanup_on_interrupt SIGINT SIGTSTP

check_prereqs() {
    echo "=== Pre-flight checks ==="
    if ! command -v python3 >/dev/null 2>&1; then
        echo "[X] python3 not found. Install python3."
        exit 1
    fi
    echo "[✓] python3 $(python3 --version 2>&1)"
    if ! command -v zip >/dev/null 2>&1; then
        echo "[X] zip not found. Install zip (sudo apt install zip)."
        exit 1
    fi
    echo "[✓] zip found"
}

deploy_project() {
    check_prereqs
    read -p "Enter project directory name (e.g., Deng): " input_name
    if [ -z "$input_name" ]; then
        echo "[X] Name cannot be empty."
        return
    fi
    PROJECT_NAME="attendance_tracker_${input_name}"
    BASE_DIR="$PROJECT_NAME"
    ARCHIVE_NAME="${BASE_DIR}_archive.zip"

    if [ -d "$BASE_DIR" ]; then
        read -p "Directory $BASE_DIR already exists. Overwrite? [y/N]: " ow
        if [[ "$ow" != "y" && "$ow" != "Y" ]]; then
            echo "[!] Aborting. Directory exists."
            BASE_DIR=""; PROJECT_NAME=""; ARCHIVE_NAME=""
            return
        fi
        rm -rf "$BASE_DIR"
    fi

    echo "[*] Creating structure $BASE_DIR"
    mkdir -p "$BASE_DIR/Helpers" "$BASE_DIR/reports" "$BASE_DIR/archives/attendance" "$BASE_DIR/archives/absent"

    if [ ! -f "templates/attendance_checker.py" ] || [ ! -f "templates/config.json" ] || [! -f "templates/assets.csv" ]; then
        echo "[X] templates/ files missing. Need attendance_checker.py, config.json, assets.csv"
        rm -rf "$BASE_DIR"
        BASE_DIR=""; return
    fi

    cp templates/attendance_checker.py "$BASE_DIR/"
    cp templates/config.json "$BASE_DIR/Helpers/"

    echo "Choose roster build:"
    echo "1) Copy from templates/assets.csv (max 10)"
    echo "2) Generate fresh roster (0 counts)"
    read -p "Select [1-2]: " roster_opt

    if [ "$roster_opt" = "1" ]; then
        read -p "How many students to copy (1-10): " num
        if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt 10 ]; then
            echo "[X] Invalid number. Must be 1-10."
            rm -rf "$BASE_DIR"; BASE_DIR=""; return
        fi
        head -n1 templates/assets.csv > "$BASE_DIR/Helpers/assets.csv"
        tail -n +2 templates/assets.csv | head -n "$num" >> "$BASE_DIR/Helpers/assets.csv"
        echo "{\"thresholds\": {\"warning\": 75, \"failure\": 50}, \"run_mode\": \"live\", \"total_sessions\": 5}" | python3 -m json.tool > "$BASE_DIR/Helpers/config.json.tmp" && mv "$BASE_DIR/Helpers/config.json.tmp" "$BASE_DIR/Helpers/config.json"
        echo "[✓] Copied $num students. total_sessions set to 5 (4 prior + today)"
    elif [ "$roster_opt" = "2" ]; then
        read -p "How many students to generate: " num
        if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ]; then
            echo "[X] Invalid number."
            rm -rf "$BASE_DIR"; BASE_DIR=""; return
        fi
        names=("Alice Johnson" "Bob Smith" "Charlie Davis" "Diana Prince" "Ethan Cole" "Fiona Adams" "George Miller" "Hannah Lee" "Ian Wright" "Julia King")
        emails=("alice@example.com" "bob@example.com" "charlie@example.com" "diana@example.com" "ethan@example.com" "fiona@example.com" "george@example.com" "hannah@example.com" "ian@example.com" "julia@example.com")
        echo "Email,Names,Attendance Count,Absence Count" > "$BASE_DIR/Helpers/assets.csv"
        for ((i=0; i<num && i<10; i++)); do
            echo "${emails[$i]},${names[$i]},0,0" >> "$BASE_DIR/Helpers/assets.csv"
        done
        if [ "$num" -gt 10 ]; then
            for ((i=10; i<num; i++)); do
                echo "student${i}@example.com,Student ${i},0,0" >> "$BASE_DIR/Helpers/assets.csv"
            done
        fi
        echo "{\"thresholds\": {\"warning\": 75, \"failure\": 50}, \"run_mode\": \"live\", \"total_sessions\": 1}" | python3 -m json.tool > "$BASE_DIR/Helpers/config.json.tmp" && mv "$BASE_DIR/Helpers/config.json.tmp" "$BASE_DIR/Helpers/config.json"
        echo "[✓] Generated $num fresh students. total_sessions set to 1"
    else
        echo "[X] Invalid option."
        rm -rf "$BASE_DIR"; BASE_DIR=""; return
    fi

    chmod +x "$BASE_DIR/attendance_checker.py"
    chmod 600 "$BASE_DIR/Helpers/config.json"
    echo "[✓] Permissions set: attendance_checker.py executable (755), Helpers/config.json owner RW only (600)"
    ls -l "$BASE_DIR/attendance_checker.py" "$BASE_DIR/Helpers/config.json"

    read -p "Update alert thresholds? [y/N]: " upd
    if [[ "$upd" == "y" || "$upd" == "Y" ]]; then
        read -p "Enter warning threshold [75]: " warn_in
        read -p "Enter failure threshold [50]: " fail_in
        warn=75; fail=50
        if [[ "$warn_in" =~ ^[0-9]+$ ]]; then warn=$warn_in; else echo "[*] Invalid warning, using default 75"; fi
        if [[ "$fail_in" =~ ^[0-9]+$ ]]; then fail=$fail_in; else echo "[*] Invalid failure, using default 50"; fi
        sed -i "s/\"warning\": [0-9]*/\"warning\": $warn/" "$BASE_DIR/Helpers/config.json"
        sed -i "s/\"failure\": [0-9]*/\"failure\": $fail/" "$BASE_DIR/Helpers/config.json"
        echo "[✓] Thresholds updated to warning=$warn failure=$fail"
    fi

    echo "[*] Verifying deployment..."
    cat "$BASE_DIR/Helpers/config.json"
    echo "[*] Running application to verify..."
    (cd "$BASE_DIR" && python3 attendance_checker.py)
    BASE_DIR=""; PROJECT_NAME=""; ARCHIVE_NAME=""
}

run_app() {
    read -p "Enter deployed project name (e.g., Deng for attendance_tracker_Deng): " input_name
    BASE_DIR="attendance_tracker_${input_name}"
    if [ ! -d "$BASE_DIR" ]; then
        echo "[X] $BASE_DIR not found. Deploy first."
        return
    fi
    echo "[*] Running $BASE_DIR/attendance_checker.py"
    (cd "$BASE_DIR" && python3 attendance_checker.py)
}

archive_logs() {
    read -p "Enter deployed project name to archive (e.g., Deng): " input_name
    BASE_DIR="attendance_tracker_${input_name}"
    if [! -d "$BASE_DIR" ]; then
        echo "[X] $BASE_DIR not found."
        return
    fi
    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$BASE_DIR/archives/attendance" "$BASE_DIR/archives/absent"
    archived=0
    if [ -f "$BASE_DIR/reports/attendance.log" ]; then
        cp "$BASE_DIR/reports/attendance.log" "$BASE_DIR/archives/attendance/attendance_${timestamp}.log"
        echo "[✓] Archived attendance.log -> $BASE_DIR/archives/attendance/attendance_${timestamp}.log"
        archived=$((archived+1))
    else
        echo "[!] reports/attendance.log not found - skipping (no log generated yet or empty session)"
    fi
    if [ -f "$BASE_DIR/reports/absent.log" ]; then
        cp "$BASE_DIR/reports/absent.log" "$BASE_DIR/archives/absent/absent_${timestamp}.log"
        echo "[✓] Archived absent.log -> $BASE_DIR/archives/absent/absent_${timestamp}.log"
        archived=$((archived+1))
    else
        echo "[!] reports/absent.log not found - skipping (no absences or not generated)"
    fi
    if [ $archived -eq 0 ]; then
        echo "[!] No logs to archive."
    else
        echo "[✓] Archived $archived log(s)."
    fi
}

while true; do
    echo ""
    echo "==== Automated Project Bootstrapping ===="
    echo "1) Deploy"
    echo "2) Run"
    echo "3) Archive"
    echo "4) Exit"
    read -p "Select [1-4]: " choice
    case $choice in
        1) deploy_project ;;
        2) run_app ;;
        3) archive_logs ;;
        4) echo "Exiting."; exit 0 ;;
        *) echo "[X] Invalid selection." ;;
    esac
done
