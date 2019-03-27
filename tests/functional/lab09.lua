-- @example LuccME Continuous Model using the following components:
-- DemandPreComputedValues, 
-- PotentialCMaximumEntropyLike, 
-- AllocationCClueLike.
return {
	lab09 = function(unitTest)
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
			file = filePath("test/csAC.shp", "luccme")
		}

		-- LuccME APPLICATION MODEL DEFINITION
		local Lab09 = LuccMEModel
		{
			name = "Lab09",

			-- Temporal dimension definition
			startTime = 2008,
			endTime = 2014,

			-- Spatial dimension definition
			cs = CellularSpace
			{
				project = proj,
				layer = l1.name,
				cellArea = 25,
			},

			-- Land use variables definition
			landUseTypes =
			{
				"f", "d", "outros"
			},

			landUseNoData	= "outros",

			-- Behaviour dimension definition:
			-- DEMAND, POTENTIAL AND ALLOCATION COMPONENTS
			demand = DemandPreComputedValues
			{
				annualDemand =
				{
					-- "f", "d", "outros"
					{137878.1691, 19982.62882, 6489.202049}, 	-- 2008
					{137622.2199, 20238.57805, 6489.202049}, 	-- 2009
					{137366.2707, 20494.52729, 6489.202049}, 	-- 2010
					{137110.3214, 20750.47652, 6489.202049}, 	-- 2011
					{136824.6853, 21036.11265, 6489.202049}, 	-- 2012
					{136539.0492, 21321.74879, 6489.202049}, 	-- 2013
					{136253.4130, 21607.38493, 6489.202049}		-- 2014
				}
			},
			
			potential = PotentialCSampleBased
			{
				potentialData =
				{
					-- Region 1
					{
						-- f
						{
							cellUsePercentage = 75, 

							attributesPerc = 
							{
								"assentamen",
								"rodovias",
								"dist_riobr",
								"rios_todos",
								"uc_us",
								"ti",
								"ap",
								"uc_pi",
								"fertilidad"
							},

							attributesClass = 
							{
							}
						},

						-- dto
						{
							cellUsePercentage = 75, 

							attributesPerc = 
							{
								"assentamen",
								"rodovias",
								"dist_riobr",
								"rios_todos",
								"uc_us",
								"ti",
								"ap",
								"uc_pi",
								"fertilidad"
							},

							attributesClass = 
							{
							}
						},

						-- outros
						{
							cellUsePercentage = 75, 

							attributesPerc = 
							{
							},

							attributesClass = 
							{
							}
						}
					}
				}
			},
			
			allocation = AllocationCClueLike
			{
				maxDifference = 5000,
				maxIteration = 10000,
				initialElasticity = 0.01,
				minElasticity = 0.001,
				maxElasticity = 1.5,
				complementarLU = "f",
				allocationData =
				{
					-- Region 1
					{
						{static = 0, minValue = 0, maxValue = 1, minChange = 0, maxChange = 1, changeLimiarValue = 1, maxChangeAboveLimiar = 0},	-- f
						{static = 0, minValue = 0, maxValue = 1, minChange = 0, maxChange = 1, changeLimiarValue = 1, maxChangeAboveLimiar = 0},	-- d
						{static = 1, minValue = 0, maxValue = 1, minChange = 0, maxChange = 1, changeLimiarValue = 1, maxChangeAboveLimiar = 0},	-- outros
					}
				}
			},

			save  =
			{
				outputTheme = "Lab09_",
				mode = "multiple",
				saveYears = {2014},
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
				start = Lab09.startTime,
				action = function(event)
								Lab09:run(event)
						  end
			}
		}

		local env_Lab09 = Environment{}
		env_Lab09:add(timer)

		-- ENVIROMMENT EXECUTION
		if Lab09.isCoupled == false then
			local tsave = databaseSave(Lab09)
			env_Lab09:add(tsave)
			env_Lab09:run(Lab09.endTime)
			saveSingleTheme(Lab09, true)
		end

		-- Creating Map for test compare
		local cs2 = CellularSpace{
						file = filePath("test/Lab09_2014.shp", "luccme"),
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
				
		unitTest:assertSnapshot(mapsResult, "lab09.png")

		-- Removing generated files		
		projFile = File("t3mp.tview")
		if(projFile:exists()) then
			projFile:delete()
		end

		projFile = filePath("test/Lab09_2014.shp", "luccme")
		if(projFile:exists()) then
			projFile:delete()
		end
	end,
}