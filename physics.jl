using DifferentialEquations
using LinearAlgebra
using Printf

import Base: @kwdef

O = [0, 0, 0]
X = [1, 0, 0]
Y = [0, 1, 0]
Z = [0, 0, 1]

# Define Force, Particle, and System

abstract type Force end

@kwdef mutable struct System
	state = nothing
	time = 0
	history = nothing
	particles::Array = []
end

function create_particle(S::System;
		mass = 1,
		charge = 0,
		radius = 0,
		position = O,
		velocity = O,
		is_static = false,
		)

	# Push the state of the particle into the system's state matrix
	rx, ry, rz = position
	vx, vy, vz = velocity
	if S.state == nothing
		S.state = [rx ry rz vx vy vz]
	else
		S.state = [S.state; rx ry rz vx vy vz]
	end

	# Actually create the particle
	p = Particle(
		     mass = mass,
		     charge = charge,
		     radius = radius,
		     is_static = is_static,
		     )
	push!(S.particles, p)
	p.identifier = length(S.particles)

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
	is_static::Bool = false
	identifier::Integer = 0
end

function position(p::Particle, state)
	return state[p.identifier, 1:3]
end

function velocity(p::Particle, state)
	return state[p.identifier, 4:6]
end

function acceleration(p::Particle, state)
	if p.is_static
		return O
	end

	F = O
	for f in p.forces
		F += apply(f, p, state)
	end
	return F / p.mass
end

function state_derivative(state, S::System, t)
	diff = nothing
	for p in S.particles
		rx, ry, rz = position(p, state)
		vx, vy, vz = velocity(p, state)
		ax, ay, az = acceleration(p, state)

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
	S.time += dt
	return sol
end

function print_state_snapshot(S::System)
	for p in S.particles
		rx, ry, rz, vx, vy, vz = S.state[p.identifier, 1:6]
		println(S.time, '\t', p.identifier, '\t',
			rx, '\t', ry, '\t', rz, '\t',
			vx, '\t', vy, '\t', vz)
	end
end


function run(S::System, dt)
	println("t\tid\trx\try\trz\tvx\tvy\tvz")
	while true
		print_state_snapshot(S)
		update(S, dt)
	end
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


#### Restoring Force ####

@kwdef struct RestoringForce <: Force
	center = O
	k = 1
end

can_act_on(F::RestoringForce, p::Particle) = true
function apply(F::RestoringForce, p::Particle, state)
	u = position(p, state) - F.center
	return - F.k * u
end


#### Stokes' Drag ####

@kwdef struct StokesDrag <: Force
	mu = 1.8e-5
end

can_act_on(F::StokesDrag, p::Particle) = (p.radius != 0)
function apply(F::StokesDrag, p::Particle, state)
	return -6 * pi * F.mu * p.radius * velocity(p, state)
end


#### Uniform Electric Field ####

@kwdef struct UniformElectricField <: Force
	E = 1
	up = Z
end

can_act_on(F::UniformElectricField, p::Particle) = (p.charge != 0)
function apply(F::UniformElectricField, p::Particle, state)
	return F.up * F.E * p.charge
end


#### Buoyant Force ####

@kwdef struct BuoyantForce <: Force
	rho = 1
	up = Z
end

can_act_on(F::BuoyantForce, p::Particle) = (p.radius != 0)
function apply(F::BuoyantForce, p::Particle, state)
	V = 4/3 * pi * p.radius^3
	return V * F.rho * F.up
end


#### Uniform Magnetic Field ####

@kwdef struct UniformMagneticField <: Force
	B = 1
	up = Z
end

can_act_on(F::UniformMagneticField, p::Particle) = (p.charge != 0)
function apply(F::UniformMagneticField, p::Particle, state)
	v = velocity(p, state)
	return p.charge * cross(v, F.B * F.up)
end


#### Spring Force ####

@kwdef struct Spring <: Force
	k = 1
	L = 1
	pa::Particle
	pb::Particle
end

can_act_on(F::Spring, p::Particle) = (p in (F.pa, F.pb))
function apply(F::Spring, p::Particle, state)
	ra = position(F.pa, state)
	rb = position(F.pb, state)
	u = rb - ra
	n = (u == O) ? O : normalize(u)
	compression = norm(u) - F.L
	if p == F.pa
		return n * F.k * compression
	elseif p == F.pb
		return -n * F.k * compression
	else
		return O
	end
end
