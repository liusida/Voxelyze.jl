include("Voxelyze.jl")

L = 48
W = 16

Vx = Voxelyze(0.001)
enableFloor(Vx, true)
pMaterial1 = addMaterial(Vx, 1000000, 1000)
pMaterial2 = addMaterial(Vx, 1000000, 1000)
setColor(pMaterial1, 255, 0, 0)
setColor(pMaterial2, 0, 255, 0)

voxels = []
for i in 1:W
	for j in 1:L
		push!(voxels, setVoxel(Vx, pMaterial1, i, j, 1))
		setForce(voxels[end], 0, 0, -0.2)
		push!(voxels, setVoxel(Vx, pMaterial2, i, j, 2))
		setForce(voxels[end], 0, 0, 0.1)
	end
end
voxels = [voxels...]
track = voxel(Vx, 10, 1, 2)

for i in 2:(W-1)
	for j in 1:L
		breakLink(Vx, i, j, 1, Z_POS)
	end
end

pMesh = MeshRender(Vx)
scene, node = setScene(pMesh, voxels)
record(scene, "output.mp4", 1:2000) do i
	doTimeStep(Vx)
	render(pMesh, voxels, node)
	println("or: ", orientation(track))
	println("orAx: ", orientationAxis(track))
	println("orAn: ", orientationAngle(track))
	println()
end

