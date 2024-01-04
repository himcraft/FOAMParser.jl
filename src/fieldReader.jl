#TODO: process vector files
function internalFieldsReader(Case::FOAMCase)
    fieldsIndex=Dict(i => Array{Float64}(undef,Case.timeLength,Case.cells) for i in Case.fieldPtrList)
    for (time,snapshot) in enumerate(Case.timeSequence)
        for (pos,field) in enumerate(Case.fieldList)
            if isfile(Case.case*"/"*snapshot*"/"*field * (Case.gz ? ".gz" : ""))
                fileContent=foamOpen(Case.case*"/"*snapshot*"/"*field,Case)
                if Case.fieldType[pos] == "volScalarField"
                    if split(fileContent[20])[2] == "nonuniform"
                        fieldsIndex[field][time,:] = str2flt.(fileContent[23:22+Case.cells])
                    elseif split(fileContent[20])[2] == "uniform"
                        fieldsIndex[field][time,:] .= str2flt(replace(split(fileContent[20])[3],";"=>""))
                    else
                        error("error in reading field $field data")
                    end
                elseif Case.fieldType[pos] == "volVectorField"
		    if split(fileContent[20])[2] == "nonuniform"
			tmpFieldData = stact(str2vec.(fileContent[23:22+Case.cells]))
			fieldsIndex[field*"x"][time,:] = tmpFieldData[1,:]
			fieldsIndex[field*"y"][time,:] = tmpFieldData[2,:]
			fieldsIndex[field*"z"][time,:] = tmpFieldData[3,:]
		    elseif split(fileContent[20])[2] == "uniform"
			tmpFieldData = str2vec(replace(split(fileContent[20])[3],";"=>""))
			fieldsIndex[field*"x"][time,:] .= tmpFieldData[1]
			fieldsIndex[field*"y"][time,:] .= tmpFieldData[2]
			fieldsIndex[field*"z"][time,:] .= tmpFieldData[3]
		    else
                        error("error in reading field $field data")
		    end
                end
            else
                fieldsIndex[field][time,:].=0
            end
        end
    end
    return fieldsIndex
end

function internalFieldReader(Case::FOAMCase,field::String)
    resultFlag = 0
    if !(field in Case.fieldList)
	if field in Case.fieldPtrList
	    fieldComp = field
	    field = field[1:end-1]
	    fieldType = "volVectorField"
    	    fieldData = Array{Float64}(undef,Case.timeLength,Case.cells)
	else
	    error("There is no such field")
	end
    else
        fieldType=Case.fieldType[Case.fieldList .== field][1]
	if fieldType == "volVectorField"
    	    fieldData1 = Array{Float64}(undef,Case.timeLength,Case.cells)
    	    fieldData2 = Array{Float64}(undef,Case.timeLength,Case.cells)
    	    fieldData3 = Array{Float64}(undef,Case.timeLength,Case.cells)
	    resultFlag = 1
	else
    	    fieldData = Array{Float64}(undef,Case.timeLength,Case.cells)
	end
    end
    for (t,snapshot) in enumerate(Case.timeSequence)
        if isfile(Case.case*"/"*snapshot*"/"*field * (Case.gz ? ".gz" : ""))
            fileContent = foamOpen(Case.case*"/"*snapshot*"/"*field,Case)
            if fieldType == "volScalarField"
                if split(fileContent[20])[2] == "nonuniform"
                    fieldData[t,:] = str2flt.(fileContent[23:22+Case.cells])
                elseif split(fileContent[20])[2] == "uniform"
                    fieldData[t,:] .= str2flt(replace(split(fileContent[20])[3],";"=>""))
                else
                    error("error in reading field data")
                end
            elseif fieldType == "volVectorField"
		if split(fileContent[20])[2] == "nonuniform"
		    tmpFieldData = stack(str2vec.(fileContent[23:22+Case.cells]))
		    if !(@isdefined fieldComp)
			fieldData1[t,:] = tmpFieldData[1,:]
			fieldData2[t,:] = tmpFieldData[2,:]
			fieldData3[t,:] = tmpFieldData[3,:]
		    else
			fieldData[t,:]  = tmpFieldData[Int(Char(fieldComp[end]))-119,:]
		    end
		elseif split(fileContent[20])[2] == "uniform"
		    tmpFieldData = str2vec(replace(join(split(fileContent[20])[3:5]," "),";"=>""))
		    if !(@isdefined fieldComp)
			fieldData1[t,:] .= tmpFieldData[1]
			fieldData2[t,:] .= tmpFieldData[2]
			fieldData3[t,:] .= tmpFieldData[3]
		    else
			fieldData[t,:]  .= tmpFieldData[Int(Char(fieldComp[end]))-119]
		    end
		end
	    else
		error("unknown fieldType")
            end
        else
            fieldData[t,:] .= 0
        end
    end
    if resultFlag == 0
    	return fieldData
    else
	return fieldData1,fieldData2,fieldData3
    end
end

function boundaryFieldReader(Case::FOAMCase)

end

function H5internalFieldSaver(Case::FOAMCase,field::Array{Float64},fieldName::String)
    h5open(Case.case*".h5","cw") do fid
	fid[fieldName] = field
    end
end

function H5internalFieldSaver(Case::FOAMCase,field::String,isVec::Bool=false)
    if !isVec
    	fieldData = internalFieldReader(Case,field)
    	@info "Now writing scalar field $field to HDF5 file..."
    	h5open(Case.case*".h5","cw") do fid
	    fid[field] = fieldData;
    	end
    else
	fieldData1,fieldData2,fieldData3 = internalFieldReader(Case,field)
	@info "Now writing vector field $field to HDF5 file..."
	h5open(Case.case*".h5","cw") do fid
	    fid[field*"x"] = fieldData1;
	    fid[field*"y"] = fieldData2;
	    fid[field*"z"] = fieldData3;
	end
    end
end

function H5internalFieldReader(Case::FOAMCase,fieldName::String)
    h5open(Case.case*".h5","r") do fid
	field = read(fid,fieldName)
    end
end

function H5removeInternalField(Case::FOAMCase,fieldName::String)
    h5open(Case.case*".h5","cw") do fid
	if fieldName in keys(fid)
	    delete_object(fid,fieldName)
	else
	    error("There is no such field.")
	end
    end
end

function H5fieldList(Case::FOAMCase)
    h5open(Case.case*".h5","r") do fid
	println(keys(fid))
    end
end
