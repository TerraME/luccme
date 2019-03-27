--- A component that call an external model to generate the demand.
-- @arg component An instance of the component itself (an object, with all the data).
-- @arg component.file The file that execute the external model.
-- @return the modified component.
-- @usage --DONTRUN 
--D1 = DemandExternalModel
-- {
-- 	file = "",
-- 	annualDemand =
-- 	{
-- 		-- "f", "d", "outros"
-- 		{,,}, 	-- 2008
-- 		{,,}, 	-- 2009
-- 		{,,}, 	-- 2010
-- 		{,,}, 	-- 2011
-- 		{,,}, 	-- 2012
-- 		{,,}, 	-- 2013
-- 		{,,} 	-- 2014
-- 	}
-- }
function DemandExternalModel(component)
	-- Handles with the rules of the component execution.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
	-- @usage --DONTRUN
	-- component.run(event, model)
	component.run = function(self, event, luccMEModel)
		if(self.file ~= "") then
			-- create global variables to use on the external file
			_G.event = event
			_G.luccMEModel = luccMEModel
			
			-- call the external file
			dofile(self.file)
			
			-- clear the global variables
			_G.event = nil
			_G.luccMEModel = nil
			
			self.currentDemand = self.annualDemand[1]	
			self.previousDemand = self.annualDemand[1]
			
			-- delete the global variables
			collectgarbage("collect")
		end
	end -- run
	
	-- Handles with the parameters verification.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
	-- @usage --DONTRUN
	-- component.verify(event, self)
	component.verify = function(self, event, luccMEModel)
		print("Verifying Demand parameters")
		local yearsSimulated = (luccMEModel.endTime - luccMEModel.startTime) + 1

		-- Check if the demand is proper to the number of years to simulate
		if (#self.annualDemand < yearsSimulated) then
			error("The simulation time exceeds the demand set", 5)
		end	

		-- Check the number of years to simulate
		if (yearsSimulated == 0) then
			error("The simulation time is zero", 5)
		end

		-- Check file
		if (self.file == nil or self.file == "") then
			error("External file not defined", 5)
		end
		
		-- Check the land use types
		local luTypes = luccMEModel.landUseTypes
		self.demandDirection = {}
		self.numLU = 0

		for k, lu in pairs (luTypes) do
			self.demandDirection[k] = 0
			
			if (self.annualDemand[1][k] == nil) then
				error("Invalid number of land use in the demand table", 5)
			end
			
			self.numLU = self.numLU + 1
		end
	end

	-- Return the current demand of the specified component.
	-- Used on discrete allocation component.
	-- @return self.currentDemand the current demand of the component.
	-- @usage --DONTRUN
	-- component.getCurrentDemand(i)
	component.getCurrentDemand = function(self)	
		return self.currentDemand
	end

	-- Return the previous demand of the specified component.
	-- @return self.previousDemand the previous demand of the component.
	-- @usage --DONTRUN
	-- component.getPreviousDemand(i)
	component.getPreviousDemand = function(self)	
		return self.previousDemand
	end

	-- Return the current demand for an specific luIndex.
	-- Used on allocation and continuous potential components.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @return The current demand for an specific luIndex.
	-- @usage --DONTRUN
	-- component.getCurrentLuDemand(luIndex)
	component.getCurrentLuDemand = function(self, luIndex)		
		if (luIndex > self.numLU) then
			error("Invalid land use index", 5)
		end

		return self.currentDemand[luIndex]
	end

	-- Return the previous demand for an specific luIndex.
	-- Used on continuous pontencial component.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @return The previous demand for an specific luIndex.
	-- @usage --DONTRUN
	-- component.getPreviousLuDemand(luIndex)
	component.getPreviousLuDemand = function(self, luIndex)	
		if (luIndex > self.numLU) then
			error("Invalid land use index", 5)
		end	

		return self.previousDemand[luIndex]
	end

	-- Return the current demand direction for an specific luIndex.
	-- Used on continuous allocation component.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @return The current demand direction for an specific luIndex.
	-- @usage --DONTRUN
	-- component.getCurrentLuDirection(luIndex)
	component.getCurrentLuDirection = function(self, luIndex)	
		if (luIndex > self.numLU) then
			error("Invalid land use index", 5)
		end	

		return self.demandDirection[luIndex]
	end	

	-- Invert the demand direction for an specific luIndex.
	-- Used on continuous allocation component.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @return The current demand direction for an specific luIndex.
	-- @usage --DONTRUN
	-- component.changeLuDirection(luIndex)
	component.changeLuDirection = function(self, luIndex)
		local oppositeDirection = -1

		if (luIndex > self.numLU) then
			error("Invalid land use index", 5)
		end

		self.demandDirection[luIndex] = self.demandDirection[luIndex] * oppositeDirection

		return self.demandDirection[luIndex]
	end		
	
	collectgarbage("collect")
	return component
end -- DemandPreComputedValues
