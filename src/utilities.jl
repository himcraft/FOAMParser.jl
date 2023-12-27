str2flt(x::String) = parse(Float64,x)
str2int(x::String) = parse(Int64,x)


"""
FOAMCase(gz::Bool,case::String)

gz: files are compressed or not.
case: case name.
timeLength: number of time slots.
timeSequence: sequence of time slots.
cells: number of mesh cells. TODO: only 1D for now
fieldList: names of output fields.
"""
struct FOAMCase
    gz           :: Bool
    case         :: String
    timeLength   :: Integer
    timeSequence :: Vector{String}
    cells        :: Integer
    fieldList    :: Vector{String}
    function FOAMCase(gz::Bool,case::String)
        timeSequence = fileList(case)
        timeLength = length(timeSequence)
        cells = countCells(case,gz)
        fieldList = readFieldNames(case,timeSequence)
        new(gz,case,timeLength,timeSequence,cells,fieldList)
    end
end

function fileList(case::String)
    digitlist=['0','1','2','3','4','5','6','7','8','9']
    dir=readdir(case)
    filter!(x -> x[1] ∈ digitlist, dir)
    return dir
end

"""
printCaseSettings(Case::FOAMCase)

Print out contents of a FOAMCase
"""
function printCaseSettings(Case::FOAMCase)
    for i in fieldnames(FOAMCase)
        if !(typeof(Case.i) <: AbstractArray)
            println(i*":  "*Case.i)
        end
    end
end

"""
printFieldNames(Case::FOAMCase)

Print out list of output fields
"""
function printFieldNames(Case::FOAMCase)
    println(Case.fieldList)
end

"""
countCells(Case::String,gz::Bool)

Count number of cells by finding the maximum of both neighbour and owner.

TODO: only works for 1D mesh
"""
function countCells(Case::String,gz::Bool)
    owner = parse_on(:owner,Case,gz)
    neighbour = parse_on(:neighbour,Case,gz)
    return max(maximum(owner),maximum(neighbour))+1
end

"""
parse_on(object::Symbol,Case::String,gz::Bool)

Read `owner` file if `object==:owner` or `neighbour` if `object==:neighbour`.
"""
function parse_on(object::Symbol,Case::String,gz::Bool)
    if object==:owner
        lines=foamOpen(Case*"/constant/polyMesh/owner",gz)
    elseif object==:neighbour
        lines=foamOpen(Case*"/constant/polyMesh/neighbour",gz)
    else
        error("Wrong parameter for parse_on")
    end
    linenum=str2int(lines[20])
    data=str2flt.(lines[22:21+linenum])
    return data
end

function foamOpen(filename::String,gz::Bool)
    if gz==false
        file=open(x->readlines(x),filename,"r")
    else
        file=GZip.open(x->readlines(x),filename*".gz","r")
    end
    return file
end

function foamOpen(filename::String,Case::FOAMCase)
    return foamOpen(filename,Case.gz)
end

function readFieldNames(case::String,dir::Array{String})
    calcdir=filter(x -> x != "0" , dir)
    if !isempty(calcdir)
        fieldList = filter!(x -> isfile(case*"/"*calcdir[1]*"/"*x) , readdir(case*"/"*calcdir[1]))
        fieldList = replace.(fieldList , ".gz" => "")
    else
	error("only 0/ directory exist")
    end
    return fieldList
end
