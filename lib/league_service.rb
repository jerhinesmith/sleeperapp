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
    rosters.sort_by { |r| -(r.dig('settings', 'wins') || 0) }
  end

  def last_place_teams(count = 1)
    sorted = rosters.sort_by { |r| r.dig('settings', 'wins') || 0 }
    last_place_rosters = sorted.take(count)

    last_place_rosters.map do |roster|
      owner_info = roster_owner_map[roster['roster_id'].to_i]
      {
        roster_id: roster['roster_id'].to_i,
        owner: owner_info&.dig('display_name') || 'Unknown',
        team_name: owner_info&.dig('team_name') || 'Unknown',
        wins: roster.dig('settings', 'wins') || 0,
        losses: roster.dig('settings', 'losses') || 0,
        points_for: roster.dig('settings', 'fpts') || 0,
        points_against: roster.dig('settings', 'fpts_against') || 0
      }
    end
  end

  private

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
