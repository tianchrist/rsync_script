#!/bin/bash
echo "" >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_c.txt
date +"%Y-%m-%d %H:%M" >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_c.txt
echo "#################" >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_c.txt
rsync.exe -av --delete-before --exclude '*.smash_Results' --exclude 'shf' /cygdrive/c/Users/weber_c1/Documents/ /cygdrive/d/weber_c1/ >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_c.txt

echo "" >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_z.txt
date +"%Y-%m-%d %H:%M" >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_z.txt
echo "#################" >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_z.txt
rsync.exe -av --delete-before --perms --chmod=a=rw,Da+x --exclude '*.smash_Results' /cygdrive/z/ /cygdrive/d/sim4life_server/ >> /cygdrive/c/Users/weber_c1/Documents/rsynclog_z.txt



