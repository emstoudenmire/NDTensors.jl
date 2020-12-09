
#
# Block
#

struct Block{N}
  data::NTuple{N, UInt}
  hash::UInt
  function Block{N}(data::NTuple{N, UInt}) where {N, H}
    h = _hash(data)
    return new{N}(data, h)
  end
end

#
# Constructors
#

Block{N}(t::NTuple{N, Int}) where {N} =
  Block{N}(convert(NTuple{N, UInt}, t))

Block(t::NTuple{N, UInt}) where {N} = Block{N}(t)

Block(t::NTuple{N, Int}) where {N} =
  Block{N}(convert(NTuple{N, UInt}, t))

Block(I::CartesianIndex{N}) where {N} = Block{N}(I.I)

#
# Conversions
#

Block{N}(v::MVector{N}) where {N} = Block{N}(Tuple(v))

Block{N}(v::SVector{N}) where {N} = Block{N}(Tuple(v))

CartesianIndex(b::Block) = CartesianIndex(Tuple(b))

Tuple(b::Block{N}) where {N} = NTuple{N, UInt}(b.data)

convert(::Type{Block}, I::CartesianIndex{N}) where {N} = Block{N}(I.I)

convert(::Type{Block{N}}, I::CartesianIndex{N}) where {N} = Block{N}(I.I)

#
# Getting and setting fields
#

gethash(b::Block) = b.hash[]

sethash!(b::Block, h::UInt) = (b.hash[] = h; return b)

#
# Basic functions
#

length(::Block{N}) where {N} = N

iterate(b::Block, args...) = iterate(b.data, args...)

using Base: @propagate_inbounds
@propagate_inbounds function getindex(b::Block, i::Int)
  return b.data[i]
end

@propagate_inbounds setindex(b::Block{N}, args...) where {N} =
  Block{N}(setindex(b.data, args...))

ValLength(::Type{<:Block{N}}) where {N} = Val{N}

deleteat(b::Block, pos) = Block(deleteat(Tuple(b), pos))

insertafter(b::Block, val, pos) = Block(insertat(Tuple(b), val, pos))

getindices(b::Block, I) = getindices(Tuple(b), I)

#
# Hashing
#

# Borrowed from:
# https://github.com/JuliaLang/julia/issues/37073
# This is the same as Julia's Base tuple hash, but is
# a bit faster.
_hash(t::Tuple) = _hash(t, zero(UInt))
_hash(::Tuple{}, h::UInt) = h + Base.tuplehash_seed
using Base.Cartesian: @nexprs
@generated function _hash(b::NTuple{N}, h::UInt) where {N}
  quote
    out = h + Base.tuplehash_seed
    @nexprs $N i -> out = hash(b[$N-i+1], out)
  end
end
# Stop inlining after some number of arguments to avoid code blowup
function _hash(t::Base.Any16, h::UInt)
  out = h + Base.tuplehash_seed
  for i = length(t):-1:1
      out = hash(t[i], out)
  end
  return out
end

hash(b::Block) = UInt(b.hash)
hash(b::Block, h::UInt) = h + hash(b)

#
# Custom NTuple{N, Int} hashes
# These are faster, but have a lot of collisions
#

# Borrowed from:
# https://stackoverflow.com/questions/20511347/a-good-hash-function-for-a-vector
# This seems to have a lot of clashes
#function Base.hash(b::Block, seed::UInt)
#  h = UInt(0x9e3779b9)
#  for n in b
#    seed ⊻= n + h + (seed << 6) + (seed >> 2)
#  end
#  return seed
#end

# Borrowed from:
# http://www.docjar.com/html/api/java/util/Arrays.java.html
# Could also consider uring the CPython tuple hash:
# https://github.com/python/cpython/blob/0430dfac629b4eb0e899a09b899a494aa92145f6/Objects/tupleobject.c#L406
#function Base.hash(b::Block, h::UInt)
#  h += Base.tuplehash_seed
#  for n in b
#    h = 31 * h + n ⊻ (n >> 32)
#  end
#  return h
#end

