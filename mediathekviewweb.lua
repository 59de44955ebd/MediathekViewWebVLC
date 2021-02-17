--[[
 * -- MIT License
 *
 * Copyright (c) 2021 Valentin Schmidt
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 * persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 * FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * -- INSTALL
 *
 * To install, place this file in the following directory, depending on your operating system:
 *
 * a) Install for current user only
 *
 * Windows: %APPDATA%\vlc\lua\extensions
 * Linux: ~/.local/share/vlc/lua/extensions
 * macOS: /Users/<your_name>/Library/Application Support/org.videolan.vlc/lua/extensions
 *
 * b) Install for all users
 *
 * Windows: %ProgramFiles%\VideoLAN\VLC\lua\extensions
 * Linux: /usr/lib/vlc/lua/extensions
 * macOS: /Applications/VLC.app/Contents/MacOS/share/lua/extensions
--]]

require('common')
json = require('dkjson')

CHANNEL_URL = 'https://mediathekviewweb.de/api/channels'
QUERY_URL = 'https://mediathekviewweb.de/api/query?query=%s'

BUF_SIZE = 65536

dlg = nil
channels = nil
title = nil
topic = nil
description = nil
channel = nil
dur_min = nil
dur_max = nil
qual = nil
repl = nil
info = nil
exclude = nil

-- VLC Extension Descriptor
function descriptor()
	return {
		title = 'MediathekViewWeb for VLC';
		version = '0.1';
		author = 'Valentin Schmidt';
		url = 'https://github.com/59de44955ebd/MediathekViewWebVLC';
		description = 'Search for videos in the media libraries of german public TV stations';
		shortdesc = 'MediathekViewWeb';
		capabilities = {"menu"};
	}
end

-- Function triggered when the extension is activated
function activate()
	vlc.msg.dbg('[MediathekViewWeb] Activating')
	show_dialog()
	return true
end

-- Function triggered when the extension is deactivated
function deactivate()
	close()
	vlc.msg.dbg('[MediathekViewWeb] Deactivated')
	return true
end

function menu()
	return {
		"Search",
		"List Livestreams"
	}
end

function trigger_menu(id)
	if id == 1 then
		dlg:show()
	elseif id == 2 then
		get_livestreams()
	end
	collectgarbage()
end

function new_dialog(dtitle)
	dlg = vlc.dialog(dtitle)

	local w = 1
	local row = 0

	row = row +1
	-- column, row, col_span, row_span, width, height
	dlg:add_label('Title:', 1, row, 1, 1)
	title = dlg:add_text_input('', 2, row, w, 1)

	row = row +1
	dlg:add_label('Topic:', 1, row, 1, 1)
	topic = dlg:add_text_input('Kino - Filme', 2, row, w, 1)

	row = row +1
	dlg:add_label('Description:', 1, row, 1, 1)
	description = dlg:add_text_input('', 2, row, w, 1)

	row = row +1
	dlg:add_label('Channel:', 1, row, 1, 1)
	channel = dlg:add_dropdown(2, row, 1, 1)
	channel:add_value('', '')
	get_channels()

	row = row +1
	dlg:add_label('Min. Duration (sec.):', 1, row, 1, 1)
	dur_min = dlg:add_text_input('3600', 2, row, 1, 1)

	row = row +1
	dlg:add_label('Max. Duration (sec.):', 1, row, 1, 1)
	dur_max = dlg:add_text_input('', 2, row, 1, 1)

	row = row +1
	dlg:add_label('Preferred Quality:', 1, row, 1, 1)
	qual = dlg:add_dropdown(2, row, 1, 1)
	qual:add_value('Medium', 0)
	qual:add_value('Low', 1)
	qual:add_value('High', 2)

	row = row +1
	dlg:add_label('Exclude:', 1, row, 1, 1)
	exclude = dlg:add_text_input('', 2, row, w, 1)

	row = row +1
	repl = dlg:add_check_box('Replace existing playlist', true, 1, row, 1 + w, 1)

	row = row +1
	dlg:add_label(' ', 1, row, 2, 1) -- just as visual separator

	row = row +1
	button_search = dlg:add_button('Search', click_search, 1, row, 1, 1)

	row = row +1
	info = dlg:add_label(' ', 1, row, 2, 1)
end

function show_dialog()
	if dlg == nil then
		new_dialog('MediathekViewWeb')
	end
	return true
end

function get_livestreams()
	local queries = {}
	table.insert(queries, {fields = {'topic'}, query = 'Livestream'})
	table.insert(queries, {fields = {'title'}, query = 'Livestream'})
	local q = {
		queries = queries,
		size = 500
	}
	local data = vlc.stream(QUERY_URL:format(vlc.strings.encode_uri_component(json.encode(q))))
	local res = ''
	local s = data:read(BUF_SIZE)
	while (s ~= nil) do
		res = res..s
		s = data:read(BUF_SIZE)
	end
	res = json.decode(res)
	vlc.playlist.clear()
	local tmp = {}
	local results = res['result']['results']
	for _, track in ipairs(results) do
		tmp[track['title']] = {
			name = track['title']..' ['..track['channel']..']',
			path = track['url_video'],
			url = track['url_website']
		}
	end
	local pl = {}
	for k,v in common.pairs_sorted(tmp) do
		table.insert(pl, v)
	end
	vlc.playlist.enqueue(pl)
end

function click_search()
	local v
	local queries = {}

	v = topic:get_text()
	if v ~= '' then
		table.insert(queries, {fields = {'topic'}, query = v})
	end

	v = title:get_text()
	if v ~= '' then
		table.insert(queries, {fields = {'title'}, query = v})
	end

	v = description:get_text()
	if v ~= '' then
		table.insert(queries, {fields = {'description'}, query = v})
	end

	v = channel:get_value()
	if v ~= 0 then
		table.insert(queries, {fields = {'channel'}, query = channels[v]})
	end

	local q = {
		queries = queries,
		sortBy = 'timestamp',
		sortOrder = 'desc',
		future = 0,
		offset = 0,
		size = 500
	}

	v = dur_min:get_text()
	if v ~= '' then
		q['duration_min'] = tonumber(v)
	end

	v = dur_max:get_text()
	if v ~= '' then
		q['duration_max'] = tonumber(v)
	end

	-- make API request
	local data = vlc.stream(QUERY_URL:format(vlc.strings.encode_uri_component(json.encode(q))))
	local res = ''
	local s = data:read(BUF_SIZE)
	while (s ~= nil) do
		res = res..s
		s = data:read(BUF_SIZE)
	end
	res = json.decode(res)

	if repl:get_checked() then
		vlc.playlist.clear()
	end

	local filters = {}
	v = exclude:get_text()
	if v ~= '' then
		for f, s in v:gmatch('([^|]*)(|?)') do
			if f ~= '' then table.insert(filters, f) end
			if s == '' then break end
		end
	end

	local p
	local pl = {}
	local cnt = 0
	local results = res['result']['results']
	v = qual:get_value()
	for _, track in ipairs(results) do
		-- ignore items with title or topic that match exclude filters
		filtered = false
		for _, f in ipairs(filters) do
			if track['title']:find(f) ~= nil or track['topic']:find(f) ~= nil then
				filtered = true
				break
			end
		end
		if not filtered then
			if v == 1 and track['url_video_low'] ~= nil and track['url_video_low'] ~= '' then
				p = track['url_video_low']
			elseif v == 2 and track['url_video_hd'] ~= nil and track['url_video_hd'] ~= '' then
				p = track['url_video_hd']
			else
				p = track['url_video']
			end
			table.insert(pl, {
				name = track['title']..' ['..track['channel']..']',
				path = p,
				description = track['description'],
				url = track['url_website']
			})
			cnt = cnt + 1
		end
	end

	-- add results to playlist
	vlc.playlist.enqueue(pl)

	-- show number of results
	info:set_text(tostring(cnt)..' results added to playlist')
end

function get_channels()
	local data = vlc.stream(CHANNEL_URL)
	local res = ''
	local s = data:read(BUF_SIZE)
	while (s ~= nil) do
		res = res..s
		s = data:read(BUF_SIZE)
	end
	res = json.decode(res)
	channels = res['channels']
	table.sort(channels)
	for k, v in ipairs(channels) do
		channel:add_value(v, k)
	end
end
