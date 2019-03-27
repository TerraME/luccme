--- Uses linear regression techniques to estimate the cell potential for change. Based on the original 
-- continuous CLUE model proposal, the change potential for each use (increase or decrease the percentage
-- in the cell at a given time is estimated as the difference between the regression cover and the actual 
-- land use percentage at a given time (see Verburg et al. 1999 for a detailed description). 
-- @arg component A Linear Regression component.
-- @arg component.potentialData A table with the regression parameters for each attribute.
-- @arg component.potentialData.isLog Inform whether the model is part of a coupling model.
-- @arg component.potentialData.const A linear regression constant.
-- @arg component.potentialData.betas A linear regression betas for land use drivers
-- and the index of landUseDrivers to be used by the regression (attributes).
-- @arg component.landUseDrivers The land use drivers fields in database.
-- @arg component.run Handles with the execution method of a PotentialCLinearRegression component.
-- @arg component.verify Handles with the verify method of a PotentialCLinearRegression component.
-- @arg component.modify Handles with the modify method of a PotentialCLinearRegression component.
-- @arg component.adaptRegressionConstants Handles with the constants regression method of a
-- PotentialCLinearRegression component.
-- @arg component.modifyDriver Modify potencial for an protected area.
-- @arg component.computePotential Handles with the modify method of a PotentialCLinearRegression component.
-- @return The modified component.
-- @usage --DONTRUN
--P1 = PotentialCLinearRegression
--{
--  potentialData =
--  {
--    -- Region 1
--    {
--      -- floresta
--      {
--        isLog = false,
--        const = 0.7392,
--
--        betas =
--        {
--          assentamentos = -0.2193,
--          uc_us = 0.1754,
--          uc_pi = 0.09708,
--          ti = 0.1207,
--          dist_riobranco = 0.0000002388,
--          fertilidadealtaoumedia = -0.1313
--        }
--      },
--
--      -- desmatamento
--      {
--        isLog = false,
--        const = 0.267,
--
--        betas =
--        {
--          rodovias = -0.0000009922,
--          assentamentos = 0.2294,
--          uc_us = -0.09867,
--          dist_riobranco = -0.0000003216,
--          fertilidadealtaoumedia = 0.1281
--        }
--      },
--
--      -- outros
--      {
--        isLog = false,
--        const = 0,
--
--        betas =
--        {
--          
--        }
--      }
--    }
--  }
--}
function PotentialCLinearRegression(component)
	-- Handles with the execution method of a PotentialCLinearRegression component.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A luccME Model.
	-- @usage --DONTRUN
	-- component.run(event, model)
	component.run = function(self, event, luccMEModel)
		local cs = luccMEModel.cs
		local luDrivers = self.landUseDrivers
		local luTypes = luccMEModel.landUseTypes
		local demand = luccMEModel.demand
		local regionsNumber = #self.potentialData

		-- Create an internal constant that can be modified during allocation
		for rNumber = 1, regionsNumber, 1 do
			for i, luData in pairs (self.potentialData[rNumber]) do
				if (luData.const  == nil) then 
					luData.const = 0 
				end
				
				luData.newconst = luData.const
			end

			if (event:getTime() > luccMEModel.startTime) then 
				self:adaptRegressionConstants(demand, rNumber)
			end

			for i = 1, #luTypes, 1 do                         
				self:computePotential(luccMEModel, rNumber, i)
			end
		end
	end  -- function run

	-- Handles with the verify method of a PotentialCLinearRegression component.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A luccME Model.
	-- @usage --DONTRUN
	-- component.verify(event, self)
	component.verify = function(self, event, luccMEModel)
		print("Verifying Potential parameters")
		local cs = luccMEModel.cs

		if (self.regionAttr == nil) then
			self.regionAttr = "region"
		end   

		forEachCell(cs, function(cell)
							cell["alternate_model"] = 0
							
							if (cell[self.regionAttr] == nil) then
								cell["region"] = 1
							else
								cell["region"] = cell[self.regionAttr]
							end
						end
					)

		-- check potentialData
		if (self.potentialData == nil) then
			error("potentialData is missing", 2)
		end    

		local regionsNumber = #self.potentialData

		-- check number of Regions
		if (regionsNumber == nil or regionsNumber == 0) then
			error("The model must have at least One region")
		else
			for i = 1, regionsNumber, 1 do
				local regressionNumber = #self.potentialData[i]
				local lutNumber = #luccMEModel.landUseTypes

				-- check the number of regressions
				if (regressionNumber ~= lutNumber) then
					error("Invalid number of regressions on Region number "..i.." . Regressions: "..regressionNumber.." LandUseTypes: "..lutNumber)
				end

				for j = 1, regressionNumber, 1 do
					-- check isLog variable
					if(self.potentialData[i][j].isLog == nil) then
						error("isLog variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
					end

					-- check const variable
					if (self.potentialData[i][j].const == nil) then
						error("const variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
					end

					-- check betas variable
					if (self.potentialData[i][j].betas == nil) then
						error("betas variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
					end

					-- check betas within database
					for k, lu in pairs (self.potentialData[i][j].betas) do
						if (luccMEModel.cs.cells[1][k] == nil) then
							error("Beta "..k.." on Region "..i.." LandUseType "..luccMEModel.landUseTypes[j].." not found within database", 2)
						end
					end
				end -- for j
			end -- for i
		end -- else
	end
 
	-- Handles with the potential modify method of a PotentialCLinearRegression component.
	-- This method is called by the Allocation component.
	-- @arg luccMEModel A luccME Model.
	-- @arg rNumber The potential region number.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @arg direction The direction for the regression.
	-- @usage --DONTRUN
	-- component.modify(luccMEModel, j, i, luDirect)
	component.modify = function(self, luccMEModel, rNumber, luIndex, direction)
		local luData = self.potentialData[rNumber][luIndex] 

		if (luData.newconst == nil) then 
			luData.newconst = 0 
		end	

		if (luData.isLog) then 
			luData.newconst = luData.newconst - math.log(0.1, 10) * direction
		else
			luData.newconst = luData.newconst + 0.1 * direction
		end
		
		self:computePotential(luccMEModel, rNumber, luIndex)
	end	-- function	modify	

	-- Handles with the constants regression method of a PotentialCLinearRegression component.
	-- @arg demand A demand to calculate the potential.
	-- @arg rNumber The potential region number.
	-- @usage --DONTRUN
	-- component.adaptRegressionConstants(demand, rNumber)
	component.adaptRegressionConstants = function(self, demand, rNumber)
		for i, luData in pairs (self.potentialData[rNumber]) do			
			local currentDemand = demand:getCurrentLuDemand(i)
			local previousDemand = demand:getPreviousLuDemand(i) 
			local plus = ((currentDemand - previousDemand) / previousDemand)

			luData.newconst = luData .const

			if (luData.isLog) then
				if (plus > 0) then 
					luData.newconst = luData.newconst - math.log(plus, 10) * 0.01 
				end
				
				if (plus < 0) then 
					luData.newconst = luData.newconst + math.log((-1) * plus, 10) * 0.01
				end
			else 
				luData.newconst = luData.newconst + plus * 0.01  
			end 
		end
	end	-- function adaptRegressionConstants

	-- Modify potencial for an protected area.
	-- @arg complementarLU Land use name.
	-- @arg attrProtection The protetion attribute name.
	-- @arg rate A rate for potencial multiplier.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A luccME Model.
	-- @usage --DONTRUN
	-- component.modifyDriver(self.complementarLU, self.attrProtection, 0.5, event, luccMEModel)
	component.modifyDriver = function(self, complementarLU, attrProtection, rate, event, luccMEModel)
		local regionsNumber = #luccMEModel.potential.potentialData
		local luTypes = luccMEModel.landUseTypes
		local luIndex = 1

		for i, complementarLU in pairs (luTypes) do
			if (complementarLU == luTypes[i]) then
				luIndex = i
				break
			end
		end

		for i = 1, regionsNumber, 1 do
			self:computePotential(luccMEModel, i, luIndex)
		end
	end
  
	-- Handles with the compute potential method of a PotentialCLinearRegression component.
	-- @arg luccMEModel A luccME Model.
	-- @arg rNumber The potential region number.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @usage --DONTRUN
	-- component.computePotential(luccMEModel, luIndex)		
	component.computePotential = function(self, luccMEModel, rNumber, luIndex)
		local cs = luccMEModel.cs	
		local luTypes = luccMEModel.landUseTypes
		local lu = luTypes[luIndex]
		local luData = self.potentialData[rNumber][luIndex]
		local pot = lu.."_pot"
		local reg = lu.."_reg"
		local activeRegionNumber = 0

		for k,cell in pairs (cs.cells) do
			if (cell.region == rNumber) then
				activeRegionNumber = rNumber

				local regression = luData.newconst

				for var, beta in pairs (luData.betas) do 
					regression = regression + beta * cell[var]
				end

				if (luData.isLog) then -- if the land use is log transformed
					regression = 10 ^ regression
				end 

				if (regression > 1) then
					regression = 1
				end

				if (regression < 0) then
					regression = 0
				end

				if (luccMEModel.landUseNoData ~= nil) then     
					regression = regression * (1 - cell[luccMEModel.landUseNoData]) 
				end
				
				cell[reg] = regression 
				cell[pot] = regression - cell.past[lu] 
			end 
		end

		if (activeRegionNumber == 0) then
			error("Region ".. rNumber.." is not set into database.")  
		end
	end  -- function computePotential

	collectgarbage("collect")
	return component
end -- component definition
