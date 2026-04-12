#!/bin/bash
# search-component.sh — Check if an AI Elements component is installed in a project
# Usage: bash search-component.sh <project_root> <component_name>
#
# Examples:
#   bash search-component.sh /path/to/project message
#   bash search-component.sh . reasoning
#   bash search-component.sh /app conversation

set -e

PROJECT_ROOT="${1:-.}"
COMPONENT="${2}"

if [ -z "$COMPONENT" ]; then
  echo "❌ Usage: bash search-component.sh <project_root> <component_name>"
  echo "   Example: bash search-component.sh . message"
  exit 1
fi

# Normalize component name (kebab-case)
COMPONENT=$(echo "$COMPONENT" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Default AI Elements directory
AI_ELEMENTS_DIR="$PROJECT_ROOT/components/ai-elements"
# Also check src/ prefix
AI_ELEMENTS_DIR_SRC="$PROJECT_ROOT/src/components/ai-elements"

echo "🔍 Searching for AI Elements component: $COMPONENT"
echo "   Project root: $PROJECT_ROOT"
echo ""

# Check if the component file exists
FOUND=false
for dir in "$AI_ELEMENTS_DIR" "$AI_ELEMENTS_DIR_SRC"; do
  if [ -f "$dir/$COMPONENT.tsx" ] || [ -f "$dir/$COMPONENT.ts" ]; then
    FOUND=true
    FILE=$(ls "$dir/$COMPONENT".ts* 2>/dev/null | head -1)
    echo "✅ Component file found: $FILE"
    echo "   Size: $(wc -l < "$FILE") lines"
    echo ""
    break
  fi
done

if [ "$FOUND" = false ]; then
  echo "⚠️  Component file NOT found in:"
  echo "   - $AI_ELEMENTS_DIR/$COMPONENT.tsx"
  echo "   - $AI_ELEMENTS_DIR_SRC/$COMPONENT.tsx"
  echo ""
  echo "   Install with: npx ai-elements@latest add $COMPONENT"
  echo ""
fi

# Search for imports/usage of the component across the project
echo "📂 Searching for usage of '$COMPONENT' across the project..."
echo ""

USAGES=$(grep -rl "ai-elements/$COMPONENT" "$PROJECT_ROOT" \
  --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git \
  --exclude-dir=components/ai-elements 2>/dev/null || true)

if [ -n "$USAGES" ]; then
  echo "📌 Files importing this component:"
  echo "$USAGES" | while read -r file; do
    echo "   - $file"
    grep "ai-elements/$COMPONENT" "$file" | head -3 | sed 's/^/     /'
  done
  echo ""
  echo "   Total files: $(echo "$USAGES" | wc -l | tr -d ' ')"
else
  echo "   No usages found (component is installed but not imported anywhere)"
fi

echo ""
echo "Done."
