@echo off
echo Starting PCS Server...
mvn exec:java -Dexec.mainClass="Server.Main"
pause