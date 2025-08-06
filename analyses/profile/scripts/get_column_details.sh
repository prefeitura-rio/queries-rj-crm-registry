#!/bin/bash

# Enhanced Column Details Extractor
# Usage: ./get_column_details.sh <table_name> <column_name>

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "❌ Usage: $0 <table_name> <column_name>"
    echo "Example: $0 \"project.dataset.table\" \"column_name\""
    exit 1
fi

TABLE_NAME="$1"
COLUMN_NAME="$2"

# Get script directory to ensure we always write to correct location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Create directory name from table name (replace dots with underscores)
DIR_NAME=$(echo "$TABLE_NAME" | sed 's/\./_/g')
PROFILE_DIR="$REPO_ROOT/analyses/profile/results/$DIR_NAME"

# Create profile directory
mkdir -p "$PROFILE_DIR"

# Parse table components
PROJECT=$(echo "$TABLE_NAME" | cut -d'.' -f1)
DATASET=$(echo "$TABLE_NAME" | cut -d'.' -f2)
TABLE=$(echo "$TABLE_NAME" | cut -d'.' -f3)
FULL_TABLE_NAME="$PROJECT.$DATASET.$TABLE"

# --- Step 1: Get distinct value count to determine if categorical ---
echo "🔍 Analyzing column '$COLUMN_NAME' in table: $TABLE_NAME..."

# Create temporary file for bq output
TEMP_FILE=$(mktemp)

# Get distinct count with error handling
if ! bq query --use_legacy_sql=false --format=csv --max_rows=2 "
  SELECT COUNT(DISTINCT $COLUMN_NAME) FROM \`$FULL_TABLE_NAME\`
" > "$TEMP_FILE" 2>&1; then
    echo "❌ BigQuery job failed:"
    cat "$TEMP_FILE"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Extract distinct count from result
DISTINCT_COUNT=$(tail -n 1 "$TEMP_FILE")
rm -f "$TEMP_FILE"

# Validate that we got a numeric result
if ! [[ "$DISTINCT_COUNT" =~ ^[0-9]+$ ]]; then
    echo "❌ Failed to get distinct count. Got: $DISTINCT_COUNT"
    echo "Please verify the table and column exist and you have access to them."
    exit 1
fi

CATEGORICAL_THRESHOLD=1000

echo "Distinct values found: $DISTINCT_COUNT"

# --- Step 2: Branch logic based on whether it's categorical ---

if [ "$DISTINCT_COUNT" -lt "$CATEGORICAL_THRESHOLD" ]; then
    # --- Logic for CATEGORICAL columns ---
    echo "-> Column appears to be CATEGORICAL. Generating stats and category counts."

    STATS_FILE="$PROFILE_DIR/${COLUMN_NAME}_stats.txt"
    CATEGORIES_FILE="$PROFILE_DIR/${COLUMN_NAME}_categories.csv"

    # Query for basic stats
    echo "📊 Generating basic stats..."
    TEMP_STATS=$(mktemp)
    if ! bq query --use_legacy_sql=false --format=pretty "
      SELECT
        COUNT(*) AS total_rows,
        $DISTINCT_COUNT AS distinct_values,
        COUNTIF($COLUMN_NAME IS NULL) AS null_values,
        ROUND(COUNTIF($COLUMN_NAME IS NULL) * 100 / COUNT(*), 2) AS null_percentage
      FROM \`$FULL_TABLE_NAME\`
    " > "$TEMP_STATS" 2>&1; then
        echo "❌ Basic stats query failed:"
        cat "$TEMP_STATS"
        rm -f "$TEMP_STATS"
        exit 1
    fi
    mv "$TEMP_STATS" "$STATS_FILE"

    # Query for category counts
    echo "📋 Generating category counts (top 1000)..."
    TEMP_CATS=$(mktemp)
    if ! bq query --use_legacy_sql=false --format=csv "
      SELECT
        $COLUMN_NAME,
        COUNT(*) AS count
      FROM \`$FULL_TABLE_NAME\`
      GROUP BY 1
      ORDER BY 2 DESC
      LIMIT 1000
    " > "$TEMP_CATS" 2>&1; then
        echo "❌ Category counts query failed:"
        cat "$TEMP_CATS"
        rm -f "$TEMP_CATS"
        exit 1
    fi
    mv "$TEMP_CATS" "$CATEGORIES_FILE"

    echo "✓ Basic stats saved to: $STATS_FILE"
    echo "✓ Category counts saved to: $CATEGORIES_FILE"
    echo ""
    echo "--- Stats ---"
    cat "$STATS_FILE"
    echo "
--- Top 10 Categories ---"
    head -n 11 "$CATEGORIES_FILE"

else
    # --- Logic for NON-CATEGORICAL columns ---
    echo "-> Column appears to be NON-CATEGORICAL. Generating detailed stats."
    OUTPUT_FILE="$PROFILE_DIR/${COLUMN_NAME}_details.txt"

    TEMP_DETAILS=$(mktemp)
    if ! bq query --use_legacy_sql=false --format=pretty "
      SELECT
        COUNT(*) AS total_rows,
        $DISTINCT_COUNT AS distinct_values,
        COUNTIF($COLUMN_NAME IS NULL) AS null_values,
        ROUND(COUNTIF($COLUMN_NAME IS NULL) * 100 / COUNT(*), 2) AS null_percentage,
        MIN(CAST($COLUMN_NAME AS STRING)) AS min_value,
        MAX(CAST($COLUMN_NAME AS STRING)) AS max_value,
        APPROX_TOP_COUNT($COLUMN_NAME, 10) AS top_10_values
      FROM \`$FULL_TABLE_NAME\`
    " > "$TEMP_DETAILS" 2>&1; then
        echo "❌ Detailed stats query failed:"
        cat "$TEMP_DETAILS"
        rm -f "$TEMP_DETAILS"
        exit 1
    fi
    mv "$TEMP_DETAILS" "$OUTPUT_FILE"

    echo "✓ Detailed stats saved to: $OUTPUT_FILE"
    echo ""
    echo "--- Details ---"
    cat "$OUTPUT_FILE"
fi