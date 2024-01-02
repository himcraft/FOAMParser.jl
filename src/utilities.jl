str2flt(x::AbstractString) = parse(Float64,x)
str2int(x::String) = parse(Int64,x)
function str2vec(x::String) 
    a,b,c = str2flt.(split(replace(x,"("=>"",")"=>"")))
    return a,b,c
end

"""
FOAMCase(gz::Bool,case::String)

gz: files are compressed or not.
case: case name.
timeLength: number of time slots.
timeSequence: sequence of time slots.
cells: number of mesh cells. TODO: only 1D for now
fieldList: names of OPENFOAM output fields to be read and parsed.
fieldType: types of output fields. (:scalar & :vector)
fieldPtrList: names of fields to be stored.
"""
struct FOAMCase
    gz              :: Bool
    case            :: String
    timeLength      :: Integer
    timeSequence    :: Vector{String}
    cells           :: Integer
    fieldList       :: Vector{String}
    fieldType       :: Vector{String}
    fieldPtrList    :: Vector{String}
    function FOAMCase(gz::Bool,case::String)
        timeSequence = fileList(case)
        timeLength = length(timeSequence)
        cells = countCells(case,gz)
        fieldList,fieldType,fieldPtrList = readFieldNames(case,timeSequence,gz)
        new(gz,case,timeLength,timeSequence,cells,fieldList,fieldType,fieldPtrList)
    end
    function FOAMCase(gz::Bool,case::String,timeLength::Integer,
		    timeSequence::Vector{String},cells::Integer,
		    fieldList::Vector{String},fieldType::Vector{String},
		    fieldPtrList::Vector{String})
	new(gz,case,timeLength,timeSequence,cells,fieldList,fieldType,fieldPtrList)
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
	fieldPtrList = copy(fieldList)
	fieldType = Array{String}(undef,length(fieldList))
	for (num,field) in enumerate(fieldList)
	    fieldLines = foamOpen(case*"/"*calcdir[1]*"/"*field,gz)
	    fieldType[num] = replace(split(fieldLines[12])[2],";"=>"")
	    if fieldType[num] == "volVectorField"
		vecPos = findfirst(fieldPtrList .== field)
		fieldPtrList[vecPos] = field*"x"
		insert!(fieldPtrList,vecPos+1,field*"z")	
		insert!(fieldPtrList,vecPos+1,field*"y")	
	    end
	end
    else
	error("only 0/ directory exist")
    end
    return fieldList,fieldType,fieldPtrList
end

function saveFOAMCase(Case::FOAMCase)
    h5open(Case.case*".h5","cw") do fid
	if "FOAMCase" in keys(fid)
	    delete_object(fid,"FOAMCase")
	end
	g = create_group(fid, "FOAMCase")
	g["gz"]           = Case.gz
	g["case"]         = Case.case
	g["timeLength"]   = Case.timeLength
	g["timeSequence"] = Case.timeSequence
	g["cells"]        = Case.cells
	g["fieldList"]    = Case.fieldList
	g["fieldType"]    = Case.fieldType
	g["fieldPtrList"] = Case.fieldPtrList
    end
end

function loadFOAMCase(case::String)
    fid = h5open(case*".h5","r")
    g = fid["FOAMCase"]
    gz           = read(g["gz"])
    timeLength   = read(g["timeLength"])
    timeSequence = read(g["timeSequence"])
    cells        = read(g["cells"])
    fieldList    = read(g["fieldList"])
    fieldType    = read(g["fieldType"])
    fieldPtrList = read(g["fieldPtrList"])
    close(fid)
    return FOAMCase(gz,case,timeLength,timeSequence,cells,fieldList,fieldType,fieldPtrList)
end
	
