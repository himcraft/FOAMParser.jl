module FOAM

using GZip

export FOAMCase
export internalFieldReader
# export boundaryFieldReader
export printCaseSettings
export printFieldNames

include("utilities.jl")
include("fieldReader.jl")

end
