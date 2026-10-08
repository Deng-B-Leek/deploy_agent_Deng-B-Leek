#!/bin/bash
PROJECT_DIR=""
cleanup_on_interrupt() {
    echo ""
    echo " [ !] Deployment interrupted by user"
    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        zip -r "${PROJECT_DIR}_archive.zip" "$PROJECT_DIR" > /dev/null
        rm -rf "$PROJECT_DIR"
        echo "[✓] Archived as ${PROJECT_DIR}_archive.zip"
    fi
    exit 1
}
trap cleanup_on_interrupt SIGINT SIGTSTP

deploy_feature() {
    if ! command -v python3 > /dev/null 2>&1; then echo "[X] python3 not found"; return 1; fi
    if ! command -v zip > /dev/null 2>&1; then echo "[X] zip not found"; return 1; fi
    echo "[✓] Pre-flight ok"
    read -p "Enter project name: " input_name
    PROJECT_DIR="attendance_tracker_${input_name}"
    if [ -d "$PROJECT_DIR" ]; then
        read -p " [ !] Exists. Overwrite? (y/n): " ow
        [[ "$ow" == "y" || "$ow" == "Y" ]] && rm -rf "$PROJECT_DIR" || { echo "[X] Aborted"; PROJECT_DIR=""; return 1; }
    fi
    mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports" "$PROJECT_DIR/archives/attendance" "$PROJECT_DIR/archives/absent"
    cp templates/attendance_checker.py "$PROJECT_DIR/"
    cp templates/config.json "$PROJECT_DIR/Helpers/"
    echo "1) Copy from templates/assets.csv"; echo "2) Generate fresh roster"
    read -p "Select [1-2]: " roster_opt
    if [ "$roster_opt" == "1" ]; then
        read -p "How many students (max 10): " num
        head -n 1 templates/assets.csv > "$PROJECT_DIR/Helpers/assets.csv"
        tail -n +2 templates/assets.csv | head -n "$num" >> "$PROJECT_DIR/Helpers/assets.csv"
        python3 -c "import json; p='$PROJECT_DIR/Helpers/config.json'; d=json.load(open(p)); d['total_sessions']=5; json.dump(d, open(p,'w'), indent=4)"
    else
        read -p "How many to generate: " num
        echo "Email,Names,Attendance Count,Absence Count" > "$PROJECT_DIR/Helpers/assets.csv"
        names=("Alice Johnson" "Bob Smith" "Charlie Lee" "Diana Ross" "Evan Green" "Fiona White" "George Brown" "Hannah Blue" "Ian Black" "Jane Doe")
        emails=("alice@example.com" "bob@example.com" "charlie@example.com" "diana@example.com" "evan@example.com" "fiona@example.com" "george@example.com" "hannah@example.com" "ian@example.com" "jane@example.com")
        for ((i=0; i<num; i++)); do echo "${emails[$i]},${names[$i]},0,0" >> "$PROJECT_DIR/Helpers/assets.csv"; done
        python3 -c "import json; p='$PROJECT_DIR/Helpers/config.json'; d=json.load(open(p)); d['total_sessions']=1; json.dump(d, open(p,'w'), indent=4)"
    fi
    chmod +x "$PROJECT_DIR/attendance_checker.py"
    chmod 600 "$PROJECT_DIR/Helpers/config.json"
    echo "[✓] Permissions set"
    read -p "Update thresholds? (y/n): " upd
    if [[ "$upd" == "y" || "$upd" == "Y" ]]; then
        read -p "Enter warning [75]: " warn; read -p "Enter failure [50]: " fail
        warn=${warn:-75}; fail=${fail:-50}
        if ! [[ "$warn" =~ ^[0-9]+$ && "$fail" =~ ^[0-9]+$ ]]; then echo "[X] Must be numeric"
        else python3 -c "import json; p='$PROJECT_DIR/Helpers/config.json'; d=json.load(open(p)); d['thresholds']['warning']=$warn; d['thresholds']['failure']=$fail; json.dump(d, open(p,'w'), indent=4)"; echo "[✓] Updated thresholds: warning=$warn, failure=$fail"; fi
    fi
    echo "[✓] Deployment complete. Verifying..."
    run_feature
    PROJECT_DIR=""
}
run_feature() {
    if [ -z "$PROJECT_DIR" ]; then read -p "Enter project name to run: " input_name; PROJECT_DIR="attendance_tracker_${input_name}"; fi
    if [ ! -d "$PROJECT_DIR" ]; then echo "[X] Project $PROJECT_DIR not found."; PROJECT_DIR=""; return 1; fi
    cd "$PROJECT_DIR" && python3 attendance_checker.py; cd - > /dev/null
}
archive_feature() {
    if [ -z "$PROJECT_DIR" ]; then read -p "Enter project name to archive: " input_name; PROJECT_DIR="attendance_tracker_${input_name}"; fi
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    if [ -f "$PROJECT_DIR/reports/attendance.log" ]; then DEST="$PROJECT_DIR/archives/attendance/attendance_${TIMESTAMP}.log"; cp "$PROJECT_DIR/reports/attendance.log" "$DEST"; echo "[✓] Archived attendance.log -> $DEST"; else echo " [ !] attendance.log not found"; fi
    if [ -f "$PROJECT_DIR/reports/absent.log" ]; then DEST="$PROJECT_DIR/archives/absent/absent_${TIMESTAMP}.log"; cp "$PROJECT_DIR/reports/absent.log" "$DEST"; echo "[✓] Archived absent.log -> $DEST"; else echo " [ !] absent.log not found (maybe no absentees)"; fi
    PROJECT_DIR=""
}
while true; do
    echo ""; echo "==== Automated Project Bootstrapping ===="; echo "1) Deploy"; echo "2) Run"; echo "3) Archive"; echo "4) Exit"
    read -p "Select [1-4]: " opt
    case $opt in 1) deploy_feature;; 2) run_feature;; 3) archive_feature;; 4) echo "Bye"; exit 0;; *) echo "Invalid";; esac
done
