@echo off
echo Starting ngrok for port 7070 with pooling enabled...
echo Ensure ngrok is installed and in your PATH.
ngrok http 7070 --pooling-enabled
pause