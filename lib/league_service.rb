# frozen_string_literal: true

require_relative 'sleeper_api'

# Handles league-specific operations like rosters, users, and matchups
class LeagueService
  def initialize(league_id)
    @league_id = league_id
    @roster_owner_map = nil
  end

  def current_nfl_week
    state = SleeperAPI.nfl_state
    # Prefer display_week if present; fall back to week
    (state['display_week'] || state['week']).to_i
  end

  def league_info
    @league_info ||= SleeperAPI.league(@league_id)
  end

  def users
    @users ||= SleeperAPI.league_users(@league_id)
  end

  def rosters
    @rosters ||= SleeperAPI.league_rosters(@league_id)
  end

  def matchups(week)
    SleeperAPI.league_matchups(@league_id, week)
  end

  def transactions(week)
    SleeperAPI.league_transactions(@league_id, week)
  end

  def roster_owner_map
    return @roster_owner_map if @roster_owner_map

    user_lookup = build_user_lookup
    @roster_owner_map = build_roster_owner_map(user_lookup)
  end

  def team_standings
    rosters.sort_by do |r|
      settings = r['settings'] || {}
      wins = (settings['wins'] || 0).to_i
      points_for = calculate_total_points(settings, 'fpts', 'fpts_decimal')
      points_against = calculate_total_points(settings, 'fpts_against', 'fpts_against_decimal')

      [-wins, -points_for, points_against]
    end
  end

  def last_place_teams(count = 1)
    sorted = sort_rosters_for_last_place
    last_place_rosters = sorted.take(count)
    format_last_place_teams(last_place_rosters)
  end

  private

  def calculate_total_points(settings, base_field, decimal_field)
    base = (settings[base_field] || 0).to_f
    decimal = (settings[decimal_field] || 0).to_f / 100
    base + decimal
  end

  def sort_rosters_for_last_place
    rosters.sort_by do |r|
      settings = r['settings'] || {}
      wins = (settings['wins'] || 0).to_i
      points_for = calculate_total_points(settings, 'fpts', 'fpts_decimal')
      points_against = calculate_total_points(settings, 'fpts_against', 'fpts_against_decimal')

      [wins, points_for, -points_against]
    end
  end

  def format_last_place_teams(rosters)
    rosters.map do |roster|
      owner_info = roster_owner_map[roster['roster_id'].to_i]
      settings = roster['settings'] || {}
      {
        roster_id: roster['roster_id'].to_i,
        owner: owner_info&.dig('display_name') || 'Unknown',
        team_name: owner_info&.dig('team_name') || 'Unknown',
        wins: settings['wins'] || 0,
        losses: settings['losses'] || 0,
        points_for: calculate_total_points(settings, 'fpts', 'fpts_decimal').round(2),
        points_against: calculate_total_points(settings, 'fpts_against',
                                               'fpts_against_decimal').round(2)
      }
    end
  end

  def build_user_lookup
    users.each_with_object({}) do |user, lookup|
      team_name = user.dig('metadata', 'team_name')&.strip || ''
      display_name = user['display_name'] || user['username'] || 'Unknown'

      lookup[user['user_id']] = {
        'display_name' => display_name,
        'team_name' => team_name.empty? ? display_name : team_name
      }
    end
  end

  def build_roster_owner_map(user_lookup)
    rosters.each_with_object({}) do |roster, map|
      owner_info = user_lookup[roster['owner_id']] || {}
      map[roster['roster_id'].to_i] = {
        'owner_id' => roster['owner_id'],
        'display_name' => owner_info['display_name'] || 'Unknown',
        'team_name' => owner_info['team_name'] || (owner_info['display_name'] || 'Unknown')
      }
    end
  end
end
