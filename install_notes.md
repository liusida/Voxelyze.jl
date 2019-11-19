Should be installed in Linux, because the Cxx.jl not quite support Windows. 

Also remember to build julia with `USE_BINARYBUILDER=0`, otherwise you will receive error while installing Cxx.jl, and you'll need to rebuild julia :X

Refer to: https://github.com/JuliaInterop/Cxx.jl
