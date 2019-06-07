# Voxelyze.jl

This project is a wrapper around [Voxelyze](https://github.com/jonhiller/Voxelyze):

>Voxelyze is a general purpose multi-material voxel simulation library for static and dynamic analysis. To quickly get a feel for its capabilities you can create and play with Voxelyze objects using [VoxCAD](http://www.voxcad.com) (Windows and Linux executables available). An paper describing the theory and capabilities of Voxelyze has been published in Soft Robotics journal: "[Dynamic Simulation of Soft Multimaterial 3D-Printed Objects](http://online.liebertpub.com/doi/pdfplus/10.1089/soro.2013.0010)" (2014). [Numerous](https://sites.google.com/site/jonhiller/hardware/soft-robots) [academic](http://creativemachines.cornell.edu/soft-robots), [corporate](http://www.fastcompany.com/3006259/stratasyss-programmable-materials-just-add-water), and [educational](http://www.sciencebuddies.org/science-fair-projects/project_ideas/Robotics_p016.shtml) projects make use of Voxelyze.


## Basic Usage

Basic use of Voxelyze consists of five simple steps:

1. Create a Voxelyze instance
2. Create a material
3. Add voxels using this material
4. Specify voxels that should be fixed in place or have force applied
5. Execute timesteps

```julia
include("Voxelyze.jl")

Vx = Voxelyze(0.005) 					# 5mm voxels
pMaterial = addMaterial(Vx, 1000000, 1000) 		# A material with stiffness E=1MPa and density 1000Kg/m^3
Voxel1 = setVoxel(Vx, pMaterial, 0, 0, 0) 		# Voxel at index x=0, y=0. z=0
Voxel2 = setVoxel(Vx, pMaterial, 1, 0, 0)
Voxel3 = setVoxel(Vx, pMaterial, 2, 0, 0) 		# Beam extends in the +X direction

setFixedAll(Voxel1) 					# Fixes all 6 degrees of freedom with an external condition on Voxel 1
setForce(Voxel3, 0, 0, -1) 				# Pulls Voxel 3 downward with 1 Newton of force.

for i=1:100 						# Simulate 100 timesteps
	doTimeStep(Vx)
end
```

This is the equivalent of doing the below in the original Voxelyze library:

```c++
#include "Voxelyze.h"

int main()
{
	CVoxelyze Vx(0.005); 					 //5mm voxels
	CVX_Material* pMaterial = Vx.addMaterial(1000000, 1000); //A material with stiffness E=1MPa and density 1000Kg/m^3
	CVX_Voxel* Voxel1 = Vx.setVoxel(pMaterial, 0, 0, 0); 	 //Voxel at index x=0, y=0. z=0
	CVX_Voxel* Voxel2 = Vx.setVoxel(pMaterial, 1, 0, 0);
	CVX_Voxel* Voxel3 = Vx.setVoxel(pMaterial, 2, 0, 0); 	 //Beam extends in the +X direction

	Voxel1->external()->setFixedAll(); 			 //Fixes all 6 degrees of freedom with an external condition on Voxel 1
	Voxel3->external()->setForce(0, 0, -1); 		 //pulls Voxel 3 downward with 1 Newton of force.

	for (int i=0; i<100; i++) Vx.doTimeStep(); 		 //simulate  100 timesteps.

	return 0;
}
```

## Running/Compiling Voxelyze

The Voxelyze code is structured as a library and compiles on linux and mac. The usual "make" can be executed on linux and mac to build a dynamic shared *.so library. This package also requires you to install Cxx.jl and Libdl.jl as Julia packages.

To run first make the file with terminal command:
```bash
make
```
And then in your julia repl:
```repl
julia> ]
(v1.1) pkg> add Cxx
(v1.1) pkg> add Libdl
```
Then back in the terminal you can now run the example with command:
```bash
julia example.jl
```

To run the c++ example (in case you are interested) you would do the following in the terminal:
```bash
make
clang++ example.cpp -I./include -L.lib -lvoxelyze
./a.out
```

### Extra Notes

**CHANGE COMPILER**: On line 9 in the makefile you can define your compiler with CC=(gcc | g++ | etc), where the current is CC=clang++ 

**ENABLE MULTITHREADING**: On line 11 in the makefile you can define "USE_OMP" by adding the flag -DUSE_OMP=1 to the FLAGS variable
