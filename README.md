# deploy_agent_Deng-B-Leek - Automated Project Bootstrapping

Bash deploy agent that automates deployment, execution, archiving and permission management.

## Features
- Pre-flight check for python3 and zip
- Trap Ctrl+C/Ctrl+Z: archives incomplete project to zip
- Roster option 1: Copy from templates/assets.csv (total_sessions=5)
- Roster option 2: Generate fresh roster (total_sessions=1)
- chmod +x attendance_checker.py, chmod 600 Helpers/config.json
- Threshold validation with numeric check and defaults 75/50
- Run Application and Archive Logs with graceful handling

## Usage
chmod +x deploy_agent.sh
./deploy_agent.sh
1) Deploy - enter Deng, choose 1, 5 students, y, 80, 70
2) Run
3) Archive
4) Exit

## Created Structure
attendance_tracker_Deng/
  attendance_checker.py (755)
  Helpers/assets.csv, config.json (600)
  reports/attendance.log, absent.log
  archives/attendance/, absent/
