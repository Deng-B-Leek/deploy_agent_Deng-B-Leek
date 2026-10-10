# Attendance Tracker Deploy Agent - Deng B Leek

## Video Demo
https://youtu.be/REPLACE_ME

## Approach
Menu-driven Bash agent: Deploy, Run, Archive, Exit. trap SIGINT SIGTSTP archives incomplete project then cleans workspace. BASE_DIR set late after project name input.

## Tools
- Bash, git branch fix/trap-safety, trap, python3, zip, sed, chmod +x and 600

## Setup
bash -n deploy_agent.sh
./deploy_agent.sh

## Test Results - TRUE
TEST6 Ctrl+C PASS: Created 4.3K zip, unzip -l 8 files, ls dir -> No such file PASS cleaned
TEST7 Ctrl+Z similar
TEST1 Deploy creates attendance_tracker_Deng with Helpers/reports/archives, chmod +x, chmod 600, total_sessions 5
Pre-flight python3 3.14.4 and zip checks pass
