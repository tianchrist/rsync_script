#!/bin/bash
#SRC1="/cygdrive/c/Users/weber_c1/Documents/temp"
SRC1="/cygdrive/c/Users/weber_c1/Documents"
SRCTAG1="documents"

#SRC2="/cygdrive/z/s-parameter"
SRC2="/cygdrive/z"
SRCTAG2="sim4life_server"
DSTBASEDIR="/cygdrive/d/backup_timeline"

function getFreeSpace {
    df "$DSTBASEDIR" --block-size=1 | tail --lines=1 | awk '{print $4}'
}

{
NOW=$(date +"%Y-%m-%d-%H%M%S")
NOW=${NOW:0:-1}  ## remove last character (\r)
echo ""
echo $NOW
echo "#################"

if [ ! -d "$DSTBASEDIR" ]; then
    echo ERROR: Destination folder "$DSTBASEDIR" does not exist.
    exit 1
fi

NOWFOLDER="$DSTBASEDIR/$NOW"
echo Destination folder: "$NOWFOLDER"
# get source folder size
SIZE1=$(rsync.exe -avn --delete-before --exclude '*.smash_Results' --exclude 'shf' "$SRC1"/ "$NOWFOLDER"/"$SRCTAG1"/ | tail --lines=1 | awk '{print $4}')
# remove comma
SIZE1=${SIZE1//,/}
SIZE2=$(rsync.exe -avn --delete-before --exclude '*.smash_Results' --exclude 'shf' "$SRC2"/ "$NOWFOLDER"/"$SRCTAG2"/ | tail --lines=1 | awk '{print $4}')
SIZE2=${SIZE2//,/}
SUM=$((SIZE1+SIZE2))
FREESPACE=$(getFreeSpace)
REQSPACE=$((SUM*11/10))
echo Folder $SRC1 has size: $(numfmt --to=iec $SIZE1)
echo Folder $SRC2 has size: $(numfmt --to=iec $SIZE2)
echo The total size is $(numfmt --to=iec $SUM)
echo "The required space (10% more than total size) is $(numfmt --to=iec $REQSPACE)"
echo Available space on "$DSTBASEDIR": $(numfmt --to=iec $FREESPACE)
# delete an existing empty folder from previous session
cd "$DSTBASEDIR"
if [ -d empty ]; then
    rm -rf empty
fi
# find the newest folder (will be used later for exclusion from delete list and for rsync changelog)
# bugfix 21_01_25: must be set before the next if!
NEWEST=$(ls -1d "$DSTBASEDIR"/*/ | sort | tail --lines=1)
echo "Newest folder: $NEWEST"


# check if folder size is greater than free space on destination disk
if [ "$FREESPACE" -lt "$REQSPACE" ]; then
    echo "Changed into directory"
    pwd
    FOLDERCOUNT=$(ls -1d "$DSTBASEDIR"/*/ | wc -l)
    echo "Check if deleting all except the newest backup would free enough space..."
    SIZEOFALL=$(du $DSTBASEDIR/* -d 0 --block-size=1 | awk '{sum+=$1} END {print sum}')
    if [ "$SIZEOFALL" == "" ]; then
        echo "Error occured during disk usage calculation $DSTBASEDIR"
        exit 1
    fi 
    echo "Size of all folders: $(numfmt --to=iec $SIZEOFALL)"
    echo "Newest folder: $NEWEST"
    SIZEOFNEWEST=$(du "${NEWEST:0:-1}" -d 0 --block-size=1 | awk '{print $1}')
    if [ "$SIZEOFNEWEST" == "" ]; then
        echo "Error occured during disk usage calculation $NEWEST"
        exit 1
    fi 
    echo "Size of newest folder: $(numfmt --to=iec $SIZEOFNEWEST)"
    MAXFREESPACE=$((SIZEOFALL-SIZEOFNEWEST+FREESPACE))
    echo "Potentially available space: $(numfmt --to=iec $MAXFREESPACE)"
    if [ "$MAXFREESPACE" -ge "$REQSPACE" ]; then
        echo Start deleting old backups...
        echo Number of old backups: $FOLDERCOUNT
        # delete oldest backup folder until there is enough space
        # but stop before the last existing folder
        
        mkdir empty
        while [ "$FOLDERCOUNT" -gt 1 ] && [ "$FREESPACE" -lt "$REQSPACE" ] ; do
            OLDEST=$(ls -1d * | grep --invert-match "empty" | sort | head --lines=1)
            echo Deleting folder "${OLDEST:0:-1}/"
            # rsync deletes faster AND handles long file names
            rsync -a --delete empty/ "${OLDEST:0:-1}/"
            # rm is needed to remove the empty folder
            rm -rf "${OLDEST:0:-1}"   ## remove last character (\r)
            FOLDERCOUNT=$(ls -1d * | grep --invert-match "empty" | wc -l)
            echo Number of remaining backups: $FOLDERCOUNT
            FREESPACE=$(getFreeSpace)
            echo Available space: $(numfmt --to=iec $FREESPACE)
            ## check if deleting frees up any space (or if folder count decreases)
        done
        rm -rf empty
    else
        echo "Deleting old backups won't help. Not enough space on disk."
        exit 1
    fi
fi

if [ "$FREESPACE" -ge "$REQSPACE" ]; then
    mkdir "$NOWFOLDER"
    chmod a+rwx "$NOWFOLDER"
    mkdir "$NOWFOLDER"/"$SRCTAG1"
    chmod a+rwx "$NOWFOLDER"/"$SRCTAG1"
    mkdir "$NOWFOLDER"/"$SRCTAG2"
    chmod a+rwx "$NOWFOLDER"/"$SRCTAG2"

    # dry run to create changelog
    rsync -rltDvni --delete-before --exclude '*.smash_Results' --exclude 'shf' "$SRC1"/ "${NEWEST:0:-1}"/"$SRCTAG1"/ > "$NOWFOLDER"/"$SRCTAG1"_changes.log
    rsync -rltDvni --delete-before --exclude '*.smash_Results' --exclude 'shf' "$SRC2"/ "${NEWEST:0:-1}"/"$SRCTAG2"/ > "$NOWFOLDER"/"$SRCTAG2"_changes.log
    echo "Changelog (compared to newest backup) written."
    echo backing up $SRC1 ...
    rsync.exe -av --chmod=ugo=rwX --delete-before --exclude '*.smash_Results' --exclude 'shf' "$SRC1"/ "$NOWFOLDER"/"$SRCTAG1"/ > "$NOWFOLDER"/"$SRCTAG1"_rsync.log
    echo backing up $SRC2 ...
    rsync.exe -av --chmod=ugo=rwX --delete-before --exclude '*.smash_Results' --exclude 'shf' "$SRC2"/ "$NOWFOLDER"/"$SRCTAG2"/ > "$NOWFOLDER"/"$SRCTAG2"_rsync.log
    echo "Finished!"
else
    echo "Not enough space on disk."
fi    
} >> rsync_script.log 2>&1