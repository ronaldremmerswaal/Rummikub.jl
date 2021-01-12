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
struct GameState{N,K,M}
  # Available tiles (hand + table)
  available::MArray{Tuple{N,K}, Int}

  # Current runs that are formed (true iff tile is used)
  runs::MArray{Tuple{N,K,M}, Bool}

  # Tiles that are on the table
  table::MArray{Tuple{N,K}, Int}

  GameState{N, K, M}() where {N, K, M} = new(MArray{Tuple{N,K}, Int}(zeros(Int, N, K)), MArray{Tuple{N,K,M}, Bool}(zeros(Bool, N, K, M)), MArray{Tuple{N,K}, Int}(zeros(Int, N, K)))
  GameState{N, K, M}(available::MArray{Tuple{N,K}, Int}, runs::MArray{Tuple{N,K,M}, Bool}, table::MArray{Tuple{N,K}, Int}) where {N, K, M} = new(available, runs, table)
end

function GameState(hand::MArray{Tuple{N,K}, Int}, table::MArray{Tuple{N,K}, Int}) where {N, K}
  available = hand + table
  M = max(1, maximum(available))
  return GameState{N, K, M}(available, MArray{Tuple{N,K,M}, Bool}(zeros(Bool, N, K, M)), table)
end

# TODO how large is third dimension of score/max_index? (less than 3^M)
struct ScoreMemory{N,K,M}
  score::Array{Int}
  max_index::Array{Int}
end

# Extend the runs by the given extension, and remove tiles from the available
# and table array
function extend_runs!(state::GameState{N,K,M}, extension, value::Int) where {N,K,M}

end

# Undo the action of extend_runs!
function undo_extend_runs!(state::GameState{N,K,M}, extension, value::Int) where {N,K,M}

end

# The maximum score increment depends on wether the length of the current runs
# of a particular suit are shorter than S-1, equal to S-1, or larger than S-1.
#   < S-1: then the increment for this run will be zero (regardless of wether it is 0, 1, ..., S-2 long)
#   = S-1: then the increment for this run will be value-S+1 + ... + value-1 + value
#   > S-1: then the increment for this run will be value
# So all (state, value) pairs that map to index have the same max_score_increment.
function index(state::GameState{N,K,M}, value::Int) where {N,K,M}

end

# The maximum score increment that can be achieved by adding all tiles ≥ value
# that are available
function max_score_increment(memory::ScoreMemory{N,K,M}, state::GameState{N}, value::Int) where {N,K,M}
  if value > N return 0 end
  I = index(state, value)
  # Skip if score score increment has already been computed
  if memory.score[I] > -Inf return memory.score[I] end

  # Consider all possible run extensions of the current state, using the
  # available tiles of the current value
  for extension ∈ run_extensions(state, value)
    extend_runs!(state, extension, value)

    # For each such extension, consider the maximum group that can be formed
    # using the remaining available tiles
    group_size = sum_of_valid_group_sizes(state, value)

    # The group size == -Inf if the resulting groups can not use all the
    # available tiles of the current value that are on the table
    if group_size > -Inf
      new_score = value * group_size + score_increment(state, value) + max_score_increment(state, value + 1)
      if new_score > memory.score[I]
        memory.score[I] = new_score
        memory.max_index[I] = index(state, value)
      end
    end
    undo_extend_runs!(state, extension, value)
  end

  memory.score[I] = max(memory.score[I], 0)
end

# The increment in score achieved by the use of value in state
function score_increment(state::GameState{N,K,M}, value::Int)  where {N,K,M}
  ans = 0
  for suit = 1 : K
    for deck = 1 : M
      if state.runs[value,suit,deck]
        if value > S && all(state.runs[value-S:value,suit,deck])
          # Run was already valid
          ans += value
        elseif value > S - 1 && all(state.runs[value-S+1:value,suit,deck])
          # Run becomes valid, so the increment is
          #   value - S + 1, value - S + 2, ..., value
          ans += Int(S * (value - (S - 1)/2))
        end
      end
    end
  end
end

# Form as large as possible valid groups with the available tiles of the current value
# returns the sum of the group sizes
# A valid group is one which has length at least S
function sum_of_valid_group_sizes(state::GameState{N,K,M}, value::Int) where {N,K,M}

end

# Iterate over all possible valid extensions of the runs using the available tiles
# with the current value
# A valid extension is one which either has length ≥ S or one which can still be extended
# with a larger value
# That is, runs which will require value+i further on, without any value+i being available
# of that particular suit, are omitted
function run_extensions(state::GameState{N,K,M}, value::Int) where {N,K,M}

end

# Given the maximum score increments, reconstruct which runs result in
# this score (groups trivially follow from state.available)
function reconstruct_optimal_runs!(state::GameState{N, K, M}, memory::ScoreMemory{N,K,M}) where {N,K,M}
  value = 0
  I = index(state, value)
  while value ≤ N
    # Obtain the index at value + 1 which results in the maximum score increment
    I = memory.max_index[I]
    extension = reconstruct_extension(state, I)

    extend_runs!(state, extension, value)

    value += 1
  end

  return state
end

# Given a state and an extended index, find the corresponding extension
function reconstruct_extension(state::GameState{N,K,M}, extended_index) where {N,K,M}

end

end # module
