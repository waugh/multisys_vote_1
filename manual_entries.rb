# To be entered manually command by command.

irb

load "init.rb"
load "raw_data.rb"

load "score.rb"

r1 = $example.score_election.first_round
r1.leaders

r2 = r1.next
r2.leaders

