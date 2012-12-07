# Rank election by my best understanding of the method of James Ogle despite being
# somewhat confused by his communications about it.

# An Ogle election only has one round.  However, to make the code parallel the
# code for a score election, I will objectify the round.

class OgleElection < ExtendedObject
  def voters
    $example.voters
  end
  def candidates
    $example.candidates
  end
  def ballots
    @ballots ||= voters.map do | a_voter |
      OgleBallot.new do |it|
        it.election = self
        it.voter = a_voter
      end
    end
  end
  def first_round
    # Answer with my first round.
    @first_round ||= OgleRound.new do |it|
      it.real_ballots = ballots
      it.candidates = candidates
      it.ordinal = 1 # for display
    end
  end
end

class << $example
  attr_accessor :rank_election
end
$example.rank_election = OgleElection.new

class OgleTally
  # An instance denotes the tally of a candidate across the ballots.

  attr_accessor :candidate, :round

  def high_order_part
    do_tally unless @high_order_part
    @high_order_part
  end
  def low_order_part
    do_tally unless @low_order_part
    @low_order_part
  end

  def inspect
    if @candidate && @round
      "{(#{high_order_part}, #{low_order_part}) #{candidate.name}}"
    else
      "{a tally}"
    end
  end

  def <=> another
    if    high_order_part < another.high_order_part
      1
    elsif high_order_part > another.high_order_part
      -1
    elsif low_order_part  < another.low_order_part
      1
    elsif low_order_part  > another.low_order_part
      -1
    else
      0
    end
  end

  def do_tally
    # Private.
    high = 0
    low = 0
    round.ballots.each do | a_ballot |
      hit = a_ballot.rank_for_candidate candidate
      if hit
        high += 1     # tic count.
        low -= hit    # sum rank numbers negated.
      end
    end
    @high_order_part = high
    @low_order_part  = low
    true
  end
end

class OgleRound < ExtendedObject
  attr_accessor :ballots, :candidates, :ordinal
  attr_writer :prior_winners, :winners

  def real_ballots=(them)
    # Receive them as the real ballots on which to base my work.
    self.ballots = them
  end

  def prior_winners
    # What candidates already won on prior rounds?
    @prior_winners ||= []
  end

  def follow prior_round
    # Be the round that follows prior_round.
    self.ordinal = prior_round.ordinal + 1
    self.prior_winners = prior_round.prior_winners + prior_round.winners.map(&:candidate)
    self.ballots = prior_round.ballots.map {|e|e.deweighted_with_winners prior_winners}
    self.candidates = prior_round.candidates - prior_winners
    true
  end

  def inspect
    if ordinal
      "{round #{ordinal}}"
    else
      "{a round}"
    end
  end

  def tallies
    @tallies ||= lambda do
      candidates.map do | a_candidate |
        n = OgleTally.new
        n.round     = self
        n.candidate = a_candidate
        n
      end
    end.call
  end

  def ordered_tallies
    tallies.sort
  end

  def winners
    @winners ||= leaders
  end

  def leaders
    # Answer with the tallies of the candidates in first place by Ogle pair.
    throw "Don't ask."
  end # def

  def successor
    r = self.class.new
    r.follow self
    r
  end
  def next_round
    successor
  end
  def next    # Can do this with a keyword?  Yes, but be careful with implied "self".
    successor
  end
end

class OgleBallot < ExtendedObject
  attr_accessor :voter, :election
  attr_writer :ranks_by_candidate

  def inspect
    if voter
      "{ballot of #{voter.inspect} #{ranks_by_candidate.size} ranks}"
    else
      "{a score ballot}"
    end
  end

  def rank_for_candidate a_candidate
    ranks_by_candidate[a_candidate]
  end

  def ranks_by_candidate
    @ranks_by_candidate ||= lambda do
      r = voter.ranks_by_candidate
      # Just do a sanity check.
      candidates_by_rank = Array.new r.size
      r.each {|k, v| candidates_by_rank[v - 1] = k}
      candidates_by_rank.each do |e|
        e || (throw "Bad rank ballot #{voter.inspect}.")
      end
      r
    end.call
  end
end

