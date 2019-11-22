Should be installed in Linux, because the Cxx.jl not quite support Windows. 

Also remember to build julia with `USE_BINARYBUILDER=0`, otherwise you will receive error while installing Cxx.jl, and you'll need to rebuild julia :X

Refer to: https://github.com/JuliaInterop/Cxx.jl

Here is Sida's test environment:

* Ubuntu 19.10

* Julia 1.2 (Compiled with flag `USE_BINARYBUILDER=0`)

* Cxx v0.3.3

* Makie v0.9.5

And I change `clang++` to `g++` in the `Makefile`
