#!/bin/bash

set -e

# Load config variables
source ./config.conf

# Colors for output
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m' # No Color

FORCE_VERSION=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -fv|--force-version)
      FORCE_VERSION="$2"
      shift 2
      ;;
    *)
      echo -e "${red}Unknown argument: $1${nc}"
      exit 1
      ;;
  esac
done

# Ensure we're in a Git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo -e "${red}This script must be run inside the Git repository.${nc}"
  exit 1
fi

# Pull latest changes
echo -e "${green}Pulling latest changes...${nc}"
git pull origin ${GITHUB_BRANCH_NAME}

# Get the last tag from remote
echo -e "${green}Checking last tag...${nc}"
LAST_TAG=$(git tag | sort -V | tail -n1)

if [[ "$FORCE_VERSION" != "" ]]; then
  NEW_TAG="$FORCE_VERSION"
else
  # Auto-increment version (assumes semantic versioning vX.Y.Z)
  IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
  PATCH=$((PATCH + 1))
  NEW_TAG="v$MAJOR.$MINOR.$PATCH"
fi

# Commit & tag the new version
echo -e "${green}Creating new tag: $NEW_TAG${nc}"
git tag "$NEW_TAG"
git push origin "$NEW_TAG"

# Create release tar.gz, Build release tarball manually
echo -e "${green}Packaging standalone binary...${nc}"
RELEASE_TARBALL="${REPO_NAME}-${NEW_TAG}.tar.gz"
tar -czf "$RELEASE_TARBALL" "main.d" "networkstat.1"

echo -e "${green}Creating GitHub release...${nc}"
gh release create "$NEW_TAG" --repo "$GITHUB_OWNER/$REPO_NAME" --title "$NEW_TAG" --notes "Auto release for $NEW_TAG"

# ⬇️ Upload the tarball to GitHub release
echo -e "${green}Uploading binary to GitHub release...${nc}"
gh release upload "$NEW_TAG" "$RELEASE_TARBALL" --repo "$GITHUB_OWNER/$REPO_NAME" --clobber

# Calculate SHA256
SHA256=$(shasum -a 256 "$RELEASE_TARBALL" | awk '{print $1}')
echo -e "${green}SHA256: $SHA256${nc}"

# Set new release asset URL
TARBALL_URL="https://github.com/${GITHUB_OWNER}/${REPO_NAME}/releases/download/${NEW_TAG}/${RELEASE_TARBALL}"

# Update formula
echo -e "${green}Updating formula at $TAP_FORMULA_PATH...${nc}"
sed -i.bak -E \
  -e "s|url \\\".*\\\"|url \\\"$TARBALL_URL\\\"|" \
  -e "s|sha256 \\\"[a-f0-9]+\\\"|sha256 \\\"$SHA256\\\"|" \
  -e "s|version \\\"v?[^\"]+\\\"|version \\\"${NEW_TAG#v}\\\"|" \
  "$TAP_FORMULA_PATH"


# Commit the updated formula
cd $(dirname "$TAP_FORMULA_PATH")
git add $(basename "$TAP_FORMULA_PATH")
git commit -m "Update $REPO_NAME to $NEW_TAG"
git push
cd - > /dev/null

# Cleanup
rm -f "$ARCHIVE_NAME"

echo -e "${green}✅ Done! Version $NEW_TAG released and formula updated.${nc}"
