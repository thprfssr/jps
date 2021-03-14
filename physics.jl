using DifferentialEquations

import Base: @kwdef

include("vec.jl")

# Define Force, Particle, and System

abstract type Force end

@kwdef mutable struct System
	state = nothing
	particles::Array = []
end

function create_particle(S::System;
		mass = 1,
		charge = 0,
		radius = 0,
		pos::Vec = O,
		vel::Vec = O)

	# Push the state of the particle into the system's state matrix
	rx, ry, rz = pos.x, pos.y, pos.z
	vx, vy, vz = vel.x, vel.y, vel.z
	if S.state == nothing
		S.state = [rx ry rz vx vy vz]
	else
		S.state = [S.state; rx ry rz vx vy vz]
	end

	# Actually create the particle
	p = Particle(mass = mass, charge = charge, radius = radius)
	push!(S.particles, p)
	p._id = length(S.particles)

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
	_id::Integer = 0
end

function position(p::Particle, state)
	return Vec(state[p._id, 1:3]...)
end

function velocity(p::Particle, state)
	return Vec(state[p._id, 4:6]...)
end

function acceleration(p::Particle, state)
	F = O
	for f in p.forces
		F += apply(f, p, state)
	end
	return F / p.mass
end

function state_derivative(state, S::System, t)
	diff = nothing
	for p in S.particles
		rx, ry, rz, vx, vy, vz = state[p._id, 1:6]
		acc = acceleration(p, state)
		ax, ay, az = acc.x, acc.y, acc.z

		if diff == nothing
			diff = [vx vy vz ax ay az]
		else
			diff = [diff; vx vy vz ax ay az]
		end
	end
	return diff
end

function update(S, dt)
	tspan = (0.0, dt)
	prob = ODEProblem(state_derivative, S.state, tspan, S)
	sol = solve(prob)
	S.state = sol(dt)
end



#### Uniform Gravitational Field ####

@kwdef struct UniformGravity <: Force
	g = 9.8
	up = Z
end

can_act_on(F::UniformGravity, p::Particle) = true
function apply(F::UniformGravity, p::Particle, state)
	return - p.mass * F.g * F.up
end

#### Simple Drag ####

@kwdef struct LinearDrag <: Force
	beta = 1
end

can_act_on(F::LinearDrag, p::Particle) = true
function apply(F::LinearDrag, p::Particle, state)
	return -F.beta * velocity(p, state)
end
