#TODO: process vector files
function internalFieldsReader(Case::FOAMCase)
    fieldsIndex=Dict(i => Array{Float64}(undef,Case.timeLength,Case.cells) for i in Case.fieldList)
    for (time,snapshot) in enumerate(Case.timeSequence)
        for (pos,field) in enumerate(Case.fieldList)
            if isfile(Case.case*"/"*snapshot*"/"*field * (Case.gz ? ".gz" : ""))
                fileContent=foamOpen(Case.case*"/"*snapshot*"/"*field,Case)
                if Case.fieldType[pos]==:volScalarField
                    if split(fileContent[20])[2]=="nonuniform"
                        fieldsIndex[field][time,:]=str2flt.(fileContent[23:22+Case.cells])
                    elseif split(fileContent[20])[2]=="uniform"
                        fieldsIndex[field][time,:].=str2flt(replace(split(fileContent[20])[3],";"=>""))
                    else
                        error("error in reading field data")
                    end
                elseif Case.fieldType[pos]==:volVectorField
                    continue
                end
            else
                fieldsIndex[field][time,:].=0
            end
        end
    end
    return fieldsIndex
end

function internalFieldReader(Case::FOAMCase,field::String)
    fieldType=Case.fieldType[Case.fieldList .== field][1]
    fieldData=Array{Float64}(undef,Case.timeLength,Case.cells)
    for (t,snapshot) in enumerate(Case.timeSequence)
        if isfile(Case.case*"/"*snapshot*"/"*field * (Case.gz ? ".gz" : ""))
            fileContent=foamOpen(Case.case*"/"*snapshot*"/"*field,Case)
            if fieldType==:volScalarField
                if split(fileContent[20])[2]=="nonuniform"
                    fieldData[t,:]=str2flt.(fileContent[23:22+Case.cells])
                elseif split(fileContent[20])[2]=="uniform"
                    fieldData[t,:].=str2flt(replace(split(fileContent[20])[3],";"=>""))
                else
                    error("error in reading field data")
                end
            elseif fieldType==:volVectorField
                continue
	    else
		error("unknown fieldType")
            end
        else
            fieldData[t,:].=1110
        end
    end
    return fieldData
end

function boundaryFieldReader(Case::FOAMCase)

end

