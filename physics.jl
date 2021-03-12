import Base: @kwdef


# Define Force, Particle, and System

abstract type Force end

@kwdef mutable struct System
	state::Dict = Dict()
end

function create_particle(S::System;
		mass = 1,
		charge = 0,
		radius = 0,
		position::Vec = O,
		velocity::Vec = O)
	p = Particle(mass = mass, charge = charge, radius = radius)
	S.state[p] = (position, velocity)
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
	position, velocity = state[p]
	return position
end

function velocity(p::Particle, state::Dict)
	position, velocity = state[p]
	return velocity
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
