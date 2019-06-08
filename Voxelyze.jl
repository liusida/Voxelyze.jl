using Cxx
using Libdl

const path = pwd()
const path_to_header = path * "/include"
const path_to_lib = path * "/lib"
addHeaderDir(path_to_header, kind=C_User)
Libdl.dlopen(path_to_lib * "/libvoxelyze.so", Libdl.RTLD_GLOBAL)
cxxinclude("Voxelyze.h")

VxT = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVoxelyze},(false, false, false)},480}

pMaterialT = Cxx.CxxCore.CppPtr{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVX_Material},(false, false, false)},(false, false, false)}

voxelT = Cxx.CxxCore.CppPtr{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVX_Voxel},(false, false, false)},(false, false, false)}
linkDirection = Cxx.CxxCore.CppEnum{Symbol("CVX_Voxel::linkDirection"),UInt32}
voxelCorner = Cxx.CxxCore.CppEnum{Symbol("CVX_Voxel::voxelCorner"),UInt32}

#######################################################
############## VOXELYZE ENGINE FUNCTIONS ##############
#######################################################

# Creates an instance of the Voxelyze engine
function Voxelyze(voxelSize::Real)
	@cxx CVoxelyze(voxelSize)
end

# Load Voxel Properties from JSON file
function loadJSON(Vx::VxT, jsonFilePath::String)
	@cxx Vx->loadJSON(pointer(jsonFilePath))
end

# Save Voxel Properties in JSON file
function saveJSON(Vx::VxT, jsonFilePath::String)
	@cxx Vx->saveJSON(pointer(jsonFilePath))
end

# Runs one step through the simulation
function doTimeStep(Vx::VxT)
	@cxx Vx->doTimeStep()
end

# Runs one step through the simulation with diven time step dt
function doTimeStep(Vx::VxT, dt::Real)
	@cxx Vx->doTimeStep(dt)
end

# Reset the Voxelyze engine and all of the voxels to original positions
function reset(Vx::VxT)
	@cxx Vx->resetTime()
end

# Set the gravity of the voxelyze engine
function setGravity(Vx::VxT, g::Real)
	@cxx Vx->setGravity(g)
end

# Enable the floor of the voxelyze engine
function enableFloor(Vx::VxT, enabled::Bool)
	@cxx Vx->enableFloor(enabled)
end

# Enable collisions of the voxelyze engine
function enableCollisions(Vx::VxT, enabled::Bool)
	@cxx Vx->enableCollisions(enabled)
end

# Set the ambient temperature of the voxelyze engine
function setAmbientTemperature(Vx::VxT, temperature::Real)
	@cxx Vx->setAmbientTemperature(temperature, true)
end

# Set the ambient temperature of the current voxelyze instance
function setAmbientTemperature(Vx::VxT, temperature::Real, allVoxels::Bool)
	@cxx Vx->setAmbientTemperature(temperature, allVoxels)
end




#######################################################
################# MATERIAL FUNCTIONS ##################
#######################################################

# Creates a material in the materials pallet and returns pointer to it
function addMaterial(Vx::VxT, youngsModulus::Real, density::Real)
	@cxx Vx->addMaterial(youngsModulus, density)
end

# Sets the color of a given material
function setColor(pMaterial::pMaterialT, red::Int, green::Int, blue::Int, alpha::Int)
	@cxx pMaterial->setColor(red, green, blue, alpha)
end

# Sets the color of a given material
function setColor(pMaterial::pMaterialT, red::Int, green::Int, blue::Int)
	@cxx pMaterial->setColor(red, green, blue, 255)
end




#######################################################
################### VOXEL FUNCTIONS ###################
#######################################################

# Defines the direction of a link relative to a given voxel
X_POS = @cxx CVX_Voxel::X_POS # Positive X direction
X_NEG = @cxx CVX_Voxel::X_NEG # Negative X direction
Y_POS = @cxx CVX_Voxel::Y_POS # Positive Y direction
Y_NEG = @cxx CVX_Voxel::Y_NEG # Negative Y direction
Z_POS = @cxx CVX_Voxel::Z_POS # Positive Z direction
Z_NEG = @cxx CVX_Voxel::Z_NEG # Negative Z direction

# Defines each of 8 corners of a voxel
NNN = @cxx CVX_Voxel::NNN # 0b000
NNP = @cxx CVX_Voxel::NNP # 0b001
NPN = @cxx CVX_Voxel::NPN # 0b010
NPP = @cxx CVX_Voxel::NPP # 0b011
PNN = @cxx CVX_Voxel::PNN # 0b100
PNP = @cxx CVX_Voxel::PNP # 0b101
PPN = @cxx CVX_Voxel::PPN # 0b110
PPP = @cxx CVX_Voxel::PPP # 0b111

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

# Set the temperature of a specific voxel
function setTemperature(voxel::voxelT, temperature::Real)
	@cxx voxel->setTemperature(temperature)
end

# Get the adjacent voxel (if linked) in the specified direction
function adjacentVoxel(voxel::voxelT, direction::linkDirection)
	@cxx voxel->adjacentVoxel(direction)
end

function position(voxel::voxelT)
	vec3D = @cxx voxel->position()
	[(@cxx vec3D->x), (@cxx vec3D->y), (@cxx vec3D->z)]
end

# Get the specified corner position of the voxel
function cornerPosition(voxel::voxelT, corner::voxelCorner)
	vec3D = @cxx voxel->cornerPosition(corner)
	[(@cxx vec3D->x), (@cxx vec3D->y), (@cxx vec3D->z)]
end

# Get the specified corner offset of the voxel
function cornerOffset(voxel::voxelT, corner::voxelCorner)
	vec3D = @cxx voxel->cornerOffset(corner)
	[(@cxx vec3D->x), (@cxx vec3D->y), (@cxx vec3D->z)]
end





