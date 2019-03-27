-- @example LuccME Continuous Model using the following components, Dynamic Variables and Scenario: 
-- DemandPreComputedValues, 
-- PotentialCSpatialLagRegression, 
-- AllocationCClueLike, 
-- Dynamic Variables update in 2009, 
-- Scenario staring in 2015, update variables in 2020, until 2025.
return {
	lab07 = function(unitTest)
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

		local l2 = gis.Layer{
			project = proj,
			name = "layer_2009",
			file = filePath("test/csAC_2009.shp", "luccme")
		}

		local l3 = gis.Layer{
			project = proj,
			name = "layer_cenarioA_2020",
			file = filePath("test/csAC_cenarioA_2020.shp", "luccme")
		}

		-- LuccME APPLICATION MODEL DEFINITION
		local Lab07 = LuccMEModel
		{
			name = "Lab07",

			-- Temporal dimension definition
			startTime = 2008,
			endTime = 2025,

			-- Spatial dimension definition
			cs = CellularSpace
			{
				project = proj,
				layer = l1.name,
				cellArea = 25,
			},

			-- Dynamic variables definition
			updateYears = {2009, 2020},
			scenarioStartTime = 2015,
			scenarioName = "cenarioA",

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
					{136253.413, 21607.38493, 6489.202049}, 	-- 2014
					{135973.413, 21887.38493, 6489.202049}, 	-- 2015
					{135693.413, 22167.38493, 6489.202049}, 	-- 2016
					{135413.413, 22447.38493, 6489.202049}, 	-- 2017
					{135133.413, 22727.38493, 6489.202049}, 	-- 2018
					{134853.413, 23007.38493, 6489.202049}, 	-- 2019
					{134573.413, 23287.38493, 6489.202049}, 	-- 2020
					{134293.413, 23567.38493, 6489.202049}, 	-- 2021
					{133993.413, 23867.38493, 6489.202049}, 	-- 2022
					{133693.413, 24167.38493, 6489.202049}, 	-- 2023
					{133393.413, 24467.38493, 6489.202049}, 	-- 2024
					{133093.413, 24767.38493, 6489.202049}		-- 2025
				}
			},
			
			potential = PotentialCSpatialLagRegression
			{
				potentialData =
				{
					-- Region 1
					{
						-- f
						{
							isLog = false,
							const = 0.05266679,
							minReg = 0,
							maxReg = 1,
							ro = 0.9124615,

							betas =
							{
								uc_us = 0.03789872,
								uc_pi = 0.04141921,
								ti = 0.04455667
							}
						},

						-- dto
						{
							isLog = false,
							const = 0.01431553,
							minReg = 0,
							maxReg = 1,
							ro = 0.9019253,

							betas =
							{
								assentamen = 0.0443537,
								uc_us = -0.01454847,
								dist_riobr = -0.00000002262071,
								fertilidad = 0.01701601
							}
						},

						-- outros
						{
							isLog = false,
							const = 0,
							minReg = 0,
							maxReg = 1,
							ro = 0,

							betas =
							{
								
							}
						}
					}
				}
			},
			
			allocation = AllocationCClueLike
			{
				maxDifference = 2000,
				maxIteration = 1000,
				initialElasticity = 0.1,
				minElasticity = 0.001,
				maxElasticity = 1.5,
				complementarLU = "f",
				allocationData =
				{
					-- Region 1
					{
						{static = -1, minValue = 0, maxValue = 1, minChange = 0, maxChange = 1, changeLimiarValue = 1, maxChangeAboveLimiar = 0},	-- f
						{static = -1, minValue = 0, maxValue = 1, minChange = 0, maxChange = 1, changeLimiarValue = 1, maxChangeAboveLimiar = 0},	-- d
						{static = 1, minValue = 0, maxValue = 1, minChange = 0, maxChange = 1, changeLimiarValue = 1, maxChangeAboveLimiar = 0},	-- outros
					}
				}
			},

			save  =
			{
				outputTheme = "Lab07_",
				mode = "multiple",
				saveYears = {2025},
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
				start = Lab07.startTime,
				action = function(event)
								Lab07:run(event)
						  end
			}
		}

		local env_Lab07 = Environment{}
		env_Lab07:add(timer)

		-- ENVIROMMENT EXECUTION
		if Lab07.isCoupled == false then
			local tsave = databaseSave(Lab07)
			env_Lab07:add(tsave)
			env_Lab07:run(Lab07.endTime)
			saveSingleTheme(Lab07, true)
		end

		-- Creating Map for test compare
		local cs2 = CellularSpace{
						file = filePath("test/Lab07_2025.shp", "luccme"),
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

		unitTest:assertSnapshot(mapsResult, "lab07.png")
		
		-- Removing generated files		
		projFile = File("t3mp.tview")
		if(projFile:exists()) then
			projFile:delete()
		end

		projFile = filePath("test/Lab07_2025.shp", "luccme")
		if(projFile:exists()) then
			projFile:delete()
		end
	end,
}