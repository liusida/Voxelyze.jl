include("Voxelyze.jl")

Vx = Voxelyze(0.005)                        # 5mm voxels
pMaterial = addMaterial(Vx, 1000000, 1000)  # A material with stiffness E=1MPa and density 1000Kg/m^3
Voxel1 = setVoxel(Vx, pMaterial, 0, 0, 0)   # Voxel at index x=0, y=0. z=0
Voxel2 = setVoxel(Vx, pMaterial, 1, 0, 0)
Voxel3 = setVoxel(Vx, pMaterial, 2, 0, 0)   # Beam extends in the +X direction

setFixedAll(Voxel1)                         # Fixes all 6 degrees of freedom with an external condition on Voxel 1
setForce(Voxel3, 0, 0, -1)                  # Pulls Voxel 3 downward with 1 Newton of force.

pMesh = MeshRender(Vx)
for i=1:100                                 # Simulate 100 timesteps
    doTimeStep(Vx)
    generateMesh(pMesh)
    @cxx pMesh->saveObj(pointer("obj/test$i.obj"))
end

