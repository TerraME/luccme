--- Handles with a LuccME model behaviour.
-- @arg model.name The model name.
-- @arg model.startTime The initial year of simulation.
-- @arg model.endTime The final year of simulation.
-- @arg model.cs The spatial dimension definition (CellularSpace).
-- @arg model.landUseTypes The name of the use land types for simulation.
-- @arg model.landUseNoData The name of land use that is not consider on the simulation.
-- @arg model.potential The name of component that calculates the potential of change  for each cell.
-- @arg model.allocation The name of component that handles with the allocation on the cell
-- based on it potential and demand.
-- @arg model.demand The name of component that handles with the allocation demand.
-- @arg model.save The name of component that handles with the simulation data save in a database.
-- @arg model.isCoupled A flag to inform with the model for simulation is coupled to another.
-- @arg model.execute Handles with the execution method of a LuccMe model.
-- @arg model.verify Handles with the verify method of a LuccMe model.
-- @arg model.dinamicVars Handles with the dinamicVars method of a LuccMe model.
-- @usage --DONTRUN
--import("luccme")
--
--dofile("D:\\Diego Melo\\Desktop\\lab1_submodel.lua")
--
--
-- --------------------------------------------------------------
-- --             LuccME APPLICATION MODEL DEFINITION          --
-- --------------------------------------------------------------
--Lab1 = LuccMEModel
--{
--  name = "Lab1",
--
--  -----------------------------------------------------
--  -- Temporal dimension definition                   --
--  -----------------------------------------------------
--  startTime = 2008,
--  endTime = 2014,
--
--  -----------------------------------------------------
--  -- Spatial dimension definition                    --
--  -----------------------------------------------------
--  cs = CellularSpace
--  {
--    project = "D:\\cs_continuous.tview",
--    layer = "csAC",
--    cellArea = 25,
--  },
--
--  -----------------------------------------------------
--  -- Land use variables definition                   --
--  -----------------------------------------------------
--  landUseTypes =
--  {
--    "floresta", "desmatamento", "outros"
--  },
--
--  landUseNoData = "outros",
--
--  -----------------------------------------------------
--  -- Behaviour dimension definition:                 --
--  -- DEMAND, POTENTIAL AND ALLOCATION COMPONENTS     --
--  -----------------------------------------------------
--  demand = D1,
--  potential = P1,
--  allocation = A1,
--
--  save  =
--  {
--    outputTheme = "Lab1_",
--    mode = "multiple",
--    saveYears = {2014},
--    saveAttrs = 
--    {
--      "desmatamento_out",
--      "desmatamento_change",
--      "desmatamento_pot",
--    },
--
--  },
--
--  isCoupled = false
--}  -- END LuccME application model definition
--
-- -----------------------------------------------------
-- -- ENVIROMMENT DEFINITION                          --
-- -----------------------------------------------------
--timer = Timer
--{
--  Event
--  {
--    start = Lab1.startTime,
--    action = function(event)
--            Lab1:run(event)
--          end
--  }
--}
--
--env_Lab1 = Environment{}
--env_Lab1:add(timer)
--
-- -----------------------------------------------------
-- -- ENVIROMMENT EXECUTION                           --
-- -----------------------------------------------------
--if Lab1.isCoupled == false then
--  tsave = databaseSave(Lab1)
--  env_Lab1:add(tsave)
--  env_Lab1:run(Lab1.endTime)
--  saveSingleTheme (Lab1, true)
--end
function LuccMEModel(model)
	-- Implements the execution method of a LuccMe model.
	-- @arg event An Event represents a time instant when the simulation engine must execute some computation.
	-- @usage --DONTRUN
	-- model.run(event)
	model.run = function(self, event)
		if (event:getTime() == self.startTime) then
			model:verify(event)
		end
		
		if (self.updateYears ~= nil) then
			model:dinamicVars(event, model)
		end
		
		-- execute the components
		print("\nExecuting Demand component") 
		self.demand:run(event, model)
		print("Executing Potential component")
		self.potential:run(event, model)
		print("Executing Allocation component")
		self.allocation:run(event, model)
	end

	-- Implements the verify method of a LuccMe model.
	-- @arg event An Event represents a time instant when the simulation engine must execute some computation.
	-- @usage --DONTRUN 
	-- model.verify(event)
	model.verify = function(self, event)
		local equal = 0
		print("\nVerifying Model parameters")
		-- Verify the model name
		if (model.name == nil) then
			error("Model name not defined", 2)
		end

		-- Verify the scenario name
		if (self.name == nil) then
			error("A scenario name is required", 2)
		end

		-- Verify the scenario start time
		if (self.startTime == nil) then
			error("A scenario start time is required", 2)
		end
		
		  -- Verify the scenario stop time
		if (self.endTime == nil) then
			error("A scenario end time is required", 2)
		end
		
		-- Verify the scenario date
		if (self.endTime <= self.startTime) then
			error("The scenario end time must be higher than the scenario start time", 2)
		end

		-- Verify the cellular space
		if (not self.cs) then
			error("A Cellular Space must be defined", 2)
		else
			if (self.cs.cells[1].lin ~= nil) then
				local aux = self.cs
				self.cs = CellularSpace {
					project = "t3mp.tview",
					layer = "layer",
					xy = {"col", "lin"},
					cellArea = aux.cellArea
				}
			elseif (self.cs.cells[1].Lin ~= nil) then
				local aux = self.cs
				self.cs = CellularSpace {
					project = "t3mp.tview",
					layer = "layer",
					xy = {"Col", "Lin"},
					cellArea = aux.cellArea
			}
			end
		end

		-- Verify whether the land use no data is declared and its valid
		if(self.landUseNoData == nil) then
			error("Land use no data type is missing", 2)
		elseif(self.cs.cells[1][self.landUseNoData] == nil) then
			error("landUseNoData: "..self.landUseNoData.." not found within database", 2)
		end
    
		self.result = {}

		-- Verify whether the attributes to be saved were calculated in the model
		for i, lu in pairs (self.landUseTypes) do
			if (self.cs.cells[1][lu] == nil) then
				error("landUseType: "..lu.." not found within database", 2)
			end
			equal = 1
		end
		
		if (equal == 0) then
			error("Attributes to be saved must be calculated as land use type in the model", 2)
		end

		local luTypes = self.landUseTypes
		local cs = self.cs
		
		if (cs.cells[1].past[luTypes[1]] == nil) then
			cs:synchronize()
		end
		
		-- Print model status during its execution
		if (self.useLog == nil) then
			self.useLog = true 			
		end
		
		-- Inform whether the model is part of a coupling model
		if (self.isCoupled == nil) then
			isCoupled = false 			
		end
		
		io.flush()
		
		-- Verify wheter the demand compontent was declared
		if (not self.demand) then
			error("A demand component must be specified", 2)
		end
		
		-- Verify wheter the potential compontent was declared
		if (not self.potential) then
			error("A potential component must be specified", 2)     
		end
			
			-- Verify wheter the allocation compontent was declared
		if (not self.allocation) then
			error("An allocation component must be specified", 2)     
		end
    
		-- Verify the dates to be saved
		-- This verification is done on Save.lua, because it necessary to execute before here.

		-- Verify the components
		self.demand:verify(event, self)
		self.potential:verify(event, self)
		self.allocation:verify(event, self)
		collectgarbage("collect")
	end
	
	-- Implements the variables dynamic method of a LuccMe model.
	-- @arg event An Event represents a time instant when the simulation engine must execute some computation.
	-- @arg model A luccME Model.
	-- @usage --DONTRUN 
	-- model.dinamicVars(event)
	model.dinamicVars = function(self, event, model)
		local currentTime = event:getTime()
		local cs = model.cs
		local cs_temp = {}
		
		for i, updtYear in pairs (self.updateYears) do
			-- If current year needs to update variables
			if (currentTime == updtYear) then
				print("\nUpdating dynamic variables...")
				
				if ((self.scenarioStartTime ~= nil) and (currentTime >= self.scenarioStartTime)) then
					cs_temp = CellularSpace {	project = self.cs.project, 
												layer = self.cs.layer.name.."_"..self.scenarioName.."_"..updtYear
											}
					print(self.cs.layer.name.."_"..self.scenarioName.."_"..updtYear)
				else
					cs_temp = CellularSpace {	project = self.cs.project,
												layer = self.cs.layer.name.."_"..updtYear
											}
					print(self.cs.layer.name.."_"..updtYear)
				end

				-- For each cell in the original cs, variables are contained in cs_temp is updated
				local flag = true
			       		
				forEachCellPair(cs, cs_temp, function(cell, cell_temp)
													for var, value in pairs (cell_temp) do
														if (var ~= "cObj_" and var ~= "objectId_" and
															var ~= "y" and var ~= "x" and var ~= "past" and
															var ~= "agents" and var ~= "agents_" and
															var ~= "object_id_" and var ~= "neighborhoods") then
																if (cell[var] ~= nil) then
																	cell[var] = cell_temp[var]
																	-- print the column name if flag = false
																	if (flag == false) then
																		print("\t"..var)
																	end		          					
																end
														end -- 1st inner if
													end -- for var
													flag = true
											 end -- function
								)
			end -- if currentTime
		end -- for				
	end -- dinamicVars

	-- Implements the externatl method of a LuccMe model.
	-- @arg event An Event represents a time instant when the simulation engine must execute some computation.
	-- @usage --DONTRUN
	-- model.external(event, file)
	model.external = function(self, event, file)
		print("\nExecuting External model") 
		if(file ~= "") then
			-- create global variables to use on the external file
			_G.event = event
			_G.luccMEModel = self
			
			-- call the external file
			dofile(file)
			
			-- clear the global variables
			_G.event = nil
			_G.luccMEModel = nil
			
			self.currentDemand = self.annualDemand[1]	
			self.previousDemand = self.annualDemand[1]
			
			-- delete the global variables
			collectgarbage("collect")
		end
	end
	
	collectgarbage("collect")
	return model
end
