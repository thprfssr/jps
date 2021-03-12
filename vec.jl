using Match

import Base: +, -, *, /, print, promote_rule, convert, show

abstract type AbstractMultivec end

struct Multivec <: AbstractMultivec
	s
	x
	y
	z
	ix
	iy
	iz
	i
end

struct Vec <: AbstractMultivec
	x
	y
	z
end



# Define constant vectors
O = Vec(0, 0, 0)
X = Vec(1, 0, 0)
Y = Vec(0, 1, 0)
Z = Vec(0, 0, 1)
IX = Multivec(0, 0, 0, 0, 1, 0, 0, 0)
IY = Multivec(0, 0, 0, 0, 0, 1, 0, 0)
IZ = Multivec(0, 0, 0, 0, 0, 0, 1, 0)
I = Multivec(0, 0, 0, 0, 0, 0, 0, 1)

# Define common vector operations
(+)(u::Vec) = u
(+)(u::Vec, v::Vec) = Vec(u.x + v.x, u.y + v.y, u.z + v.z)
(-)(u::Vec, v::Vec) = Vec(u.x - v.x, u.y - v.y, u.z - v.z)
(-)(u::Vec) = Vec(-u.x, -u.y, -u.z)
(*)(u::Vec, s::Number) = Vec(u.x * s, u.y * s, u.z * s)
(*)(s::Number, u::Vec) = u * s
(/)(u::Vec, s::Number) = Vec(u.x / s, u.y / s, u.z / s)

function dot(u::Vec, v::Vec)
	return u.x * v.x + u.y * v.y + u.z * v.z
end

function norm(u::Vec)
	return sqrt(u.x^2 + u.y^2 + u.z^2)
end
magnitude = norm

function normalize(u::Vec)
	a = norm(u)
	if a == 0
		return O
	else
		return u / a
	end
end

# Define vector-to-multivector conversion rule
convert(::Type{Multivec}, u::Vec) = Multivec(0, u.x, u.y, u.z, 0, 0, 0, 0)
convert(::Type{Multivec}, s::T) where {T<:Number} = Multivec(s,0,0,0,0,0,0,0)
promote_rule(::Type{Multivec}, ::Type{Vec}) = Multivec
function promote_rule(::Type{M}, ::Type{T}) where
	{T<:Number,M<:AbstractMultivec}
	return Multivec
end

# Define common operations to be promoted
(+)(u, v) = (+)(promote(u, v)...)
(-)(u, v) = (-)(promote(u, v)...)
(*)(u::Vec, v::AbstractMultivec) = (*)(promote(u, v)...)
(*)(u::AbstractMultivec, v::Vec) = (*)(promote(u, v)...)

# Define common multivector operations

(+)(u::Multivec) = u
function (+)(u::Multivec, v::Multivec)
	return Multivec(
		u.s + v.s,
		u.x + v.x,
		u.y + v.y,
		u.z + v.z,
		u.ix + v.ix,
		u.iy + v.iy,
		u.iz + v.iz,
		u.i + v.i)
end

(-)(u::Multivec) = Multivec(-u.s, -u.x, -u.y, -u.z, -u.ix, -u.iy, -u.iz, -u.i)
function (-)(u::Multivec, v::Multivec)
	return Multivec(
		u.s - v.s,
		u.x - v.x,
		u.y - v.y,
		u.z - v.z,
		u.ix - v.ix,
		u.iy - v.iy,
		u.iz - v.iz,
		u.i - v.i)
end

(*)(s::Number, u::Multivec) = u * s
function (*)(u::Multivec, s::Number)
	return Multivec(
		u.s * s,
		u.x * s,
		u.y * s,
		u.z * s,
		u.ix * s,
		u.iy * s,
		u.iz * s,
		u.i * s)
end

(*)(u::Vec, v::Vec) = convert(Multivec, u) * convert(Multivec, v)
function (*)(u::Multivec, v::Multivec)
	ar,ax,ay,az,aix,aiy,aiz,ai = u.s,u.x,u.y,u.z,u.ix,u.iy,u.iz,u.i
	br,bx,by,bz,bix,biy,biz,bi = v.s,v.x,v.y,v.z,v.ix,v.iy,v.iz,v.i
	cr = ar*br+ax*bx+ay*by+az*bz-aix*bix-aiy*biy-aiz*biz-ai*bi
	cx = ar*bx+ax*br-ay*biz+az*biy-aix*bi-aiy*bz+aiz*by-ai*bix
	cy = ar*by+ax*biz+ay*br-az*bix+aix*bz-aiy*bi-aiz*bx-ai*biy
	cz = ar*bz-ax*biy+ay*bix+az*br-aix*by+aiy*bx-aiz*bi-ai*biz
	cix = ar*bix+ax*bi+ay*bz-az*by+aix*br-aiy*biz+aiz*biy+ai*bx
	ciy = ar*biy-ax*bz+ay*bi+az*bx+aix*biz+aiy*br-aiz*bix+ai*by
	ciz = ar*biz+ax*by-ay*bx+az*bi-aix*biy+aiy*bix+aiz*br+ai*bz
	ci = ar*bi+ax*bix+ay*biy+az*biz+aix*bx+aiy*by+aiz*bz+ai*br
	return Multivec(cr, cx, cy, cz, cix, ciy, ciz, ci)
end

function grade(u::Multivec, n::Number)
	@match n begin
		0 => return u.s
		1 => return Vec(u.x, u.y, u.z)
		2 => return u.ix * IX + u.iy * IY + u.iz * IZ
		3 => return u.i * I
		_ => return 0
	end
end

function show(io::IO, u::AbstractMultivec)
	u = convert(Multivec, u)
	B = ("1", "X", "Y", "Z", "IX", "IY", "IZ", "I")
	R = (u.s, u.x, u.y, u.z, u.ix, u.iy, u.iz, u.i)
	S = ("", "", "", "", "", "", "", "")
	representation = ""
	for i in 1:8
		s = @match R[i] begin
			0	=> ""
			1	=> B[i]
			-1	=> "-" * B[i]
			_	=> string(R[i]) * "*" * B[i]
		end

		if s != ""
			if representation != ""
				representation *= " + "
			end

			representation *= s
		end
	end

	if representation == ""
		print("O")
	else
		print(representation)
	end
end
