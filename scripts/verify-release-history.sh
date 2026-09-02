#!/bin/bash
set -euo pipefail

if [[ "$#" -ne 1 ]] || [[ ! "$1" =~ ^v([0-9]+)\.([0-9]+)\.[0-9]+$ ]]
then
  echo "usage: $0 vMAJOR.MINOR.PATCH" >&2
  exit 1
fi

tag=$1
maintenance_branch="release/${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
repository=raulgg/airpods-control
tag_sha=$(gh api "repos/${repository}/commits/refs/tags/${tag}" --jq .sha)

for branch in main "${maintenance_branch}"
do
  # For tag...branch, "ahead" means the branch contains the tag commit.
  # Require a branch, never a same-named tag. API errors must fail closed.
  comparison=$(gh api "repos/${repository}/compare/${tag_sha}...refs/heads/${branch}" --jq .status)
  case "${comparison}" in
    ahead | identical)
      printf '%s\n' "${branch}"
      exit 0
      ;;
    behind | diverged) ;;
    *)
      echo "Unexpected comparison status for ${tag} on ${branch}: ${comparison}" >&2
      exit 1
      ;;
  esac
done

echo "Refusing ${tag}: tag commit is not on upstream main or ${maintenance_branch}" >&2
exit 1
