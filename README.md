# 🏈 Sleeper Fantasy Football Weekly Summary

A set of Ruby scripts to generate comprehensive fantasy football weekly summaries from the Sleeper API and create fun, family-friendly LLM prompts for generating engaging league reports.

## Scripts Overview

### 1. `bin/weekly_summary` - Main Data Extractor
**Object-oriented version** that fetches and analyzes weekly fantasy data with dotenv support:

- **Matchup analysis** - Winners, margins, player performances
- **Transaction tracking** - Waiver wire activity, adds/drops
- **League standings** - Win/loss records, points for/against
- **Bench analysis** - Points left on the bench
- **Last place tracking** - Bottom teams for friendly ribbing

### 2. `bin/generate_llm_prompt` - Fun Summary Generator
Creates structured prompts for LLMs to generate entertaining weekly summaries with:

- **Family-friendly banter** - Playful trash talk and commentary
- **Madison Beer quote of the week** - Pop culture integration
- **"Danielle Last Place Watch"** - Personalized tracking section
- **Transaction impact analysis** - Did waiver moves pay off?
- **Bench regret analysis** - Should've started players

## Quick Start

### Basic Usage
```bash
# Using environment variable (no arguments needed!)
SLEEPER_LEAGUE_ID=YOUR_LEAGUE_ID bin/weekly_summary

# Generate data + LLM prompt in one command
SLEEPER_LEAGUE_ID=YOUR_LEAGUE_ID bin/weekly_summary | bin/generate_llm_prompt

# Using .env file (even simpler)
echo 'SLEEPER_LEAGUE_ID=YOUR_LEAGUE_ID' > .env
bin/weekly_summary
```

### Save to Files
```bash
# Save JSON data
bin/weekly_summary LEAGUE_ID 1 --out week1_data.json

# Generate prompt from saved data
bin/generate_llm_prompt --input week1_data.json --output week1_prompt.txt
```

## Detailed Usage

### Weekly Summary Script
```bash
bin/weekly_summary [LEAGUE_ID] WEEK [OPTIONS]

Arguments:
  LEAGUE_ID    Sleeper league ID (optional if SLEEPER_LEAGUE_ID env var is set)
  WEEK         NFL week number, or 'auto' for current week

Options:
  --out PATH   Save JSON output to file
  --verbose    Enable detailed logging

Environment Variables:
  SLEEPER_LEAGUE_ID    Default league ID (can be overridden by command line)
```

### LLM Prompt Generator
```bash
bin/generate_llm_prompt [OPTIONS]

Options:
  --input PATH    Read JSON from file instead of STDIN
  --output PATH   Write prompt to file instead of STDOUT
  --help         Show help message
```

## Architecture

The refactored codebase uses clean, modular classes:

- **`SleeperAPI`** - HTTP client for Sleeper API endpoints
- **`PlayerService`** - Player data management and caching (24hr cache)
- **`LeagueService`** - League operations (users, rosters, matchups)
- **`MatchupAnalyzer`** - Analyzes games, determines winners/margins
- **`TransactionAnalyzer`** - Processes waiver wire activity
- **`WeeklySummaryGenerator`** - Coordinates all services
- **`LLMPromptGenerator`** - Creates structured prompts for LLMs

## Sample Output Structure

The JSON output includes:
```json
{
  "league_id": "...",
  "week": 1,
  "league_info": { "name": "...", "total_rosters": 8 },
  "matchups": [...],           // Detailed matchup analysis
  "transactions": {...},       // Waiver wire activity
  "standings": [...],          // Current league standings
  "last_place_watch": [...]    // Bottom teams for tracking
}
```

## Features

✅ **Rich Data Extraction** - Comprehensive fantasy data analysis
✅ **Clean Architecture** - Modular, testable, maintainable code
✅ **Smart Caching** - 24-hour player data cache (5MB+ file)
✅ **Error Handling** - Graceful API error handling
✅ **Flexible Output** - JSON to stdout, files, or piped commands
✅ **LLM Integration** - Structured prompts for AI-generated summaries
✅ **Family-Friendly** - Designed for fun league banter

## Requirements

- **Ruby 2.7+** (uses built-in JSON, Net::HTTP, URI)
- **Internet connection** for Sleeper API
- **Valid Sleeper league ID** (public leagues only)
- **Optional:** dotenv, rspec, rubocop gems for development

## Setup & Installation

```bash
# Clone/download the project
cd sleeperapp

# Install development dependencies (optional)
bundle install

# Set up your league ID
cp .env.example .env
# Edit .env and set your SLEEPER_LEAGUE_ID

# Run tests (optional)
bundle exec rspec

# Run linter (optional)
bundle exec rubocop
```

## Examples

### Generate Current Week Summary
```bash
# Using environment variable (simplest - no arguments needed!)
SLEEPER_LEAGUE_ID=1234567890000000000 bin/weekly_summary

# Using .env file (recommended for regular use)
echo 'SLEEPER_LEAGUE_ID=1234567890000000000' > .env
bin/weekly_summary

# Or with command line argument
bin/weekly_summary 1234567890000000000 auto
```

### Create Fun LLM Prompt
```bash
# Full pipeline: data extraction → LLM prompt generation (simplified!)
SLEEPER_LEAGUE_ID=1234567890000000000 bin/weekly_summary | bin/generate_llm_prompt

# Or using .env file
bin/weekly_summary | bin/generate_llm_prompt
```

### Save Everything
```bash
# Save data and prompt separately
bin/weekly_summary 1234567890000000000 1 --out week1.json
bin/generate_llm_prompt --input week1.json --output week1_prompt.txt

# Or using .env file with custom defaults
echo 'SLEEPER_LEAGUE_ID=1234567890000000000' > .env
echo 'SLEEPER_DEFAULT_WEEK=1' >> .env
bin/weekly_summary --out week1.json
```

## Finding Your League ID

Your Sleeper league ID is in the URL when viewing your league:
```
https://sleeper.app/leagues/1234567890000000000/team
                            ^^^^^^^^^^^^^^^^^^^
                            This is your league ID
```

---

## API Reference

Uses the [Sleeper API](https://docs.sleeper.com/) - free, read-only, no authentication required.

**Rate Limit:** Stay under 1000 calls/minute to avoid IP blocks.

---

🏈 **Ready to generate some epic fantasy football content!** 🏈
