-- @example LuccME Discrete Model using the following components: 
-- DemandPreComputedValues, 
-- PotentialDLogisticRegressionNeighAttract, 
-- AllocationDClueSLike.
return {
	lab14 = function(unitTest)
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
		local Lab14 = LuccMEModel
		{
			name = "Lab14",

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
			
			potential = PotentialDLogisticRegressionNeighAttract
			{
				potentialData =
				{
					-- Region 1
					{
						-- f
						{
							const = 0.01,
							elasticity = 0.5,
							percNeighborsUse = 0.5,

							betas =
							{
								media_decl = -0.0272710076327129,
								dist_area_ = 4.30977432375496,
								dist_br = 3.10319957497883,
								dist_curua = 0.445414024051873,
								dist_rios_ = 47.3556329553235,
								dist_estra = 38.4966894254506
							}
						},

						-- d
						{
							const = 0.01,
							elasticity = 0.5,
							percNeighborsUse = 0.5,

							betas =
							{
								media_decl = 0.0581358851690861,
								dist_area_ = -0.974998890251365,
								dist_br = -2.51650696123426,
								dist_curua = -1.26742746441679,
								dist_rios_ = -40.3646901047482,
								dist_estra = -23.0841140199094
							}
						},

						-- o
						{
							const = 0.01,
							elasticity = 0.5,
							percNeighborsUse = 0.5,

							betas =
							{
								
							}
						}
					}
				}
			},
			
			allocation = AllocationDClueSLike
			{
				maxIteration = 1000,
				factorIteration = 0.0001,
				maxDifference = 500,
				transitionMatrix =
				{
					--Region 1
					{
						{1, 1, 0},
						{0, 1, 0},
						{0, 0, 1}
					}
				}
			},

			save  =
			{
				outputTheme = "Lab14_",
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
				start = Lab14.startTime,
				action = function(event)
								Lab14:run(event)
						  end
			}
		}

		local env_Lab14 = Environment{}
		env_Lab14:add(timer)

		-- ENVIROMMENT EXECUTION
		if Lab14.isCoupled == false then
			local tsave = databaseSave(Lab14)
			env_Lab14:add(tsave)
			env_Lab14:run(Lab14.endTime)
			saveSingleTheme(Lab14, true)
		end

		-- Creating Map for test compare
		local cs2 = CellularSpace{
						file = filePath("test/Lab14_2004.shp", "luccme"),
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
				
		unitTest:assertSnapshot(mapsResult, "lab14.png")

		-- Removing generated files		
		projFile = File("t3mp.tview")
		if(projFile:exists()) then
			projFile:delete()
		end

		projFile = filePath("test/Lab14_2004.shp", "luccme")
		if(projFile:exists()) then
			projFile:delete()
		end
	end,
}