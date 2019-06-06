#include "Voxelyze.h"
#include <iostream>
//#include "/Users/powers/.julia/packages/CxxWrap/sarOk/deps/usr/include/jlcxx/jlcxx.hpp"

int main()
{
	CVoxelyze Vx(0.005); //5mm voxels
	CVX_Material* pMaterial = Vx.addMaterial(1000000, 1000); //A material with stiffness E=1MPa and density 1000Kg/m^3
	CVX_Voxel* Voxel1 = Vx.setVoxel(pMaterial, 0, 0, 0); //Voxel at index x=0, y=0. z=0
	Voxel1->external()->setFixedAll(); //Fixes all 6 degrees of freedom with an external condition
	for (int i=0; i<100; i++)
	{
		Vx.doTimeStep(); //simulates 100 timesteps
		std::cout << i << std::endl;
	}

	return 0;
}