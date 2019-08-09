include("Voxelyze.jl")

mutable struct Sim
	Vx
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
	mats, voxs = setVoxels(Vx, W, L, E, ρ)
	return Sim(Vx, vx_size^3 * ρ, mats[1], mats[2], mats[3], voxs[1], voxs[2], voxs[3], voxs[4], [0., 0., 0.], 0, zeros(10, 1))
end

#                      Vx, 18 28 592949 1080
function setVoxels(Vx, W, L, E,     ρ)
	skin = addMaterial(Vx, E, ρ)
	setColor(skin, 0, 255, 0)
	setInternalDamping(skin, 0.8)
	setCollisionDamping(skin, 0.8)
	setStaticFriction(skin, 0.5)
	setKineticFriction(skin, 0.5)
	
	varF = [addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ)]
	map(mat -> setColor(mat, 0, 255, 0), varF)
	map(mat -> setInternalDamping(mat, 0.8), varF)
	map(mat -> setCollisionDamping(mat, 0.8), varF)
	map(mat -> setExternalScaleFactor(mat, 1.0, 1.0, 1.5), varF)
	map(mat -> setStaticFriction(mat, 0.5), varF)
	map(mat -> setKineticFriction(mat, 0.5), varF)

	
	sacs = [addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ),
			addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ)]
	map(mat -> setColor(mat, 0, 0, 255), sacs)
	map(mat -> setInternalDamping(mat, 0.8), sacs)
	map(mat -> setCollisionDamping(mat, 0.8), sacs)
	map(mat -> setExternalScaleFactor(mat, 1.0, 1.0, 0.25), sacs)
	map(mat -> setStaticFriction(mat, 0.5), sacs)
	map(mat -> setKineticFriction(mat, 0.5), sacs)
	

	voxels = []
	topLayer = []
	bottomLayer = []
	for x in 1:W
		for y in 1:L
			if y == 1 || y == 2
				push!(bottomLayer, setVoxel(Vx, varF[1], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[1], x, y, 3))
			elseif y == L || y == L-1
				push!(bottomLayer, setVoxel(Vx, varF[2], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[2], x, y, 3))
			else
				push!(bottomLayer, setVoxel(Vx, skin, x, y, 2))
				push!(topLayer, setVoxel(Vx, skin, x, y, 3))
			end
		end
	end

	#123456789012345678
	#111001110011100111
	airsacs = []
	i = 1
	for x in 1:W
		if x in [4, 5, 9, 10, 14, 15]
			if x in [5, 10, 15]
				i += 1
			end
		else
			for y in 3:L-2
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

	gravity = 2 .* g .* sim.vxMass
	for vx in sim.voxels
		setForce(vx, gravity...)
	end
	sim.gravity = gravity
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

function setPressure(sim, pressure)
	sim.pressure = pressure
end

function setActuactionMatrix(sim, matrix)
	@assert(size(matrix)[1] == 10)
	@assert(size(matrix)[2] > 0)
	sim.actMatrix = matrix
end

function initialize(sim)
	gSave = sim.gravity
	sim.gravity = 2 .* [0., 0., -9.80665] .* sim.vxMass
	for i in 1:50
		doTimeStep(sim.Vx)
		if i % 5 == 0
			map(haltMotion, sim.voxels)
		end
	end
	for i in 1:sim.pressure*2
		applyPressure(sim, i/2)
		doTimeStep(sim.Vx)
	end
	for i in 1:1000
		step(sim)
	end
	sim.gravity = gSave
	for i in 1:5000
		step(sim)
	end
end

function run(sim)

end

function step(sim)
	applyPressure(sim, sim.pressure)
	doTimeStep(sim.Vx)
end

sim = Sim(0.006, 18, 28, 592949, 1080)
setEnv(sim, 15, 0)
setPressure(sim, 7000)
initialize(sim)

pMesh = MeshRender(sim.Vx)
scene, node = setScene(pMesh)
record(scene, "output.mp4", 1:5000) do i
	println(i)
	step(sim)
	render(pMesh, node)
end





