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

- `confidence` - For confident performances
- `winning` - For victories and success
- `dominance` - For dominant performances
- `close_games` - For close matchups
- `comeback` - For comeback victories
- `struggles` - For teams having difficulties
- `high_scoring` - For high-scoring games
- `perseverance` - For fighting through adversity

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
