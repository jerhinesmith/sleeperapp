# frozen_string_literal: true

require 'time'
require_relative 'sleeper_api'
require_relative 'player_service'
require_relative 'league_service'
require_relative 'matchup_analyzer'
require_relative 'transaction_analyzer'

# Main class that coordinates all services to generate the weekly summary
class WeeklySummaryGenerator
  def initialize(league_id, cache_dir: '.sleeper_cache')
    @league_id = league_id
    @player_service = PlayerService.new(cache_dir: cache_dir)
    @league_service = LeagueService.new(league_id)
    @matchup_analyzer = MatchupAnalyzer.new(@player_service, @league_service)
    @transaction_analyzer = TransactionAnalyzer.new(@player_service)
  end

  def generate_summary(week = nil)
    week ||= @league_service.current_nfl_week
    puts "Generating summary for week #{week}..." if $VERBOSE

    {
      league_id: @league_id,
      week: week,
      generated_at: Time.now.iso8601,
      league_info: extract_league_info,
      matchups: generate_matchup_summaries(week),
      transactions: generate_transaction_summary(week),
      standings: generate_standings,
      last_place_watch: @league_service.last_place_teams(2) # Bottom 2 teams
    }
  rescue SleeperAPI::APIError => e
    puts "Error generating summary: #{e.message}" if $VERBOSE
    raise
  end

  private

  def extract_league_info
    info = @league_service.league_info
    {
      name: info['name'],
      total_rosters: info['total_rosters'],
      season: info['season'],
      status: info['status']
    }
  end

  def generate_matchup_summaries(week)
    matchups_data = @league_service.matchups(week)
    @matchup_analyzer.analyze_matchups(matchups_data)
  end

  def generate_transaction_summary(week)
    transactions_data = @league_service.transactions(week)
    analysis = @transaction_analyzer.analyze_transactions(transactions_data)

    {
      week: week,
      **analysis
    }
  end

  def generate_standings
    standings = @league_service.team_standings
    roster_map = @league_service.roster_owner_map

    standings.map.with_index do |roster, index|
      owner_info = roster_map[roster['roster_id'].to_i]
      settings = roster['settings'] || {}

      {
        rank: index + 1,
        roster_id: roster['roster_id'].to_i,
        owner: owner_info&.dig('display_name') || 'Unknown',
        team_name: owner_info&.dig('team_name') || 'Unknown',
        wins: settings['wins'] || 0,
        losses: settings['losses'] || 0,
        ties: settings['ties'] || 0,
        points_for: (settings['fpts'] || 0).to_f.round(2),
        points_against: (settings['fpts_against'] || 0).to_f.round(2)
      }
    end
  end
end
