@echo off
echo "Running rsync scripts..."
c:
cd C:\Users\weber_c1\Documents
::c:\cygwin64\bin\bash rsync_script.sh >> c:\Users\weber_c1\Documents\rsync_script.log
c:\cygwin64\bin\mintty.exe /bin/bash -e /cygdrive/c/Users/weber_c1/Documents/rsync_script.sh
