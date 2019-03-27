local x = os.clock();
--- Save the generated data after the simulation into the database for each year a layer will be created.
-- @arg luccMEModel A LuccME model.
-- @usage --DONTRUN 
-- databaseSave(luccMeModel)
function databaseSave(luccMEModel)
	local saveYears = {}
	local e1 = {}
	local e2 = {}
	local tsave = Timer{}
	
	-- Verify the outputTheme variable
	if (luccMEModel.save.outputTheme == nil) then
		error("outputTheme variable is missing on save parameters", 2)
	end
	
	-- Verify the dates to be saved
	if (luccMEModel.save.saveYears ~= nil) then
		for i = 1, #luccMEModel.save.saveYears, 1 do
			if (luccMEModel.save.saveYears[i] < luccMEModel.startTime or luccMEModel.save.saveYears[i] > luccMEModel.endTime) then
				error(luccMEModel.save.saveYears[i].." is selected to be saved, but it is out of the simulation range. From "..luccMEModel.startTime.." to "..luccMEModel.endTime..".", 2)
			end
		end
	end
	
	-- Check if one of the save year variable is declared 
	if (luccMEModel.save.saveYears == nil and luccMEModel.save.yearly == nil) then
		error("saveYears or yearly variable must be used on save parameters.", 2)
	end
	
	-- Verifies whether the years be to be saved were correctly chosen
	if ((luccMEModel.save.yearly == false) and ((luccMEModel.save.saveYears == nil) or (luccMEModel.save.saveYears[1] == nil))) then
		error("Please set which year of the simulation will be saved. (saveYears variable on save parameters)", 2)
	elseif (luccMEModel.save.yearly == true) then
		for i = 0, (luccMEModel.endTime - luccMEModel.startTime) do
			saveYears[i + 1] = luccMEModel.startTime + i
		end
	else
		saveYears = luccMEModel.save.saveYears
	end

	-- Save
	for i, year in pairs (saveYears) do
		e1 = Event {  start = year,
					  priority = 20,
					  action = function(event)
									if (luccMEModel.save.mode == "multiple") then
										print("\nSaving "..luccMEModel.save.outputTheme..event:getTime()..".")
										luccMEModel.cs:save(luccMEModel.save.outputTheme..event:getTime(), luccMEModel.save.saveAttrs)
									end
									
									return false
								end
					}
		tsave:add(e1)
	end
	
	for year = luccMEModel.startTime + 1, luccMEModel.endTime, 1 do
		e2 = Event {  start = year,
					  priority = 21,
					  action = function(event)
									forEachCell(luccMEModel.cs, function(cell)
																	for j, lu in pairs (luccMEModel.landUseTypes) do
																		if (lu ~= luccMEModel.allocation.landUseNoData) then
																			cell[lu.."_Ext"..year] = cell[lu] * luccMEModel.cs.cellArea
																			cell[lu.."_Area"..year] = cell[lu.."_chpast"] * luccMEModel.cs.cellArea
																		end
																	end
																end
												)
									return false
								 end
					}
		tsave:add(e2)
	end
	
	collectgarbage("collect")
	return tsave
end

--- Save the generated data after the simulation into the database all the data for each year will be created in a single layer.
-- @arg luccMEModel A luccME Model.
-- @usage --DONTRUN
-- saveSingleTheme(luccMeModel)
function saveSingleTheme(luccMEModel)
	local n = 1
	local attrs_inc = {}
	local attrs_ext = {}
	local out = ""
	local change = ""
	
	if (luccMEModel.potential.landUseNoData ~= nil) then
		attrs_inc[n] = "result_nodata"
		attrs_ext[n] = "result_nodata"
		n = n + 1
		forEachCell(luccMEModel.cs, function(cell)
										cell["result_nodata"] = cell[luccMEModel.potential.landUseNoData]
									end
				    )
	end

	for j, lu in pairs (luccMEModel.landUseTypes) do
		if (lu ~= luccMEModel.allocation.landUseNoData and lu ~= luccMEModel.allocation.complementarLU) then
			for year = luccMEModel.startTime + 1, luccMEModel.endTime, 1 do
				out = lu.."_Ext"..year
				change = lu.."_Area"..year
				attrs_ext[n] = out
				attrs_inc[n] = change
				n = n + 1
			end
		end
	end

	io.flush()
	if(luccMEModel.hasAuxiliaryOutputs ~= nill) then
		if (luccMEModel.hasAuxiliaryOutputs) then
			print("\nSaving "..luccMEModel.save.outputTheme.."inc_area_"..luccMEModel.endTime..".")
			luccMEModel.cs:save(luccMEModel.save.outputTheme.."inc_area_"..luccMEModel.endTime, attrs_inc)
			
			print("Saving "..luccMEModel.save.outputTheme.."ext_area_"..luccMEModel.endTime..".")
			luccMEModel.cs:save(luccMEModel.save.outputTheme.."ext_area_"..luccMEModel.endTime, attrs_ext)
		end
	end
	
	-- Calculating execution time
	local sTime = os.clock() - x
	local days = math.floor(sTime / 86400)
	local hours = math.floor(sTime % 86400 / 3600)
	local minutes = math.floor(sTime % 3600 / 60)
	local seconds = math.floor(sTime % 60)
	if seconds < 59 then
		seconds = seconds + 1
	end
    print(string.format("Elapsed time: %.2d:%.2d:%.2d hh:mm:ss", hours,minutes,seconds))
	print("\nEnd of Simulation")
end
