using Cxx
using Libdl

const path = pwd()
const path_to_header = path * "/include"
const path_to_lib = path * "/lib"
addHeaderDir(path_to_header * "/include", kind=C_User)
Libdl.dlopen(path_to_lib * "/libvoxelyze.so", Libdl.RTLD_GLOBAL)
cxxinclude("Voxelyze.h")

VxT = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVoxelyze},(false, false, false)},480}
pMaterialT = Cxx.CxxCore.CppPtr{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVX_Material},(false, false, false)},(false, false, false)}
voxelT = Cxx.CxxCore.CppPtr{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVX_Voxel},(false, false, false)},(false, false, false)}

# Creates an instance of the Voxelyze engine
function Voxelyze(voxelSize::Real)
	@cxx CVoxelyze(voxelSize)
end

# Runs one step through the simulation
function doTimeStep(Vx::VxT)
	@cxx Vx->doTimeStep()
end

# Runs one step through the simulation with diven time step dt
function doTimeStep(Vx::VxT, dt::Real)
	@cxx Vx->doTimeStep(dt)
end

# Creates a material in the materials pallet and returns pointer to it
function addMaterial(Vx::VxT, youngsModulus::Real, density::Real)
	@cxx Vx->addMaterial(youngsModulus, density)
end

# Creates a voxel at 3D coordinates: x y z,  with material properties: pMaterial
function setVoxel(Vx::VxT, pMaterial::pMaterialT, x::Real, y::Real, z::Real)
	@cxx Vx->setVoxel(pMaterial, x, y, z)
end

# Fixed all of the Degrees of Freedom of a voxel
function setFixedAll(voxel::voxelT)
	@cxx ( @cxx voxel->external() )->setFixedAll()
end

# Creates an external 3D force F on the voxel
function setForce(voxel::voxelT, Fx::Real, Fy::Real, Fz::Real)
	@cxx ( @cxx voxel->external() )->setForce(Fx, Fy, Fz)
end