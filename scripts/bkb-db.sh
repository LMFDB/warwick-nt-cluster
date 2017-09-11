#!/usr/bin/env bash
export BUP_DIR=~/bup

# "log" command writes to /var/log/syslog with the specified tag
log () { logger -t LMFDB-BKB "$@"; }

set -e # fail on error
set -u # show unused variables

# just prepend all commands with $NICE
NICE="nice ionice -c 3"

cd # go into $HOME directory
# cd `dirname "$0"`
# go into the dump directory, backup will be in a subdir

cd dump

#sensible timestamp like 20130909-1234 in UTC time
timestamp=`date -u +%Y%m%d-%H%M`
mkdir $timestamp
log "new backup started in $timestamp"

$NICE mongodump --port 37010 -u "$MONGO_USERNAME" -p "$MONGO_PASSWORD" --authenticationDatabase admin -o $timestamp
$NICE rm -rvf $timestamp/'*' && echo 'deleted directory "*"' || echo 'no directory "*" and nothing deleted ...'
log "mongodump finished"

# linked-copy into "latest"
rm -rf latest
mkdir -p latest
cp -rl $timestamp/* latest/
cd latest
rm -rf userdb admin '*'
cd ..
chmod -R ug+rw latest

# bup backup of $timestamp
$NICE bup index -uv ~/dump/$timestamp
$NICE bup save -n lmfdb --strip ~/dump/$timestamp
log "saving in bup storage finished"

# go into the dump directory and compress the dumped directories
cd $timestamp
$NICE rm -rf userdb admin '*'
#find -maxdepth 1 -mindepth 1 -type d | parallel --eta 'tar cjf {}.tar.bz2 {}'
# the compression level -L is 5, default is 7. if it is fast enough, increase it!
#for DIR in `find -maxdepth 1 -mindepth 1 -type d`; do
#    lrztar -v -o "$DIR.tar.lrz" "$DIR"
#    #$NICE tar --lzma -cf "$DIR.tar.lmza" "$DIR"
#    $NICE rm -rf "$DIR"
#done

find -size +10M -print0 | xargs -0 sha1sum > sha1sums.txt
#log "compression finished + sha1sums created"

# move to the public directory
cd
mv -v dump/$timestamp data/db/
log "moved directory to data/db/$timestamp"

# last step should be to get rid of older directories in data/db

todel="`find data/db -maxdepth 1 -mindepth 1 -ctime +40 -type d`"
echo "the following older directories in data/db are deleted: $todel"
rm -rf $todel
log "deleted old directories: $todel"
