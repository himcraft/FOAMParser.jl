#TODO: process vector files
function internalFieldReader(Case::FOAMCase)
    fieldsIndex=Dict(i => Array{Float64}(undef,Case.timeLength,Case.cells) for i in Case.fieldList)
    for (time,snapshot) in enumerate(Case.timeSequence)
        for field in Case.fieldList
            if isfile(Case.case*"/"*snapshot*"/"*field * (Case.gz ? ".gz" : ""))
                fileContent=foamOpen(Case.case*"/"*snapshot*"/"*field,Case)
                if split(fileContent[20])[2]=="nonuniform"
                    fieldsIndex[field][time,:]=str2flt.(fileContent[23:22+Case.cells])
                elseif split(fileContent[20])[2]=="uniform"
                    fieldsIndex[field][time,:].=str2flt(replace(split(fileContent[20])[3],";"=>""))
                else
                    error("error in reading field data")
                end
            else
                fieldsIndex[field][time,:].=0
            end
        end
    end
    return fieldsIndex
end

function boundaryFieldReader(Case::FOAMCase)

end

