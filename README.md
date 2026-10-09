# deploy_agent_Deng-B-Leek - Automated Project Bootstrapping

## Project Description
Bash deploy agent that automates deployment, execution, archiving and permission management.

## Features
1. Pre-flight: python3 --version and zip check
2. Trap SIGINT/SIGTSTP: archives to _archive.zip AND deletes incomplete dir
3. Roster Option A: copy N rows from templates/assets.csv -> total_sessions=5
4. Roster Option B: generate fresh roster from arrays -> total_sessions=1
5. chmod +x attendance_checker.py, chmod 600 config.json with confirmation
6. Threshold update with numeric validation regex ^[0-9]+$, sed targeting "warning": and "failure":
7. Archive with timestamp YYYYMMDD_HHMMSS, separate dirs, graceful missing handling

## How to Run
chmod +x deploy_agent.sh
./deploy_agent.sh
Menu 1 Deploy: name Deng, option 1, 5 students, y, 80, 70
Menu 2 Run: name Deng, mark P/A
Menu 3 Archive: name Deng
Menu 4 Exit

## Threshold Update Logic
Prompts y/n, reads warning/failure, validates numeric before sed. If invalid/empty, uses default 75/50. sed -i "s/\"warning\": [0-9]*/\"warning\": $warn/" without reformatting.

## Log Archiving Logic
Checks reports/attendance.log and reports/absent.log existence. Copies to archives/attendance/attendance_YYYYMMDD_HHMMSS.log and archives/absent/absent_YYYYMMDD_HHMMSS.log. Prints final paths. If missing, reports gracefully without crash.

## Trap Test
Run./deploy_agent.sh -> 1 -> name TestTrap -> press Ctrl+C or Ctrl+Z
Expected: [!] interrupted message, zip -r TestTrap_archive.zip created, rm -rf incomplete dir, exit 1 cleanly.
Zip contains whatever was created before interrupt.

## How Tested Structure
ls -R attendance_tracker_Deng matches required structure
ls -l shows 755 and 600
cat Helpers/config.json shows correct total_sessions
cat Helpers/assets.csv row count = N+header
python3 attendance_checker.py runs successfully proving structure
Archive creates timestamped logs
