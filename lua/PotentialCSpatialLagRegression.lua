--- Similar to the LinearRegression approach, but relies spatial regression techniques to estimate the 
-- regression cover (considers the spatial dependence of the land use). 
-- @arg component A Spatial Lag Regression component.
-- @arg component.potentialData A table with the regression parameters for each attribute.
-- @arg component.potentialData.isLog Inform whether the model is part of a coupling model.
-- @arg component.potentialData.const A linear regression constant.
-- @arg component.potentialData.minReg A coefficient to minimize the regression value.
-- @arg component.potentialData.maxReg A coefficient to potentiality the regression value.
-- @arg component.potentialData.ro Auto regressive coefficient.
-- @arg component.potentialData.betas A linear regression betas for land use drivers
-- and the index of landUseDrivers to be used by the regression (attributes).
-- @arg component.landUseDrivers The land use drivers fields in database.
-- @arg component.run Handles with the execution method of a PotentialCSpatialLagRegression component.
-- @arg component.verify Handles with the verify method of a PotentialCSpatialLagRegression component.
-- @arg component.modify Handles with the modify method of a PotentialCSpatialLagRegression component.
-- @arg component.adaptRegressionConstants Handles with the constants regression method of a
-- PotentialCSpatialLagRegression component.
-- @arg component.modifyDriver Modify potencial for an protected area.
-- @arg component.computePotential Handles with the modify method of a PotentialCSpatialLagRegression component.
-- @return The modified component.
-- @usage --DONTRUN 
--P1 = PotentialCSpatialLagRegression
--{
--  potentialData =
--  {
--    -- Region 1
--    {
--      -- floresta
--      {
--        isLog = false,
--        const = 0.05266679,
--        minReg = 0,
--        maxReg = 1,
--        ro = 0.9124615,
--
--        betas =
--        {
--          uc_us = 0.03789872,
--          uc_pi = 0.04141921,
--          ti = 0.04455667
--        }
--      },
--
--      -- desmatamento
--      {
--        isLog = false,
--        const = 0.01431553,
--        minReg = 0,
--        maxReg = 1,
--        ro = 0.9019253,
--
--        betas =
--        {
--          assentamentos = 0.0443537,
--          uc_us = -0.01454847,
--          dist_riobranco = -0.00000002262071,
--          fertilidadealtaoumedia = 0.01701601
--        }
--      },
--
--      -- outros
--      {
--        isLog = false,
--        const = 0,
--        minReg = 0,
--        maxReg = 1,
--        ro = 0,
--
--        betas =
--        {
--          
--        }
--      }
--    }
--  }
--}
function PotentialCSpatialLagRegression(component)
	-- Handles with the execution method of a PotentialCSpatialLagRegression component.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
	-- @usage --DONTRUN
	-- component.run(event, model)
	component.run = function(self, event, luccMEModel)
		local luTypes = luccMEModel.landUseTypes
		local demand = luccMEModel.demand
		local regionsNumber = #self.potentialData

		-- Create an internal constant that can be modified during allocation
		for rNumber = 1, regionsNumber, 1 do
			for i, luData in pairs(self.potentialData[rNumber]) do
				if (luData.const == nil) then
					luData.const = 0
				end

				if (luData.minReg == nil) then
					luData.minReg = 0
				end

				if (luData.maxReg == nil) then
					luData.maxReg = 1
				end

				luData.newconst = luData.const
				luData.newminReg = luData.minReg
				luData.newmaxReg = luData.maxReg
			end

			if (self.constChange == nil) then
				self.constChange = 0.1      -- original clue value
			end

			if (event:getTime() > luccMEModel.startTime) then 
				self:adaptRegressionConstants(demand, rNumber)
			end

			for i = 1, #luTypes, 1 do	                      
				self:computePotential(luccMEModel, rNumber, i)
			end
		end
	end -- function run
	
	-- Handles with the verify method of a PotentialCSpatialLagRegression component.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
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

					-- check minReg variable
					if(self.potentialData[i][j].minReg == nil) then
						error("minReg variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
					end

					-- check maxReg variable
					if(self.potentialData[i][j].maxReg == nil) then
						error("maxReg variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
					end

					-- check ro variable
					if(self.potentialData[i][j].ro == nil) then
						error("ro variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
					end                  

					-- check const variable
					if (self.potentialData[i][j].const == nil) then
						error("const variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
					end

					-- check betas variable
					if (self.potentialData[i][j].betas == nil) then
						error("minReg variable is missing on Region "..i.." LandUseType: "..luccMEModel.landUseTypes[j], 2)
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

		local filename = self.filename

		if (filename ~= nil) then
			loadGALNeighborhood(filename)
		else
			cs:createNeighborhood() 
		end
	end -- verify
 
	-- Handles with the modify method of a PotentialCSpatialLagRegression component.
	-- @arg luccMEModel A LuccME model.
	-- @arg rNumber The potential region number.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @arg direction The direction for the regression.
	-- @usage --DONTRUN
	-- component.modify(luccMEModel, j, i, luDirect) 
	component.modify = function(self, luccMEModel, rNumber, luIndex, direction)
		local cs = luccMEModel.cs
		local luData = self.potentialData[rNumber][luIndex] 

		if luData.newconst == nil then 
			luData.newconst = 0 
		end	

		if (luData.isLog) then 
			local const_unlog = (10 ^ luData.newconst) + self.constChange * direction
			
			if (const_unlog ~= 0) then 
				luData.newconst = math.log(const_unlog, 10) 
			end	
		else
			luData.newconst = luData.newconst + self.constChange * direction
		end

		self:computePotential (luccMEModel, rNumber, luIndex)
	end	-- function	modifyPotential	

	-- Handles with the constants regression method of a PotentialCSpatialLagRegression component.
	-- @arg demand A demand to calculate the potential.
	-- @arg rNumber The potential region number.
	-- @usage --DONTRUN
	-- component.adaptRegressionConstants(demand, rNumbers)
	component.adaptRegressionConstants = function(self, demand, rNumber)
		for i, luData in pairs (self.potentialData[rNumber]) do			
			local currentDemand = demand:getCurrentLuDemand(i)
			local previousDemand = demand:getPreviousLuDemand(i) 
			local plus = 0.01 * ((currentDemand - previousDemand) / previousDemand)

			luData.newconst = luData.const

			if (luData.isLog) then
				local const_unlog = (10 ^ luData.newconst) + plus 
				
				if (const_unlog ~= 0) then 
					luData.newconst = math.log (const_unlog, 10) 
				end
			else 
				luData.newconst = luData.newconst + plus  
			end    

			luData.newminReg = luData.newminReg + plus  
			luData.newmaxReg = luData.newmaxReg + plus
			luData.const = luData.newconst  
		end
	end	-- function adaptRegressionConstants
	
	-- Modify potencial for an protected area.
	-- @arg complementarLU Land use name.
	-- @arg attrProtection The protetion attribute name.
	-- @arg rate A rate for potencial multiplier.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A LuccME model.
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
			local regressionNumber = #luccMEModel.potential.potentialData[i]

			for j = 1, regressionNumber, 1 do
				if (luccMEModel.potential.potentialData[i][j].betas[attrProtection] ~= nil) then 
					luccMEModel.potential.potentialData[i][j].betas[attrProtection] = luccMEModel.potential.potentialData[i][j].betas[attrProtection] * rate
				end
			end

			self:computePotential(luccMEModel, i, luIndex)
		end
	end

	-- Handles with the compute potential method of a PotentialCSpatialLagRegression component.
	-- @arg luccMEModel A LuccME model.
	-- @arg rNumber The pontencial region number.
	-- @arg luIndex A land use index (an specific luIndex of a list of possible land uses).
	-- @usage --DONTRUN
	-- component.computePotential(luccMEModel, rNumber, luIndex)		
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

				local regressionX = 0

				for var, beta in pairs (luData.betas) do 
					regressionX = regressionX + beta * cell[var]
				end

				--regresDrivers = regressionX
				local regresY = 0
				local neighSum = 0
				local count = 0
				local neighY = 0
				local Y = 0

				forEachNeighbor(cell, function(neigh, _, cell)
											Y = cell.past[lu]
											neighY = neigh.past[lu]

											if (cell[luccMEModel.landUseNoData] ~= 1) then 
												Y = Y / (1 - cell[luccMEModel.landUseNoData]) 
											end

											if (neigh[luccMEModel.landUseNoData] ~= 1) then 
												neighY = neighY / (1 - neigh[luccMEModel.landUseNoData]) 
											end

											if (neigh[luccMEModel.landUseNoData] < 1) then 
												count = count + 1
												neighSum = neighSum + neighY
											end
										end
								)

				if (count > 0) then
					regresY = (Y + neighSum) / (count + 1)  
				else
					regresY = Y  
				end	
                
                local oldRegress = regresY

				if (luData.isLog) then -- if the land use is log transformed
					regresY = math.log(regresY + 0.0001, 10)   -- ANAP
				end
                  
                
                regresY = regresY*luData.ro 

				local regression = luData.newconst + regressionX + regresY 
				local regressionLimit = luData.const+ regressionX + regresY   		

				if (luData.isLog) then -- if the land use is log transformed
					regression = (10 ^ regression) - 0.0001
					regressionLimit = (10 ^ regressionLimit) - 0.0001
				end 

				local oldReg = regressionLimit

				if (regressionLimit > luData.maxReg) then
					regression = 1
				end

				if (regressionLimit < luData.minReg) then
					regression = 0
				end

				--if (regression > 1) then  -- ANAP
				--	regression = 1
				--end

				--if (regression < 0) then
				--	regression = 0
				--end

				regression = regression * (1 - cell[luccMEModel.landUseNoData])
				cell[reg] = regression 
				cell[pot] = regression - cell.past[lu] 
			end -- if region
		end -- for k

		if (activeRegionNumber == 0) then
			error("Region ".. rNumber.." is not set into database.")  
		end
	end  -- function computePotential

	collectgarbage("collect")
	return component
end -- PotentialCSpatialLagRegression
