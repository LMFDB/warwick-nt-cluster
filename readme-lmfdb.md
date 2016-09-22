# The lmfdb servers and code

There are three web servers each running a different branch of the lmfdb code:

1. www.lmfdb.org points to lmfdb.warwick.xyz (the cloud server) and runs prod.
2. beta.lmfdb.org points to lmfdb.warwick.ac.uk:37002 and runs beta.
3. lmfdb.warwick.ac.uk goes to lmfdb.warwick.ac.uk:37001 and runs prod.

The configuration files for these (2 and 3) are in
~/lmfdb-git-prod/gunicorn-config and ~/
lmfdb-git-beta/gunicorn-config-beta.  The main difference, apart from
the port number and the number of threads (more for prod) is that beta
runs with the environment variable BETA set to 1, while on prod it is
unset.  The PIDs of the associated python processes are stored in
~/gunicorn.pid and ~/gunicorn-beta.pid .

There is a normal lmfdb directory in ~/lmfdb, whose only remote is
origin = git@github.com:LMFDB/lmfdb.git. A crontab job runs every 15
minutes to update the three branches (master, beta, prod) from
github/lmfdb to here and also push them to the bare git repository in
~/lmfdb.git.  Directories lmfdb-git-prod and lmfdb-git-beta have the
current prod and beta branches checked out, and when new commits to
either of these branches are pushed to lmfdb.git, the script
~/lmfdb.git/hooks/post-receive updates those and restarts the relevant
server.  In this way when a release manager merges any code changes to
either beta or prod branches, within 15 minutes the appropriate
servers will restart with the new code.  (A similar setup updates the
cloud server whenever prod changes on github).

The directories lmfdb-git-{prod, beta} contain these checked out
branches but are not themselves git repositories (they have no .git
subdirectory).  Each has an additional gunicorn config file and a file
flasklog which logs server requests and error messages.  I do not know
when the flasklog files are deleted and new ones started, but no
backups of these logs appear to be created automatically.

Using the master branch in $HOME/lmfdb it is possible to test changes
before they are pushed to the live servers (by merging onto beta or
prod) on the same Sage versions as the servers are running, after
manually updating the master branch.  For example, to test a proposed
new push to beta, first run the unit tests:

```
cd ~/lmfdb
git checkout master
git pull
SAGE=~/sage-beta/sage ./test.sh
```
and also run the server (as one would for local development), making sure to use a port other than 37001, 37002, for example
```
cd ~/lmfdb
git checkout master
git pull
export BETA=1
~/sage-beta/sage -python ./start-lmfdb.py -p 37788
```
and then open your browser to lmfdb.warwick.ac.uk:37788 (or use ssh
tunelling to a local port).

It is not normally necessary to manually start or restart either
server.  One situation is to change the Sage version running (see
readme-sage for that).  Another is if either server stops running for
an unknown reason (which does happen, if rarely), then use the start
script (but make sure that the mongod process is running first).
