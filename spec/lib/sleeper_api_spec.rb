# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SleeperAPI do
  describe '.get' do
    let(:mock_response) { double('Net::HTTPResponse') }
    let(:mock_body) { '{"test": "data"}' }

    before do
      allow(Net::HTTP).to receive(:get_response).and_return(mock_response)
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(mock_response).to receive(:body).and_return(mock_body)
    end

    it 'makes HTTP requests to the correct URL' do
      expect(Net::HTTP).to receive(:get_response).with(URI('https://api.sleeper.app/v1/test/path'))
      described_class.get('test/path')
    end

    it 'parses JSON responses' do
      result = described_class.get('test/path')
      expect(result).to eq({ 'test' => 'data' })
    end

    context 'when request fails' do
      before do
        allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(mock_response).to receive_messages(code: '404', body: 'Not Found')
      end

      it 'raises APIError with details' do
        expect { described_class.get('test/path') }.to raise_error(
          SleeperAPI::APIError,
          %r{HTTP 404 for https://api\.sleeper\.app/v1/test/path}
        )
      end
    end

    context 'when JSON parsing fails' do
      before do
        allow(mock_response).to receive(:body).and_return('invalid json')
      end

      it 'raises APIError for invalid JSON' do
        expect { described_class.get('test/path') }.to raise_error(
          SleeperAPI::APIError,
          /Invalid JSON response/
        )
      end
    end
  end

  describe '.nfl_state' do
    it 'calls the correct endpoint' do
      expect(described_class).to receive(:get).with('state/nfl')
      described_class.nfl_state
    end
  end

  describe '.league' do
    it 'calls the correct endpoint with league ID' do
      expect(described_class).to receive(:get).with('league/123456789')
      described_class.league('123456789')
    end
  end

  describe '.league_users' do
    it 'calls the correct endpoint with league ID' do
      expect(described_class).to receive(:get).with('league/123456789/users')
      described_class.league_users('123456789')
    end
  end
end
