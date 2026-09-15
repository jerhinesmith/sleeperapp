# Configuration Files

This directory contains configuration files for customizing the LLM prompt generation.

## relationships.yml

Defines family and friend relationships between league members for use in weekly summaries.

### Format

```yaml
relationships:
  - type: "relationship_type"     # Type of relationship (required)
    members: ["name1", "name2"]   # List of related members (required)
    note: "Optional context"      # Additional context (optional)
```

### Supported Relationship Types

- `siblings` - Brothers and sisters
- `spouses` - Married couples
- `parent_child` - Parent and child relationships
- `cousins` - Cousin relationships
- `friends` - Close friends
- `coworkers` - Work colleagues

### Example

```yaml
relationships:
  - type: "siblings"
    members: ["jerhinesmith", "drhinesmith"]
    note: "The Rhinesmith brothers"

  - type: "spouses"
    members: ["raffel75", "sararaffel"]
    note: "The Raffel power couple"

  - type: "parent_child"
    members: ["dad_username", "son_username"]
    note: "Father and son fantasy rivalry"
```

### Usage

The relationship information will automatically appear in the LLM prompt's League Context section when related members are active in the current week's matchups.

## team_mappings.yml

Provides explicit mappings between fantasy team names and their owners to prevent confusion in LLM prompt generation. This is especially useful when team names don't clearly indicate who owns them (e.g., "Dummy's Dummies" owned by "Darlene").

### Format

```yaml
team_mappings:
  "Team Name 1": "owner_username"  # Simple string format
  "Team Name 2":                   # Extended format with pronouns
    owner: "another_owner"
    pronouns: "he/him"             # Optional: helps LLM use correct pronouns

special_targets:
  danielle_teams:
    - "team_name_1"
    - "team_name_2"
```

### Example

```yaml
team_mappings:
  "Dummy's Dummies": "darlene"
  "The Champions": "john_smith"
  "Fantasy Legends": "mike_jones"
  "Dana's Team":
    owner: "Dana"
    pronouns: "he/him"             # Helps LLM use correct pronouns

special_targets:
  danielle_teams:
    - "Danielle's Destroyers"
    - "Team Danielle"
```

### How It Works

1. **Explicit Team Mappings**: When the LLM encounters a team name that has an explicit mapping, it will use the mapped owner name instead of guessing
2. **Pronoun Support**: The extended format allows you to specify pronouns to help the LLM use correct pronouns (he/him, she/her, they/them, etc.)
3. **Special Targets**: For features like "Danielle Last Place Watch", you can explicitly specify which teams should be targeted
4. **Fallback Logic**: If no explicit mapping exists, the system falls back to intelligent name matching

### Automatic Generation

You can automatically generate the team mappings file from your Sleeper league data:

```bash
# Using environment variable
SLEEPER_LEAGUE_ID=123456789012345678 bin/generate_team_mappings

# Using command line argument
bin/generate_team_mappings 123456789012345678

# Preserve existing mappings when updating
bin/generate_team_mappings --preserve
```

This will create a `team_mappings.yml` file with all your team names and empty owner fields for you to fill in manually.

### Usage

The team mapping information automatically appears in the LLM prompt's League Context section, providing clear guidance like:

```
**Team Name to Owner Mappings:**
- Dummy's Dummies → darlene (explicit mapping)
- The Champions → john_smith (explicit mapping)
- Dana's Team → Dana (explicit mapping)
- Team Smith → mike_smith

**Pronoun Information:**
- Dana uses he/him pronouns

**IMPORTANT:** Always use the correct owner name when referring to teams.
Do not confuse team names with owner names. Use the correct pronouns for each person.
```

## manager_notes.yml

Standing flavor/storyline notes about individual managers (e.g. "rookie this year", "didn't
want to play") that get woven into the LLM prompt automatically whenever that manager is
active, instead of having to re-explain the same context by hand every week.

### Format

```yaml
notes:
  - member: "sleeper_username"    # Matched the same way relationships.yml is (case-insensitive substring)
    note: "Free text description of the storyline"
```

A member can have multiple notes. They surface in the prompt's League Context as:

```
**Manager Notes:**
- krayla21: Rookie manager - first year in the league.
```

## league_history.yml

Past-season results used to automatically flag rivalry/rematch storylines when this year's
matchups pit the same two managers against each other again (e.g. a championship rematch).

### Format

```yaml
seasons:
  - year: 2025
    champion: "sleeper_username"
    runner_up: "sleeper_username"
    note: "Optional extra context"
```

When a current-week matchup exactly matches a past season's champion/runner-up pair, it
surfaces in the prompt as:

```
**Notable Rematches:**
- sararaffel vs. BWilson8080 is a rematch of the 2025 championship (won by sararaffel)
```

### Automatic Generation

Rather than filling this in by hand, generate it from the Sleeper API. It walks the
`previous_league_id` chain back from the given league and reads each past season's
`winners_bracket` for the championship game (`"p": 1`):

```bash
# Using environment variable
SLEEPER_LEAGUE_ID=123456789012345678 bin/generate_league_history

# Using command line argument (overrides ENV)
bin/generate_league_history 123456789012345678

# Preserve any manually-added "note" text on seasons already in the file
bin/generate_league_history --preserve
```

The given league ID is always treated as the current, in-progress season and is never
included in the output. Walking stops wherever a season has no `previous_league_id` (e.g.
the league's first year on Sleeper, even if it existed on another platform before that).

## madison_beer_quotes.yml

Contains a curated collection of Madison Beer-inspired quotes that relate to fantasy football situations.

### Format

```yaml
quotes:
  - text: "Quote text here"           # The actual quote (required)
    context: "When to use this"       # Usage context (required)
    themes: ["theme1", "theme2"]      # Applicable themes (required)
```

### Supported Themes

Themes are free-form tags matched by exact string against whatever `bin/generate_llm_prompt`
detects for the week (see `determine_week_themes` in that script). It currently generates:

- `close_games` - margin under 10 points
- `dominance` - margin over 40 points
- `high_scoring` - combined matchup score over 250
- `winning_streak` - first place team with 2+ wins
- `struggles` - last place team still winless

Every quote should carry at least one of these exact tags to ever get selected automatically;
anything else (`waivers`, `trash_talk`, `confidence`, etc.) is extra flavor for manual/creative
use but won't be matched by the week-theme detector above. If you add a new theme to
`determine_week_themes`, make sure at least one quote is tagged with it, or that path silently
falls back to the generic quote.

### How It Works

The system automatically selects an appropriate quote based on the week's themes:

1. Analyzes matchup results (margins, scores, etc.)
2. Identifies themes from the week's action
3. Selects a quote that matches those themes
4. Includes it in the LLM prompt with context

### Adding Your Own Quotes

You can add new quotes by following the format above. Make sure to:

1. Keep quotes family-friendly and appropriate
2. Choose relevant themes that match fantasy football situations
3. Provide helpful context for when the quote should be used
4. Test that the quote works well with your league's tone

### Example Usage in Generated Prompt

```
### Madison Beer Quote of the Week
Use this actual Madison Beer inspired quote: "I know my worth and I'm not settling for less"
- Context: perfect for when someone dominates their matchup
- Relate it to this week's fantasy results in a creative way
- Keep it PG and fun
```
