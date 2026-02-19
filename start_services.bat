@echo off
echo Starting PCS Services (Windows)...

if exist run_server.bat (
	start "PCS Server" cmd /k "run_server.bat"
) else if exist run_server_fixed.bat (
	start "PCS Server" cmd /k "run_server_fixed.bat"
) else (
	echo "No run_server.bat or run_server_fixed.bat found. Please create one."
)

timeout /t 3

if exist run_ngrok.bat (
	start "Ngrok Tunnel" cmd /k "run_ngrok.bat"
) else (
	echo "run_ngrok.bat not found. Create run_ngrok.bat to start ngrok."
)

echo Services started in separate windows (if scripts found).
pause