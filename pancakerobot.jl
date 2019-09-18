include("Voxelyze.jl")

const MAX_INF = 2.5
const MIN_INF = 0.3
const INF_RATE = 0.0001
const MAX_ST_FRIC = 2.0
const MIN_ST_FRIC = 0.01
const MAX_K_FRIC = 1.6
const MIN_K_FRIC = 0.001
const MAX_PRESS = 15000

mutable struct Sim
	Vx
	dt
	vxMass
	skinMat
	intraMat
	varMat
	sacsMat
	voxels
	topVoxels
	bottomVoxels
	sacVoxels
	gravity
	pressure
	coef
	actMatrix
end

# 0.006, 18, 28, 592949, 1080
function Sim(vx_size, W, L, E, ρ)
	Vx = Voxelyze(vx_size)
	enableFloor(Vx, true)
	enableCollisions(Vx, true)
	setGravity(Vx, 0)
	setAmbientTemperature(Vx, 1)
	mats, voxs = setVoxels(Vx, W, L, E, ρ)
	return Sim(Vx, recommendedTimeStep(Vx)/1.5, vx_size^3 * ρ, mats[1], mats[2], mats[3], mats[4], voxs[1], voxs[2], voxs[3], voxs[4], [0., 0., 0.], 0, 0, zeros(10, 10))
end

#                      Vx, 18 28 592949 1080
function setVoxels(Vx, W, L, E,     ρ)
	skin = addMaterial(Vx, E, ρ)
	#setPoissonsRatio(skin, 0.35)
	setColor(skin, 0, 255, 0)
	setGlobalDamping(skin, 0.001)
	setInternalDamping(skin, 1.2)
	setCollisionDamping(skin, 1.2)
	setStaticFriction(skin, MAX_ST_FRIC)
	setKineticFriction(skin, MAX_K_FRIC)

	intraskin = addMaterial(Vx, E, ρ)
	#setPoissonsRatio(intraskin, 0.35)
	setColor(intraskin, 0, 255, 0)
	setGlobalDamping(intraskin, 0.001)
	setInternalDamping(intraskin, 1.2)
	setCollisionDamping(intraskin, 1.2)
	setStaticFriction(intraskin, MAX_ST_FRIC)
	setKineticFriction(intraskin, MAX_K_FRIC)
	setExternalScaleFactor(intraskin, 0.16, 1.0, 1.0)
	
	varF = [addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ)]
	#map(mat -> setPoissonsRatio(mat, 0.35), varF)
	map(mat -> setColor(mat, 0, 255, 0), varF)
	map(mat -> setGlobalDamping(mat, 0.001), varF)
	map(mat -> setInternalDamping(mat, 1.2), varF)
	map(mat -> setCollisionDamping(mat, 1.2), varF)
	map(mat -> setStaticFriction(mat, MAX_ST_FRIC), varF)
	map(mat -> setKineticFriction(mat, MAX_K_FRIC), varF)
	setExternalScaleFactor(varF[3], 0.16, 1.0, 1.0)
	setStaticFriction(varF[3], MIN_ST_FRIC)
	setKineticFriction(varF[3], MIN_K_FRIC)
	#map(mat -> setExternalScaleFactor(mat, 1.0, 1.0, 1.0), varF)

	
	sacs = [addMaterial(Vx, E/2, ρ), addMaterial(Vx, E/2, ρ), addMaterial(Vx, E/2, ρ), addMaterial(Vx, E/2, ρ),
			addMaterial(Vx, E/2, ρ), addMaterial(Vx, E/2, ρ), addMaterial(Vx, E/2, ρ), addMaterial(Vx, E/2, ρ)]
	#map(mat -> setPoissonsRatio(mat, 0.35), sacs)
	map(mat -> setColor(mat, 0, 0, 255), sacs)
	map(mat -> setGlobalDamping(mat, 0.001), sacs)
	map(mat -> setInternalDamping(mat, 1.2), sacs)
	map(mat -> setCollisionDamping(mat, 1.2), sacs)
	map(mat -> setStaticFriction(mat, MAX_ST_FRIC/2), sacs)
	map(mat -> setKineticFriction(mat, MAX_K_FRIC/2), sacs)
	map(mat -> setExternalScaleFactor(mat, 1.0, 1.0, MIN_INF), sacs)
	

voxels = []
topLayer = []
bottomLayer = []
for x in 1:W
	for y in 1:L
		if x in [4, 5, 9, 10, 14, 15]
			if y == 1 || y == 2 || y == 3
				push!(bottomLayer, setVoxel(Vx, varF[3], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[3], x, y, 3))
			elseif y == L || y == L-1 || y == L-2
				push!(bottomLayer, setVoxel(Vx, varF[3], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[3], x, y, 3))
			else
				push!(bottomLayer, setVoxel(Vx, intraskin, x, y, 2))
				push!(topLayer, setVoxel(Vx, intraskin, x, y, 3))
			end
		else
			if y == 1 || y == 2 || y == 3
				push!(bottomLayer, setVoxel(Vx, varF[1], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[1], x, y, 3))
			elseif y == L || y == L-1 || y == L-2
				push!(bottomLayer, setVoxel(Vx, varF[2], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[2], x, y, 3))
			else
				push!(bottomLayer, setVoxel(Vx, skin, x, y, 2))
				push!(topLayer, setVoxel(Vx, skin, x, y, 3))
			end
		end
	end
end

	#111011101110111
	#123456789012345678
	#111001110011100111
	airsacs = Vector{Any}(undef, 8)
	sac1 = []
	sac2 = []
	i = 1
	for x in 1:W
		if x in [4, 5, 9, 10, 14, 15] #[4, 8, 12] #
			if x in [5, 10, 15] #[4, 8, 12] #
				airsacs[i] = [sac1...]
				airsacs[9-i] = [sac2...]
				sac1 = []
				sac2 = []
				i += 1
			end
		else
			for y in 4:L-3
				push!(sac1, setVoxel(Vx, sacs[i], x, y, 4))
				push!(sac1, setVoxel(Vx, sacs[i], x, y, 5))

				push!(sac2, setVoxel(Vx, sacs[9-i], x, y, 1))
				push!(sac2, setVoxel(Vx, sacs[9-i], x, y, 0))
			end
		end
	end
	airsacs[i] = [sac1...]
	airsacs[9-i] = [sac2...]

	for x in 2:(W-1)
		for y in 1:L
			breakLink(Vx, x, y, 2, Z_POS)
		end
	end

	voxels = [topLayer..., bottomLayer..., (airsacs...)...]
	return ((skin, intraskin, varF, sacs), (voxels, topLayer, bottomLayer, [airsacs...]))
end

function polar_cart(r, θ, ϕ)
	x = r*sind(θ)*cosd(ϕ)
	y = r*sind(θ)*sind(ϕ)
	z = r*cosd(θ)
	return [x, y, z]
end

function cart_polar(x, y, z)
	r = √(x^2 + y^2 + z^2)
	θ = acosd(z/r)
	ϕ = atand(y/x)
	return [r, θ, ϕ]
end

function setEnv(sim, slope, orientation)
	r = 9.80665
	θ = 180 + slope
	ϕ = orientation
	g = polar_cart(r, θ, ϕ)

	gravity = 1 .* g .* sim.vxMass
	for vx in sim.voxels
		setForce(vx, gravity...)
	end
	sim.gravity = gravity
end


function setPressure(sim, pressure)
	sim.pressure = pressure
	sim.coef = stretchCoef(pressure)
end

function setActuactionMatrix(sim, matrix)
	@assert(size(matrix)[1] == 10)
	@assert(size(matrix)[2] > 0)
	sim.actMatrix = matrix
end

function initialize(sim, frame_rate)
	nodes = []
	pMesh = MeshRender(sim.Vx)
	generateMesh(pMesh)
	push!(nodes, getMesh(pMesh))
	gsave = sim.gravity
	sim.gravity = [0, 0, -9.80665] .* sim.vxMass
	for i in 0:0.5:sim.pressure
		applyPressure(sim, i)
		t = ambientTemperature(sim.Vx)
		setAmbientTemperature(sim.Vx, t)
		doTimeStep(sim.Vx, sim.dt)
		if i % frame_rate == 0
			generateMesh(pMesh)
			push!(nodes, getMesh(pMesh))
		end
	end
	map(mat -> setGlobalDamping(mat, 0), sim.varMat)
	map(mat -> setGlobalDamping(mat, 0), sim.sacsMat)
	setGlobalDamping(sim.skinMat, 0)
	setGlobalDamping(sim.intraMat, 0)
	for i in 1:2000
		step(sim)
		if i % frame_rate == 0
			generateMesh(pMesh)
			push!(nodes, getMesh(pMesh))
		end
	end
	sim.gravity = gsave
	return nodes
end

function initialize(sim)
	gsave = sim.gravity
	sim.gravity = [0, 0, -9.80665] .* sim.vxMass
	for i in 0:0.5:sim.pressure
		applyPressure(sim, i)
		t = ambientTemperature(sim.Vx)
		setAmbientTemperature(sim.Vx, t)
		doTimeStep(sim.Vx, sim.dt)
	end
	map(mat -> setGlobalDamping(mat, 0), sim.varMat)
	map(mat -> setGlobalDamping(mat, 0), sim.sacsMat)
	setGlobalDamping(sim.skinMat, 0)
	setGlobalDamping(sim.intraMat, 0)
	for i in 1:2000
		step(sim)
	end
	sim.gravity = gsave
end

function applyPressure(sim, pressure)
	for vx in sim.topVoxels
		p1 = cornerPosition(vx, PPP)
		p2 = cornerPosition(vx, NPP)
		p3 = cornerPosition(vx, PNP)
		x = p2-p1
		y = p3-p1
		n = pressure .* cross(x, y)
		n .+= sim.gravity
		setForce(vx, n...)
	end
	for vx in sim.bottomVoxels
		p1 = cornerPosition(vx, PPN)
		p2 = cornerPosition(vx, NPN)
		p3 = cornerPosition(vx, PNN)
		x = p2-p1
		y = p3-p1
		n = -pressure .* cross(x, y)
		n .+= sim.gravity
		setForce(vx, n...)
	end
end

function step(sim)
	vx = voxel(sim.Vx, 1, 28, 2)
	#println(position(vx))
	t = ambientTemperature(sim.Vx)
	setAmbientTemperature(sim.Vx, t)
	applyPressure(sim, sim.pressure)
	doTimeStep(sim.Vx, sim.dt)
end

function increaseFric(mat)
	sf = staticFriction(mat)
	kf = kineticFriction(mat)
	if sf >= MAX_ST_FRIC && kf >= MAX_K_FRIC
		setStaticFriction(mat, MAX_ST_FRIC)
		setKineticFriction(mat, MAX_K_FRIC)
		return true
	else
		setStaticFriction(mat, sf+0.01)
		setKineticFriction(mat, kf+0.01)
	end
	return false
end

function decreaseFric(mat)
	sf = staticFriction(mat)
	kf = kineticFriction(mat)
	if sf <= MIN_ST_FRIC && kf <= MIN_K_FRIC
		setStaticFriction(mat, MIN_ST_FRIC)
		setKineticFriction(mat, MIN_K_FRIC)
		return true
	else
		setStaticFriction(mat, sf-0.01)
		setKineticFriction(mat, kf-0.01)
	end
	return false
end

function stretchCoef(pressure)
	a = 2.2
	b = 10
	return (b - a) * ((pressure - 0)/(MAX_PRESS- 0)) + a
end

function inflate(mat, coef)
	ext = externalScaleFactor(mat)
	inf = [INF_RATE/15, INF_RATE/coef, INF_RATE]
	if ext[3] >= MAX_INF
		return true
	else
		setExternalScaleFactor(mat, (ext .+ inf)...)
	end
	return false
end

function deflate(mat, coef)
	ext = externalScaleFactor(mat)
	inf = [INF_RATE/15, INF_RATE/coef, INF_RATE]
	if ext[3] <= MIN_INF
		return true
	else
		setExternalScaleFactor(mat, (ext .- inf)...)
	end
	return false
end

function run(sim, frame_rate)
	nodes = []
	pMesh = MeshRender(sim.Vx)
	generateMesh(pMesh)
	push!(nodes, getMesh(pMesh))
	for i in 1:size(sim.actMatrix)[2]
		println(i)
		act = sim.actMatrix[:, i]
		done = zeros(Bool, 2)
		k = 0
		map(mat -> setGlobalDamping(mat, 1.0), sim.varMat)
		map(mat -> setGlobalDamping(mat, 1.0), sim.sacsMat)
		setGlobalDamping(sim.skinMat, 1.0)
		setGlobalDamping(sim.intraMat, 1.0)
		while sum(done) < 2
			for j in 1:2
				if act[8+j] == 0
					done[j] = decreaseFric(sim.varMat[j])
				elseif act[8+j] == 1
					done[j] = increaseFric(sim.varMat[j])
				end
			end
			step(sim)
			if k % frame_rate == 0
				generateMesh(pMesh)
				push!(nodes, getMesh(pMesh))
			end
			k += 1
		end
		for i in 0:2000
			step(sim)
			if i % frame_rate == 0
				generateMesh(pMesh)
				push!(nodes, getMesh(pMesh))
			end
		end

		act = sim.actMatrix[:, i]
		done = zeros(Bool, 8)
		k = 0
		map(mat -> setGlobalDamping(mat, 0.015), sim.varMat)
		map(mat -> setGlobalDamping(mat, 0.015), sim.sacsMat)
		setGlobalDamping(sim.skinMat, 0.015)
		setGlobalDamping(sim.intraMat, 0.015)
		while sum(done) < 8
			for j in 1:8
				if act[j] == 0
					done[j] = deflate(sim.sacsMat[j], sim.coef)
					if done[j]
						map(vx -> setForce(vx, (sim.gravity.*1.0)...), sim.sacVoxels[j])
					else
						map(vx -> setForce(vx, (sim.gravity.*0.0)...), sim.sacVoxels[j])
					end
				elseif act[j] == 1
					done[j] = inflate(sim.sacsMat[j], sim.coef)
					map(vx -> setForce(vx, (sim.gravity.*0.0)...), sim.sacVoxels[j])
				end
			end
			step(sim)
			if k % frame_rate == 0
				generateMesh(pMesh)
				push!(nodes, getMesh(pMesh))
			end
			k += 1
		end
		for i in 0:2000
			step(sim)
			if i % frame_rate == 0
				generateMesh(pMesh)
				push!(nodes, getMesh(pMesh))
			end
		end
	end
	return nodes
end

function run(sim)
	for i in 1:2#size(sim.actMatrix)[2]
		act = sim.actMatrix[:, i]
		done = zeros(Bool, 2)
		map(mat -> setGlobalDamping(mat, 1.0), sim.varMat)
		map(mat -> setGlobalDamping(mat, 1.0), sim.sacsMat)
		setGlobalDamping(sim.skinMat, 1.0)
		setGlobalDamping(sim.intraMat, 1.0)
		while sum(done) < 2
			for j in 1:2
				if act[8+j] == 0
					done[j] = decreaseFric(sim.varMat[j])
				elseif act[8+j] == 1
					done[j] = increaseFric(sim.varMat[j])
				end
			end
			step(sim)
		end
		for i in 0:2000
			step(sim)
		end

		act = sim.actMatrix[:, i]
		done = zeros(Bool, 8)
		map(mat -> setGlobalDamping(mat, 0.015), sim.varMat)
		map(mat -> setGlobalDamping(mat, 0.015), sim.sacsMat)
		setGlobalDamping(sim.skinMat, 0.015)
		setGlobalDamping(sim.intraMat, 0.015)
		while sum(done) < 8
			for j in 1:8
				if act[j] == 0
					done[j] = deflate(sim.sacsMat[j], sim.coef)
					if done[j]
						map(vx -> setForce(vx, (sim.gravity.*1.0)...), sim.sacVoxels[j])
					else
						map(vx -> setForce(vx, (sim.gravity.*0.0)...), sim.sacVoxels[j])
					end
				elseif act[j] == 1
					done[j] = inflate(sim.sacsMat[j], sim.coef)
					map(vx -> setForce(vx, (sim.gravity.*0.0)...), sim.sacVoxels[j])
				end
			end
			step(sim)
		end
		for i in 0:2000
			step(sim)
		end
	end
end

function my_round(x)
	if abs(x) > 0.99
		return 1
	else
		return 0
	end
end

function my_sin(f, ϕ)
	if f == 0
		return ones(Int64, 17)
	end
	x = collect(0:0.5:8)
	c1 = π/f
	c2 = (ϕ/2)*π/f
	return my_round.(sin.(c1 .* x .+ c2))
end

function actuation_matrix(genome)
	f = genome[:, 1]
	ϕ = genome[:, 2]
	act_mat = zeros(Int64, 10, 17)
	for r in 1:10
		act_mat[r, :] = my_sin(f[r], ϕ[r])
	end
	return act_mat
end

function fitness(genome, env)
	sim = Sim(0.01, 18, 28, 400000, 2000)
	setEnv(sim, env, genome[1])
	setPressure(sim, genome[2])
	setActuactionMatrix(sim, actuation_matrix(genome[3]))
	initialize(sim)
	run(sim)

	vector_dir = polar_cart(1, 90, genome[1])
	max_disp = 0
	for vx in sim.voxels
		cur_disp = dot(position(vx), vector_dir)
		if cur_disp > max_disp
			max_disp = cur_disp
		end
	end
	return max_disp
end

empty_matrix = [
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		]

inch_matrix = [
		  	1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
		  	1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
		  	1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
		  	1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1;
		  	1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
		]

roll_matrix = [
			0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1;
			0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0;
			0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0;
			0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0;
			0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0;
			0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0;
			0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0;
			1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		]

#genome = [ direction as angle from x,  pressure,  actuation ]

#=genome = [90, 0, inch_matrix];
println(fitness(genome, 0))
sim = Sim(0.01, 18, 28, 400000, 2000)
setEnv(sim, 0, genome[1])
setPressure(sim, genome[2])
setActuactionMatrix(sim, genome[3])
nodes = initialize(sim, 1000)
nodes = [nodes..., (run(sim, 1000))...]
scene = Scene()
n = Node(nodes[1])
mesh!(scene, lift(x -> x[1], n), lift(x -> x[2], n), color=lift(x -> x[3], n))
record(scene, "inch_flat.mp4", 2:1:length(nodes)) do i
	push!(n, nodes[i])
end


genome = [90, 0, inch_matrix];
println(fitness(genome, 15))
sim = Sim(0.01, 18, 28, 400000, 2000)
setEnv(sim, 15, genome[1])
setPressure(sim, genome[2])
setActuactionMatrix(sim, genome[3])
nodes = initialize(sim, 1000)
nodes = [nodes..., (run(sim, 1000))...]
scene = Scene()
n = Node(nodes[1])
mesh!(scene, lift(x -> x[1], n), lift(x -> x[2], n), color=lift(x -> x[3], n))
record(scene, "inch_hill.mp4", 2:1:length(nodes)) do i
	push!(n, nodes[i])
end


genome = [0, MAX_PRESS, roll_matrix];
println(fitness(genome, 0))
sim = Sim(0.01, 18, 28, 400000, 2000)
setEnv(sim, 0, genome[1])
setPressure(sim, genome[2])
setActuactionMatrix(sim, genome[3])
nodes = initialize(sim, 1000)
nodes = [nodes..., (run(sim, 1000))...]
scene = Scene()
n = Node(nodes[1])
mesh!(scene, lift(x -> x[1], n), lift(x -> x[2], n), color=lift(x -> x[3], n))
record(scene, "roll_flat.mp4", 2:1:length(nodes)) do i
	push!(n, nodes[i])
end


genome = [0, MAX_PRESS, roll_matrix];
println(fitness(genome, 15))
sim = Sim(0.01, 18, 28, 400000, 2000)
setEnv(sim, 15, genome[1])
setPressure(sim, genome[2])
setActuactionMatrix(sim, genome[3])
nodes = initialize(sim, 1000)
nodes = [nodes..., (run(sim, 1000))...]
scene = Scene()
n = Node(nodes[1])
mesh!(scene, lift(x -> x[1], n), lift(x -> x[2], n), color=lift(x -> x[3], n))
record(scene, "roll_hill.mp4", 2:1:length(nodes)) do i
	push!(n, nodes[i])
end=#

#update_cam!(scene, lift(x -> eyepos(x[1]), node), lift(x -> lookat(x[1]), node))
#scene.center = false




