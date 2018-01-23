_addon.name = 'AutoSkillchain'
_addon.author = 'Ameilia'
_addon.commands = {'autosc','asc'}
_addon.version = '0.1.0'
_addon.lastUpdate = '2017.05.08'

require('luau')
require('lor/lor_utils')
files = require('files')
_libs.lor.req('all')
_libs.lor.debug = false

local rarr = string.char(129,168)

local hps, mobs
local enabled = false
local ws_cmd = ''
local wsDelay = 2.5
local chains = LT{
	['SAM'] = LT{
		{
			['name'] = 'tier2',
			['repeat'] = true,
			['ws'] = L{'Tachi: Rana','Tachi: Shoha','Tachi: Fudo','Tachi: Kasha'}
		},
		{
			['name'] = 'fudo',
			['repeat'] = true,
			['ws'] = L{'Tachi: Fudo','Tachi: Fudo'}
		},
		{
			['name'] = 'jinpu',
			['repeat'] = true,
			['ws'] = L{'Tachi: Jinpu','Tachi: Jinpu'}
		},
		{
			['name'] = 'distortion',
			['repeat'] = false,
			['ws'] = L{'Tachi: Enpi','Tachi: Enpi'}
		},
		{
			['name'] = 'double light',
			['repeat'] = false,
			['ws'] = L{'Tachi: Fudo','Tachi: Kasha','Tachi: Shoha','Tachi: Fudo'}
		},
		{
			['name'] = 'radiance',
			['repeat'] = true,
			['ws'] = L{'Tachi: Shoha','Tachi: Gekko','Tachi: Kasha','Tachi: Shoha','Tachi: Fudo'}
		},
		{
			['name'] = 'shoha',
			['repeat'] = true,
			['ws'] = L{'Tachi: Shoha','Tachi: Shoha'}
		}
	},
	['DRG'] = LT{
		{
			['name'] = 'tier2',
			['repeat'] = true,
			['ws'] = L{'Stardiver','Camlann\'s Torment','Geirskogul','Drakesbane'}
		},
		{
			['name'] = 'darkness',
			['repeat'] = true,
			['ws'] = L{'Geirskogul','Stardiver'}
		},
		{
			['name'] = 'light',
			['repeat'] = true,
			['ws'] = L{'Geirskogul','Camlann\'s Torment'}
		},
		{
			['name'] = 'double light',
			['repeat'] = false,
			['ws'] = L{'Stardiver','Camlann\'s Torment','Drakesbane','Camlann\'s Torment'}
		},
		{
			['name'] = 'long double light',
			['repeat'] = false,
			['ws'] = L{'Stardiver','Camlann\'s Torment','Geirskogul','Drakesbane','Camlann\'s Torment','Camlann\'s Torment'}
		}
	},
	['DRK'] = LT{
		{
			['name'] = 'light',
			['repeat'] = true,
			['ws'] = L{'Scourge','Torcleaver'}
		},
		{
			['name'] = 'double light',
			['repeat'] = true,
			['ws'] = L{'Resolution','Torcleaver','Scourge','Resolution','Torcleaver'}
		},
		{
			['name'] = 'darkness',
			['repeat'] = true,
			['ws'] = L{'Entropy','Cross Reaper'}
		},
		{
			['name'] = 'double darkness',
			['repeat'] = false,
			['ws'] = L{'Insurgency','Entropy','Cross Reaper','Quietus'}
		},
		{
			['name'] = 'umbra',
			['repeat'] = true,
			['ws'] = L{'Insurgency','Entropy','Cross Reaper','Entropy'}
		}
	}
}

local player = windower.ffxi.get_player()
local job = player.main_job
local selected_chain_index = 1
local chain_index = 1
local activeChain = chains[job][1]
local chain_name = activeChain['name']


windower.register_event('addon command', function (command,...)
	command = command and command:lower() or 'help'
	local args = T{...}
	local arg_str = windower.convert_auto_trans(' ':join(args))
	local player = windower.ffxi.get_player()
	local job = player.main_job
	
	if S{'reload','unload'}:contains(command) then
		windower.send_command('lua %s %s':format(command, _addon.name))
	elseif S{'enable','on','start'}:contains(command) then
		enabled = true
		chain_index = 1
		print_status()
	elseif S{'disable','off','stop'}:contains(command) then
		enabled = false
		print_status()
	elseif command == 'toggle' then
		enabled = not enabled
		chain_index = 1
		print_status()
	elseif command == 'mobs' then
		pprint_tiered(mobs)
	elseif command == 'status' then
		print_status()
	elseif command == 'cycle_chain' then
		selected_chain_index = (selected_chain_index % #chains[job]) + 1
		set_chain(selected_chain_index)
	elseif S{'help','--help'}:contains(command) then
		print_help()
	elseif command == 'info' then
		if not _libs.lor.exec then
			atc(3,'Unable to parse info.  Windower/addons/libs/lor/lor_exec.lua was unable to be loaded.')
			atc(3,'If you would like to use this function, please visit https://github.com/lorand-ffxi/lor_libs to download it.')
			return
		end
		local cmd = args[1]     --Take the first element as the command
		table.remove(args, 1)   --Remove the first from the list of args
		_libs.lor.exec.process_input(cmd, args)
	else
		atc('Error: Unknown command')
	end
end)


windower.register_event('load', function()
	if not _libs.lor then
		windower.add_to_chat(39,'ERROR: .../Windower/addons/libs/lor/ not found! Please download: https://github.com/lorand-ffxi/lor_libs')
	end
	atcc(262, 'Welcome to AutoSkillChain!')
	autowsLastCheck = os.clock()
	
	windower.send_command('unbind ^k')
	windower.send_command('unbind !k')
	windower.send_command('bind ^k asc toggle')
	windower.send_command('bind !k asc cycle_chain')
end)


windower.register_event('logout', function()
	windower.send_command('lua unload autoskillchain')
end)


windower.register_event('zone change', function(new_id, old_id)
	autowsLastCheck = os.clock() + 15
end)


windower.register_event('job change', function()
	enabled = false
end)


windower.register_event('prerender', function()
	if enabled then
		local now = os.clock()
		if (now - autowsLastCheck) >= wsDelay then
			local player = windower.ffxi.get_player()
			local mob = windower.ffxi.get_mob_by_target()
			if (player ~= nil) and (player.status == 1) and (mob ~= nil) then
				if player.vitals.tp > 999 then
					handle_chain()
				end
			end
			autowsLastCheck = now
		end
	end
end)

function set_chain(chindex)
	local player = windower.ffxi.get_player()
	local job = player.main_job
	if chindex <= #chains[job] then
		chain_index = 1
		activeChain = chains[job][chindex]
		chain_name = activeChain['name']
	end
	print_status()
end
	
function handle_chain()
	local stop = false
	if chain_index == #activeChain['ws'] and not activeChain['repeat'] then
		stop = true
	end	
	
	local ws = activeChain['ws'][chain_index]
	--atcc(262, 'AutoSkillChain would perform '..ws)
	windower.send_command('input /ws %s <t>':format(ws))
	chain_index = (chain_index % #activeChain['ws']) + 1
	
	if stop then
		enabled = false
		atcc(17, 'Reached the end of the chain. Stopping AutoSC.')
	end
end

function print_status()
	local power = enabled and 'ON' or 'OFF'
	local msg = '[AutoSC: %s] %s ':format(power, chain_name)
	if enabled then
		msg = msg..rarr..' '..activeChain['ws']:tostring()
	end
	
	if activeChain['repeat'] then
		msg = msg..' REPEATING'
	end

	atcc(50, msg)
end

function print_help()
	local help = T{
		['[on|off|toggle]'] = 'Enable / disable AutoSkillchain',
		['cycle_chain'] = 'Cycle which skillchain will be attempted',
	}
	--local mwwidth = max(unpack(map(string.wlen, table.keys(help))))
	local mwwidth = col_width(help:keys())
	atcc(262, 'AutoSkillChain commands:')
	for cmd,desc in opairs(help) do
		atc(cmd:rpad(' ', mwwidth):colorize(263), desc:colorize(1))
	end
end
