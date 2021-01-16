# The algorithm is based on
#
#   van Rijn, Jan N., Frank W. Takes, and Jonathan K. Vis.
#   "The complexity of Rummikub problems."
#   arXiv preprint arXiv:1604.07553 (2016).
#
#   (https://arxiv.org/abs/1604.07553)
module Rummikub

# N values
# K suits
# M decks
# S minimum run and group length
struct GameState{N,K,M,S}
  # Available tiles (hand + table) (N x K)
  available::Array{Int, 2}

  # Current runs that are formed (true iff tile is used) (N x M x K)
  runs::Array{Bool, 3}

  # Available tiles on the table (N x K)
  table::Array{Int, 2}

  GameState{N, K, M, S}() where {N, K, M, S} = new(zeros(Int, N, K), zeros(Bool, N, M, K), zeros(Int, N, K))
  GameState{N, K, M, S}(available::Array{Int, 2}, runs::Array{Bool, 3}, table::Array{Int, 2}) where {N, K, M, S} = new(available, runs, table)
end

function GameState(hand::Array{Int, 2}, table::Array{Int, 2}, S::Int)
  available = hand + table
  N, K = size(hand)
  M = max(1, maximum(available))
  return GameState{N, K, M, S}(available, zeros(Bool, N, M, K), table)
end

struct RunExtension
  deck::Int
  suit::Int
  from_table::Bool
end

# struct ScoreMemory{N,K,M}
#   score::Array{Int, 3}
#   max_index::Array{Int, 3}
# end
#
# ScoreMemory(N::Int, K::Int, M::Int) = ScoreMemory{N, K, M}(zeros(Int, N, K, third_dimension(M)), zeros(Bool, N, K, third_dimension(M)))

# TODO The paper suggests a state space of size N x K x f(M) rather than N x f(M)^K, how?
struct ScoreMemory{N,K,M}
  # Stores the maximum score increment (N x f(M)^K)
  score::Array{Int}
  max_index::Array{Int}
end

ScoreMemory(N::Int, K::Int, M::Int) = ScoreMemory{N, K, M}(zeros(Int, ntuple(i -> i == 1 ? N : third_dimension(M), 1+K)), zeros(Bool, ntuple(i -> i == 1 ? N : third_dimension(M), 1+K)))

# With 'third dimension' we refer to the third dimension of the score memory arrays
Base.@pure third_dimension(M::Int) = Int((M + 1) * (M + 2) /2)

# Index defines the mapping for which
#   score[index(state, value)] == max_score_increment(state, value)
# The maximum score increment depends on wether the length of the current runs
# of a particular suit are shorter than S-1, equal to S-1, or larger than S-1.
#   < S-1: then the increment for this run will be zero (regardless of wether it is 0, 1, ..., S-2 long)
#   = S-1: then the increment for this run will be value-S+1 + ... + value-1 + value
#   > S-1: then the increment for this run will be value
# So all (state, value) pairs that map to index have the same max_score_increment.
function index(state::GameState{N, K, M, S}, value::Int) where {N, K, M, S}
  return CartesianIndex(ntuple(i -> i == 1 ? value : index_per_suit(view(state.runs, :, :, i - 1), value, S), 1 + K))
end
function index_per_suit(runs::Array{Bool, 2}, value::Int, S)
  # We indicate 'length < S-1' by '0', 'length = S-1' by '1' and 'length > S-1' by '2'.
  # Then if M=2, all possible lengths are (note that for the score increment it
  # does not matter if we have a '12' or a '21')
  #   length: 00, 01, 02, 11, 12, 22
  #    index:  1   2   3   4   5   6
  # where the number of possibilities (6) equals third_dimension(2)
  N, M = size(runs)
  lengths = zeros(Int, M)
  for deck = 1 : M
    if runs[value, deck]
      lengths[deck] = 2
      for look_back = 1 : S
        if !runs[value - look_back, deck]
          if look_back < S - 1
            lengths[deck] = 0
          elseif look_back == S - 1
            lengths[deck] = 1
          else
            lengths[deck] = 2
          end
          break
        end
      end
    end
  end

  sort!(lengths)
  if M == 1
    return lengths[1]
  elseif M == 2
    if lengths[1] == 0
      return lengths[2]
    elseif lengths[1] == 1
      return lengths[2] + 3
    else
      return 6
    end
  else
    # TODO general case
  end
end

# Extend the runs by the given extension, and remove tiles from the available
# and table array
function extend_runs!(state::GameState{N, K, M, S}, extension::Vector{RunExtension}, value::Int) where {N, K, M, S}
  for e ∈ extension
    state.runs[value,e.deck,e.suit] = true
    e.from_table = state.table[value,e.suit] > 0
    if e.from_table
      # We prefer taking from the table
      state.table[value,e.suit] = state.table[value,e.suit] - 1
    end
    state.available[value,e.suit] = state.available[value,e.suit] - 1
  end
end

# Undo the action of extend_runs!
function undo_extend_runs!(state::GameState{N, K, M, S}, extension::Vector{RunExtension}, value::Int) where {N, K, M, S}
  for e ∈ extension
    state.runs[value,e.deck,e.suit] = false
    if e.from_table
      state.table[value,e.suit] = state.table[value,e.suit] + 1
    end
    state.available[value,e.suit] = state.available[value,e.suit] + 1
  end
end

# The maximum score increment that can be achieved by adding all tiles ≥ value
# that are available (i.e. the MaxScore function of Van Rijn et. al.)
function max_score_increment(memory::ScoreMemory{N, K, M}, state::GameState{N, K, M, S}, value::Int) where {N, K, M, S}
  if value > N return 0 end
  I = index(state, value)
  # Skip if score score increment has already been computed
  if memory.score[I] > -Inf
    return memory.score[I] == -1 ? -Inf memory.score[I]
  end

  # Consider all possible run extensions of the current state, using the
  # available tiles of the current value
  for extension ∈ run_extensions(state, value)
    extend_runs!(state, extension, value)

    # For each such extension, consider the maximum groups that can be formed
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

  # The score is invalidated if no valid extensions were considered
  memory.score[I] = max(memory.score[I], -1)
end

# The increment in score achieved by the use of value in state
function score_increment(state::GameState{N, K, M, S}, value::Int)  where {N, K, M, S}
  ans = 0
  for suit = 1 : K
    for deck = 1 : M
      if state.runs[value,deck,suit]
        if value > S && all(state.runs[value-S:value,deck,suit])
          # Run was already valid
          ans += value
        elseif value > S - 1 && all(state.runs[value-S+1:value,deck,suit])
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
# A valid group is one which has length at least S, each of a different suit
# Moreover, the groups as a whole are valid if all table tiles of value are used
function sum_of_valid_group_sizes(state::GameState{N, K, M, S}, value::Int) where {N, K, M, S}
  nr_available_per_suit = view(state.available, value, :)
  nr_table_per_suit = view(state.table, value, :)

  nr_available = sum(nr_available_per_suit)
  nr_table = sum(nr_table_per_suit)

  # Trivial cases
  if nr_available == 0
    return 0
  elseif nr_available < S
    # Impossible to make valid group(s)
    return -1
  elseif nr_available < 2S
    # At most 1 group can be made. This is valid only if all tiles on the table are used
    # in this group and if there are at least S different suits available
    return nr_table ≤ S && all(nr_table_per_suit ≤ 1) && count(nr_available_per_suit > 0) ≥ S ? S : -1
  end

  

end

# Iterate over all possible valid extensions of the runs using the available tiles
# with the current value
# A valid extension is one which either has length ≥ S or one which can still be extended
# with a larger value
# That is, runs which will require value+i further on, without any value+i being available
# of that particular suit, are omitted
function run_extensions(state::GameState{N, K, M, S}, value::Int) where {N, K, M, S}

end

# Given the maximum score increments, reconstruct which runs result in
# this score (groups trivially follow from state.available)
function reconstruct_optimal_runs!(state::GameState{N, K, M, S}, memory::ScoreMemory{N,K,M}) where {N, K, M, S}
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
function reconstruct_extension(state::GameState{N, K, M, S}, extended_index) where {N, K, M, S}

end

end # module
