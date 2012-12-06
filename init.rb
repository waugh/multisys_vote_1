class ExtendedObject
  # Put any methods here that I want to use just about all over the place.
  def voter name
    # Return an object to represent the voter whose name is given.
    $example.voter name
  end
  def candidate name
    # Return an object to represent the candidate whose name is given.
    $example.candidate name
  end
end
class Person < ExtendedObject
  attr_accessor :name
  def inspect
    if name
      "{#{class_word} #{name}}"
    else
      "{a #{class_word}}"
    end
  end
end
class Voter < Person
  attr_accessor :ranks_by_candidate, :scores_by_candidate
  class Initializer
    attr_accessor :target
    class CandidateInitializer
      attr_accessor :voter, :candidate
      def rank a_rank
        voter.ranks_by_candidate[candidate] = a_rank
      end
      def score a_score
        voter.scores_by_candidate[candidate] = a_score
      end
    end
    def candidate name, &y
      # Accept data initialization concerning the voter's attitude to the named candidate.
      target.scores_by_candidate ||= Hash.new
      target.ranks_by_candidate  ||= Hash.new
      ci = CandidateInitializer.new
      ci.voter = target
      ci.candidate = target.candidate name
      y.call ci
      true
    end
  end # Initilizer
  def initializer
    # Answer with an object that can initialize me from data declarations.
    iobj = Initializer.new
    iobj.target = self
    iobj
  end
  def class_word
    "voter"
  end
end # Voter
class Candidate < Person
  def class_word
    "candidate"
  end
end

$example ||= Object.new
class << $example
  attr_accessor :data_initializer_thingy, :voters_by_name, :candidates_by_name
  def inspect
    "$example"
  end
  def data
    # Accept a data declaration specified by the block.
    yield data_initializer_thingy
    true
  end
  def voter name
    # Return an object to represent the voter whose name is given.
    voters_by_name[name]     ||= Voter.new
  end
  def candidate name
    # Return an object to represent the candidate whose name is given.
    candidates_by_name[name] ||= Candidate.new
  end
end # class << $example
$example.candidates_by_name ||= Hash.new
$example.voters_by_name     ||= Hash.new
$example.data_initializer_thingy = Object.new
class << $example.data_initializer_thingy
  def inspect
    "{the data initializer thingy}"
  end
  def voter voter_name, &y
    # Accept a data declaration concerning the voter whose name is given by
    # voter_name.  Consult the block given for further details about the data to be associated
    # to the voter.
    y.call(($example.voter voter_name).initializer)
  end
end # class << $example.data_initializer_thingy
