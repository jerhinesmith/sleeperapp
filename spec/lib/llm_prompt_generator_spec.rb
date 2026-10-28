# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LLMPromptGenerator do
  let(:generator) { described_class.new }

  def standing(owner:, team_name:, wins:, losses:)
    {
      'rank' => 1,
      'roster_id' => 1,
      'owner' => owner,
      'team_name' => team_name,
      'wins' => wins,
      'losses' => losses,
      'points_for' => 0,
      'points_against' => 0
    }
  end

  def base_data(standings: [])
    {
      'league_info' => { 'name' => 'Test League' },
      'week' => 5,
      'generated_at' => '2026-10-13T00:00:00Z',
      'standings' => standings,
      'matchups' => [],
      'last_place_watch' => [],
      'transactions' => {}
    }
  end

  describe '#generate_prompt notes section' do
    context 'when notes are provided' do
      it "includes a This Week's Notes section listing each note" do
        prompt = generator.generate_prompt(
          base_data,
          notes: ['testowner_alpha and testowner_beta are in Spain right now',
                  'Do not mention testowner_gamma being new']
        )

        expect(prompt).to include("**This Week's Notes:**")
        expect(prompt).to include('- testowner_alpha and testowner_beta are in Spain right now')
        expect(prompt).to include('- Do not mention testowner_gamma being new')
      end
    end

    context 'when no notes are provided' do
      it "omits the This Week's Notes section" do
        prompt = generator.generate_prompt(base_data)

        expect(prompt).not_to include("This Week's Notes")
      end
    end
  end

  describe '#generate_prompt unbeaten & winless watch' do
    context 'with exactly one unbeaten team' do
      it 'calls out that team as the last unbeaten team' do
        data = base_data(standings: [
                           standing(owner: 'testowner_alpha', team_name: 'Alpha Squad', wins: 5,
                                    losses: 0),
                           standing(owner: 'testowner_beta', team_name: 'Beta Crew', wins: 3,
                                    losses: 2)
                         ])

        prompt = generator.generate_prompt(data)

        expect(prompt).to match(/testowner_alpha.*last unbeaten team/)
      end
    end

    context 'with multiple unbeaten teams' do
      it 'lists all of the still-unbeaten teams' do
        data = base_data(standings: [
                           standing(owner: 'testowner_alpha', team_name: 'Alpha Squad', wins: 5,
                                    losses: 0),
                           standing(owner: 'testowner_beta', team_name: 'Beta Crew', wins: 4,
                                    losses: 0)
                         ])

        prompt = generator.generate_prompt(data)

        expect(prompt).to include('testowner_alpha')
        expect(prompt).to include('testowner_beta')
        expect(prompt).not_to match(/last unbeaten team/)
      end
    end

    context 'with no unbeaten teams' do
      it 'instructs the LLM to skip the unbeaten callout' do
        data = base_data(standings: [
                           standing(owner: 'testowner_alpha', team_name: 'Alpha Squad', wins: 3,
                                    losses: 2)
                         ])

        prompt = generator.generate_prompt(data)

        expect(prompt).to include('No team is unbeaten this week - skip this callout entirely.')
      end
    end

    context 'with exactly one winless team' do
      it 'calls out that team as the only winless team' do
        data = base_data(standings: [
                           standing(owner: 'testowner_alpha', team_name: 'Alpha Squad', wins: 5,
                                    losses: 0),
                           standing(owner: 'testowner_gamma', team_name: 'Gamma Guild', wins: 0,
                                    losses: 5)
                         ])

        prompt = generator.generate_prompt(data)

        expect(prompt).to match(/testowner_gamma.*only winless team/)
      end
    end

    context 'with multiple winless teams' do
      it 'lists all of the still-winless teams' do
        data = base_data(standings: [
                           standing(owner: 'testowner_gamma', team_name: 'Gamma Guild', wins: 0,
                                    losses: 5),
                           standing(owner: 'testowner_delta', team_name: 'Delta Force', wins: 0,
                                    losses: 4)
                         ])

        prompt = generator.generate_prompt(data)

        expect(prompt).to include('testowner_gamma')
        expect(prompt).to include('testowner_delta')
        expect(prompt).not_to match(/only winless team/)
      end
    end

    context 'with no winless teams' do
      it 'instructs the LLM to skip the winless callout' do
        data = base_data(standings: [
                           standing(owner: 'testowner_alpha', team_name: 'Alpha Squad', wins: 3,
                                    losses: 2)
                         ])

        prompt = generator.generate_prompt(data)

        expect(prompt).to include('No team is still winless this week')
      end
    end
  end
end
