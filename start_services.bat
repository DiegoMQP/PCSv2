@echo off
echo Starting PCS Services...
start "PCS Server" cmd /c "run_server.bat"
timeout /t 5
start "Ngrok Tunnel" cmd /c "run_ngrok.bat"
echo Services started in separate windows.
pause