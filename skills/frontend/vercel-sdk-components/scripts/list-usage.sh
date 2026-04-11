#!/bin/bash
# list-usage.sh — Find all usages of AI Elements components in a project
# Usage: bash list-usage.sh [project_root]

set -e

PROJECT_ROOT="${1:-.}"

echo "📊 AI Elements Usage Report"
echo "   Project: $PROJECT_ROOT"
echo ""

# Find all files importing from ai-elements
FILES=$(grep -rl "ai-elements/" "$PROJECT_ROOT" \
  --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git \
  --exclude-dir=components/ai-elements \
  --exclude-dir=src/components/ai-elements 2>/dev/null || true)

if [ -z "$FILES" ]; then
  echo "   No AI Elements usage found in the project."
  exit 0
fi

echo "📂 Files using AI Elements:"
echo ""

# Collect component usage
declare -A COMPONENT_COUNT 2>/dev/null || true

while IFS= read -r file; do
  COMPONENTS=$(grep -oP 'ai-elements/[a-z-]+' "$file" 2>/dev/null | sed 's|ai-elements/||' | sort -u)
  if [ -n "$COMPONENTS" ]; then
    echo "  📄 $file"
    while IFS= read -r comp; do
      echo "     └─ $comp"
    done <<< "$COMPONENTS"
    echo ""
  fi
done <<< "$FILES"

echo "─────────────────────────────────────"
echo ""

TOTAL_FILES=$(echo "$FILES" | wc -l | tr -d ' ')
echo "   Total files with AI Elements: $TOTAL_FILES"

# Show all unique components used
echo ""
echo "📈 Unique components imported:"
echo ""
grep -ohP 'ai-elements/[a-z-]+' $FILES 2>/dev/null | sed 's|ai-elements/||' | sort | uniq -c | sort -rn | while read -r count name; do
  printf "   %-25s %d file(s)\n" "$name" "$count"
done

echo ""
echo "Done."
