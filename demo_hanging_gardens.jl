include("physics.jl")

# Define the mesh size and the system.
M = 10
N = 10
R = 5
S = System()

for i = 1:M*N
	create_particle(S)
end

for i = 1:N
	theta = 2*pi/N
	create_particle(S, mass = Inf, is_static = true,
			pos = R * (X * cos(theta) + Y * sin(theta)))
end

# Connect the mesh to the top ring
for i = 1:N
	F = Spring(pa = S.particles[i], pb = S.particles[i + N])
	add_force(S, F)
end

# Connect each level ring together
for i = 1:M
	for j = 1:N
		if j != N
			k = j+1
		else
			k = 1
		end
		F = Spring(pa = S.particles[N*(i-1) + j], pb = S.particles[N*(i-1) + k])
		add_force(S, F)
	end
end

# Connect each vertical
for i = 1 : M - 1
	for j = 1:N
		F = Spring(pa = S.particles[N*(i-1) + j], pb = S.particles[N*i + j])
		add_force(S, F)
	end
end

# Connect each diagonal
for i = 1:M
	for j = 1:N
		if j != N
			k = j + 1
		else
			k = 1
		end
		F = Spring(pa = S.particles[N*(i-1) + j], pb = S.particles[N*i + k])
		add_force(S, F)
	end
end

# Add gravity and drag to the system
add_force(S, UniformGravity())
add_force(S, LinearDrag(beta = 10))

# Run the system
while true
	update(S, 0.01)
	#println(velocity(p, S.state))
	print_state_snapshot(S)
end
