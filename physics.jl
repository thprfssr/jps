import Base: @kwdef

@kwdef struct Particle
	mass = 1
	charge = 0
	radius = 0
end

struct Force
	parameters::Dict
	evaluate::Function
	can_act_on::Function
end
