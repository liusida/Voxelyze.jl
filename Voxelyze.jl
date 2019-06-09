# Voxelyze.jl a wrapper around the Voxelyze Library
using Cxx
using Libdl



#######################################################
################## LOADING LIBRARY ####################
#######################################################

const path = pwd()
const path_to_header = path * "/include"
const path_to_lib = path * "/lib"
addHeaderDir(path_to_header, kind=C_User)
Libdl.dlopen(path_to_lib * "/libvoxelyze.so", Libdl.RTLD_GLOBAL)
cxxinclude("Voxelyze.h")



#######################################################
################### TYPES & ENUMS #####################
#######################################################

# CVoxelyze type, CVoxelyze Enum types, and Enums
vxT = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVoxelyze},(false, false, false)},480}
stateInfotype = Cxx.CxxCore.CppEnum{Symbol("CVoxelyze::stateInfoType"),UInt32}
valueType = Cxx.CxxCore.CppEnum{Symbol("CVoxelyze::valueType"),UInt32}

# Defines various types of information to query about the state of a voxelyze object
DISPLACEMENT = @cxx CVoxelyze::DISPLACEMENT 				# Displacement from a nominal position in meters
VELOCITY = @cxx CVoxelyze::VELOCITY 						# Velocity in meters per second
KINETIC_ENERGY = @cxx CVoxelyze::KINETIC_ENERGY 			# Kinetic energy in joules
ANGULAR_DISPLACEMENT = @cxx CVoxelyze::ANGULAR_DISPLACEMENT # Angular displacement from nominal orientation in radians
ANGULAR_VELOCITY = @cxx CVoxelyze::ANGULAR_VELOCITY 		# Angular velocity in radians per second
ENG_STRESS = @cxx CVoxelyze::ENG_STRESS 					# Engineering stress in pascals
ENG_STRAIN = @cxx CVoxelyze::ENG_STRAIN 					# Engineering strain (unitless)
STRAIN_ENERGY = @cxx CVoxelyze::STRAIN_ENERGY 				# Strain energy in joules
PRESSURE = @cxx CVoxelyze::PRESSURE 						# Pressure in pascals
MASS = @cxx CVoxelyze::MASS 								# Mass in Kg

# The type of value desired for a given stateInfoType. Considers all voxels or all links (depending on stateInfoType).
MIN = @cxx CVoxelyze::MIN 									# Minimum of all values
MAX = @cxx CVoxelyze::MAX 									# Maximum of all values
TOTAL = @cxx CVoxelyze::TOTAL 								# Total (sum) of all values
AVERAGE = @cxx CVoxelyze::AVERAGE 							# Average of all values

# CVX_Material type
materialT = Cxx.CxxCore.CppPtr{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVX_Material},(false, false, false)},(false, false, false)}

# CVX_Voxel type, CVX_Voxel Enum types, and Enums
voxelT = Cxx.CxxCore.CppPtr{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVX_Voxel},(false, false, false)},(false, false, false)}
linkDirection = Cxx.CxxCore.CppEnum{Symbol("CVX_Voxel::linkDirection"),UInt32}
voxelCorner = Cxx.CxxCore.CppEnum{Symbol("CVX_Voxel::voxelCorner"),UInt32}

# Defines the direction of a link relative to a given voxel
X_POS = @cxx CVX_Voxel::X_POS 								# Positive X direction
X_NEG = @cxx CVX_Voxel::X_NEG 								# Negative X direction
Y_POS = @cxx CVX_Voxel::Y_POS 								# Positive Y direction
Y_NEG = @cxx CVX_Voxel::Y_NEG 								# Negative Y direction
Z_POS = @cxx CVX_Voxel::Z_POS 								# Positive Z direction
Z_NEG = @cxx CVX_Voxel::Z_NEG 								# Negative Z direction

# Defines each of 8 corners of a voxel
NNN = @cxx CVX_Voxel::NNN 									# 0b000
NNP = @cxx CVX_Voxel::NNP 									# 0b001
NPN = @cxx CVX_Voxel::NPN 									# 0b010
NPP = @cxx CVX_Voxel::NPP 									# 0b011
PNN = @cxx CVX_Voxel::PNN 									# 0b100
PNP = @cxx CVX_Voxel::PNP 									# 0b101
PPN = @cxx CVX_Voxel::PPN 									# 0b110
PPP = @cxx CVX_Voxel::PPP 									# 0b111

# linkT = golbidy goop

# Defines an axis (X, Y, or Z)
linkAxis = Cxx.CxxCore.CppEnum{Symbol("CVX_Link::linkAxis"),UInt32}
X_AXIS = @cxx CVX_Link::X_AXIS								# X Axis
Y_AXIS = @cxx CVX_Link::Y_AXIS								# Y Axis
Z_AXIS = @cxx CVX_Link::Z_AXIS 								# Z Axis



#######################################################
################# VOXELYZE FUNCTIONS ##################
#######################################################

# Constructs an empty voxelyze object
function Voxelyze(voxelSize::Real)
	@cxx CVoxelyze(voxelSize)
end

# Constructs a voxelyze object from a *.vxl.json file
function Voxelyze(jsonFilePath::String)
	@cxx CVoxelyze(pointer(jsonFilePath))
end

# Erases all voxels and materials and restores the voxelyze object to its default (empty) state.
function clear(pVx::vxT)
	@cxx pVx->clear()
end

# Clears this voxelyze instance and loads fresh from a *.vxl.json file
function loadJSON(pVx::vxT, jsonFilePath::String)
	@cxx pVx->loadJSON(pointer(jsonFilePath))
end

# Saves this voxelyze instance to a json file. All voxels are saved at their default locations - the state is not captured. It is recommended to specify the standard *.vxl.json file suffix
function saveJSON(pVx::vxT, jsonFilePath::String)
	@cxx pVx->saveJSON(pointer(jsonFilePath))
end

# Linearizes the voxelyze object and does a one-time linear solution to set the position and orientation of all voxels. The current state of the voxel object will be discarded. Currently only the pardiso solver is supported. To make use of this feature voxelyze must be built with PARDISO_5 defined in the preprocessor. A valid pardiso 5 license file and library file should be obtained from www.pardiso-project.org and placed in the directory your executable will be run from
function doLinearSolve(pVx::vxT)
	@cxx pVx->doLinearSolve()
end

# Returns an estimate of the largest stable time step based on the current state of the simulation. If poisson's ratios are all zero and material properties do not otherwise change this can be called once and the same timestep value used for all subsequent doTimeStep() calls. Otherwise the timestep should be recalculated whenever the simulation has changed
function recommendedTimeStep(pVx::vxT)
	@cxx pVx->recommendedTimeStep()
end

# Executes a single timestep on this voxelyze object and updates all state information (voxel positions and orientations) accordingly. In most situations this function will be called repeatedly until the desired result is obtained
function doTimeStep(pVx::vxT)
	@cxx pVx->doTimeStep()
end

# Executes a single timestep on this voxelyze object and updates all state information (voxel positions and orientations) accordingly. In most situations this function will be called repeatedly until the desired result is obtained
function doTimeStep(pVx::vxT, dt::Real)
	@cxx pVx->doTimeStep(dt)
end

# Resets all voxels to their initial state and zeroes the elapsed time counter. Call this to "start over" without changing any of the voxels
function resetTime(pVx::vxT)
	@cxx pVx->resetTime()
end

# Adds a material to this voxelyze object with the minimum necessary information for dynamic simulation (stiffness, density). Returns a pointer to the newly created material that can be used to further specify properties
function addMaterial(pVx::vxT, youngsModulus::Real, density::Real)
	@cxx pVx->addMaterial(youngsModulus, density)
end

# Removes the specified material from the voxelyze object and deletes all voxels currently using it
function removeMaterial(pVx::vxT, toRemove::materialT)
	@cxx pVx->removeMaterial(toRemove)
end

# Replaces all voxels of one material with another material
function replaceMaterial(pVx::vxT, replaceMe::materialT, replaceWith::materialT)
	@cxx pVx->replaceMaterial(replaceMe, replaceWith)
end

# Returns the number of materials currently in this voxelyze object
function materialCount(pVx::vxT)
	@cxx pVx->materialCount()
end

# Returns a pointer to a material that has been added to this voxelyze object
function material(pVx::vxT, materialIndex)
	@cxx pVx->material(materialIndex)
end

# Adds a voxel made of material at the specified index. If a voxel already exists here it is replaced
function setVoxel(pVx::vxT, pMaterial::materialT, xIndex::Int, yIndex::Int, zIndex::Int)
	@cxx pVx->setVoxel(pMaterial, x, y, z)
end

# Returns a pointer to the voxel at this location if one exists, or null otherwise
function voxel(pVx::vxT, xIndex::Int, yIndex::Int, zIndex::Int)
	@cxx pVx->voxel(xIndex, yIndex, xIndex)
end

# Returns a pointer to a voxel that has been added to this voxelyze object
function voxel(pVx::vxT, voxelIndex::Int)
	@cxx pVx->voxel(xIndex)
end

# Returns the number of voxels currently in this voxelyze object
function voxelCount(pVx::vxT)
	@cxx pVx->voxelCount()
end

# Returns a pointer to the internal list of voxels in this voxelyze object
function voxelList(pVx::vxT)
	@cxx pVx->voxelList()
end

# The minimum X index of any voxel in this voxelyze object
function indexMinX(pVx::vxT)
	@cxx pVx->indexMinX()
end

# The minimum Y index of any voxel in this voxelyze object
function indexMinY(pVx::vxT)
	@cxx pVx->indexMinY()
end

# The minimum Z index of any voxel in this voxelyze object
function indexMinZ(pVx::vxT)
	@cxx pVx->indexMinZ()
end

# The maximum X index of any voxel in this voxelyze object
function indexMaxX(pVx::vxT)
	@cxx pVx->indexMaxX()
end

# The maximum Y index of any voxel in this voxelyze object
function indexMaxY(pVx::vxT)
	@cxx pVx->indexMaxY()
end

# The maximum Z index of any voxel in this voxelyze object
function indexMaxZ(pVx::vxT)
	@cxx pVx->indexMaxZ()
end

# Set the gravity of the voxelyze engine
function setGravity(pVx::vxT, g::Real)
	@cxx pVx->setGravity(g)
end

# Enable the floor of the voxelyze engine
function enableFloor(pVx::vxT, enabled::Bool)
	@cxx pVx->enableFloor(enabled)
end

# Enable collisions of the voxelyze engine
function enableCollisions(pVx::vxT, enabled::Bool)
	@cxx pVx->enableCollisions(enabled)
end

# Set the ambient temperature of the voxelyze engine
function setAmbientTemperature(pVx::vxT, temperature::Real)
	@cxx pVx->setAmbientTemperature(temperature, true)
end

# Set the ambient temperature of the current voxelyze instance
function setAmbientTemperature(pVx::vxT, temperature::Real, allVoxels::Bool)
	@cxx pVx->setAmbientTemperature(temperature, allVoxels)
end




#######################################################
################# MATERIAL FUNCTIONS ##################
#######################################################

# Sets the color of a given material
function setColor(pMaterial::materialT, red::Int, green::Int, blue::Int, alpha::Int)
	@cxx pMaterial->setColor(red, green, blue, alpha)
end

# Sets the color of a given material
function setColor(pMaterial::materialT, red::Int, green::Int, blue::Int)
	@cxx pMaterial->setColor(red, green, blue, 255)
end




#######################################################
################### VOXEL FUNCTIONS ###################
#######################################################

# Fixed all of the Degrees of Freedom of a voxel
function setFixedAll(pVoxel::voxelT)
	@cxx ( @cxx pVoxel->external() )->setFixedAll()
end

# Creates an external 3D force F on the voxel
function setForce(pVoxel::voxelT, Fx::Real, Fy::Real, Fz::Real)
	@cxx ( @cxx pVoxel->external() )->setForce(Fx, Fy, Fz)
end

# Set the temperature of a specific voxel
function setTemperature(pVoxel::voxelT, temperature::Real)
	@cxx pVoxel->setTemperature(temperature)
end

# Get the adjacent voxel (if linked) in the specified direction
function adjacentVoxel(pVoxel::voxelT, direction::linkDirection)
	@cxx pVoxel->adjacentVoxel(direction)
end

function position(pVoxel::voxelT)
	vec3D = @cxx pVoxel->position()
	[(@cxx vec3D->x), (@cxx vec3D->y), (@cxx vec3D->z)]
end

# Get the specified corner position of the voxel
function cornerPosition(pVoxel::voxelT, corner::voxelCorner)
	vec3D = @cxx pVoxel->cornerPosition(corner)
	[(@cxx vec3D->x), (@cxx vec3D->y), (@cxx vec3D->z)]
end

# Get the specified corner offset of the voxel
function cornerOffset(pVoxel::voxelT, corner::voxelCorner)
	vec3D = @cxx pVoxel->cornerOffset(corner)
	[(@cxx vec3D->x), (@cxx vec3D->y), (@cxx vec3D->z)]
end





