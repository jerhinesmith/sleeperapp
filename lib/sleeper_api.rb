# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

# Handles all HTTP requests to the Sleeper API
class SleeperAPI
  BASE_URL = 'https://api.sleeper.app/v1/'

  class APIError < StandardError; end

  def self.get(path)
    uri = URI.join(BASE_URL, path)
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise APIError, "HTTP #{response.code} for #{uri} - #{response.body}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise APIError, "Invalid JSON response from #{uri}: #{e.message}"
  end

  def self.nfl_state
    get('state/nfl')
  end

  def self.players(sport = 'nfl')
    get("players/#{sport}")
  end

  def self.league(league_id)
    get("league/#{league_id}")
  end

  def self.league_users(league_id)
    get("league/#{league_id}/users")
  end

  def self.league_rosters(league_id)
    get("league/#{league_id}/rosters")
  end

  def self.league_matchups(league_id, week)
    get("league/#{league_id}/matchups/#{week}")
  end

  def self.league_transactions(league_id, week)
    get("league/#{league_id}/transactions/#{week}")
  end

  def self.winners_bracket(league_id)
    get("league/#{league_id}/winners_bracket")
  end

  def self.losers_bracket(league_id)
    get("league/#{league_id}/losers_bracket")
  end
end
