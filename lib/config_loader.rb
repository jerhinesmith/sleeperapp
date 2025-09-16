# frozen_string_literal: true

require 'yaml'

# Handles loading configuration files for relationships and quotes
class ConfigLoader
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

  def self.build_relationship_description(relationship, matching_members)
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
end
