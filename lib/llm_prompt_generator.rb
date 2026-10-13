# frozen_string_literal: true

require 'json'
require_relative 'config_loader'

# Builds the structured LLM prompt from a week's JSON summary data
class LLMPromptGenerator # rubocop:disable Metrics/ClassLength
  def initialize
    @json_data = nil
    @notes = []
  end

  def generate_prompt(json_input, notes: [])
    @json_data = parse_json_input(json_input)
    @notes = notes

    prompt_sections = [
      build_header,
      build_context_section,
      build_matchup_instructions,
      build_transaction_instructions,
      build_special_sections_instructions,
      build_tone_and_format_instructions,
      build_data_section
    ]

    prompt_sections.join("\n\n")
  end

  private

  def parse_json_input(input)
    case input
    when String
      JSON.parse(input)
    when Hash
      input
    else
      raise "Invalid input type: #{input.class}"
    end
  rescue JSON::ParserError => e
    raise "Invalid JSON input: #{e.message}"
  end

  def build_header
    <<~HEADER
      # 🏈 Weekly Fantasy Football Summary Generator

      You are tasked with creating a fun, family-friendly fantasy football weekly summary with lots of playful banter and personality.
    HEADER
  end

  def build_context_section
    league_name = @json_data.dig('league_info', 'name') || 'Fantasy League'
    week = @json_data['week']

    # Get relationship context
    owner_names = extract_owner_names
    relationships = ConfigLoader.find_relationship_context(owner_names)

    relationship_context = if relationships.any?
                             "\n\n**Family/Friend Relationships:**\n#{relationships.map do |rel|
                               "- #{rel}"
                             end.join("\n")}"
                           else
                             ''
                           end

    manager_notes_context = build_manager_notes_context(owner_names)
    rematch_context = build_rematch_context
    sacko_context = build_sacko_context
    weekly_notes_context = build_weekly_notes_context

    # Add team-to-owner mappings for clarity
    team_mappings_context = build_team_mappings_context

    <<~CONTEXT
      ## League Context

      **League:** #{league_name}
      **Week:** #{week}
      **Generated:** #{@json_data['generated_at']}

      This is a family/friend league where good-natured ribbing and playful trash talk are encouraged. Keep the tone light, fun, and engaging while highlighting the key storylines from this week.#{relationship_context}#{manager_notes_context}#{rematch_context}#{sacko_context}#{weekly_notes_context}#{team_mappings_context}
    CONTEXT
  end

  def build_manager_notes_context(owner_names)
    notes = ConfigLoader.find_manager_notes(owner_names)
    return '' if notes.empty?

    lines = notes.map { |entry| "- #{entry['member']}: #{entry['note']}" }
    "\n\n**Manager Notes:**\n#{lines.join("\n")}"
  end

  def build_rematch_context
    rematches = ConfigLoader.find_rematches(@json_data['matchups'] || [])
    return '' if rematches.empty?

    "\n\n**Notable Rematches:**\n#{rematches.map { |r| "- #{r}" }.join("\n")}"
  end

  def build_sacko_context
    sackos = ConfigLoader.find_returning_sackos(@json_data['last_place_watch'])
    return '' if sackos.empty?

    "\n\n**Last Place Watch:**\n#{sackos.map { |s| "- #{s}" }.join("\n")}"
  end

  def build_weekly_notes_context
    return '' if @notes.empty?

    "\n\n**This Week's Notes:**\n#{@notes.map { |n| "- #{n}" }.join("\n")}"
  end

  def build_matchup_instructions
    <<~MATCHUPS
      ## 📊 Matchup Analysis Instructions

      For each matchup, provide:

      1. **Matchup Result Summary** - Winner, final score, margin of victory
      2. **Key Performances** - Highlight standout players (both good and bad)
      3. **Transaction Impact Analysis** - Did any waiver wire pickups or recent adds help this week?
      4. **Bench Analysis** - Point out any bench players who would have made a difference if started
      5. **Playful Commentary** - Add some family-friendly banter about the teams/owners

      Focus on storytelling and making each matchup feel like a mini-drama with heroes, villains, and plot twists.
    MATCHUPS
  end

  def build_transaction_instructions
    <<~TRANSACTIONS
      ## 💼 Weekly Transaction Summary Instructions

      Create a "Waiver Wire Report" section that covers:

      1. **Most Active Managers** - Who was busy on the waiver wire?
      2. **Smart Pickups** - Which adds paid off immediately?
      3. **Questionable Drops** - Anyone drop someone who scored well?
      4. **Waiver Wire Winners/Losers** - Who made the best/worst moves?

      Make this feel like insider trading analysis but for fantasy football.
    TRANSACTIONS
  end

  def build_special_sections_instructions
    danielle_info = describe_danielle_teams

    # Get a Madison Beer quote based on this week's context
    context_themes = determine_week_themes
    madison_quote = ConfigLoader.select_madison_beer_quote(context_themes)

    <<~SPECIAL
      ## 🎵 Special Sections Instructions

      ### Madison Beer Quote of the Week
      Use this actual Madison Beer inspired quote: "#{madison_quote[:text]}"
      - Context: #{madison_quote[:context]}
      - Relate it to this week's fantasy results in a creative way
      - Keep it PG and fun

      ### Unbeaten & Winless Watch
      #{build_records_watch_instructions}

      ### "Danielle Last Place Watch"
      - #{danielle_info}
      - Provide a humorous update on how Danielle's team is doing
      - If Danielle isn't actually in last place, playfully roast her anyway
      - Include record, recent performance, and chances of avoiding the sacko
      - Make it sound like a sports ticker update but with family sass

      ### Next Week Preview
      - Create a "Looking Ahead" section with next week's matchup previews
      - Highlight interesting storylines and potential revenge games
      - Mention key players to watch and potential lineup decisions
      - Build anticipation for competitive matchups
      - Include family dynamics if relatives are facing off
      - Keep it brief but engaging - 2-3 sentences per matchup
    SPECIAL
  end

  def build_records_watch_instructions
    "#{describe_unbeaten_teams}\n#{describe_winless_teams}"
  end

  def describe_danielle_teams
    danielle_teams = find_danielle_teams_improved
    if danielle_teams.empty?
      return 'Look for teams owned by Danielle or similar names, or use the last place team(s)'
    end

    team_names = danielle_teams.map { |t| t['team_name'] || t[:team_name] }.compact
    owner_names = danielle_teams.map { |t| t['owner'] || t[:owner] }.compact.uniq
    "Focus on: #{team_names.join(', ')} (owned by: #{owner_names.join(', ')})"
  end

  def describe_unbeaten_teams
    teams = find_unbeaten_teams
    return '- No team is unbeaten this week - skip this callout entirely.' if teams.empty?

    names = teams.map { |t| "#{t['owner']} (#{t['team_name']}, #{t['wins']}-#{t['losses']})" }
    if teams.size == 1
      "- #{names.first} is the last unbeaten team left in the league - give this real " \
        'emphasis, a dedicated paragraph building suspense around the chase for a perfect season.'
    else
      "- Still unbeaten: #{names.join(', ')} - call out that multiple teams remain perfect " \
        'and build anticipation for when one of them finally loses.'
    end
  end

  def describe_winless_teams
    teams = find_winless_teams
    return '- No team is still winless this week - skip this callout entirely.' if teams.empty?

    names = teams.map { |t| "#{t['owner']} (#{t['team_name']}, #{t['wins']}-#{t['losses']})" }
    if teams.size == 1
      "- #{names.first} is the only winless team left - give this real emphasis too, as the " \
        'flip side of the unbeaten storyline.'
    else
      "- Still winless: #{names.join(', ')} - call out the shared misery and who is most " \
        'likely to break through first.'
    end
  end

  def find_unbeaten_teams
    (@json_data['standings'] || []).select do |t|
      (t['wins'] || 0).positive? && (t['losses'] || 0).zero?
    end
  end

  def find_winless_teams
    (@json_data['standings'] || []).select do |t|
      (t['wins'] || 0).zero? && (t['losses'] || 0).positive?
    end
  end

  def build_tone_and_format_instructions
    <<~TONE
      ## 🎯 Tone & Format Guidelines

      **Writing Style:**
      - Family-friendly banter and playful roasting
      - Use emoji liberally and often - several per section, don't hold back 🎉🏈🔥
      - Include fantasy football terminology but explain it if needed
      - Make everyone feel included in the fun
      - Balance congratulations with gentle ribbing

      **Structure:**
      1. Week Overview (2-3 sentences)
      2. Matchup Breakdowns (one section per matchup)
      3. Waiver Wire Report
      4. Madison Beer Quote of the Week
      5. Unbeaten & Winless Watch
      6. Danielle Last Place Watch
      7. Next Week Preview (upcoming matchups and storylines)

      **Length:** Aim for 600-900 words total - detailed enough to be engaging but not overwhelming.
    TONE
  end

  def build_data_section
    <<~DATA
      ## 📋 Week #{@json_data['week']} Data

      ```json
      #{JSON.pretty_generate(@json_data)}
      ```

      ---

      **Now generate the fun weekly summary using this data and following all the instructions above!**
    DATA
  end

  def extract_owner_names
    names = []

    # Get names from standings
    if @json_data['standings']
      names.concat(@json_data['standings'].map { |team| team['owner'] }.compact)
    end

    # Get names from matchups
    @json_data['matchups']&.each do |matchup|
      matchup['teams']&.each do |team|
        names << team['owner'] if team['owner']
      end
    end

    names.uniq.compact
  end

  def determine_week_themes
    themes = []
    themes.concat(analyze_matchup_themes)
    themes.concat(analyze_standings_themes)
    themes.uniq
  end

  def analyze_matchup_themes
    themes = []
    return themes unless @json_data['matchups']

    @json_data['matchups'].each do |matchup|
      next unless matchup['teams']&.size == 2

      themes.concat(extract_matchup_themes(matchup))
    end

    themes
  end

  def extract_matchup_themes(matchup)
    themes = []
    team1, team2 = matchup['teams']
    margin = matchup['margin'] || 0

    themes << 'close_games' if margin < 10
    themes << 'dominance' if margin > 40

    if team1 && team2
      total_points = (team1['points'] || 0) + (team2['points'] || 0)
      themes << 'high_scoring' if total_points > 250
    end

    themes
  end

  def analyze_standings_themes
    themes = []
    return themes unless @json_data['standings']

    first_place = @json_data['standings'].first
    themes << 'winning_streak' if first_place && (first_place['wins'] || 0) > 1

    last_place = @json_data['standings'].last
    themes << 'struggles' if last_place && (last_place['wins'] || 0).zero?

    themes
  end

  def find_danielle_teams_improved
    return [] unless @json_data['standings']

    # First, check if there are explicitly configured Danielle teams
    explicit_danielle_teams = ConfigLoader.get_special_target_teams('danielle_teams')

    if explicit_danielle_teams.any?
      # Find teams that match the explicit configuration
      return @json_data['standings'].select do |team|
        team_name = team['team_name'] || team[:team_name]
        explicit_danielle_teams.include?(team_name)
      end
    end

    # Fallback to improved search with better owner/team distinction
    ConfigLoader.find_teams_by_owner_or_explicit_mapping(
      @json_data['standings'],
      'danielle',
      %w[dani daniella] # Additional search terms
    )
  end

  # Keep the old method for backwards compatibility
  def find_danielle_teams
    find_danielle_teams_improved
  end

  def build_team_mappings_context
    return '' unless @json_data['standings']

    # Build a list of team-to-owner mappings from the data
    team_owner_pairs = []
    pronoun_info = []

    @json_data['standings'].each do |team|
      team_name = team['team_name'] || team[:team_name] || 'Unknown Team'
      owner_name = team['owner'] || team[:owner] || 'Unknown Owner'

      # Get team info (owner and pronouns)
      team_info = ConfigLoader.get_team_info(team_name)
      actual_owner = team_info[:owner] || owner_name
      pronouns = team_info[:pronouns]

      mapping_text = "- #{team_name} → #{actual_owner}"
      mapping_text += ' (explicit mapping)' if team_info[:owner]
      team_owner_pairs << mapping_text

      # Collect pronoun information
      pronoun_info << "- #{actual_owner} uses #{pronouns} pronouns" if pronouns
    end

    return '' if team_owner_pairs.empty?

    context = "\n\n**Team Name to Owner Mappings:**\n#{team_owner_pairs.join("\n")}"

    context += "\n\n**Pronoun Information:**\n#{pronoun_info.join("\n")}" if pronoun_info.any?

    context += "\n\n**IMPORTANT:** Always use the correct owner name when referring to teams. " \
               'Do not confuse team names with owner names. ' \
               'Use the correct pronouns for each person.'

    context
  end
end
