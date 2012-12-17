$example.data do |d|
  d.voter "first 26 people" do |v|
    v.weight 26
    v.candidate "Candidate A" do |c|
      c.rank  1
      c.score 10
    end
    v.candidate "Candidate B" do |c|
      c.rank  2
      c.score 9.9
    end
    v.candidate "Candidate C" do |c|
      # c.rank  no rank
      c.score 0
    end
  end
  d.voter "second group" do |v|
    v.weight 25
    v.candidate "Candidate B" do |c|
      c.rank  1
      c.score 10
    end
    v.candidate "Candidate A" do |c|
      c.rank  2
      c.score 9.9
    end
    v.candidate "Candidate C" do |c|
      # c.rank  no rank
      c.score 0
    end
  end
  d.voter "Opposition group" do |v|
    v.weight 49
    v.candidate "Candidate C" do |c|
      c.rank  1
      c.score 10
    end
    v.candidate "Candidate B" do |c|
      # c.rank  no rank
      c.score 0
    end
    v.candidate "Candidate A" do |c|
      # c.rank  no rank
      c.score 0
    end
  end
end
