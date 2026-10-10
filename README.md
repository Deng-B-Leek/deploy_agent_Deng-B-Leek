# Attendance Tracker Deploy Agent - Deng B Leek
## Video Demo
https://youtu.be/REPLACE_ME
## Repo Name
deploy_agent_Deng-B-Leek
## Approach
Menu-driven Bash 1-4. Deploy checks python3 --version and zip. BASE_DIR assigned AFTER input so trap only zips intended dir. Templates read-only. Ends Deploy by auto-running checker.
## Tools
Bash, trap SIGINT SIGTSTP, zip, sed, chmod +x and 600, branch fix/trap-safety merged --no-ff
## How to Run & Select Feature
bash -n deploy_agent.sh
./deploy_agent.sh -> 1 Deploy asks dir name Deng, asks roster 1 copy 2 fresh, asks how many 1-10, asks thresholds y/N, auto-runs marking. 2 Run asks name and runs python3 attendance_checker.py. 3 Archive asks name and archives logs. 4 Exit
## How Threshold Update Works
Prompt Update thresholds y/N. If y read warning failure. Validates numeric and warning < failure. If invalid e.g., 90/95 prints Invalid keeping defaults 75/50. Uses sed -i to edit warning and failure lines in place without reformat.
## How Log Archiving Works
Structure: attendance_tracker_Deng/archives/attendance/attendance_YYYYMMDD_HHMMSS.log and archives/absent/absent_YYYYMMDD_HHMMSS.log. Timestamp date +%Y%m%d_%H%M%S. Checks reports/attendance.log and reports/absent.log exists. Archives each existing. If missing e.g., no absent prints Missing skip but continues. Prints final paths.
## How to Test Ctrl+C Ctrl+Z & Zip Contents
Trigger: ./deploy_agent.sh -> 1 -> name TrapTest -> at Select [1-2] press Ctrl+C or Ctrl+Z. Expected: Deployment interrupted Archiving Zipping to attendance_tracker_TrapTest_archive.zip Archived Cleaned up Workspace not cluttered. Verify: ls -lh shows 4.3K, unzip -l shows 8 files (Helpers reports archives checker config), ls -d dir shows No such file PASS cleaned Exemplary. If pressed before name: No directory to archive yet.
## How Tested Structure
TEST1 Deploy: ls -l shows dirs Helpers reports archives, -rwxr-xr-x checker, -rw------- config 600, total_sessions 5 for copy (4 prior+1) 1 for fresh, copied 3 students.
TEST2 Existing: prompt exists Overwrite y/N N abort y re-deploy.
TEST3 Invalid Threshold 90/95 -> keeps 75/50.
TEST4 Run: menu 2 runs marking.
TEST5 Archive Missing: rm reports log then archive graceful skip.
TEST6/7 Trap: Ctrl+C and Ctrl+Z zip 4.3K 8 files dir cleaned.
## Git Workflow
main, fix/trap-safety branch, merge --no-ff preserves history, .gitignore ignores tracker and zips and swp, git log --graph proves branching.
