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
cxxinclude("VX_MeshRender.h")




#######################################################
################### TYPES & ENUMS #####################
#######################################################

# CVoxelyze type, CVoxelyze Enum types, and Enums
#vxT = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVoxelyze},(false, false, false)},480}
vxT = Cxx.CxxCore.CppPtr{Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:CVoxelyze},(false, false, false)},N} where N,(false, false, false)}
stateInfoType = Cxx.CxxCore.CppEnum{Symbol("CVoxelyze::stateInfoType"),UInt32}
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
#= Defines an axis (X, Y, or Z)
linkAxis = Cxx.CxxCore.CppEnum{Symbol("CVX_Link::linkAxis"),UInt32}
X_AXIS = @cxx CVX_Link::X_AXIS								# X Axis
Y_AXIS = @cxx CVX_Link::Y_AXIS								# Y Axis
Z_AXIS = @cxx CVX_Link::Z_AXIS 								# Z Axis
=#




#######################################################
################# VOXELYZE FUNCTIONS ##################
#######################################################

Voxelyze(voxelSize::Real) = @cxxnew CVoxelyze(voxelSize)									# Constructs an empty voxelyze object
Voxelyze(jsonFilePath::String) = @cxxnew CVoxelyze(pointer(jsonFilePath))					# Constructs a voxelyze object from a *.vxl.json file
loadJSON(pVx::vxT, jsonFilePath::String) = @cxx pVx->loadJSON(pointer(jsonFilePath))	# Clears this voxelyze instance and loads fresh from a *.vxl.json file
saveJSON(pVx::vxT, jsonFilePath::String) = @cxx pVx->saveJSON(pointer(jsonFilePath))	# Saves this voxelyze instance to a json file. All voxels are saved at their default locations - the state is not captured. It is recommended to specify the standard *.vxl.json file suffix
clear(pVx::vxT) = @cxx pVx->clear()														# Erases all voxels and materials and restores the voxelyze object to its default (empty) state


doTimeStep(pVx::vxT) = @cxx pVx->doTimeStep()											# Executes a single timestep on this voxelyze object and updates all state information (voxel positions and orientations) accordingly. In most situations this function will be called repeatedly until the desired result is obtained
doTimeStep(pVx::vxT, dt::Real) = @cxx pVx->doTimeStep(dt)								# Executes a single timestep on this voxelyze object and updates all state information (voxel positions and orientations) accordingly. In most situations this function will be called repeatedly until the desired result is obtained
doLinearSolve(pVx::vxT) = @cxx pVx->doLinearSolve()										# Linearizes the voxelyze object and does a one-time linear solution to set the position and orientation of all voxels. The current state of the voxel object will be discarded. Currently only the pardiso solver is supported. To make use of this feature voxelyze must be built with PARDISO_5 defined in the preprocessor. A valid pardiso 5 license file and library file should be obtained from www.pardiso-project.org and placed in the directory your executable will be run from
recommendedTimeStep(pVx::vxT) = @cxx pVx->recommendedTimeStep()							# Returns an estimate of the largest stable time step based on the current state of the simulation. If poisson's ratios are all zero and material properties do not otherwise change this can be called once and the same timestep value used for all subsequent doTimeStep() calls. Otherwise the timestep should be recalculated whenever the simulation has changed
resetTime(pVx::vxT) = @cxx pVx->resetTime()												# Resets all voxels to their initial state and zeroes the elapsed time counter. Call this to "start over" without changing any of the voxels


addMaterial(pVx::vxT, youngsModulus::Real, density::Real) = 
	@cxx pVx->addMaterial(youngsModulus, density)										# Adds a material to this voxelyze object with the minimum necessary information for dynamic simulation (stiffness, density). Returns a pointer to the newly created material that can be used to further specify properties
addMaterial(pVx::vxT, pMaterial::materialT) = 
	@cxx pVx->addMaterial(pMaterial)													# Adds a material to this voxelyze object
removeMaterial(pVx::vxT, toRemove::materialT) = @cxx pVx->removeMaterial(toRemove)		# Removes the specified material from the voxelyze object and deletes all voxels currently using it
replaceMaterial(pVx::vxT, replaceMe::materialT, replaceWith::materialT) = 
	@cxx pVx->replaceMaterial(replaceMe, replaceWith)									# Replaces all voxels of one material with another material
materialCount(pVx::vxT) = @cxx pVx->materialCount()										# Returns the number of materials currently in this voxelyze object
material(pVx::vxT, materialIndex::Int) = @cxx pVx->material(materialIndex)				# Returns a pointer to a material that has been added to this voxelyze object


setVoxel(pVx::vxT, pMaterial::materialT, xIndex::Int, yIndex::Int, zIndex::Int) = 
	@cxx pVx->setVoxel(pMaterial, xIndex, yIndex, zIndex)								# Adds a voxel made of material at the specified index. If a voxel already exists here it is replaced
#voxelCount(pVx::vxT) = @cxx pVx->voxelCount()											# Returns the number of voxels currently in this voxelyze object
#voxelList(pVx::vxT) = @cxx pVx->voxelList()											# Returns a pointer to the internal list of voxels in this voxelyze object
voxel(pVx::vxT, xIndex::Int, yIndex::Int, zIndex::Int) = 
	@cxx pVx->voxel(xIndex, yIndex, xIndex)												# Returns a pointer to the voxel at this location if one exists, or null otherwise
voxel(pVx::vxT, voxelIndex::Int) = @cxx pVx->voxel(voxelIndex)							# Returns a pointer to a voxel that has been added to this voxelyze object
breakLink(pVx::vxT, xIndex::Int, yIndex::Int, zIndex::Int, direction::linkDirection) =
	@cxx pVx->breakLink(xIndex, yIndex, zIndex, direction)								# Removes the link at this voxel location in the direction indicated if one exists


indexMinX(pVx::vxT) = @cxx pVx->indexMinX()												# The minimum X index of any voxel in this voxelyze object
indexMinY(pVx::vxT) = @cxx pVx->indexMinY()												# The minimum Y index of any voxel in this voxelyze object
indexMinZ(pVx::vxT) = @cxx pVx->indexMinZ()												# The minimum Z index of any voxel in this voxelyze object
indexMaxX(pVx::vxT) = @cxx pVx->indexMaxX()												# The maximum X index of any voxel in this voxelyze object
indexMaxY(pVx::vxT) = @cxx pVx->indexMaxY()												# The maximum Y index of any voxel in this voxelyze object
indexMaxZ(pVx::vxT) = @cxx pVx->indexMaxZ()												# The maximum Z index of any voxel in this voxelyze object


#linkCount(pVx::vxT) = @cxx pVx->linkCount()											# Returns the number of links currently in this voxelyze object
#linkList(pVx::vxT) = @cxx pVx->linkList()												# Returns a pointer to the internal list of links in this voxelyze object
#collisionList(pVx::vxT) = @cxx pVx->collisionList()									# Returns a pointer to the internal list of collisions in this voxelyze object
#link(pVx::vxT, xIndex::Int, yIndex::Int, zIndex::Int, direction::linkDirection) =
#	@cxx pVx->link(xIndex, yIndex, zIndex, direction)									# Returns a pointer to the link at this voxel location in the direction indicated if one exists
#link(pVx::vxT, linkIndex::Int) = @cxx pVx->link(linkIndex)								# Returns a pointer to a link that is a part of this voxelyze object


setVoxelSize(pVx::vxT, voxelSize::Real) = @cxx pVx->setVoxelSize(voxelSize)				# Sets the base voxel size for the entire voxelyze object
setGravity(pVx::vxT, g::Real) = @cxx pVx->setGravity(g)									# Set the gravity of the voxelyze engine
setAmbientTemperature(pVx::vxT, temperature::Real) = 
	@cxx pVx->setAmbientTemperature(temperature, true)									# Set the ambient temperature of the voxelyze engine
setAmbientTemperature(pVx::vxT, temperature::Real, allVoxels::Bool) = 
	@cxx pVx->setAmbientTemperature(temperature, allVoxels)								# Set the ambient temperature of the current voxelyze instance
enableFloor(pVx::vxT, enabled::Bool) = @cxx pVx->enableFloor(enabled)					# Enable the floor of the voxelyze engine
enableCollisions(pVx::vxT, enabled::Bool) = @cxx pVx->enableCollisions(enabled)			# Enable collisions of the voxelyze engine
voxelSize(pVx::vxT) = @cxx pVx->voxelSize()												# Returns the base voxel size in meters
ambientTemperature(pVx::vxT) = @cxx pVx->ambientTemperature()							# Returns the current relative ambient temperature
gravity(pVx::vxT) = @cxx pVx->gravity()													# Returns the current gravitational acceleration in g's. 1 g = -9.80665 m/s^2
isFloorEnabled(pVx::vxT) = @cxx pVx->isFloorEnabled()									# Returns a boolean value indication if the floor is enabled or not
isCollisionsEnabled(pVx::vxT) = @cxx pVx->isCollisionsEnabled()							# Returns a boolean value indication if the collision watcher is enabled or not


stateInfo(pVx::vxT, info::stateInfoType, type::valueType) =
	@cxx pVx->stateInfo(info, type)														# Returns a specific piece of information about the current state of the simulation




#######################################################
################# MATERIAL FUNCTIONS ##################
#######################################################

setName(pMaterial::materialT, name::String) = @cxx pMaterial->setName(pointer(name))			# Adds an optional name to the material
name(pMaterial::materialT) = unsafe_string(@cxx pMaterial->name())								# Returns the optional material name if one was specifed


function setModel(pMaterial::materialT, dataPointCount::Int,
	pStrainValues::AbstractVector{<:Real}, pStressValues::AbstractVector{<:Real})
	strain = pointer(Float32.(pStrainValues))
	stress = pointer(Float32.(pStressValues))
	@cxx pMaterial->setModel(dataPointCount, strain, stress)									# Defines the physical material behavior with a series of true stress/strain data points
end
setModelLinear(pMaterial::materialT, youngsModulus::Real, failureStress::Real) = 
	@cxx pMaterial->setModelLinear(youngsModulus, failureStress)								# Convenience function to quickly define a linear material
setModelBilinear(pMaterial::materialT, youngsModulus::Real, plasticModulus::Real,
	yieldStress::Real, failureStress::Real) = 
	@cxx pMaterial->setModelBilinear(youngsModulus, plasticModulus, yieldStress, failureStress)	# Convenience function to quickly define a bilinear material
isModelLinear(pMaterial::materialT) = @cxx pMaterial->isModelLinear()							# Returns true if the material model is a simple linear behavior


stress(pMaterial::materialT, strain::Real, transverseStrainSum::Real, forceLinear::Bool) = 
	@cxx pMaterial->stress(strain, transverseStrainSumm, forceLinear) 							# Returns the stress of the material model accounting for volumetric strain effects
modulus(pMaterial::materialT, strain::Real) =
	@cxx pMaterial->modulus(strain)																# Returns the modulus (slope of the stress/strain curve) of the material model at the specified strain
isYielded(pMaterial::materialT, strain::Real) =
	@cxx pMaterial->isYielded(strain)															# Returns true if the specified strain is past the yield point (if one is specified)
isFailed(pMaterial, strain::Real) = 
	@cxx pMaterial->isFailed(strain)															# Returns true if the specified strain is past the failure point (if one is specified)


youngsModulus(pMaterial::materialT) = @cxx pMaterial->youngsModulus()							# Returns Youngs modulus in Pa
yieldStress(pMaterial::materialT) = @cxx pMaterial->yieldStress()								# Returns the yield stress in Pa or -1 if unspecified
failureStress(pMaterial::materialT) = @cxx pMaterial->failureStress()							# Returns the failure stress in Pa or -1 if unspecified
modelDataPoints(pMaterial::materialT) = @cxx pMaterial->modelDataPoints()						# Returns the number of data points in the current material model data arrays
function modelDataStrain(pMaterial::materialT)
	data = pMaterial->modelDataStrain()
	unsafe_wrap(Array, data, modelDataPoints(pMaterial))										# Returns a pointer to the first strain value data point in a continuous array. The assumed first value of 0 is included
end
function modelDataStress(pMaterial::materialT)
	data = pMaterial->modelDataStress()
	unsafe_wrap(Array, data, modelDataPoints(pMaterial))										# Returns a pointer to the first stress value data point in a continuous array. The assumed first value of 0 is included
end


setPoissonsRatio(pMaterial::materialT, poissonsRatio::Real) =
	@cxx pMaterial->setPoissonsRatio(poissonsRatio)												# Defines Poisson's ratio for the material
poissonsRatio(pMaterial::materialT) = @cxx pMaterial->poissonsRatio()							# Returns the current Poissons ratio
bulkModulus(pMaterial::materialT) = @cxx pMaterial->bulkModulus()								# Calculates the bulk modulus from Young's modulus and Poisson's ratio
lamesFirstParameter(pMaterial::materialT) = @cxx pMaterial->lamesFirstParameter()				# Calculates Lame's first parameter from Young's modulus and Poisson's ratio
shearModulus(pMaterial::materialT) = @cxx pMaterial->shearModulus()								# Calculates the shear modulus from Young's modulus and Poisson's ratio
isXyzIndependent(pMaterial::materialT) = @cxx pMaterial->isXyzIndependent()						# Returns true if poisson's ratio is zero - i.e. deformations in each dimension are independent of those in other dimensions


setDensity(pMaterial::materialT, density::Real) = 
	@cxx pMaterial->setDensity(density)															# Defines the density for the material in Kg/m^3. @param [in] density Desired density (0, INF)
setStaticFriction(pMaterial::materialT, staticFrictionCoefficient::Real) =
	@cxx pMaterial->setStaticFriction(staticFrictionCoefficient)								# Defines the coefficient of static friction
setKineticFriction(pMaterial::materialT, kineticFrictionCoefficient::Real) =
	@cxx pMaterial->setKineticFriction(kineticFrictionCoefficient)								# Defines the coefficient of kinetic friction
density(pMaterial::materialT) = @cxx pMaterial->density()										# Returns the current density
staticFriction(pMaterial::materialT) = @cxx pMaterial->staticFriction()							# Returns the current coefficient of static friction
kineticFriction(pMaterial::materialT) = @cxx pMaterial->kineticFriction()						# Returns the current coefficient of kinetic friction


setInternalDamping(pMaterial::materialT, zeta::Real) = 
	@cxx pMaterial->setInternalDamping(zeta)													# Defines the internal material damping ratio. The effect is to damp out vibrations within a structure. zeta = mu/2 (mu = loss factor) = 1/(2Q) (Q = amplification factor). High values of zeta may lead to simulation instability. Recommended value: 1.0
setGlobalDamping(pMaterial::materialT, zeta::Real) = 
	@cxx pMaterial->setGlobalDamping(zeta)														# Defines the viscous damping of any voxels using this material relative to ground (no motion). Translation C (damping coefficient) is calculated according to zeta*2*sqrt(m*k) where k=E*nomSize. Rotational damping coefficient is similarly calculated High values relative to 1.0 may cause simulation instability
setCollisionDamping(pMaterial::materialT, zeta::Real) = 
	@cxx pMaterial->setCollisionDamping(zeta)													# Defines the material damping ratio for when this material collides with something. This gives some control over the elasticity of a collision. A value of zero results in a completely elastic collision
internalDamping(pMaterial::materialT) = @cxx pMaterial->internalDamping()						# Returns the internal material damping ratio
globalDamping(pMaterial::materialT) = @cxx pMaterial->globalDamping()							# Returns the global material damping ratio
collisionDamping(pMaterial::materialT) = @cxx pMaterial->collisionDamping()						# Returns the collision material damping ratio


function setExternalScaleFactor(pMaterial::materialT, dx::Real, dy::Real, dz::Real)
	@cxx pMaterial->setExternalScaleFactor(dx, dy, dz)											# Scales all voxels of this material by a specified factor in each dimension (1.0 is no scaling). This allows enables volumetric displacement-based actuation within a structure. As such, mass is unchanged when the external scale factor changes. Actual size is obtained by multiplying nominal size by the provided factor
end
setExternalScaleFactor(pMaterial::materialT, factor::Real) = 
	@cxx pMaterial->setExternalScaleFactor(factor)												# Convenience function to specify isotropic external scaling factor
function externalScaleFactor(pMaterial::materialT)
	vec3D = @cxx pMaterial->externalScaleFactor()
	[(@cxx vec3D->x), (@cxx vec3D->y), (@cxx vec3D->z)]											# Returns the current external scaling factor (unitless)
end


setCte(pMaterial::materialT, cte::Real) = @cxx pMaterial->setCte(cte)							# Defines the coefficient of thermal expansion
cte(pMaterial::materialT) = @cxx pMaterial->cte()												# Returns the current coefficient of thermal expansion per degree C


setColor(pMaterial::materialT, red::Int, green::Int, blue::Int, alpha::Int) = 
	@cxx pMaterial->setColor(red, green, blue, alpha)											# Sets the material color. Values from [0,255]
setColor(pMaterial::materialT, red::Int, green::Int, blue::Int) = 
	@cxx pMaterial->setColor(red, green, blue, 255)												# Sets the material color. Values from [0,255]
setRed(pMaterial::materialT, red::Int) = @cxx pMaterial->setRed(red)							# Sets the red channel of the material color
setGreen(pMaterial::materialT, green::Int) = @cxx pMaterial->setGreen(green)					# Sets the green channel of the material color
setBlue(pMaterial::materialT, blue::Int) = @cxx pMaterial->setBlue(blue)						# Sets the blue channel of the material color
setAlpha(pMaterial::materialT, alpha::Int) = @cxx pMaterial->setAlpha(alpha)					# Sets the alpha channel of the material color
red(pMaterial::materialT) = @cxx pMaterial->red()												# Returns the red channel of the material color
green(pMaterial::materialT) = @cxx pMaterial->green()											# Returns the green channel of the material color
blue(pMaterial::materialT) = @cxx pMaterial->blue()												# Returns the blue channel of the material color
alpha(pMaterial::materialT) = @cxx pMaterial->alpha()											# Returns the alpha channel of the material color




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




#######################################################
################# RENDERING FUNCTIONS #################
#######################################################
using AbstractPlotting

MeshRender(pVx::vxT) = @cxx CVX_MeshRender(Vx)
generateMesh(pMesh) = @cxx pMesh->generateMesh()


vCount(pMesh) = @cxx pMesh->vCount()
qCount(pMesh) = @cxx pMesh->qCount()
cCount(pMesh) = @cxx pMesh->cCount()


getVertices(pMesh) = unsafe_wrap(Array, (@cxx pMesh->getVertices()), vCount(pMesh))
getQuads(pMesh) = unsafe_wrap(Array, (@cxx pMesh->getQuads()), qCount(pMesh))
getQuadColors(pMesh) = unsafe_wrap(Array, (@cxx pMesh->getQuadColors()), cCount(pMesh))


function getMesh(pMesh)
	vcount = vCount(pMesh)
	qcount = qCount(pMesh)
	ccount = cCount(pMesh)

	verts = unsafe_wrap(Array, (@cxx pMesh->getVertices()), vcount)
	quads = unsafe_wrap(Array, (@cxx pMesh->getQuads()), qcount) .+ 1
	qcolors = unsafe_wrap(Array, (@cxx pMesh->getQuadColors()), ccount)

	coordinates = Matrix{Float32}(undef, div(vcount, 3), 3)
	for (i, j) in zip(1:div(vcount, 3), 1:3:vcount)
		coordinates[i, :] = verts[j:j+2]
	end

	connectivity = Matrix{Int32}(undef, div(qcount, 2), 3)
	vcolors = Vector{Any}(undef, div(vcount, 3))
	for (i, j, k) in zip(1:2:div(qcount, 2), 1:4:qcount, 1:div(ccount, 3))
		connectivity[i, :] = quads[j:j+2]
		connectivity[i+1, :] = [quads[j+2:j+3]..., quads[j]]
		for idx in Set([connectivity[i, :]..., connectivity[i+1, :]...])
			vcolors[idx] = RGBf0(qcolors[k:k+2]...)
		end
	end

	return coordinates, connectivity, [vcolors...]
end

