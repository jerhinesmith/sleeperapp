# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'
require_relative 'sleeper_api'

# Manages player data, including caching and lookups
class PlayerService
  CACHE_DURATION = 24 * 3600 # 24 hours in seconds

  def initialize(cache_dir: '.sleeper_cache')
    @cache_dir = cache_dir
    @players_cache = nil
    setup_cache_directory
  end

  def player_name(player_id)
    players_data = cached_players
    player = players_data[player_id.to_s]

    if player
      format_player_name(player)
    else
      # Likely a team defense or unknown player
      player_id.to_s.length <= 4 ? "#{player_id} D/ST" : player_id.to_s
    end
  end

  def player_info(player_id)
    players_data = cached_players
    players_data[player_id.to_s]
  end

  private

  def setup_cache_directory
    FileUtils.mkdir_p(@cache_dir)
  end

  def cached_players
    return @players_cache if @players_cache

    cache_file = File.join(@cache_dir, 'players.json')

    if cache_valid?(cache_file)
      @players_cache = JSON.parse(File.read(cache_file))
    else
      fetch_and_cache_players(cache_file)
    end

    @players_cache
  end

  def cache_valid?(cache_file)
    File.exist?(cache_file) && (Time.now - File.mtime(cache_file) < CACHE_DURATION)
  end

  def fetch_and_cache_players(cache_file)
    puts 'Fetching player data from Sleeper API...' if $VERBOSE
    @players_cache = SleeperAPI.players
    File.write(cache_file, JSON.pretty_generate(@players_cache))
    puts "Cached player data to #{cache_file}" if $VERBOSE
  end

  def format_player_name(player)
    first_name = player['first_name'] || player['first'] || ''
    last_name = player['last_name'] || player['last'] || ''
    name = [first_name, last_name].join(' ').strip

    name.empty? ? (player['full_name'] || player['player_id'] || 'Unknown') : name
  end
end
