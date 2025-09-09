# frozen_string_literal: true

require 'time'

# Analyzes and formats transaction data
class TransactionAnalyzer
  def initialize(player_service)
    @player_service = player_service
  end

  def analyze_transactions(transactions_data)
    formatted_transactions = transactions_data.map { |txn| format_transaction(txn) }

    {
      count: formatted_transactions.size,
      items: formatted_transactions,
      summary: summarize_transactions(formatted_transactions)
    }
  end

  private

  def format_transaction(transaction)
    {
      type: transaction['type'],
      status: transaction['status'],
      roster_ids: (transaction['roster_ids'] || []).map(&:to_i),
      players_added: format_player_moves(transaction['adds'] || {}),
      players_dropped: format_player_moves(transaction['drops'] || {}, dropped: true),
      waiver_bid: transaction['waiver_bid'],
      draft_picks: transaction['draft_picks'],
      created: format_timestamp(transaction['created'])
    }
  end

  def format_player_moves(moves_hash, dropped: false)
    moves_hash.map do |player_id, roster_id|
      {
        id: player_id.to_s,
        name: @player_service.player_name(player_id),
        roster_id: roster_id.to_i,
        direction: dropped ? :from_roster : :to_roster
      }
    end
  end

  def format_timestamp(timestamp)
    return nil unless timestamp

    Time.at(timestamp.to_i / 1000).iso8601
  rescue StandardError => e
    puts "Warning: Could not parse timestamp #{timestamp}: #{e.message}" if $VERBOSE
    nil
  end

  def summarize_transactions(transactions)
    summary = {
      total: transactions.size,
      by_type: Hash.new(0),
      waiver_activity: [],
      free_agent_activity: []
    }

    transactions.each do |txn|
      summary[:by_type][txn[:type]] += 1

      case txn[:type]
      when 'waiver'
        summary[:waiver_activity] << format_waiver_activity(txn)
      when 'free_agent'
        summary[:free_agent_activity] << format_free_agent_activity(txn)
      end
    end

    summary
  end

  def format_waiver_activity(transaction)
    {
      roster_ids: transaction[:roster_ids],
      bid: transaction[:waiver_bid],
      players_added: transaction[:players_added],
      players_dropped: transaction[:players_dropped]
    }
  end

  def format_free_agent_activity(transaction)
    {
      roster_ids: transaction[:roster_ids],
      players_added: transaction[:players_added],
      players_dropped: transaction[:players_dropped]
    }
  end
end
