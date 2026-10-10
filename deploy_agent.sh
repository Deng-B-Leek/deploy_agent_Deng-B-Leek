#!/bin/bash
cd "$(dirname "$0")" || exit 1


PROJECT_NAME=""
BASE_DIR=""
ARCHIVE_NAME=""

cleanup_on_interrupt() {
    echo ""
    echo "[!] Deployment interrupted by signal (Ctrl+C / Ctrl+Z). Archiving..."
    if [ -n "$BASE_DIR" ] && [ -d "$BASE_DIR" ]; then
        ARCHIVE_NAME="${BASE_DIR}_archive.zip"
        echo "[*] Zipping incomplete project $BASE_DIR -> $ARCHIVE_NAME"
        if zip -r "$ARCHIVE_NAME" "$BASE_DIR" >/dev/null 2>&1; then
            if [ -f "$ARCHIVE_NAME" ]; then
                echo "[✓] Archived incomplete project to $ARCHIVE_NAME"
                echo "[*] Cleaning up incomplete directory $BASE_DIR"
                rm -rf "$BASE_DIR"
                echo "[✓] Cleaned up. Workspace not cluttered."
            fi
        else
            echo "[X] zip failed - keeping $BASE_DIR for recovery"
        fi
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

    if [ ! -f "templates/attendance_checker.py" ] || [ ! -f "templates/config.json" ] || [ ! -f "templates/assets.csv" ]; then
        echo "[X] templates/ files missing. Need attendance_checker.py, config.json, assets.csv in templates/"
        return
    fi

    read -p "Enter project directory name (e.g., Deng): " input_name
    if ! [[ "$input_name" =~ ^[A-Za-z0-9_-]+$ ]]; then
 echo "[X] Name must use only letters, numbers, - and _."
 return
    fi
    local target_dir="attendance_tracker_${input_name}"

    if [ -d "$target_dir" ]; then
        read -p "Directory $target_dir already exists. Overwrite? [y/N]: " ow
        if [[ "$ow" != "y" && "$ow" != "Y" ]]; then
            echo "[!] Aborting. Directory exists."
            return
        fi
        rm -rf "$target_dir"
    fi

    PROJECT_NAME="attendance_tracker_${input_name}"
    BASE_DIR="$PROJECT_NAME"
    ARCHIVE_NAME="${BASE_DIR}_archive.zip"

    echo "[*] Creating structure $BASE_DIR"
    if ! mkdir -p "$BASE_DIR/Helpers" "$BASE_DIR/reports" "$BASE_DIR/archives/attendance" "$BASE_DIR/archives/absent" 2>/dev/null; then
        echo "[X] Permission denied or cannot create $BASE_DIR"
        BASE_DIR=""; PROJECT_NAME=""; ARCHIVE_NAME=""
        return
    fi

    if ! cp templates/attendance_checker.py "$BASE_DIR/"; then
        echo "[X] Failed to copy attendance_checker.py"
        rm -rf "$BASE_DIR"; BASE_DIR=""; return
    fi
    if ! cp templates/config.json "$BASE_DIR/Helpers/"; then
        echo "[X] Failed to copy config.json"
        rm -rf "$BASE_DIR"; BASE_DIR=""; return
    fi

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
        echo "[✓] Copied $num students. total_sessions=5 (4 prior + today) - config.json unmodified"
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
        for ((i=10; i<num; i++)); do
            echo "student${i}@example.com,Student ${i},0,0" >> "$BASE_DIR/Helpers/assets.csv"
        done
        sed -i 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$BASE_DIR/Helpers/config.json"
        echo "[✓] Generated $num fresh students. total_sessions=1 via sed"
    else
        echo "[X] Invalid option."
        rm -rf "$BASE_DIR"; BASE_DIR=""; return
    fi

    if ! chmod +x "$BASE_DIR/attendance_checker.py"; then
        echo "[X] chmod +x failed"; rm -rf "$BASE_DIR"; BASE_DIR=""; return
    fi
    if ! chmod 600 "$BASE_DIR/Helpers/config.json"; then
        echo "[X] chmod 600 failed"; rm -rf "$BASE_DIR"; BASE_DIR=""; return
    fi
    echo "[✓] Permissions set: attendance_checker.py +x, Helpers/config.json 600"
    ls -l "$BASE_DIR/attendance_checker.py" "$BASE_DIR/Helpers/config.json"

    read -p "Update alert thresholds? [y/N]: " upd
    if [[ "$upd" == "y" || "$upd" == "Y" ]]; then
        read -p "Enter warning threshold [75]: " warn_in
        read -p "Enter failure threshold [50]: " fail_in
        warn=75; fail=50
        if [[ -z "$warn_in" ]]; then
            echo "[*] Warning empty, using default 75"
        elif [[ "$warn_in" =~ ^[0-9]+$ ]] && [ "$warn_in" -ge 0 ] && [ "$warn_in" -le 100 ]; then
            warn=$((10#$warn_in))
        else
            echo "[*] Invalid warning (must be 0-100), using default 75"
        fi
        if [[ -z "$fail_in" ]]; then
            echo "[*] Failure empty, using default 50"
        elif [[ "$fail_in" =~ ^[0-9]+$ ]] && [ "$fail_in" -ge 0 ] && [ "$fail_in" -le 100 ]; then
            fail=$((10#$fail_in))
        else
            echo "[*] Invalid failure (must be 0-100), using default 50"
        fi
        if [ "$fail" -ge "$warn" ]; then
            echo "[X] failure ($fail) must be < warning ($warn). Keeping defaults 75/50"
            warn=75; fail=50
        fi
        sed -i "s/\"warning\": [0-9]*/\"warning\": $warn/" "$BASE_DIR/Helpers/config.json"
        sed -i "s/\"failure\": [0-9]*/\"failure\": $fail/" "$BASE_DIR/Helpers/config.json"
        echo "[✓] Thresholds updated to warning=$warn failure=$fail"
    fi

    echo "[*] Verifying deployment..."
    cat "$BASE_DIR/Helpers/config.json"
    echo "[*] Running application to verify..."
    BASE_DIR=""
    PROJECT_NAME=""
    ARCHIVE_NAME=""
    (cd "$target_dir" && python3 attendance_checker.py)
}

run_app() {
    read -p "Enter deployed project name (e.g., Deng): " input_name
    local proj_dir="attendance_tracker_${input_name}"
    if [ ! -d "$proj_dir" ]; then
        echo "[X] $proj_dir not found. Deploy first."
        return
    fi
    (cd "$proj_dir" && python3 attendance_checker.py)
}

archive_logs() {
    read -p "Enter deployed project name to archive (e.g., Deng): " input_name
    local proj_dir="attendance_tracker_${input_name}"
    if [ ! -d "$proj_dir" ]; then
        echo "[X] $proj_dir not found."
        return
    fi
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$proj_dir/archives/attendance" "$proj_dir/archives/absent"
    local archived=0
    if [ -f "$proj_dir/reports/attendance.log" ]; then
        cp "$proj_dir/reports/attendance.log" "$proj_dir/archives/attendance/attendance_${timestamp}.log"
        echo "[✓] Archived attendance.log -> $proj_dir/archives/attendance/attendance_${timestamp}.log"
        archived=$((archived+1))
    else
        echo "[!] reports/attendance.log not found - skipping"
    fi
    if [ -f "$proj_dir/reports/absent.log" ]; then
        cp "$proj_dir/reports/absent.log" "$proj_dir/archives/absent/absent_${timestamp}.log"
        echo "[✓] Archived absent.log -> $proj_dir/archives/absent/absent_${timestamp}.log"
        archived=$((archived+1))
    else
        echo "[!] reports/absent.log not found - skipping (no absences)"
    fi
    if [ $archived -eq 0 ]; then echo "[!] No logs to archive."; else echo "[✓] Archived $archived log(s)."; fi
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
        *) echo "[X] Invalid" ;;
    esac
done
