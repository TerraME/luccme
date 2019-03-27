-- @example LuccME Discrete Model using the following components: 
-- DemandComputeThreeDates, 
-- PotentialDLogisticRegression, 
-- AllocationDClueSLike.
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
		local Lab17 = LuccMEModel
		{
			name = "Lab17",

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
			demand = DemandComputeThreeDates
			{
				middleYearForInterpolation = 2004,
				middleLandUseTypesForInterpolation = {"f04", "d04", "o"},
				finalYearForInterpolation = 2007,
				finalLandUseTypesForInterpolation = {"f07", "d07", "o"},
			},
			
			potential = PotentialDLogisticRegression
			{
				potentialData =
				{
					-- Region 1
					{
						-- f
						{
							const = -2.34187976925989,
							elasticity = 0.0,

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
							const = -0.100351497277102,
							elasticity = 0.6,

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
				maxDifference = 300,
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
				outputTheme = "Lab17_",
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
				start = Lab17.startTime,
				action = function(event)
								Lab17:run(event)
						  end
			}
		}

		local env_Lab17 = Environment{}
		env_Lab17:add(timer)

		-- ENVIROMMENT EXECUTION
		if Lab17.isCoupled == false then
			local tsave = databaseSave(Lab17)
			env_Lab17:add(tsave)
			env_Lab17:run(Lab17.endTime)
			saveSingleTheme(Lab17, true)
		end

		-- Creating Map for test compare
		local cs2 = CellularSpace{
						file = filePath("test/Lab17_2004.shp", "luccme"),
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

		unitTest:assertSnapshot(mapsResult, "lab17.png")		
		
		-- Removing generated files		
		projFile = File("t3mp.tview")
		if(projFile:exists()) then
			projFile:delete()
		end

		projFile = filePath("test/Lab17_2004.shp", "luccme")
		if(projFile:exists()) then
			projFile:delete()
		end
	end,
}