-- @example LuccME Discrete Model using the following components: 
-- DemandPreComputedValues, 
-- PotentialDNeighInverseDistanceRule, 
-- AllocationDSimpleOrdering.
return {
	lab12 = function(unitTest)
		print = function() end
		
		-- Creatig project
		local gis = getPackage("gis")

		local projFile = File("t3mp.tview")
		if(projFile:exists()) then
			projFile:delete()
		end

		local proj = gis.Project {
			file = "t3mp.tview",
			clean = true
		}

		local l1 = gis.Layer{
			project = proj,
			name = "layer",
			file = filePath("test/cs_moju.shp", "luccme")
		}

		-- LuccME APPLICATION MODEL DEFINITION
		local Lab12 = LuccMEModel
		{
			name = "Lab12",

			-- Temporal dimension definition
			startTime = 1999,
			endTime = 2004,

			-- Spatial dimension definition
			cs = CellularSpace
			{
				project = proj,
				layer = l1.name,
				cellArea = 1,
			},

			-- Land use variables definition
			landUseTypes =
			{
				"f", "d", "o"
			},

			landUseNoData	= "o",

			-- Behaviour dimension definition:
			-- DEMAND, POTENTIAL AND ALLOCATION COMPONENTS
			demand = DemandPreComputedValues
			{
				annualDemand =
				{
					-- "f", "d", "o"
					{5706, 205, 3}, 	-- 1999
					{5658, 253, 3}, 	-- 2000
					{5611, 300, 3}, 	-- 2001
					{5563, 348, 3}, 	-- 2002
					{5516, 395, 3}, 	-- 2003
					{5468, 443, 3} 		-- 2004
				}
			},
			
			potential = PotentialDNeighInverseDistanceRule
			{
				potentialData =
				{
					-- Region 1
					{
						-- f
						{
							const = 0.01,

							betas =
							{
								dist_estra = -0.3,
								dist_br = -0.3
							}
						},

						-- d
						{
							const = 0.01,

							betas =
							{
								dist_estra = 0.3,
								dist_br = 0.3
							}
						},

						-- o
						{
							const = 0.01,

							betas =
							{
								
							}
						}
					}
				}
			},
			
			allocation = AllocationDSimpleOrdering
			{
				maxDifference = 106
			},

			save  =
			{
				outputTheme = "Lab12_",
				mode = "multiple",
				saveYears = {2004},
				saveAttrs = 
				{
					"d_out",
				},
			},

			isCoupled = false
		}  -- END LuccME application model definition

		-- ENVIROMMENT DEFINITION
		local timer = Timer
		{
			Event
			{
				start = Lab12.startTime,
				action = function(event)
								Lab12:run(event)
						  end
			}
		}

		local env_Lab12 = Environment{}
		env_Lab12:add(timer)

		-- ENVIROMMENT EXECUTION
		if Lab12.isCoupled == false then
			local tsave = databaseSave(Lab12)
			env_Lab12:add(tsave)
			env_Lab12:run(Lab12.endTime)
			saveSingleTheme(Lab12, true)
		end

		-- Creating Map for test compare
		local cs2 = CellularSpace{
						file = filePath("test/Lab12_2004.shp", "luccme"),
						zero = "top"
					}
			
		local mapsResult = Map{
					target = cs2,
					select = "d_out",
					slices = 10,
					min = 0,
					max = 1,
					color = "RdYlGn",
					invert = true,
				}
				
		unitTest:assertSnapshot(mapsResult, "lab12.png")

		-- Removing generated files		
		projFile = File("t3mp.tview")
		if(projFile:exists()) then
			projFile:delete()
		end

		projFile = filePath("test/Lab12_2004.shp", "luccme")
		if(projFile:exists()) then
			projFile:delete()
		end
	end,
}