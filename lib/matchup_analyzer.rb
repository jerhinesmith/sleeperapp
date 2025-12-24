# frozen_string_literal: true

# Analyzes matchups to determine winners, margins, and player performance
class MatchupAnalyzer
  def initialize(player_service, league_service)
    @player_service = player_service
    @league_service = league_service
  end

  def analyze_matchups(matchups_data)
    grouped_matchups = matchups_data.group_by { |m| m['matchup_id'] }

    grouped_matchups.keys.compact.sort.map do |matchup_id|
      analyze_single_matchup(matchup_id, grouped_matchups[matchup_id])
    end
  end

  private

  def analyze_single_matchup(matchup_id, teams_data)
    teams = teams_data.map { |team_data| analyze_team(team_data) }

    {
      matchup_id: matchup_id,
      teams: teams,
      winner: determine_winner(teams),
      margin: calculate_margin(teams)
    }
  end

  def analyze_team(team_data)
    roster_id = team_data['roster_id'].to_i
    owner_info = @league_service.roster_owner_map[roster_id]

    starters = build_player_list(
      team_data['starters'] || [],
      team_data['players_points'] || {},
      team_data['starters_points'] || []
    )

    bench_players = build_bench_list(
      team_data['players'] || [],
      team_data['starters'] || [],
      team_data['players_points'] || {}
    )

    {
      roster_id: roster_id,
      owner: owner_info&.dig('display_name') || 'Unknown',
      team_name: owner_info&.dig('team_name') || 'Unknown',
      points: (team_data['points'] || 0.0).to_f.round(2),
      starters: starters,
      bench: bench_players,
      bench_points_total: calculate_bench_total(bench_players)
    }
  end

  def build_player_list(player_ids, points_map, starters_points)
    player_ids.each_with_index.map do |player_id, index|
      points = points_map[player_id.to_s] || starters_points[index]

      {
        id: player_id.to_s,
        name: @player_service.player_name(player_id),
        points: points&.to_f&.round(2)
      }
    end
  end

  def build_bench_list(all_players, starters, points_map)
    bench_ids = all_players.map(&:to_s) - starters.map(&:to_s)

    bench_ids.map do |player_id|
      {
        id: player_id,
        name: @player_service.player_name(player_id),
        points: points_map[player_id]&.to_f&.round(2)
      }
    end
  end

  def calculate_bench_total(bench_players)
    bench_players.sum { |player| player[:points] || 0.0 }.round(2)
  end

  def determine_winner(teams)
    return nil if teams.size < 2

    sorted_teams = teams.sort_by { |team| -team[:points] }
    top_score = sorted_teams[0][:points]
    second_score = sorted_teams[1][:points]

    return nil if top_score == second_score # Tie

    winner = sorted_teams[0]
    {
      roster_id: winner[:roster_id],
      team_name: winner[:team_name],
      owner: winner[:owner],
      points: winner[:points]
    }
  end

  def calculate_margin(teams)
    return nil if teams.size < 2

    points = teams.map { |team| team[:points] }.sort.reverse
    (points[0] - points[1]).round(2)
  end
end
