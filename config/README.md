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
