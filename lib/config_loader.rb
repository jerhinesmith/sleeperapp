# frozen_string_literal: true

require 'yaml'

# Handles loading configuration files for relationships and quotes
class ConfigLoader # rubocop:disable Metrics/ClassLength
  CONFIG_DIR = File.join(__dir__, '..', 'config')

  def self.load_relationships
    relationships_file = File.join(CONFIG_DIR, 'relationships.yml')
    return [] unless File.exist?(relationships_file)

    data = YAML.load_file(relationships_file)
    data['relationships'] || []
  rescue StandardError => e
    puts "Warning: Could not load relationships config: #{e.message}" if $VERBOSE
    []
  end

  def self.load_madison_beer_quotes
    quotes_file = File.join(CONFIG_DIR, 'madison_beer_quotes.yml')
    return [] unless File.exist?(quotes_file)

    data = YAML.load_file(quotes_file)
    data['quotes'] || []
  rescue StandardError => e
    puts "Warning: Could not load Madison Beer quotes config: #{e.message}" if $VERBOSE
    []
  end

  def self.load_team_mappings
    mappings_file = File.join(CONFIG_DIR, 'team_mappings.yml')
    return { 'team_mappings' => {}, 'special_targets' => {} } unless File.exist?(mappings_file)

    data = YAML.load_file(mappings_file)
    {
      'team_mappings' => data['team_mappings'] || {},
      'special_targets' => data['special_targets'] || {}
    }
  rescue StandardError => e
    puts "Warning: Could not load team mappings config: #{e.message}" if $VERBOSE
    { 'team_mappings' => {}, 'special_targets' => {} }
  end

  def self.find_relationship_context(owner_names)
    relationships = load_relationships
    context = []

    relationships.each do |rel|
      matching_members = find_matching_members(rel, owner_names)
      next unless matching_members.size >= 2

      relationship_desc = build_relationship_description(rel, matching_members)
      context << relationship_desc
    end

    context
  end

  def self.find_matching_members(relationship, owner_names)
    members = relationship['members'] || []
    members.select do |member|
      owner_names.any? { |name| name.to_s.downcase.include?(member.downcase) }
    end
  end

  def self.build_relationship_description(relationship, matching_members) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity
    relationship_desc = case relationship['type']
                        when 'siblings'
                          "#{matching_members.join(' and ')} are siblings"
                        when 'spouses'
                          "#{matching_members.join(' and ')} are married"
                        when 'partners'
                          "#{matching_members.join(' and ')} are partners"
                        when 'parent_child'
                          "#{matching_members.first} and #{matching_members.last} are " \
                          'parent and child'
                        when 'father_daughter'
                          "#{matching_members.first} is #{matching_members.last}'s father - " \
                          "#{matching_members.last} is #{matching_members.first}'s daughter"
                        when 'father_son'
                          "#{matching_members.first} is #{matching_members.last}'s father - " \
                          "#{matching_members.last} is #{matching_members.first}'s son"
                        when 'mother_daughter'
                          "#{matching_members.first} is #{matching_members.last}'s mother - " \
                          "#{matching_members.last} is #{matching_members.first}'s daughter"
                        when 'mother_son'
                          "#{matching_members.first} is #{matching_members.last}'s mother - " \
                          "#{matching_members.last} is #{matching_members.first}'s son"
                        when 'aunt_nephew'
                          "#{matching_members.first} is an aunt to #{matching_members.last}"
                        when 'cousins'
                          "#{matching_members.join(', ')} are cousins"
                        when 'friends'
                          "#{matching_members.join(' and ')} are close friends"
                        when 'coworkers'
                          "#{matching_members.join(' and ')} work together"
                        else
                          "#{matching_members.join(' and ')} are related (#{relationship['type']})"
                        end

    relationship_desc += " - #{relationship['note']}" if relationship['note']
    relationship_desc
  end

  def self.select_madison_beer_quote(context_themes = [])
    quotes = load_madison_beer_quotes
    return fallback_quote if quotes.empty?

    # Try to find a quote that matches the context themes
    matching_quotes = quotes.select do |quote|
      quote_themes = quote['themes'] || []
      quote_themes.intersect?(context_themes)
    end

    # If no matching quotes, use any quote
    selected_quotes = matching_quotes.empty? ? quotes : matching_quotes
    selected_quote = selected_quotes.sample

    {
      text: selected_quote['text'],
      context: selected_quote['context']
    }
  end

  def self.fallback_quote
    {
      text: 'Stay focused on your goals and trust the process',
      context: 'good general motivation for any fantasy situation'
    }
  end

  def self.get_team_owner(team_name)
    mappings = load_team_mappings
    team_mappings = mappings['team_mappings'] || {}
    mapping = team_mappings[team_name]

    case mapping
    when Hash
      mapping['owner']
    when String
      mapping
    end
  end

  def self.get_team_pronouns(team_name)
    mappings = load_team_mappings
    team_mappings = mappings['team_mappings'] || {}
    mapping = team_mappings[team_name]

    return mapping['pronouns'] if mapping.is_a?(Hash)

    nil
  end

  def self.get_team_info(team_name)
    mappings = load_team_mappings
    team_mappings = mappings['team_mappings'] || {}
    mapping = team_mappings[team_name]

    case mapping
    when Hash
      {
        owner: mapping['owner'],
        pronouns: mapping['pronouns']
      }
    when String
      {
        owner: mapping,
        pronouns: nil
      }
    else
      {
        owner: nil,
        pronouns: nil
      }
    end
  end

  def self.get_special_target_teams(target_type)
    mappings = load_team_mappings
    special_targets = mappings['special_targets'] || {}
    special_targets[target_type] || []
  end

  def self.find_teams_by_owner_or_explicit_mapping(teams_data, target_owner,
                                                   fallback_search_terms = [])
    # Try explicit mapping first
    explicit_teams = find_explicit_team_mappings(target_owner)
    return find_teams_by_explicit_mapping(teams_data, explicit_teams) if explicit_teams.any?

    # Fallback to search logic
    search_teams_by_terms(teams_data, [target_owner] + fallback_search_terms)
  end

  def self.find_explicit_team_mappings(target_owner)
    mappings = load_team_mappings
    team_mappings = mappings['team_mappings'] || {}

    team_mappings.select do |_team_name, mapping|
      owner = case mapping
              when Hash
                mapping['owner']
              when String
                mapping
              end

      owner&.downcase == target_owner.downcase
    end
  end

  def self.find_teams_by_explicit_mapping(teams_data, explicit_teams)
    teams_data.select do |team|
      explicit_teams.key?(team['team_name']) || explicit_teams.key?(team[:team_name])
    end
  end

  def self.search_teams_by_terms(teams_data, search_terms)
    teams_data.select do |team|
      name_fields = [team['owner'], team['team_name'], team[:owner], team[:team_name]]
                    .compact.map(&:to_s).map(&:downcase)

      search_terms.any? do |term|
        name_fields.any? { |field| field.include?(term.downcase) }
      end
    end
  end
end
