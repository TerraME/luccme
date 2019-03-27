-- @example LuccME Discrete Model using the following components: 
-- DemandPreComputedValues, 
-- PotentialDNeighSimpleRule, 
-- AllocationDSimpleOrdering.
return {
	lab10 = function(unitTest)
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
		local Lab10 = LuccMEModel
		{
			name = "Lab10",

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
			
			potential = PotentialDNeighSimpleRule{},
			
			allocation = AllocationDSimpleOrdering
			{
				maxDifference = 106
			},

			save  =
			{
				outputTheme = "Lab10_",
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
				start = Lab10.startTime,
				action = function(event)
								Lab10:run(event)
						  end
			}
		}

		local env_Lab10 = Environment{}
		env_Lab10:add(timer)

		-- ENVIROMMENT EXECUTION
		if Lab10.isCoupled == false then
			local tsave = databaseSave(Lab10)
			env_Lab10:add(tsave)
			env_Lab10:run(Lab10.endTime)
			saveSingleTheme(Lab10, true)
		end

		-- Creating Map for test compare
		local cs2 = CellularSpace{
						file = filePath("test/Lab10_2004.shp", "luccme"),
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

		unitTest:assertSnapshot(mapsResult, "lab10.png")
		
		-- Removing generated files		
		projFile = File("t3mp.tview")
		if(projFile:exists()) then
			projFile:delete()
		end

		projFile = filePath("test/Lab10_2004.shp", "luccme")
		if(projFile:exists()) then
			projFile:delete()
		end
	end,
}