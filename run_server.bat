@echo off
set MVN_CMD="C:\apache-maven-3.9.12\bin\mvn.cmd"

echo Compiling and Starting PCS Server...
echo Using Maven: %MVN_CMD%

call %MVN_CMD% compile exec:java -Dexec.mainClass="Server.Main"
if %errorlevel% neq 0 (
    echo.
    echo ----------------------------------------------------------------------
    echo ERROR: Server execution failed. Please check the logs above.
    echo ----------------------------------------------------------------------
)
pause