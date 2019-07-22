include("Voxelyze.jl")

function setTopPressure(voxels)
	for vx in voxels
		p1 = cornerPosition(vx, PPP)
		p2 = cornerPosition(vx, NPP)
		p3 = cornerPosition(vx, PNP)
		x = p2-p1
		y = p3-p1
		n = 2000000 .* cross(x, y)
		setForce(vx, n...)
	end
end

function setBottomPressure(voxels)
	for vx in voxels
		p1 = cornerPosition(vx, PPN)
		p2 = cornerPosition(vx, NPN)
		p3 = cornerPosition(vx, PNN)
		x = p2-p1
		y = p3-p1
		n = -2000000 .* cross(x, y)
		setForce(vx, n...)
	end
end

L = 48
W = 17

Vx = Voxelyze(0.05)
enableFloor(Vx, true)
enableCollisions(Vx, false)
setGravity(Vx, 1)

pMaterial1 = addMaterial(Vx, 50000000, 2300)
pMaterial2 = addMaterial(Vx, 50000000, 2300)
pMaterial3 = addMaterial(Vx, 50000000, 2300)
setColor(pMaterial1, 255, 0, 0)
setColor(pMaterial2, 0, 255, 0)
setColor(pMaterial3, 0, 0, 255)
setCte(pMaterial1, 0)
setCte(pMaterial2, 0)
setCte(pMaterial3, 0)
setInternalDamping(pMaterial1, 1.0)
setGlobalDamping(pMaterial1, 0.5)
setCollisionDamping(pMaterial1, 1.0)
setInternalDamping(pMaterial2, 1.0)
setGlobalDamping(pMaterial2, 0.5)
setCollisionDamping(pMaterial2, 1.0)
setInternalDamping(pMaterial3, 1.0)
setGlobalDamping(pMaterial3, 0.5)
setCollisionDamping(pMaterial3, 1.0)

voxels = []
topVoxels = []
bottomVoxels = []
for i in 1:W
	for j in 1:L
		push!(bottomVoxels, setVoxel(Vx, pMaterial1, i, j, 0))
		#setForce(voxels[end], 0, 0, -0.2)
		push!(topVoxels, setVoxel(Vx, pMaterial2, i, j, 1))
		#setForce(voxels[end], 0, 0, 0.1)
		#=if i%2 == 0
			push!(voxels, setVoxel(Vx, pMaterial3, i, j, 3))
		end=#
	end
end
topVoxels = [topVoxels...]
bottomVoxels = [bottomVoxels...]
voxels = [topVoxels..., bottomVoxels...]

for i in 2:(W-1)
	for j in 1:L
		breakLink(Vx, i, j, 0, Z_POS)
	end
end

pMesh = MeshRender(Vx)
scene, node = setScene(pMesh, bottomVoxels)
record(scene, "output.mp4", 1:4000) do i
	#global topVoxels, bottomVoxels
	#setAmbientTemperature(Vx, abs(sind(i/100)))
	setTopPressure(topVoxels)
	setBottomPressure(bottomVoxels)
	doTimeStep(Vx)
	render(pMesh, bottomVoxels, node)
end

