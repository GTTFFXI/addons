local cast = {}

function cast.JA(str)
    windower.send_command(str)
    del = 1.2
end

function cast.MA(str,ta)
    windower.send_command('input /ma "%s" %s':format(str,ta))
    del = settings.delay
end

function cast.song(str,ta,buffs,recasts,JA_WS_lock)
    if not JA_WS_lock and not buffs.nightingale and recasts[109] <= 0 then
        cast.JA('input /ja "Nightingale" <me>')
    elseif not JA_WS_lock and not buffs.troubadour and recasts[110] <= 0 then
        cast.JA('input /ja "Troubadour" <me>')
    elseif not JA_WS_lock and str == settings.marcato and not buffs.marcato and not buffs['soul voice'] and recasts[48] <= 0 then
        cast.JA('input /ja "Marcato" <me>')
    elseif ta ~= '<me>' and not buffs.pianissimo then 
        if not JA_WS_lock and recasts[112] <= 0 then
            cast.JA('input /ja "Pianissimo" <me>')
        end
    else
        cast.MA(str,ta)
    end
end

function cast.check_song(songs,targ,buffs,spell_recasts,recast)
    local maxsongs = get.maxsongs(targ,buffs)
    local song_list = get.song_list(songs,targ,maxsongs)
    for k,song in ipairs(settings.dummy) do
        if base_songs >= k+2 and timers[targ] and table.length(timers[targ]) == maxsongs-k and spell_recasts[get.song(song).id] <= 0 then
            return song
        end
    end
    for buff,num in pairs(song_list) do
        for x = 1,num do
			local song
			if buff == 'carol' then
				song = get.song((get.songs[buff][x]):format(settings['carolElement']))
			else			
				song = get.song(get.songs[buff][x])
			end
            
            if song and spell_recasts[song.id] <= 0 and
            (not timers[targ] or not timers[targ][song.enl] or os.time()-timers[targ][song.enl].ts+recast>0 or 
            (buffs.troubadour and not timers[targ][song.enl].nt) or 
            (buffs['soul voice'] and not timers[targ][song.enl].sv)) then
                return song.enl
            end
        end
    end
    return false
end

return cast
