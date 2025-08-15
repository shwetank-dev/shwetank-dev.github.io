#!/usr/bin/env bash
set -euo pipefail

# --- config (optional) --------------------------------------------------------
BUILD_DIR="_site"           # Jekyll output directory
PUBLISH_BRANCH="gh-pages"   # Branch GitHub Pages serves from
WORKTREE_DIR=".gh-pages"    # Local folder for the publish branch worktree
# -----------------------------------------------------------------------------

# Ensure we're at the repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "❌ Not inside a Git repository."
  exit 1
fi
cd "${REPO_ROOT}"

# Ensure clean working tree (no accidental publishes)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ You have uncommitted changes. Commit or stash before deploying."
  exit 1
fi

# Build (prefers Bundler when Gemfile exists)
echo "🔨 Building site…"
if [[ -f "Gemfile" ]]; then
  bundle install --quiet
  bundle exec jekyll build
else
  jekyll build
fi

# Safety check
if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "❌ Build directory '${BUILD_DIR}' not found. Did the build fail?"
  exit 1
fi

# Prepare the gh-pages worktree
echo "🌿 Preparing worktree for branch '${PUBLISH_BRANCH}'…"
# Fetch to ensure we know about remote branches
git fetch origin --quiet || true

if git show-ref --verify --quiet "refs/heads/${PUBLISH_BRANCH}"; then
  # Local branch exists: link it
  if [[ ! -d "${WORKTREE_DIR}" ]]; then
    git worktree add -B "${PUBLISH_BRANCH}" "${WORKTREE_DIR}" "origin/${PUBLISH_BRANCH}" 2>/dev/null || \
    git worktree add -B "${PUBLISH_BRANCH}" "${WORKTREE_DIR}" "${PUBLISH_BRANCH}"
  fi
else
  # Create orphan branch via worktree
  git worktree add -B "${PUBLISH_BRANCH}" "${WORKTREE_DIR}"
  (
    cd "${WORKTREE_DIR}"
    # Orphan-like initial commit if empty
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
      echo "<html><body>Initializing ${PUBLISH_BRANCH}</body></html>" > index.html
      git add index.html
      git commit -m "Initialize ${PUBLISH_BRANCH}"
      git push -u origin "${PUBLISH_BRANCH}"
    fi
  )
fi

# Copy built site into the worktree (wipe old files first)
echo "📦 Publishing files…"
shopt -s dotglob
(
  cd "${WORKTREE_DIR}"
  # Remove everything except .git
  find . -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +
)
cp -R "${BUILD_DIR}/"* "${WORKTREE_DIR}/" || true

# Add .nojekyll to bypass GitHub’s Jekyll processing (serves exactly what you built)
touch "${WORKTREE_DIR}/.nojekyll"

# Preserve CNAME if present at repo root
if [[ -f "CNAME" ]]; then
  cp "CNAME" "${WORKTREE_DIR}/CNAME"
fi

# Commit & push
COMMIT_SHA="$(git rev-parse --short HEAD)"
DATE_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

(
  cd "${WORKTREE_DIR}"
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "Deploy ${COMMIT_SHA} at ${DATE_UTC}"
    echo "🚀 Pushing to origin/${PUBLISH_BRANCH}…"
    git push origin "${PUBLISH_BRANCH}"
  else
    echo "ℹ️ No changes to publish."
  fi
)

echo "✅ Deployed ${COMMIT_SHA} to '${PUBLISH_BRANCH}'."
echo "🔗 Check your site URL in: GitHub → Settings → Pages"
