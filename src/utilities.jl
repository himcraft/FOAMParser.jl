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
fieldType: types of output fields. (:scalar & :vector)
"""
struct FOAMCase
    gz           :: Bool
    case         :: String
    timeLength   :: Integer
    timeSequence :: Vector{String}
    cells        :: Integer
    fieldList    :: Vector{String}
    fieldType    :: Vector{Symbol}
    function FOAMCase(gz::Bool,case::String)
        timeSequence = fileList(case)
        timeLength = length(timeSequence)
        cells = countCells(case,gz)
        fieldList,fieldType = readFieldNames(case,timeSequence,gz)
        new(gz,case,timeLength,timeSequence,cells,fieldList,fieldType)
    end
    function FOAMCase(gz::Bool,case::String,timeLength::Integer,
		    timeSequence::Vector{String},cells::Integer,
		    fieldList::Vector{String},fieldType::Vector{Symbol})
	new(gz,case,timeLength,timeSequence,cells,fieldList,fieldType)
    end
end

function fileList(case::String)
    digitlist=['0','1','2','3','4','5','6','7','8','9']
    dir=readdir(case)
    filter!(x -> x[1] ∈ digitlist, dir)
    dir=string.(sort(str2flt.(dir)))
    if dir[1]=="0.0" dir[1]="0" end
    dir=replace.(dir,".0e"=>"e")
    dir=replace.(dir,"e-"=>"e-0")
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

function readFieldNames(case::String,dir::Array{String},gz::Bool)
    calcdir=filter(x -> x != "0" , dir)
    if !isempty(calcdir)
        fieldList = filter!(x -> isfile(case*"/"*calcdir[1]*"/"*x) , readdir(case*"/"*calcdir[1]))
        fieldList = replace.(fieldList , ".gz" => "")
	fieldType = Array{Symbol}(undef,length(fieldList))
	for (num,field) in enumerate(fieldList)
	    fieldLines=foamOpen(case*"/"*calcdir[1]*"/"*field,gz)
	    fieldType[num]=Symbol(replace(split(fieldLines[12])[2],";"=>""))
	end
    else
	error("only 0/ directory exist")
    end
    return fieldList,fieldType
end

function writeFOAMCase(Case::FOAMCase)
    h5open(Case.case*".h5","cw") do fid
	g = create_group(fid, "FOAMCase")
	g["gz"]           = Case.gz
	g["case"]         = Case.case
	g["timeLength"]   = Case.timeLength
	g["timeSequence"] = Case.timeSequence
	g["cells"]        = Case.cells
	g["fieldList"]    = Case.fieldList
	g["fieldType"]    = Case.fieldType
    end
end

function readFOAMCase(case::String)
    h5open(case*".h5","r") do fid
	g = fid["FOAMCase"]
	gz           = g["gz"]
	timeLength   = g["timeLength"]
	timeSequence = g["timeSequence"]
	cells        = g["cells"]
	fieldList    = g["fieldList"]
	fieldType    = g["fieldType"]
    end
    return FOAMCase(gz,case,timeLength,timeSequence,cells,fieldList,fieldType)
end
	
