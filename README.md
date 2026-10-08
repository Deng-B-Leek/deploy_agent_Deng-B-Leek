# deploy_agent_Deng-B-Leek - Automated Project Bootstrapping

## Project Description
Bash deploy agent that automates deployment, execution, archiving and permission management for attendance_tracker.

## Features Implemented
1. Pre-flight check: `python3 --version` and `zip` existence, fail early
2. Trap Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP): zips incomplete project to `attendance_tracker_{name}_archive.zip` and deletes incomplete dir
3. Two roster options:
   - Option A: copy N rows from templates/assets.csv (max 10) -> total_sessions=5 (4 prior + today)
   - Option B: generate fresh roster from arrays -> total_sessions=1
4. Permission management: chmod +x attendance_checker.py, chmod 600 Helpers/config.json with confirmation
5. Threshold update with validation: numeric check, default 75/50, sed in-place on "warning" and "failure" lines only
6. Run Application: cd + python3 attendance_checker.py
7. Archive Logs: checks existence, archives to archives/attendance/attendance_YYYYMMDD_HHMMSS.log and archives/absent/, timestamped, graceful if missing

## How to Run and Select Feature
chmod +x deploy_agent.sh
./deploy_agent.sh
Menu:
1) Deploy -> Enter name -> Choose 1 or 2 -> Enter student count -> y -> warning -> failure
2) Run -> Enter deployed name -> interactive P/A marking
3) Archive -> Enter deployed name -> archives logs
4) Exit

## How Threshold Update Works
Prompts y/n. If y, reads warning/failure. Validates with regex `^[0-9]+$`, else keeps default 75/50. Uses `sed -i` to replace `"warning": [0-9]*` and `"failure": [0-9]*` without reformatting file.

## How Log Archiving Works
Checks `reports/attendance.log` and `reports/absent.log`. If exists, creates `archives/attendance/` and `archives/absent/` and copies with `$(date +%Y%m%d_%H%M%S)`. Prints confirmation path. If missing, prints warning and continues without crashing.

## How to Test Ctrl+C/Ctrl+Z Trap
1. Run `./deploy_agent.sh`
2. Select 1 Deploy
3. When it asks for project name or student count, press Ctrl+C or Ctrl+Z
4. Script prints: `[!] Deployment interrupted by signal. Archiving...`
5. Creates `attendance_tracker_{name}_archive.zip` containing partial dir
6. Deletes incomplete directory to prevent workspace clutter
7. Exits cleanly with code 1

What zip contains: whatever was created before interrupt (Helpers/, reports/ etc).

## How Tested Deployed Structure
- `ls -R attendance_tracker_Deng` matches required structure
- `ls -l` shows 755 for attendance_checker.py and 600 for config.json
- `cat Helpers/config.json` shows correct total_sessions (5 for Option A, 1 for Option B)
- `cat Helpers/assets.csv` row count = requested + header
- Running `python3 attendance_checker.py` succeeds proving structure works
- Archive creates timestamped logs and handles missing logs gracefully

## File Structure Created After Deploy
attendance_tracker_Deng/
├── attendance_checker.py (755)
├── Helpers/
│ ├── assets.csv
│ └── config.json (600)
├── reports/
│ ├── attendance.log
│ └── absent.log
└── archives/
    ├── attendance/
    └── absent/
