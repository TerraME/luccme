--- Simple component developed as teaching material. Not to be used in real applications. Estimates cell 
-- potential for a given use according to the percentage of cells of the same type in a Moore neighbourhood.
-- @arg component A PotentialDNeighSimpleRule component.
-- @arg component.run Handles with the execution method of a PotentialDNeighSimpleRule component.
-- @arg component.verify Handles with the verify method of a PotentialDNeighSimpleRule component.
-- @return The modified component.
-- @usage -- DONTRUN
-- P1 = PotentialDNeighSimpleRule{}
function PotentialDNeighSimpleRule(component)
	-- Handles with the execution method of a PotentialDNeighSimpleRule component.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @arg luccMEModel A luccME Model.
	-- @usage --DONTRUN 
	-- component.run(event, model)
	component.run = function(self, event, luccMEModel)
		local cs = luccMEModel.cs
		local luTypes = luccMEModel.landUseTypes
		local potentialData = self.potentialData
		local landUseDrivers = self.landUseDrivers
		local filename = self.filename

		if (filename ~= nil) then
			loadGALNeighborhood(filename)
		else
			if(event:getTime() == luccMEModel.startTime) then
				cs:createNeighborhood()		
			end
		end

		local totalNeigh = 0

		for k, cell in pairs (cs.cells) do
			totalNeigh = #cell:getNeighborhood()

			if (cell.region == nil) then
				cell.region = 1
			end 	

			for i, lu in pairs (luTypes) do 
				cell[lu.."_pot"] = 0
				local numNeigh = 0;
				
				forEachNeighbor(cell, function(neigh, _, cell)				
											if (neigh[lu] == 1) then					
												numNeigh = numNeigh + 1
											end
										end
								)

				if (totalNeigh > 0) then
					cell[lu.."_pot"] = numNeigh / totalNeigh 	
				else 	
					cell[lu.."_pot"] = 0
				end	
			end -- for i
		end -- for k
	end -- end run

	-- Handles with the verify method of a PotentialDNeighSimpleRule component.
	-- @arg event A representation of a time instant when the simulation engine must run.
	-- @usage --DONTRUN 
	-- component.verify(self, event)
	component.verify = function(self, event)
		print("Verifying Potential parameters")
	end

	collectgarbage("collect")
	return component
end --close RegressionLogistcModelNeighbourhood
