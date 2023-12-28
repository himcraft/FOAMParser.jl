module FOAM

using GZip
using HDF5

export FOAMCase
export internalFieldReader
# export boundaryFieldReader
export printCaseSettings
export printFieldNames

include("utilities.jl")
include("fieldReader.jl")

end
