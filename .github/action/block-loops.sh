#!/bin/bash

set -euo pipefail

expected_commit_subject="${1:?"Set the commit message that will be used by this action"}"

# The branch to find changes against.
# Pull requests are most of the time made against the "main" branch.
origin_branch="origin/main"

# The maximum allowed number of commits from the last author.
# This should be enough to allow a few commits to be made, but not too much to
# limits the number of GHA runs in case we run into an endless loop.
# Typically, 3 commits should allow:
#   1. An original update from Renovate
#   2. Updating golden files after the update
#   3. (normally not needed)
max_commit=3

# First, we need to test if the upstream branch exists. If not, we assume the
# repository wasn't cloned with all the branches and the script can't detect if
# there are "too many commits" to break the loop.
# In this case, we continue with a warning.
if ! git show-ref --quiet "refs/remotes/$origin_branch"
then
    echo "::warning::No '$origin_branch' branch found, unable to check if commits create endless GitHub Action run loops"
    echo "::warning::Run 'actions/checkout' with 'fetch-depth: 0' to fetch all the branches."
    exit 0
fi

# Display the list of commits that we are taking into account...
echo "::group::git commits"
git log --format="oneline" "${origin_branch}.."
echo "::endgroup::"

# Find the author of the last commit. "%an" is the author name.
last_author="$(git log --max-count 1 --pretty="format:%an")"

echo "Will try to find commits made by: \"$last_author\" with subject: \"$expected_commit_subject\""

# Find the number of commits made:
# 1. By the last author (%an)
# 2. Using the commit subject this action would use later on (%s)
#
# If there are "too many" commits matching these criteria, we consider we are
# in an endless loop of automated commits.
#
# We only check the last "$max_commit" commits to see if they are repeated: if
# they are the same and they are all match the "expected" commits to block,
# then stop the workflow.
expected="$last_author = $expected_commit_subject"
nb_commits_repeated="$(git log --max-count "$max_commit" --format="format:%an = %s" "${origin_branch}.." | grep --fixed-strings --count "$expected" || true)"

if [ "$nb_commits_repeated" -ge "$max_commit" ]
then
    echo "::error::Too many commits (total=$nb_commits_repeated commits repeated) made by $last_author with subject: $expected_commit_subject."
    echo "::error::Stopping GitHub Action now because it may be running in an endless loop."
    exit 255
fi

echo "::notice::$last_author commited $nb_commits_repeated commits with subject \"$expected_commit_subject\" compared to the origin branch: $origin_branch (within the last $max_commit commits)."
exit 0
