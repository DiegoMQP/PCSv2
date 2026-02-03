@echo off
echo Starting PCS Server...
"C:\apache-maven-3.9.12\bin\mvn" exec:java -Dexec.mainClass="Server.Main"
pause