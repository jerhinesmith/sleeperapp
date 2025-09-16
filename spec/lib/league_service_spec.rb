# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/league_service'
require_relative '../../lib/sleeper_api'

RSpec.describe LeagueService do
  let(:league_id) { 'LEAGUE123' }
  let(:service) { described_class.new(league_id) }

  let(:users) do
    [
      { 'user_id' => 'u1', 'display_name' => 'jerhinesmith', 'username' => 'jerhinesmith',
        'metadata' => { 'team_name' => 'Team Rhino' } },
      { 'user_id' => 'u2', 'display_name' => 'Skyallen', 'username' => 'Skyallen',
        'metadata' => { 'team_name' => 'Skyallen' } },
      { 'user_id' => 'u3', 'display_name' => 'BWilson8080', 'username' => 'BWilson8080',
        'metadata' => { 'team_name' => 'BWilson8080' } },
      { 'user_id' => 'u4', 'display_name' => 'raffel75', 'username' => 'raffel75',
        'metadata' => { 'team_name' => 'HoosierDaddy' } },
      { 'user_id' => 'u5', 'display_name' => 'sararaffel', 'username' => 'sararaffel',
        'metadata' => { 'team_name' => 'No Punt Intended' } },
      { 'user_id' => 'u6', 'display_name' => 'dstrock', 'username' => 'dstrock',
        'metadata' => { 'team_name' => 'Dummy’s Dummies' } },
      { 'user_id' => 'u7', 'display_name' => 'drhinesmith', 'username' => 'drhinesmith',
        'metadata' => { 'team_name' => 'drhinesmith' } },
      { 'user_id' => 'u8', 'display_name' => 'tstrock', 'username' => 'tstrock',
        'metadata' => { 'team_name' => 'Strock’s Jock’s' } }
    ]
  end

  let(:rosters) do
    [
      { 'roster_id' => 1, 'owner_id' => 'u1',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 309.12, 'fpts_against' => 266.56 } },
      { 'roster_id' => 2, 'owner_id' => 'u2',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 283.02, 'fpts_against' => 301.32 } },
      { 'roster_id' => 3, 'owner_id' => 'u3',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 280.30, 'fpts_against' => 285.06 } },
      { 'roster_id' => 4, 'owner_id' => 'u4',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 275.86, 'fpts_against' => 251.80 } },
      { 'roster_id' => 5, 'owner_id' => 'u5',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 275.18, 'fpts_against' => 286.42 } },
      { 'roster_id' => 6, 'owner_id' => 'u6',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 261.68, 'fpts_against' => 269.74 } },
      { 'roster_id' => 7, 'owner_id' => 'u7',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 256.90, 'fpts_against' => 237.72 } },
      { 'roster_id' => 8, 'owner_id' => 'u8',
        'settings' => { 'wins' => 1, 'losses' => 1, 'fpts' => 221.26, 'fpts_against' => 264.70 } }
    ]
  end

  before do
    allow(SleeperAPI).to receive(:league).with(league_id).and_return({ 'name' => 'Test League',
                                                                       'total_rosters' => 8 })
    allow(SleeperAPI).to receive(:league_users).with(league_id).and_return(users)
    allow(SleeperAPI).to receive(:league_rosters).with(league_id).and_return(rosters)
  end

  describe '#team_standings' do
    it 'sorts by wins desc, then points_for desc, then points_against asc' do
      order = service.team_standings.map { |r| r['roster_id'] }
      expect(order).to eq([1, 2, 3, 4, 5, 6, 7, 8])
    end
  end

  describe '#last_place_teams' do
    it 'returns the bottom N teams using wins, PF, and PA tie-breakers' do
      bottom_two = service.last_place_teams(2)
      expect(bottom_two.map { |t| t[:roster_id] }).to eq([8, 7])
      expect(bottom_two.first[:team_name]).to eq('Strock’s Jock’s')
      expect(bottom_two.last[:team_name]).to eq('drhinesmith')
    end
  end
end
