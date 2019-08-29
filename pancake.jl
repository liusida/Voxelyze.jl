include("Voxelyze.jl")

const MAX_INF = 2.4
const MIN_INF = 0.2
const INF_RATE = 0.00015
const MAX_ST_FRIC = 2.0
const MIN_ST_FRIC = 0.0001
const MAX_K_FRIC = 2.0
const MIN_K_FRIC = 0.0001
const MAX_PRESS = 25000

mutable struct Sim
	Vx
	dt
	vxMass
	skinMat
	varMat
	sacsMat
	voxels
	topVoxels
	bottomVoxels
	sacVoxels
	gravity
	pressure
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
	return Sim(Vx, recommendedTimeStep(Vx)/2, vx_size^3 * ρ, mats[1], mats[2], mats[3], voxs[1], voxs[2], voxs[3], voxs[4], [0., 0., 0.], 0, zeros(10, 10))
end

#                      Vx, 18 28 592949 1080
function setVoxels(Vx, W, L, E,     ρ)
	skin = addMaterial(Vx, E, ρ)
	setPoissonsRatio(skin, 0.35)
	setColor(skin, 0, 255, 0)
	setGlobalDamping(skin, 0.0001)
	setInternalDamping(skin, 1.0)
	setCollisionDamping(skin, 1.0)
	setStaticFriction(skin, MAX_ST_FRIC)
	setKineticFriction(skin, MAX_K_FRIC)
	
	varF = [addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ)]
	map(mat -> setPoissonsRatio(mat, 0.35), varF)
	map(mat -> setColor(mat, 0, 255, 0), varF)
	map(mat -> setGlobalDamping(mat, 0.0001), varF)
	map(mat -> setInternalDamping(mat, 1.0), varF)
	map(mat -> setCollisionDamping(mat, 1.0), varF)
	map(mat -> setStaticFriction(mat, MIN_ST_FRIC), varF)
	map(mat -> setKineticFriction(mat, MIN_K_FRIC), varF)

	
	sacs = [addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ),
			addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ)]
	map(mat -> setPoissonsRatio(mat, 0.35), sacs)
	map(mat -> setColor(mat, 0, 0, 255), sacs)
	map(mat -> setGlobalDamping(mat, 0.0001), sacs)
	map(mat -> setInternalDamping(mat, 1.0), sacs)
	map(mat -> setCollisionDamping(mat, 1.0), sacs)
	map(mat -> setStaticFriction(mat, 0.5), sacs)
	map(mat -> setKineticFriction(mat, 0.4), sacs)
	

	voxels = []
	topLayer = []
	bottomLayer = []
	for x in 1:W
		for y in 1:L
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

	#111011101110111
	#123456789012345678
	#111001110011100111
	airsacs = []
	i = 1
	for x in 1:W
		if x in [4, 8, 12] #[4, 5, 9, 10, 14, 15]
			if x in [4, 8, 12] #[5, 10, 15]
				i += 1
			end
		else
			for y in 4:L-3
				push!(airsacs, setVoxel(Vx, sacs[i], x, y, 4))
				push!(airsacs, setVoxel(Vx, sacs[i], x, y, 5))

				push!(airsacs, setVoxel(Vx, sacs[i+4], x, y, 1))
				push!(airsacs, setVoxel(Vx, sacs[i+4], x, y, 0))
			end
		end
	end

	for x in 2:(W-1)
		for y in 1:L
			breakLink(Vx, x, y, 2, Z_POS)
		end
	end

	voxels = [topLayer..., bottomLayer..., airsacs...]
	return ((skin, varF, sacs), (voxels, topLayer, bottomLayer, airsacs))
end

function polar_cart(r, θ, ϕ)
	x = r*sind(θ)*cosd(ϕ)
	y = r*sind(θ)*sind(θ)
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
end

function setActuactionMatrix(sim, matrix)
	@assert(size(matrix)[1] == 10)
	@assert(size(matrix)[2] > 0)
	sim.actMatrix = matrix
end

function initialize(sim)
	nodes = []
	pMesh = MeshRender(sim.Vx)
	generateMesh(pMesh)
	push!(nodes, getMesh(pMesh))
	for i in 1.0:-0.001:MIN_INF
		map(mat -> setExternalScaleFactor(mat, 1.0, 1.0, i), sim.sacsMat)
		t = ambientTemperature(sim.Vx)
		setAmbientTemperature(sim.Vx, t)
		map(vx -> setForce(vx, sim.gravity...), sim.bottomVoxels)
		map(vx -> setForce(vx, sim.gravity...), sim.topVoxels)
		map(vx -> setForce(vx, (sim.gravity./50)...), sim.sacVoxels)
		doTimeStep(sim.Vx, sim.dt)
		if i % 100 == 0
			generateMesh(pMesh)
			push!(nodes, getMesh(pMesh))
		end
	end
	for i in 0:2:sim.pressure
		applyPressure(sim, i)
		map(vx -> setForce(vx, (sim.gravity./50)...), sim.sacVoxels)
		doTimeStep(sim.Vx, sim.dt)
		if i % 100 == 0
			generateMesh(pMesh)
			push!(nodes, getMesh(pMesh))
		end
	end
	map(mat -> setGlobalDamping(mat, 0), sim.varMat)
	map(mat -> setGlobalDamping(mat, 0), sim.sacsMat)
	setGlobalDamping(sim.skinMat, 0)
	for i in 1:2000
		step(sim)
		if i % 100 == 0
			generateMesh(pMesh)
			push!(nodes, getMesh(pMesh))
		end
	end
	return nodes
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
	t = ambientTemperature(sim.Vx)
	setAmbientTemperature(sim.Vx, t)
	applyPressure(sim, sim.pressure)
	map(vx -> setForce(vx, (sim.gravity./50)...), sim.sacVoxels)
	doTimeStep(sim.Vx, sim.dt)
end

function increaseFric(mat)
	setStaticFriction(mat, MAX_ST_FRIC)
	setKineticFriction(mat, MAX_K_FRIC)
	#setExternalScaleFactor(mat, 1.0, 1.0, 1.4)
	true
end

function decreaseFric(mat)
	setStaticFriction(mat, MIN_ST_FRIC)
	setKineticFriction(mat, MIN_K_FRIC)
	#setExternalScaleFactor(mat, 1.0, 1.0, 1.0)
	true
end

function stretchCoef(pressure)
	a = 1.5
	b = 3.5
	return (b - a) * ((pressure - 0)/(MAX_PRESS- 0)) + a
end

function inflate(mat)
	ext = externalScaleFactor(mat)
	inf = [INF_RATE/35, INF_RATE/stretchCoef(sim.pressure), INF_RATE]
	if ext[3] >= MAX_INF
		return true
	else
		setExternalScaleFactor(mat, (ext .+ inf)...)
	end
	return false
end

function deflate(mat)
	ext = externalScaleFactor(mat)
	inf = [INF_RATE/35, INF_RATE/stretchCoef(sim.pressure), INF_RATE]
	if ext[3] <= MIN_INF
		return true
	else
		setExternalScaleFactor(mat, (ext .- inf)...)
	end
	return false
end

function run(sim; save=false)
	nodes = []
	pMesh = Nothing
	if save
		pMesh = MeshRender(sim.Vx)
		generateMesh(pMesh)
		push!(nodes, getMesh(pMesh))
	end
	for i in 1:12#size(sim.actMatrix)[2]
		println(i)
		act = sim.actMatrix[:, i]
		done = zeros(Bool, 8)
		for j in 1:2
			act[8+j] == 0 && decreaseFric(sim.varMat[j])
			act[8+j] == 1 && increaseFric(sim.varMat[j])
		end
		k = 0
		while sum(done) < 8
			for j in 1:8
				if act[j] == 0
					done[j] = deflate(sim.sacsMat[j])
				elseif act[j] == 1
					done[j] = inflate(sim.sacsMat[j])
				end
			end
			step(sim)
			if save && k % 100 == 0
				generateMesh(pMesh)
				push!(nodes, getMesh(pMesh))
			end
			k += 1
		end
		for i in 0:2000
			step(sim)
			if save && i % 100 == 0
				generateMesh(pMesh)
				push!(nodes, getMesh(pMesh))
			end
		end
	end
	return nodes
end

inch_matrix = [
		  	0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1;
		  	0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1;
		  	0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1;
		  	0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		  	1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
		  	0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1;
		]

roll_matrix = [
			0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1;
			0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0;
			0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0;
			0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0;
			1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0;
			0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0;
			0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0;
			0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
			0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
		]

#sim = Sim(0.05, 18, 28, 1000000, 10000)
sim = Sim(0.1, 15, 24, 592949, 3000)
setEnv(sim, 0, 0)
setPressure(sim, 0)#MAX_PRESS
setActuactionMatrix(sim, inch_matrix)
nodes = initialize(sim)
nodes = [nodes..., (run(sim; save=true))...]
scene = Scene()
n = Node(nodes[1])
mesh!(scene, lift(x -> x[1], n), lift(x -> x[2], n), color=lift(x -> x[3], n))
#update_cam!(scene, lift(x -> eyepos(x[1]), node), lift(x -> lookat(x[1]), node))
#scene.center = false
println(recommendedTimeStep(sim.Vx))
record(scene, "output.mp4", 2:1:length(nodes)) do i
	push!(n, nodes[i])
end





