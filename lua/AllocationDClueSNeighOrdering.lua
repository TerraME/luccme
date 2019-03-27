--- Based on the process of competition among classes in the same cell, adjusted iteratively to reach the demand when all cells are considered, as described in Verburg et al. (2002)
-- based on the process of competition among classes in the same cell, adjusted iteratively to reach the demand when all cells are considered, as described in Verburg et al. (1999),
-- extended to incorporate new features, such as change in blocks (optional, parametrized by cell) but first ordering the potencial according to neighborhood.
-- @arg component.maxIteration Limit of interactions trying to allocate the demand.
-- @arg component.factorIteration Initial value of the parameter which controls the allocation interaction factor.
-- @arg component.maxDifference Maximum difference between informed demand and demand allocated by the model.
-- @arg component.transitionMatrix Indicates the allowable (1) and  not allowable (0) transition in a landuse x landuse matrix.
-- Must have at least one region.
-- @arg component.run Handles with the rules of the component execution.
-- @arg component.verify Handles with the parameters verification.
-- @usage --DONTRUN 
--A1 = AllocationDClueSNeighOrdering
--{
--  maxIteration = 1000,
--  factorIteration = 0.000001,
--  maxDifference = 106,
--  transitionMatrix =
--  {
--    --Region 1
--    {
--      {1, 1, 0},
--      {0, 1, 0},
--      {0, 0, 1}
--    }
--  }
--}
function AllocationDClueSNeighOrdering(component)
	-- Handles with the rules of the component execution.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
	-- @usage --DONTRUN 
	-- component.run(event, model)
	component.run = function(self, event, luccMEModel)
		local useLog = luccMEModel.useLog
		local cs = luccMEModel.cs
		local cellarea = cs.cellArea
		local step = event:getTime() - luccMEModel.startTime + 1;		
		local nIter = 0
		local allocation_ok = false
		local numofcells  = #cs.cells
		local luTypes = luccMEModel.landUseTypes
		local max_iteration = self.maxIteration
		local area = 0
		local luind = 0
		local lu_pastIndex = 0
		local possibleTransitions = 0
		local upCell = 0
		local Cell = 0
		local potentialCell = 0
		local potentialupCell = 0
		local aux = 0
		local j = 0

		if (event:getTime() == luccMEModel.startTime) then
			for k, cell in pairs (cs.cells) do
				for luind, lu in  pairs (luTypes) do
					cell[lu.."_backup"] = cell[lu]
					cell[lu.."_chtot"] = 0
					cell[lu.."_chpast"] = 0
				end
			end
		elseif (belong(event:getTime() - 1,luccMEModel.save.saveYears) and (event:getTime() - 1)) then
			for k, cell in pairs (cs.cells) do
				for luind, lu in  pairs (luTypes) do
					cell[lu] = cell[lu.."_backupYear"]
				end
			end
		end				

		if (belong(event:getTime(),luccMEModel.save.saveYears)) then
			for k, cell in pairs (cs.cells) do
				for luind, lu in  pairs (luTypes) do
					cell[lu.."_backupYear"] = cell[lu]
				end
			end
		end				
		
		print("\nTime: "..event:getTime())

		if useLog == true then
			print("-------------------------------------------------------------------------------")
			print("Cell Area "..cellarea)
			print("Num of cells "..numofcells)
			print("Max diff area "..self.maxDifference)	 		

			for landuse, ivalues in pairs (luTypes) do         
				area = self:areaAllocated(cs,cellarea, luTypes[landuse], 1) 
				print("Initial area for land use : "..luTypes[landuse].." -> "..area) 
			end		

			print("-------------------------------------------------------------------------------\n")
		end

		local iteration = self:initIteration(luTypes)
		local first = true

		for k,cell in pairs (cs.cells) do
			for luind, lu in  pairs (luTypes) do
				cell[lu.."_out"] = cell[lu]
			end
		end

		for k, cell in pairs (cs.cells) do
			if (nIter == 0) then
				if (math.ceil(k / numofcells * 100) % 100 == 1 and first) then
					print("Ordenamento: 100%")
					first = false
				end
			end
			
			for i, lu in  pairs (luTypes) do
				if cell["tau_"..lu] == nil then
					cell["tau_"..lu] = 0
				end

				if k > 1 then            
					j = k - 1

					upCell = rawget(cs.cells, j)
					Cell = rawget(cs.cells, k)

					potentialCell = (1 + Cell["tau_"..lu]) * Cell[lu.."_pot"]
					potentialupCell = (1 + upCell["tau_"..lu]) * upCell[lu.."_pot"]

					while (potentialCell > potentialupCell) do 
						aux = Cell[lu.."_out"]
						Cell[lu.."_out"] = upCell[lu.."_out"]
						upCell[lu.."_out"] = aux
						Cell = rawget(cs.cells, j)
						j = j - 1
						if j > 0 then 
							upCell = rawget(cs.cells,j)
							potentialupCell = (1 + upCell["tau_"..lu]) * upCell[lu.."_pot"]
						else
							break
						end
					end
				end
			end
		end

		while ((nIter <= max_iteration) and (allocation_ok == false)) do	
			if useLog == true then
				if (nIter == 0) then
					print("\n")
				end
				print ("\nYear: "..event:getTime().." Iteration -> "..nIter)
			end	

			for k, cell in pairs (cs.cells) do
				local lu_past = self:currentUse(cell, luTypes);
				local lu_maior = lu_past;
				local probMaior = -999999999
				local maxLuNeigh

				if (cell.region == nil) then
					cell.region = 1
				end

				for i, lu in pairs (luTypes) do	
					luind = self:toIndex(lu ,luTypes)
					lu_pastIndex = self:toIndex(lu_past, luTypes)
					possibleTransitions = self.transitionMatrix[cell.region][lu_pastIndex][luind] 

					if cell["tau_"..lu] == nil then
						cell["tau_"..lu] = 0
					end


					local suit_plus_iter = (1 + cell["tau_"..lu]) * cell[lu.."_pot"] +  iteration[lu]

					if (possibleTransitions == 1)then 
						if (suit_plus_iter > probMaior) then
							probMaior = suit_plus_iter
							lu_maior = lu
							Cell = cell[lu.."_out"]
						end 	    		   
					end
				end

				luind = self:toIndex(lu_maior, luTypes)		
				cell.simUse = luind
				self:changeUse(cell, lu_past, lu_maior, event:getTime(), luccMEModel.startTime)
			end -- end for cell space

			local diff = self:calcDifferences(event, luccMEModel)

			allocation_ok = self:convergency(diff, luTypes, self.maxDifference)
			self:adjustIteration(diff, luTypes, self.factorIteration, iteration)

			nIter= nIter + 1;

			if (allocation_ok == true) then  
				print("\nDemand allocated correctly in this time: "..event:getTime())
				if (belong(event:getTime(),luccMEModel.save.saveYears)) then
					for k, cell in pairs (cs.cells) do
						for luind, lu in  pairs (luTypes) do
							cell[lu.."_chpast"] =  cell[lu.."_backupYear"] - cell[lu]
							cell[lu.."_chtot"] =  cell[lu.."_backup"] - cell[lu]
							cell[lu] = cell[lu.."_backup"]
						end
					end
				end			
			elseif	(nIter >= max_iteration) then 
				print("\nDemand not allocated correctly in this time step: "..event:getTime().."\n")
				os.exit()
			end      		
		end -- end of 'while do'
	end -- end run
 	
	-- Handles with the parameters verification.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
	-- @usage --DONTRUN
	-- component.verify(event, self)
	component.verify = function(self, event, luccMEModel)
		print("Verifying Allocation parameters")
		-- check maxIteration
		if (self.maxIteration == nil) then
			error("maxIteration variable is missing", 2)
		end 

		-- check factorIteration
		if (self.factorIteration == nil) then
			error("factorIteration variable is missing", 2)
		end  

		-- check maxDifference
		if (self.maxDifference == nil) then
			error("maxDifference variable is missing", 2)
		end 

		-- check transitionMatrix
		if (self.transitionMatrix == nil) then
			error("transitionMatrix is missing", 2)
		end    

		local regionsNumber = #self.transitionMatrix

		-- check number of Regions
		if (regionsNumber == nil or regionsNumber == 0) then
			error("The model must have at least One region", 2)
		else
			for i = 1, regionsNumber, 1 do
				local transitionNumber = #self.transitionMatrix[i]
				local lutNumber = #luccMEModel.landUseTypes

				-- check the number of transitions
				if (transitionNumber ~= lutNumber) then
					error("Invalid number of transitions on Region number "..i..". Transitions: "..transitionNumber.." LandUseTypes: "..lutNumber, 2)
				end

				for j = 1, transitionNumber, 1 do
					for k = 1, lutNumber, 1 do  
						-- check the matrix values
						if(self.transitionMatrix[i][j][k] ~= 0 and self.transitionMatrix[i][j][k] ~= 1) then
							error("Invalid data on transitionMatrix: "..self.transitionMatrix[i][j][k]..". Region: "..i.. " Position: "..j.."x"..k..". The acceptable values are 0 or 1", 2)
						end
					end -- for k
				end -- for j
			end -- for i
		end -- else
	end -- verify

	-- Calculate the difference between the value of the demand and the value to be allocate.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
	-- @usage --DONTRUN
	-- component.calcDifferences(event, model)
	component.calcDifferences = function(self, event, luccMEModel)
		local cs = luccMEModel.cs
		local luTypes = luccMEModel.landUseTypes
		local demand = luccMEModel.demand
		local cellarea = cs.cellArea      
		local differences = {}
		local areaAlloc = 0
		local dem = 0

		for luind, land in pairs (luTypes) do
			areaAlloc = self:areaAllocated(cs, cellarea, land, 1)
			dem = demand:getCurrentLuDemand(luind)
			differences[land] = (dem - (areaAlloc))
			
			if luccMEModel.useLog == true then
				print(land.." -> " ..areaAlloc.."\t\tdemand -> "..dem.." difference -> "..differences[land])
			end
		end

		return differences
	end

	-- Modify for each land use the value of the cell area for an iteration.
	-- @arg diff The demand area difference.
	-- @arg luTypes A set of land uses types.
	-- @arg interationFactor Interation factor.
	-- @arg iter The modifier (value) that changes the potential of each cell according to the difference to demand.
	-- @usage --DONTRUN
	-- component.adjustIteration(cs, diff, luTypes, self.factorIteration, iteration, cellarea, self.maxDifference)
	component.adjustIteration = function(self, diff, luTypes, interationFactor, iter) 
		for luind, land in pairs (luTypes) do
			iter[land] = iter[land] + (diff[land] * interationFactor)
		end
	end
	
	-- Handles with the allocation convergence based on self.maxDifference.
	-- @arg diff The demand area difference.
	-- @arg luTypes A set of land uses types.
	-- @arg maxdiffarea The limit between the demand and the allocated area.
	-- @usage --DONTRUN
	-- component.convergency(diff, luTypes, maxdiffarea)
	component.convergency = function(self, diff, luTypes, maxdiffarea)
		local tot_diff = 0.0
		local maxdiff = 0.0

		for luind, land in pairs (luTypes) do
			if ((math.abs(diff[land])) > maxdiff) then
				maxdiff = (math.abs(diff[land]))
			end
		end
		
		if (maxdiff <= maxdiffarea) then
			return true
		else
			return false
		end
	end

	-- Count the number of allocated areas.
	-- @arg cs A multivalued set of Cells (Cell Space).
	-- @arg cellarea A cell area.
	-- @arg field The field to be checked (Columns name).
	-- @arg attr The attribute to be checked.
	-- @usage --DONTRUN
	-- component.areaAllocated(cs, cellarea, land, 1)
	component.areaAllocated = function(self, cs, cellarea, field, attr)
		local count = 0
		forEachCell(cs, function(cell)
							if (cell[field] == attr) then
								count = count + 1
							end
						end
					)
		
		return (count * cellarea)
	end 

	-- Return an Index for a land use type in a set of land use types.
	-- @arg lu A land use type.
	-- @arg usetypes A set of land use type.
	-- @usage --DONTRUN
	-- component.toIndex(lu, luTypes)
	component.toIndex = function(self, lu, usetypes)
		local index = 0
		for i, value in  pairs (usetypes) do
			if (value == lu) then
				index = i
				break
			end   
		end

		return index
	end
   
	-- Initialise the iteration vector for each land use type.
	-- @arg lutypes A set of land use types.
	-- @usage --DONTRUN
	-- component.initIteration(luTypes)
	component.initIteration = function(self, lutypes)
		local iteration = {}  
		
		for k, lu in pairs (lutypes) do
			iteration[lu] = 0
		end

		return iteration
	end

	-- Handles with the change of an use for a cell area.
	-- @arg cell A cell area.
	-- @arg cur_use The current use.
	-- @arg higher_use The biggest cell value.
	-- @usage --DONTRUN 
	-- component.changeUse(cell, currentUse(cell, luTypes), cell.simUse, currentTime, initialTime))
	component.changeUse = function(self, cell, cur_use, higher_use, currentTime, initialTime)
		cell[cur_use] = 0
		cell[cur_use.."_out"] = 0
		
		cell[higher_use] = 1
		cell[higher_use.."_out"] = 1
		
		cell[higher_use.."_chpast"] = 0
		cell[cur_use.."_chpast"] = 0  
	end
  
	-- Return the current use for a cell area.
	-- @arg cell A cell area.
	-- @arg landuses A set of land use types.
	-- @usage --DONTRUN
	-- component.currentUse(cell, luTypes)
	component.currentUse = function(self, cell, landuses)
		for i, land in pairs (landuses) do
			if (cell[land] == 1) then
				return land
			end
		end
	end

	collectgarbage("collect")
	return component
end -- end of AllocationDClueSNeighOrdering
