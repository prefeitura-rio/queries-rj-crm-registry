#!/bin/bash

# Simple Table Schema Extractor
# Usage: ./get_schema.sh <table_name>

set -e

if [ -z "$1" ]; then
    echo "❌ Usage: $0 <table_name>"
    echo "Example: $0 \"project.dataset.table\""
    exit 1
fi

TABLE_NAME="$1"

# Get script directory to ensure we always write to correct location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Create directory name from table name (replace dots with underscores)
DIR_NAME=$(echo "$TABLE_NAME" | sed 's/\./_/g')
PROFILE_DIR="$REPO_ROOT/analyses/profile/results/$DIR_NAME"
OUTPUT_FILE="$PROFILE_DIR/schema.csv"

# Create profile directory
mkdir -p "$PROFILE_DIR"

echo "Getting schema for: $TABLE_NAME"
echo "Output directory: $PROFILE_DIR"
echo "Output file: $OUTPUT_FILE"
echo ""

# Parse table components
PROJECT=$(echo "$TABLE_NAME" | cut -d'.' -f1)
DATASET=$(echo "$TABLE_NAME" | cut -d'.' -f2) 
TABLE=$(echo "$TABLE_NAME" | cut -d'.' -f3)

# Create temporary file for bq output
TEMP_FILE=$(mktemp)

# Get schema information with error handling
if ! bq query --use_legacy_sql=false --format=csv "
SELECT 
  ordinal_position,
  column_name,
  data_type,
  is_nullable,
  CASE 
    WHEN data_type IN ('STRING') THEN 'Text'
    WHEN data_type IN ('INT64', 'FLOAT64', 'NUMERIC') THEN 'Numeric'
    WHEN data_type IN ('DATE', 'DATETIME', 'TIMESTAMP') THEN 'Temporal'
    WHEN data_type = 'BOOLEAN' THEN 'Boolean'
    ELSE 'Other'
  END as category
FROM \`$PROJECT.$DATASET\`.INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = '$TABLE'
ORDER BY ordinal_position
" > "$TEMP_FILE" 2>&1; then
    echo "❌ BigQuery job failed:"
    cat "$TEMP_FILE"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Check if we got actual results (more than just header)
if [ $(wc -l < "$TEMP_FILE") -le 1 ]; then
    echo "❌ No columns found for table: $TABLE_NAME"
    echo "Please verify the table exists and you have access to it."
    rm -f "$TEMP_FILE"
    exit 1
fi

# Move temp file to final location
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "✓ Schema saved to: $OUTPUT_FILE"
echo ""
echo "Column count:"
tail -n +2 "$OUTPUT_FILE" | wc -l
echo ""
echo "First 10 columns:"
head -11 "$OUTPUT_FILE"