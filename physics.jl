import Base: @kwdef

include("vec.jl")

# Define Force, Particle, and System

abstract type Force end

@kwdef mutable struct System
	state::Dict = Dict()
	particles::Array = []
end

function create_particle(S::System;
		mass = 1,
		charge = 0,
		radius = 0,
		position::Vec = O,
		velocity::Vec = O)
	p = Particle(mass = mass, charge = charge, radius = radius)
	S.state[p] = (position, velocity)
	push!(S.particles, p)
	return p
end

function add_force(S::System, F::Force)
	for p in S.particles
		if can_act_on(F, p)
			push!(p.forces, F)
		end
	end
end

@kwdef mutable struct Particle
	mass = 1
	charge = 0
	radius = 0
	forces::Set = Set()
end

function position(p::Particle, state::Dict)
	pos, vel = state[p]
	return pos
end

function velocity(p::Particle, state::Dict)
	pos, vel = state[p]
	return vel
end

function acceleration(p::Particle, state::Dict)
	F = O
	for f in p.forces
		F += apply(f, p, state)
	end
	return F / p.mass
end

function __state_dict_to_matrix(state::Dict, S::System)
	A = reshape([], 0, 6) # Make empty six-row matrix
	for p in S.particles
		pos, vel = state[p]
		rx, ry, rz = pos.x, pos.y, pos.z
		vx, vy, vz = vel.x, vel.y, vel.z
		A = [A; rx ry rz vx vy vz]
	end
	return A
end

function __state_matrix_to_dict(state_matrix, S::System)
	i = 1
	state = Dict()
	for p in S.particles
		rx, ry, rz, vx, vy, vz = state_matrix[i,1:6]
		pos = Vec(rx, ry, rz)
		vel = Vec(vx, vy, vz)
		state[p] = (pos, vel)

		i += 1
	end
	return state
end

#### Uniform Gravitational Field ####

@kwdef struct UniformGravity <: Force
	g = 9.8
	up = Z
end

function apply(F::UniformGravity, p::Particle, state::Dict)
	return - p.mass * F.g * F.up
end

can_act_on(F::UniformGravity, p::Particle) = true
