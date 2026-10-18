#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="logs/lab3.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Cleanup / Exit trap
cleanup() {
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log "LAB3_END"
    else
        log "SCRIPT_FAILED_WITH_EXIT_CODE_$exit_code"
    fi
}
trap cleanup EXIT

# Ensure data and logs directories exist
mkdir -p data logs

log "BASH_OK"
echo "Bash script validation and initialization successful."

# --- Step 3: Dad Jokes API ---
JOKE_URL="https://icanhazdadjoke.com/"
JOKE_STATUS=$(curl -sS -H 'Accept: application/json' -w '%{http_code}' -o data/dad_joke.json "$JOKE_URL")

if [ "$JOKE_STATUS" -ne 200 ]; then
    log "CURL_JOKE_FAIL"
    echo "Error: Dad Jokes API returned status $JOKE_STATUS" >&2
    exit 1
fi
log "CURL_JOKE_OK"

# Parse fields with jq
jq -r '.id, .joke' data/dad_joke.json > data/dad_joke.txt
log "JQ_JOKE_OK"

# --- Step 4: Deck of Cards API ---
# 1. Create a deck
CREATE_URL="https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1"
CREATE_STATUS=$(curl -sS -w '%{http_code}' -o data/deck_create.json "$CREATE_URL")

if [ "$CREATE_STATUS" -ne 200 ]; then
    echo "Error creating deck" >&2
    exit 1
fi
log "DECK_CREATE_OK"

# Extract deck_id using jq
DECK_ID=$(jq -r '.deck_id' data/deck_create.json)

# 2. Draw 2 cards using the deck_id
DRAW_URL="https://deckofcardsapi.com/api/deck/$DECK_ID/draw/?count=2"
DRAW_STATUS=$(curl -sS -w '%{http_code}' -o data/deck_draw.json "$DRAW_URL")

if [ "$DRAW_STATUS" -ne 200 ]; then
    echo "Error drawing cards" >&2
    exit 1
fi
log "DECK_DRAW_OK"

# Save summary including remaining cards and drawn cards
{
    echo "Remaining Cards: $(jq -r '.remaining' data/deck_draw.json)"
    echo "Drawn Cards:"
    jq -r '.cards[] | "- \(.value) of \(.suit)"' data/deck_draw.json
} > data/deck_summary.txt

log "JQ_DECK_OK"