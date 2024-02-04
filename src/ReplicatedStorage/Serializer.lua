local Serializer = {}

function  Serializer.Serialize(myTable)
	local tempTable = {}
	local i =1
	for k,v in pairs(myTable) do
		if type(v)=="table" then
			v=Serializer.Deserialize(v)
		end
		tempTable[i] = {k,v}
		i+=1
	end
	return tempTable
end


function  Serializer.Deserialize(myTable)
	local tempTable = {}
	for _,t in pairs(myTable) do
		if type(t[2]) == "table" then
			t[2] = Serializer.Deserialize(t[2])
		end
		tempTable[t[1]] = t[2]
	end
	return tempTable
end

return Serializer