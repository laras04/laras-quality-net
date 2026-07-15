#!/bin/bash

BODY="$1"

echo "Checking Pull Request..."

if [[ "$BODY" != *"Spec Link"* ]]; then
  echo "❌ Missing Spec / PRD"
  exit 1
fi

if [[ "$BODY" != *"Acceptance Criteria"* ]]; then
  echo "❌ Missing Acceptance Criteria"
  exit 1
fi

if [[ "$BODY" != *"Solution / Design Plan"* ]]; then
  echo "❌ Missing Design Plan"
  exit 1
fi

echo "✅ Requirement check passed"