#!/bin/sh

set -e

# Travis does the git clone with a limited depth (50 at the time of
# writing). This may not be enough to find the common ancestor with
# $REMOTE/master so we unshallow the git checkout
git fetch --unshallow || echo "Unshallowing the git checkout failed"

# Tackle both common cases of origin and upstream as remote
# Note: upstream has priority if it exists
git remote -v
git remote | grep upstream && REMOTE=upstream || REMOTE=origin
# Make sure that $REMOTE/master is set
git remote set-branches --add $REMOTE master
git fetch $REMOTE master
REMOTE_MASTER_REF="$REMOTE/master"

# Find common ancestor between HEAD and remotes/$REMOTE/master
COMMIT=$(git merge-base @ $REMOTE_MASTER_REF) || \
    echo "No common ancestor found for $(git show @ -q) and $(git show $REMOTE_MASTER_REF -q)"

if [ -z "$COMMIT" ]; then
    exit 1
fi

echo Common ancestor is:
git show $COMMIT --stat


echo '\nRunning flake8 on the diff in the range'\
     "$(git rev-parse --short $COMMIT)..$(git rev-parse --short @)" \
     "($(git rev-list $COMMIT.. | wc -l) commit(s)):"
echo '--------------------------------------------------------------------------------'

git diff $COMMIT | flake8 --diff && echo -e "No problem detected by flake8\n"
