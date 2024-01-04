module FOAM

using GZip
using HDF5

export FOAMCase
export internalFieldsReader
export internalFieldReader
export H5internalFieldSaver
export H5internalFieldReader
# export boundaryFieldReader
export printCaseSettings
export printFieldNames
export saveFOAMCase
export loadFOAMCase
export H5fieldList
export H5removeInternalField

include("utilities.jl")
include("fieldReader.jl")

end
