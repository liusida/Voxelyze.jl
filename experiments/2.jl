include("../Voxelyze.jl")

# Question: Why the time seems frozen after I add Blob B?

function exp2()
    Vx = Voxelyze(0.005)							# 5mm voxels
    setGravity(Vx, 1)   #Is g=1 normal?

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

    blob(Vx, 1, 1e2, 10) # Blob A.

    #blob(Vx, 1e7, 1e2, -10) # Blob B. After I add this blob, why time frozen? Does adding this blob have effect on Blob A?

    pMesh = MeshRender(Vx)
    scene, node = setScene(pMesh)
    record(scene, string(@__FILE__, ".mp4"), 1:500) do i
        doTimeStep(Vx)
        render(pMesh, node)
        if i % 10 == 0 println("step ", i) end
    end
end

exp2()
