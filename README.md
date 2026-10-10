# deploy_agent_Deng-B-Leek - Automated Project Bootstrapping

## Project Description
Bash deploy agent that automates deployment, execution, archiving and permission management for Student Attendance Tracker. Uses templates/ for source files.

## How to Run
chmod +x deploy_agent.sh
./deploy_agent.sh
Menu: 1) Deploy 2) Run 3) Archive 4) Exit

## Pre-flight Checks
Script checks python3 --version and zip command exists. Fails early with clear message if missing.

## Deployed Structure
    attendance_tracker_{name}/
    ├── attendance_checker.py
    ├── Helpers/
    │   ├── assets.csv
    │   └── config.json
    ├── reports/          (starts empty)
    └── archives/
        ├── attendance/
        └── absent/

reports/ starts empty. The application creates reports/attendance.log and reports/absent.log the first time it runs, which during a deploy is the verification run. absent.log only appears if at least one student is marked absent.

## Roster Options and total_sessions
total_sessions in config.json counts all sessions including today's, so it must be one more than the prior sessions recorded in the roster.

Option A: copy from template - first N rows of templates/assets.csv (max 10) - Prior 4 each - total_sessions 5 (4 prior + today)
Option B: generate fresh roster - N rows built from arrays in the script - Prior 0 each - total_sessions 1 (0 prior + today)

The verification run is a real marking session, so it updates the roster counts.

## Permissions
After deployment the script runs chmod +x on attendance_checker.py and chmod 600 on Helpers/config.json (owner read/write only, because it holds the grading-sensitive thresholds), then prints the result with ls -l.

## Threshold Update Logic
Prompts Update alert thresholds? [y/N]. If yes, reads warning default 75 and failure default 50, validates numeric with ^[0-9]+$. Uses sed targeting "warning": and "failure": lines only, without reformatting file.

## Log Archiving Logic
Checks reports/attendance.log and reports/absent.log existence. Copies to archives/attendance/attendance_YYYYMMDD_HHMMSS.log and archives/absent/absent_YYYYMMDD_HHMMSS.log with timestamp from date +%Y%m%d_%H%M%S. Prints final paths. Gracefully reports if missing.

## Trap Test
Run ./deploy_agent.sh then 1 -> TestTrap -> press Ctrl+C
Expected: [!] Deployment interrupted..., zips incomplete project to attendance_tracker_TestTrap_archive.zip (using zip -r), deletes incomplete directory attendance_tracker_TestTrap, exits cleanly.

## How Tested Structure
ls -R attendance_tracker_Deng
ls -l attendance_tracker_Deng/attendance_checker.py attendance_tracker_Deng/Helpers/config.json
cat attendance_tracker_Deng/Helpers/config.json

## Video Walkthrough
Link: [Add YouTube unlisted link]
