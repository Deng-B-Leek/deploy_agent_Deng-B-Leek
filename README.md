# deploy_agent_Deng-B-Leek

## Project Description
Bash deploy agent that automates deployment, execution, archiving and permission management.

## How to Run
chmod +x deploy_agent.sh
./deploy_agent.sh

## Pre-flight Checks
- python3 --version and zip checked before mkdir
- templates files checked BEFORE mkdir

## Deployed Structure
attendance_tracker_{name}/
  attendance_checker.py
  Helpers/assets.csv, config.json
  reports/ (starts empty)
  archives/attendance/, archives/absent/

reports/ starts empty, app creates attendance.log and absent.log on first run (verification run). absent.log only if absent.

## Roster Options and total_sessions
Option A: copy first N rows of templates/assets.csv (max 10) - Prior 4 each - total_sessions 5
Option B: generate fresh from arrays - Prior 0 - total_sessions 1 via sed
Option A config.json deployed unmodified.

## Permissions
chmod +x attendance_checker.py and chmod 600 Helpers/config.json, then ls -l
600 = owner rw only because thresholds are grading-sensitive.

## Threshold Update Logic
Prompt Update thresholds [y/N]. If y: empty keeps default 75/50, validates ^[0-9]+$ and 0-100, failure must be < warning else reset to 75/50. Uses sed on "warning": and "failure": lines.

## Log Archiving Logic
timestamp=$(date +%Y%m%d_%H%M%S)
cp reports/attendance.log archives/attendance/attendance_${timestamp}.log
cp reports/absent.log archives/absent/absent_${timestamp}.log
Prints final paths, graceful if missing.

## Signal Handling Ctrl+C and Ctrl+Z
Trap for shell script during deployment, not for attendance_checker.py.
On SIGINT/SIGTSTP: zips incomplete dir to attendance_tracker_{name}_archive.zip via zip -r, only if zip succeeds deletes dir, lists via unzip -l.
What zip contains: whatever existed before interrupt at Select [1-2] prompt, e.g. Helpers/, reports/, archives/, attendance_checker.py, config.json, assets.csv

Trap Test:
1) ./deploy_agent.sh -> 1 -> TestTrap -> at Select [1-2] press Ctrl+C -> zip created, dir deleted
2) ./deploy_agent.sh -> 1 -> TestTrap2 -> at Select [1-2] press Ctrl+Z -> zip created
Verify: ls -l *.zip ; unzip -l *_archive.zip ; ls dir should fail
3) Overwrite prompt Ctrl+C should NOT archive (BASE_DIR not set yet)

## How Tested
ls -R attendance_tracker_Deng -> saw Helpers/, reports/, archives/, py
ls -l py -> rwxr-xr-x executable
ls -l config.json -> rw------- 600
cat config.json -> total_sessions 5 for A, 1 for B
wc -l assets.csv -> 6 = header+5
python3 attendance_checker.py -> P/A prompts, logs created, assets.csv updated
archive logs -> attendance_*.log archived
trap tests -> zip + cleanup worked for Ctrl+C and Ctrl+Z

## Video
Link: https://youtu.be/REPLACE_ME - shows logic, live marking, ls -l, Ctrl+C demo with unzip -l, Ctrl+Z demo, archive demo
