# to run the experiment faster several times:
# ```
# julia
# include("exp.jl")
# ```
# change the source code, and use include to run again:
# ```
# include("exp.jl")
# ```
# this will skip the progress of reload Cxx and Voxelyze.so
#
include("../Voxelyze.jl")


Vx = Voxelyze(0.005)							# 5mm voxels
enableFloor(Vx, true)
enableCollisions(Vx, true)
setGravity(Vx, 10)

pGround = addMaterial(Vx, 10000, 10000)
setColor(pGround, 100,100,100)
for i=-20:20
    for j=-20:20
        v = setVoxel(Vx, pGround, i,j,-1)
        setFixedAll(v)
    end
end

function blob(Vx, youngsModulus, density, offset=0)
    pMaterial = addMaterial(Vx, youngsModulus, density)
    setColor(pMaterial, 0,50,200)

    size = (10,10,10)
    Robot = Array{Any}(nothing, size)
    A = rand(size[1], size[2], size[3])
    for i in CartesianIndices(A)
        if (A[i]<1.0)
            Robot[i] = setVoxel(Vx, pMaterial, offset+i[1], i[2], i[3]+10)
        end
    end
end

blob(Vx, 1e3, 1e4, 10)
blob(Vx, 1, 1, -10)

pMesh = MeshRender(Vx)
scene, node = setScene(pMesh)
record(scene, string(@__FILE__, ".mp4"), 1:500) do i
	doTimeStep(Vx)
	render(pMesh, node)
	if i % 10 == 0 println("step ", i) end
end
