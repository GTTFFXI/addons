require 'luau'

_addon.name = 'ElementalHelper'
_addon.version = '1.0'
_addon.author = 'Ameilia'
_addon.commands = {'eh','elementalhelper','elehelper'}

elements = {'Stone','Water','Aero','Fire','Blizzard','Thunder'}
helices = {'Geo','Hydro','Anemo','Pyro','Cryo','Iono'}
storms = {'Sand','Rain','Wind','Fire','Hail','Thunder'}
gas = {'Stone','Water','Aero','Fira','Blizza','Thunda'}
sc1 = {'Aero','Stone','Stone','Stone','Water','Water'}
sc2 = {'Stone','Water','Aero','Fire','Blizzard','Thunder'}

eleIndex = 1

function handle_spell(spelltype, cmdParams)
	local target = '<t>'
    local tier = ''
	local spellstr = elements[eleIndex]

	if cmdParams[1] then
        tier = cmdParams[1]:upper()	
		if(tier == 'I') then
			tier = ''
		end
    end
	
	if(S{'ga','ja'}:contains(spelltype)) then
		spellstr = gas[eleIndex] .. spelltype
	elseif spelltype == 'helix' then
		spellstr = helices[eleIndex] .. spelltype
	elseif spelltype == 'storm' then
		spellstr = storms[eleIndex] .. spelltype
		target = '<stpt>'
	elseif spelltype == 'sc1' then
		spellstr = sc1[eleIndex]
		windower.send_command('input /p '..elements[eleIndex]..' Skillchain #1 (Fast>Fast)')
	elseif spelltype == 'sc2' then
		spellstr = sc2[eleIndex]
		windower.send_command('input /p '..elements[eleIndex]..' Skillchain #2 (Fast)')
	end
    	
	local spell = spellstr..' '..tier	
	windower.send_command('@input /ma "'..spell..'" '..target)
end

windower.register_event('addon command',function(...)
    local args = {...}
    local first = table.remove(args,1):lower()

	if first then
		if first == 'cycle' then
			eleIndex = (eleIndex % #elements) + 1
			report_nuke()
			windower.send_command('ank setnuke '..elements[eleIndex])
		elseif S{'storm','nuke','helix','ga','ja','sc1','sc2'}:contains(first) then
			handle_spell(first, args)
		elseif S{'unload','reload'}:contains(first) then
			windower.send_command('lua %s %s':format(first, _addon.name))
		elseif first == 'set' then
			local found = false
			local el = args[1]:lower()
			for i,v in ipairs(elements) do
				if v:lower() == el then
					eleIndex = i
					found = true
				end
			end
			if found then
				report_nuke()
			else 
				windower.add_to_chat(39, 'Could not find Element '..args[1])
			end
		elseif first == 'help' then
			print_help()
		else
			windower.add_to_chat(39, 'Error: Unknown Command')
		end
	end
end)

windower.register_event('load', function()
	windower.add_to_chat(50, 'Welcome to ElementalHelper')
	report_nuke()
end)

function report_nuke()
	windower.add_to_chat(50, 'ElementalHelper Element: '..elements[eleIndex])
end

function print_help()
	windower.add_to_chat(50, 'ElementalHelper usage (//eh):')
	windower.add_to_chat(50, '   cycle - Cycles the element')
	windower.add_to_chat(50, '   set (element) - Sets the element directly')
	windower.add_to_chat(50, '   nuke (I,II,III,IV,V) - Cast (element) (tier)')
	windower.add_to_chat(50, '   ga (I,II,III) - Cast (element)ga (tier)')
	windower.add_to_chat(50, '   ja - Cast (element)ja')
	windower.add_to_chat(50, '   helix (I,II) - Cast (element)helix (tier)')
	windower.add_to_chat(50, '   storm (I,II) - Cast (element)storm (tier)')
	windower.add_to_chat(50, '   sc1 - Open SCH tier1 skillchain for (element)')
	windower.add_to_chat(50, '   sc2 - Close SCH tier1 skillchain for (element)')
end
