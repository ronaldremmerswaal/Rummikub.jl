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
  available::SizedArray{Tuple{N,K}, Int}

  # Current runs that are formed (true iff tile is used)
  runs::SizedArray{Tuple{N,K,M}, Bool}

  # Tiles that are on the table
  table::SizedArray{Tuple{N,K}, Int}

  GameState{N, K, M}() where {N, K, M} = new(SizedArray{Tuple{N,K}, Int}(zeros(Int, N, K)), SizedArray{Tuple{N,K,M}, Bool}(zeros(Bool, N, K, M)), SizedArray{Tuple{N,K}, Int}(zeros(Int, N, K)))
  GameState{N, K, M}(available::SizedArray{Tuple{N,K}, Int}, runs::SizedArray{Tuple{N,K,M}, Bool}, table::SizedArray{Tuple{N,K}, Int}) where {N, K, M} = new(available, runs, table)
end

function GameState(hand::SizedArray{Tuple{N,K}, Int}, table::SizedArray{Tuple{N,K}, Int}) where {N, K}
  available = hand + table
  M = min(1, max(available))
  return GameState(hand + table, SizedArray{Tuple{N,K,M}, Bool}(zeros(Bool, N, K, M)), table)
end

struct ScoreMemory{N,K,M}
  score::Array{Int}
  max_index::Array{Int}
end

# Extend the runs by the given extension, and remove tiles from the available
# and table array
function extend_runs!(state::GameState{N,K,M}, extension, value::Int)

end

# Undo the action of extend_runs!
function undo_extend_runs!(state::GameState{N,K,M}, extension, value::Int)

end

# The maximum score increment depends on wether the length of the current runs
# of a particular suit are shorter than S-1, equal to S-1, or larger than S-1.
#   < S-1: then the increment for this run will be zero (regardless of wether it is 0, 1, ..., S-2 long)
#   = S-1: then the increment for this run will be value-S+1 + ... + value-1 + value
#   > S-1: then the increment for this run will be value
# So all (state, value) pairs that map to index have the same max_score_increment.
function index(state::GameState{N,K,M}, value::Int)

end

# The maximum score increment that can be achieved by adding all tiles ≥ value
# that are available
function max_score_increment(memory::ScoreMemory{N,K,M}, state::GameState{N}, value::Int)
  if value > N return 0
  I = index(state, value)
  # Skip if score score increment has already been computed
  if memory.score[I] > -Inf return memory.score[I]

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
# That is, runs which will require value+i further on, without any value+i being available
# of that particular suit, are omitted
function run_extensions(state::GameState{N}, value::Int)

end

# Given the maximum score increments, reconstruct which runs and groups result in
# this score
function reconstruct_optimal_solution(memory::ScoreMemory{N,K,M})
  state = GameState{N, K, M}()
  value = 0
  I = index(state, value)
  while value ≤ N
    # Obtain the index at value + 1 which results in the maximum score increment
    I = memory.max_index[I]
    extension = reconstruct_extension(state, I)

    extend_runs!(state, extension, value)

    # TODO should we store groups in the state as well?
    form_groups!(state, value)

    value += 1
  end

  return state.runs
end

# Given a state and an extended index, find the corresponding extension
function reconstruct_extension(state::GameState{N,K,M}, extended_index)

end

end # module
