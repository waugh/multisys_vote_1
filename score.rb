# Score or range voting.

class ScoreElection < ExtendedObject
  attr_accessor :max_score # What is the maximum score that a voter is allowed to assign to a
                             # candidate in this election?
  # Code all over the place assumes the minimum score is zero.
  def initialize
    @max_score = 10.0
    super
  end
  def voters
    $example.voters
  end
  def candidates
    $example.candidates
  end
  def ballots
    @ballots ||= voters.map do | a_voter |
      ScoreBallot.new do |it|
        it.election = self
        it.voter = a_voter
      end
    end
  end
  def first_round
    # Answer with my first round.
    @first_round ||= ScoreRound.new do |it|
      it.real_ballots = ballots
      it.candidates = candidates
    end
  end
end


class << $example
  # This is a re-open.

  attr_accessor :score_election

  def voters
    voters_by_name.values
  end
  def candidates
    candidates_by_name.values
  end
end

$example.score_election = ScoreElection.new


class ScoreBallot < ExtendedObject
  attr_accessor :weight, :voter, :election

  def initialize
    @weight = 1.0 # Use unity by default.
    super
  end

  def inspect
    if voter
      "{ballot of #{voter.inspect} wt:#{weight} #{scores_by_candidate.size} scores}"
    else
      "{a score ballot}"
    end
  end

  def scores_by_candidate
    @scores_by_candidate ||= lambda do
      r = Hash.new
      voter.scores_by_candidate.each do | cand, score |
        r[cand] = score.to_f
      end
      r
    end.call
  end

  def weighted_score_for_candidate a_candidate
    hit = scores_by_candidate[a_candidate]
    if hit
      hit * weight
    else
      nil
    end
  end

  def []=(k, v)
    scores_by_candidate[k] = v
  end

  def deweighted_with_winners some_winners
    # Answer with a ballot similar to myself but with weight determined by
    # some_winners as canddidates who have already won in prior rounds of the
    # multi-winner election.
    sum = some_winners.inject(0.0) do | acc, a_winner |
      acc + ((weighted_score_for_candidate a_winner) || 0.0)
    end
    new_weight = 0.5 / (0.5 + sum / max_score)
    if new_weight == weight
      self
    else
      n = self.class.allocate
      n.scores_by_candidate = scores_by_candidate
      n.voter               = voter
      n.weight              = new_weight
      n
    end
  end
end

class FakeBallot < ExtendedObject
  attr_accessor :weight
  def weighted_score_for_candidate any_candidate
    0.0
  end
  def deweighted_with_winners some_winners
    self
  end
end

class RoundCandidateTally
  # The purpose of a round candidate tally is to calculate the total score that
  # a candidate receives in a round.

  attr_accessor :candidate, :round

  def score
    @score ||= lambda do
      acc  = 0.0
      base = 0.0
      round.ballots.each do | a_ballot |
        hit = a_ballot.weighted_score_for_candidate candidate
        if hit
          acc  += hit
          base += a_ballot.weight
        end
      end
      acc / base
    end.call
  end

  def inspect
    if @candidate
      "{#{score} #{candidate.name}}"
    else
      "{an uninitialized tally object}"
    end
  end
end

class ScoreRound < ExtendedObject
  # An instance represents a round of tallying for a reweighted range (score) multi-winner
  # election.

  attr_accessor :ballots, :candidates, :ordinal
  attr_writer :prior_winners
  
  attr_writer :winners
    # Can be set from outside to express decision between ties for first place.
    # Expressed as tallies, not candidates (historical reasons).
    # Probably should have just one element.

  def real_ballots=(them)
    # Receive them as the real ballots on which to base my work.
    # Internally, our ballots can also include artificial ballots for
    # the "better quorum" scheme http://rangevoting.org/BetterQuorum.html
    fake = FakeBallot.new {|it| it.weight = [them.size, 1000].min.to_f}
    self.ballots = them + [fake]
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
        n = RoundCandidateTally.new
        n.round     = self
        n.candidate = a_candidate
        n
      end
    end.call
  end

  def ordered_tallies
    tallies.sort_by {|t| 0.0 - t.score}
  end

  def winners
    @winners ||= leaders # by default; can be set otherwise.
  end

  def leaders
    # Answer with the tallies of the candidates in first place by score.

    @leaders ||= lambda do
      ordered_tallies = self.ordered_tallies
      acc = []
      unless ordered_tallies.empty?
        cur = 1
        lim = ordered_tallies.size
        top_score = ordered_tallies.first.score
        acc = [ordered_tallies.first]
        while cur < lim && (hit = ordered_tallies[cur]).score == top_score
          acc += [hit]
          cur += 1
        end # while
      end # unless
      acc
    end.call
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
end # class

