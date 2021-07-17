include("physics.jl")

S = System()
p = create_particle(S, charge=1)
G = UniformGravity()
R = RestoringForce()
D = LinearDrag()
B = UniformMagneticField(B = 100, up = X)
add_force(S, G)
add_force(S, R)
add_force(S, D)
add_force(S, B)

while true
	update(S, 1)
	#println(velocity(p, S.state))
	print_state_snapshot(S)
end
