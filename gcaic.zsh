# AI-assisted commit helper
# Generates a Conventional Commit-style message using codex and commits staged changes.

gcaic(){
  if git diff --cached --quiet; then
    printf 'No staged changes; stage files with git add first.\n' >&2
    return 1
  fi

  if ! command -v codex >/dev/null 2>&1; then
    printf 'codex CLI not found on PATH.\n' >&2
    return 1
  fi

  local summary diff prompt msg
  summary=$(git status --short)
  diff=$(git diff --cached)

  prompt=$'You are writing a concise conventional-style git commit message.\n'
  prompt+=$'Given the staged diff and status summary below, return one line formatted as "<type>: <subject>" without trailing punctuation.\n'
  prompt+=$'Allowed types: feat, fix, chore, docs, refactor, test, perf, build. If nothing fits, use chore.\n\n'
  prompt+=$'Status:\n'
  prompt+="$summary"
  prompt+=$'\n\nDiff:\n'
  prompt+="$diff"

  msg=$(codex --sandbox danger-full-access --ask-for-approval never \
    --prompt "$prompt" \
    --output-format text 2>/dev/null | head -n1)

  if [[ -z $msg ]]; then
    printf 'No commit message generated; aborting.\n' >&2
    return 1
  fi

  printf 'Using commit message: %s\n' "$msg"
  git commit -m "$msg"
}
