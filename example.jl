include("Voxelyze.jl")

Vx = Voxelyze(0.005)                        # 5mm voxels
pMaterial1 = addMaterial(Vx, 1000000, 1000)  # A material with stiffness E=1MPa and density 1000Kg/m^3
setColor(pMaterial1, 255, 0, 0)
pMaterial2 = addMaterial(Vx, 1000000, 1000)  # A material with stiffness E=1MPa and density 1000Kg/m^3
setColor(pMaterial2, 0, 255, 0)
pMaterial3 = addMaterial(Vx, 1000000, 1000)  # A material with stiffness E=1MPa and density 1000Kg/m^3
setColor(pMaterial3, 0, 0, 255)
Voxel1 = setVoxel(Vx, pMaterial1, 0, 0, 0)   # Voxel at index x=0, y=0. z=0
Voxel2 = setVoxel(Vx, pMaterial2, 1, 0, 0)
Voxel3 = setVoxel(Vx, pMaterial3, 2, 0, 0)   # Beam extends in the +X direction

setFixedAll(Voxel1)                         # Fixes all 6 degrees of freedom with an external condition on Voxel 1
setForce(Voxel3, 0, 0, -1)                  # Pulls Voxel 3 downward with 1 Newton of force.

pMesh = MeshRender(Vx)
scene, node = setScene(pMesh)
record(scene, "output.mp4", 1:2000) do i
	if i % 1000 == 0 setForce(Voxel3, 0, 0, 0) end
	if i % 1200 == 0 breakLink(Vx, 2, 0, 0, X_NEG) end
	doTimeStep(Vx)
	render(pMesh, node)
end

