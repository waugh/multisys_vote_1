# To be entered manually command by command.

irb

load "init.rb"
load "raw_data.rb"

load "score.rb"

r1 = $example.score_election.first_round
r1.leaders

r2 = r1.next
r2.leaders

r3 = r2.next
r3.leaders

r4 = r3.next
r4.leaders


load "rank.rb"

rr = $example.rank_election.first_round
rr.ordered_tallies

