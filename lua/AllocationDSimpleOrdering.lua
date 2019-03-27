--- Simple model developed as teaching material. Not to be used in real applications. Instead of using the iterative process employed in the CLUE family, 
-- the component implements a simple ordering approach. A more elaborate ordering approch is under construction.
-- @arg component A AllocationDSimpleOrdering component.
-- @arg component.run Handles with the rules of the component execution.
-- @arg component.verify Handles with the parameters verification.
-- @usage --DONTRUN 
--A1 = AllocationDSimpleOrdering
--{
--  maxDifference = 106
--} 
function AllocationDSimpleOrdering(component)
	-- Handles with the rules of the component execution.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
	-- @usage --DONTRUN 
	-- component.run(event, model)
	component.run = function(self, event, luccMEModel)
		local useLog = luccMEModel.useLog
		local cs = luccMEModel.cs
		local cellarea = cs.cellArea
		local demand = luccMEModel.demand
		local allocation_ok = false
		local numofcells  = #cs.cells
		local luTypes = luccMEModel.landUseTypes
		local dem = {}
		local differences = {}
		local area = 0
		
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
		
		--Inicialização das demandas
		for ind, lu in  pairs (luTypes) do	
 			dem[lu] = -1
 		end
  		
		print("\nTime: "..event:getTime())

		if (useLog == true) then
			print("-------------------------------------------------------------------------------")
			print("Cell Area "..cellarea)
			print("Num of cells "..numofcells)
			print("Max diff area "..self.maxDifference)

			for landuse, ivalues in pairs (luTypes) do        
				area = self:areaAllocated(cs, cellarea, luTypes[landuse], 1)
				print("Initial area for land use : "..luTypes[landuse].." -> "..area)
			end		
			print("-------------------------------------------------------------------------------")
		end
	   	
		for k, cell in pairs (cs.cells) do
			for luind, lu in  pairs (luTypes) do
				cell[lu.."_out"] = cell[lu]
			end
			cell.alloc = 0
			cell.simUse = self:currentUse(cell, luTypes)
		end

		local diff = 0
		local ord = {}

		-- Ordenação dos vetores de uso de acordo com as maiores probabilidades
		for ind, lu in  pairs (luTypes) do	
			if (lu ~= luccMEModel.landUseNoData) then 
				ord = Trajectory { target = cs,
								   select = function(cell)
												return (cell.alloc ~= 1 and cell.simUse ~= luccMEModel.landUseNoData)
											end,
								   greater = function(c, d)
												return c[lu.."_pot"] > d[lu.."_pot"]
											end
								 }

				--Seleção de tantas células quanto forem necessárias na demanda
				local j = 1
				if (dem[lu] == -1) then
					dem[lu] = demand.currentDemand
					dem[lu] = dem[lu][ind]
				end
				
				local cs_size = #cs.cells
				local trj_size = #ord.cells	
				
				print("demand\t"..lu.."\t"..dem[lu].."\ttrajectory size".."\t"..trj_size)
		
				while (j <= dem[lu]) and (j <= (trj_size * cellarea))  do 
					-- This show if the use was allocated or not
					ord.cells[j].alloc = 1
					ord.cells[j].simUse = lu
					j = j + 1
				end

				-- Quantidade alocada do uso neste passo de tempo
				local areaAlloc = self:areaAllocated(ord, cellarea, "alloc", 1)
			
				print("areaAlloc".."\t"..lu.."\t"..areaAlloc)
				differences[lu] = (dem[lu] - areaAlloc)

				if (differences[lu]> 0) then
					dem[lu] = differences[lu]
				else
					dem[lu] = 0
				end
				
				-- Diferença total
				diff = diff + math.abs(differences[lu])
			end
		end
		
		if (diff <= self.maxDifference) then
			allocation_ok = true
		end
 		
		if (allocation_ok == true) then 
 			-- Update the status of each use for eache cell if the demand was allocated
			for k, cell in pairs (cs.cells) do			
 				self:changeUse(cell, self:currentUse(cell, luTypes), cell.simUse, event:getTime(), luccMEModel.startTime)
 				cell.alloc = 0
 			end
			
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
		else
			print("\nDemand not allocated correctly in this time step: "..event:getTime().."\n")
			os.exit()
		end      	
 	end -- end of 'run' function
 	
	-- Handles with the parameters verification.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @usage --DONTRUN 
	-- component.verify(event, self)
	component.verify = function(self, event)
		print("Verifying Allocation parameters")
		
		if (self.maxDifference == nil) then
			error("maxDifference variable is missing", 2)
		end
	end

	-- Count the number of allocated areas.
	-- @arg cs A multivalued set of Cells (Cell Space).
	-- @arg cellarea A cell area.
	-- @arg field The field to be checked (Columns name).
	-- @arg attr The attribute to be checked.
	-- @usage --DONTRUN 
	-- component.areaAllocated(ord, cellarea, "alloc", 1)
	component.areaAllocated = function(self, cs, cellarea, field, attr)
		local c = 0
		forEachCell(cs, function(cell)
							if (cell[field] == attr) then
								c = c + 1   
							end
						end
					)
					
		return (c * cellarea)
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
		for i, land  in pairs (landuses) do
		  if (cell[land] == 1) then
			return land
		  end
		end
	end

	collectgarbage("collect")
	return component
end -- end of AllocationCluesLike
