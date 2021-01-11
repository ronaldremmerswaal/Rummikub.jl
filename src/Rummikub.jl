# The algorithm is based on
#
#   van Rijn, Jan N., Frank W. Takes, and Jonathan K. Vis.
#   "The complexity of Rummikub problems."
#   arXiv preprint arXiv:1604.07553 (2016).
#
#   (https://arxiv.org/abs/1604.07553)
module Rummikub

using StaticArrays

# N values
# K suits
# M decks
# S minimum run and group length
struct GameState{N,K,M,S}
  # Available tiles (hand + table)
  available::SizedArray{Tuple{N,K}, Int}

  # Current runs that are formed (true iff tile is used)
  runs::SizedArray{Tuple{N,K,M}, Bool}

  # Tiles that are on the table
  table::SizedArray{Tuple{N,K}, Int}
end

# Extend the runs by the given extension, and remove tiles from the available
# and table array
function extend!(state::GameState{N,K,M,S}, extension, value::Int)

end

# Undo the action of extend!
function undo_extend!(state::GameState{N,K,M,S}, extension, value::Int)

end

# The maximum score increment depends on wether the length of the current runs
# of a particular suit are shorter than S-1, equal to S-1, or larger than S-1.
#   < S-1: then the increment for this run will be zero (regardless of wether it is 0, 1, ..., S-2 long)
#   = S-1: then the increment for this run will be value-S+1 + ... + value-1 + value
#   > S-1: then the increment for this run will be value
# So all (state, value) pairs that map to index have the same max_score_increment.
function index(state::GameState{N,K,M,S}, value::Int)

end

# The maximum score increment that can be achieved by adding all tiles ≥ value
# that are available
function max_score_increment(scores_increment::Array{Int}, state::GameState{N}, value::Int)
  if value > N return 0
  I = index(state, value)
  # Skip if score score increment has already been computed
  if scores_increment[I] > -Inf return scores_increment[I]

  # Consider all possible run extensions of the current state, using the
  # available tiles of the current value
  for extension ∈ extensions(state, value)
    extend!(state, extension, value)

    # For each such extension, consider the maximum group that can be formed
    # using the remaining available tiles
    group_size = sum_of_valid_group_sizes(state, value)

    # The group size == -Inf if the resulting groups can not use all the
    # available tiles of the current value that are on the table
    if group_size > -Inf
      new_score = value * group_size + score_increment(state, value) + max_score_increment(state, value + 1)
      scores_increment[I] = max(scores_increment[I], new_score)
    end
    undo_extend!(state, extension, value)
  end

  scores_increment[I] = max(scores_increment[I], 0)
end

# The increment in score achieved by the use of value in state
function score_increment(state::GameState{N}, value::Int)

end

# Form as large as possible valid groups with the available tiles of the current value
# returns the sum of the group sizes
# A valid group is one which has length at least S
function sum_of_valid_group_sizes(state::GameState{N}, value::Int)

end

# Iterate over all possible valid extensions of the runs using the available tiles
# with the current value
# A valid extension is one which either has length ≥ S or one which can still be extended
# with a larger value
# E.g. the run [N-1,N] will never be valid for S > 2.
# Also runs which will require N+i further on, without N+i being available, are omitted
function extensions(state::GameState{N}, value::Int)

end

end # module
