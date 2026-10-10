# deploy_agent_Deng-B-Leek - Automated Project Bootstrapping

## Project Description
Bash deploy agent that automates deployment, execution, archiving and permission management. Uses templates/ for unmodified source files.

## How to Run

```
chmod +x deploy_agent.sh
./deploy_agent.sh
```

Menu: 1) Deploy 2) Run 3) Archive 4) Exit

## Pre-flight Checks
- Checks python3 --version and zip BEFORE mkdir
- Checks templates/ files exist BEFORE mkdir

## Deployed Structure
```
attendance_tracker_{name}/
  attendance_checker.py
  Helpers/assets.csv, config.json
  reports/ (starts empty)
  archives/attendance/, archives/absent/
```
reports/ starts empty. App creates attendance.log and absent.log on first run.

## Roster Options and total_sessions

| Option | Source | Prior | total_sessions |
|---|---|---|---|
| A | first N rows templates/assets.csv max10 | 4 | 5 |
| B | N rows from arrays | 0 | 1 |
Option A config.json unmodified. Option B sed to 1.

## Permissions
```
chmod +x attendance_tracker_{name}/attendance_checker.py
chmod 600 Helpers/config.json
ls -l ...py ...config.json
```
600 = owner rw only because grading-sensitive.

## Threshold Update Logic
Prompt Update thresholds [y/N]. If y: empty keeps default 75/50, validates ^[0-9]+$ and 0-100, failure < warning else reset 75/50. Uses sed on "warning": and "failure": lines.

## Log Archiving Logic
```
timestamp=$(date +%Y%m%d_%H%M%S)
cp reports/attendance.log archives/attendance/attendance_${timestamp}.log
cp reports/absent.log archives/absent/absent_${timestamp}.log
```
Checks existence, timestamped names, prints paths, graceful if missing.

## Signal Handling Ctrl+C and Ctrl+Z

**Archive trigger:** SIGINT (Ctrl+C) or SIGTSTP (Ctrl+Z) during deploy phase triggers trap to zip-and-delete incomplete project. Trap for shell script during deployment, not for attendance_checker.py.

On SIGINT/SIGTSTP:
1. Zips incomplete dir to attendance_tracker_{name}_archive.zip via zip -r
2. Only if zip succeeds deletes dir
3. Lists via unzip -l

**What zip contains:** Whatever existed before interrupt. Example if interrupted at Select [1-2] prompt: Helpers/, reports/, archives/, attendance_checker.py, Helpers/config.json, assets.csv

### Trap Test Steps
```
# Test1 Ctrl+C at Select [1-2] prompt
./deploy_agent.sh
# 1 -> TestTrap -> at Select [1-2] press Ctrl+C -> zip created dir deleted
# Test2 Ctrl+Z at Select [1-2] prompt
./deploy_agent.sh
# 1 -> TestTrap2 -> at Select [1-2] press Ctrl+Z -> zip created
ls -l *.zip
unzip -l *_archive.zip
ls attendance_tracker_TestTrap # expect No such file
# Test3 Ctrl+C at Overwrite? prompt should NOT archive (BASE_DIR not set)
```

## How Tested
```
ls -R attendance_tracker_Deng
# Result: Saw Helpers/, reports/, archives/, py
ls -l py
# Result: rwxr-xr-x executable
ls -l config.json
# Result: rw------- 600
cat config.json
# Result: 5 for A, 1 for B
wc -l assets.csv
# Result: 6 = header+5
python3 attendance_checker.py
# Result: P/A prompts, logs created
archive logs
# Result: archived timestamped
trap tests
# Result: zip+cleanup for Ctrl+C and Ctrl+Z, unzip -l showed files
```

## Video Walkthrough
Link: https://youtu.be/REPLACE_ME
Shows approach, logic, live marking, interrupt Ctrl+C with ls+unzip -l, Ctrl+Z with ls+unzip -l, edge cases existing dir/bad threshold/missing log
