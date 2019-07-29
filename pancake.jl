include("Voxelyze.jl")

#                   0.006    0              2
function initialize(vx_size, floor_incline, gs)
	Vx = Voxelyze(vx_size)
	enableFloor(Vx, true)
	enableCollisions(Vx, true)
	if floor_incline > 0
		setGravity(Vx, 0)
	else
		setGravity(Vx, gs)
	end
	return Vx
end

#                      Vx, 18 28 592949 1080 1
function createPancake(Vx, W, L, E,     ρ,   cte)
	skin = addMaterial(Vx, E, ρ)
	setColor(skin, 0, 255, 0)
	setInternalDamping(skin, 1.0)
	setCollisionDamping(skin, 1.0)
	setGlobalDamping(skin, 0.3)
	
	varF = [addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ)]
	map(mat -> setColor(mat, 0, 255, 0), varF)
	map(mat -> setInternalDamping(mat, 1.0), varF)
	map(mat -> setCollisionDamping(mat, 1.0), varF)
	map(mat -> setGlobalDamping(mat, 0.3), varF)

	
	sacs = [addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ),
			addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ), addMaterial(Vx, E, ρ)]
	map(mat -> setColor(mat, 0, 0, 255), sacs)
	map(mat -> setInternalDamping(mat, 1.0), sacs)
	map(mat -> setCollisionDamping(mat, 1.0), sacs)
	#map(mat -> setGlobalDamping(mat, 1.0), sacs)
	map(mat -> setCte(mat, cte), sacs)
	

	voxels = []
	topLayer = []
	bottomLayer = []
	for x in 1:W
		for y in 1:L
			if y == 1
				push!(bottomLayer, setVoxel(Vx, varF[1], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[3], x, y, 3))
			elseif y == L
				push!(bottomLayer, setVoxel(Vx, varF[2], x, y, 2))
				push!(topLayer, setVoxel(Vx, varF[4], x, y, 3))
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
			for y in 2:L-1
				push!(airsacs, setVoxel(Vx, sacs[i], x, y, 4))
				push!(airsacs, setVoxel(Vx, sacs[i], x, y, 5))

				push!(airsacs, setVoxel(Vx, sacs[i+4], x, y, 0))
				push!(airsacs, setVoxel(Vx, sacs[i+4], x, y, 1))
			end
		end
	end

	for x in 2:(W-1)
		for y in 1:L
			breakLink(Vx, x, y, 2, Z_POS)
		end
	end

	voxels = [topLayer..., bottomLayer..., airsacs...]
	setAmbientTemperature(Vx, 0)
	return ((skin, varF, sacs), (voxels, topLayer, bottomLayer, airsacs))
end

function setTopPressure(voxels, pressure)
	for vx in voxels
		p1 = cornerPosition(vx, PPP)
		p2 = cornerPosition(vx, NPP)
		p3 = cornerPosition(vx, PNP)
		x = p2-p1
		y = p3-p1
		n = pressure .* cross(x, y)
		setForce(vx, n...)
	end
end

function setBottomPressure(voxels, pressure)
	for vx in voxels
		p1 = cornerPosition(vx, PPN)
		p2 = cornerPosition(vx, NPN)
		p3 = cornerPosition(vx, PNN)
		x = p2-p1
		y = p3-p1
		n = -pressure .* cross(x, y)
		setForce(vx, n...)
	end
end

function setPressure(voxs, pressure)
	setTopPressure(voxs[2], pressure)
	setBottomPressure(voxs[3], pressure)
end

Vx = initialize(0.006, 0, 2)
mats, voxs = createPancake(Vx, 18, 28, 592949, 1080, 1)
topVoxels = voxs[2]
bottomVoxels = voxs[3]

pMesh = MeshRender(Vx)
scene, node = setScene(pMesh, topVoxels)
record(scene, "output.mp4", 10000:20000) do i
	println(i)
	setPressure(voxs, i)
	doTimeStep(Vx)
	render(pMesh, topVoxels, node)
end

