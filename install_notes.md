Should be installed in Linux, because the Cxx.jl not quite support Windows. 

Also remember to build julia with `USE_BINARYBUILDER=0`, otherwise you will receive error while installing Cxx.jl, and you'll need to rebuild julia :X

Refer to: https://github.com/JuliaInterop/Cxx.jl

Here is Sida's test environment:

* Ubuntu 19.10

* Install gcc-8, g++-8, gfortran-8 for compiling Julia

* Julia 1.2 (Compiled with flag `USE_BINARYBUILDER=0`)

* in Julia REPL, install Pkg Cxx v0.3.3 and Makie v0.9.5

* Atom and Juno for IDE

And I change `clang++` to `g++` in the `Makefile`
