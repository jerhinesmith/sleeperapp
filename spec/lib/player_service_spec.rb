# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe PlayerService do
  let(:temp_cache_dir) { Dir.mktmpdir }
  let(:player_service) { described_class.new(cache_dir: temp_cache_dir) }

  let(:mock_players_data) do
    {
      '4046' => {
        'player_id' => '4046',
        'first_name' => 'Patrick',
        'last_name' => 'Mahomes',
        'position' => 'QB',
        'team' => 'KC'
      },
      'BUF' => {
        'player_id' => 'BUF',
        'team' => 'BUF',
        'position' => 'DEF',
        'first_name' => '',
        'last_name' => ''
      }
    }
  end

  after do
    FileUtils.rm_rf(temp_cache_dir)
  end

  describe '#player_name' do
    before do
      allow(SleeperAPI).to receive(:players).and_return(mock_players_data)
    end

    context 'with a regular player' do
      it 'returns the formatted player name' do
        expect(player_service.player_name('4046')).to eq('Patrick Mahomes')
      end
    end

    context 'with a team defense' do
      it 'returns team name when player data exists' do
        expect(player_service.player_name('BUF')).to eq('BUF')
      end
    end

    context 'with a team defense not in data' do
      it 'returns team D/ST format' do
        expect(player_service.player_name('XYZ')).to eq('XYZ D/ST')
      end
    end

    context 'with an unknown player' do
      it 'returns the ID as-is for long IDs' do
        expect(player_service.player_name('99999999')).to eq('99999999')
      end
    end
  end

  describe '#player_info' do
    before do
      allow(SleeperAPI).to receive(:players).and_return(mock_players_data)
    end

    it 'returns player data hash' do
      result = player_service.player_info('4046')
      expect(result).to eq(mock_players_data['4046'])
    end

    it 'returns nil for unknown players' do
      result = player_service.player_info('unknown')
      expect(result).to be_nil
    end
  end

  describe 'caching behavior' do
    let(:cache_file) { File.join(temp_cache_dir, 'players.json') }

    before do
      allow(SleeperAPI).to receive(:players).and_return(mock_players_data)
    end

    it 'fetches data from API on first call' do
      expect(SleeperAPI).to receive(:players).once
      player_service.player_name('4046')
    end

    it 'uses cached data on subsequent calls' do
      player_service.player_name('4046')
      expect(SleeperAPI).not_to receive(:players)
      player_service.player_name('4046')
    end

    it 'creates cache file' do
      player_service.player_name('4046')
      expect(File.exist?(cache_file)).to be true
    end

    it 'loads from existing cache file' do
      File.write(cache_file, JSON.pretty_generate(mock_players_data))
      File.utime(Time.now, Time.now, cache_file) # Ensure recent timestamp

      expect(SleeperAPI).not_to receive(:players)
      result = player_service.player_name('4046')
      expect(result).to eq('Patrick Mahomes')
    end

    it 'refreshes stale cache' do
      File.write(cache_file, JSON.pretty_generate(mock_players_data))
      # Make file older than 24 hours
      File.utime(Time.now - (25 * 3600), Time.now - (25 * 3600), cache_file)

      expect(SleeperAPI).to receive(:players).once
      player_service.player_name('4046')
    end
  end
end
