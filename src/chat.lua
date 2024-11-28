local _time = get_time()
local current_time = _time
local frames = 0
local function update_time()
	local new_time = get_time()
	if new_time > _time then
		frames = 0
		_time = new_time
	end
	frames = frames + 1

	current_time = _time + (frames / 30)
end
hook_event(HOOK_UPDATE, update_time)

---@class BubbleMessage
---@field sender_index integer
---@field timestamp number
---@field time_to_live number
---@field message string
---@field message_s string
---@field message_l string[]
---@field message_w number

local bubbles = {}
for i = 0, MAX_PLAYERS do
	bubbles[i] = {}
end

---@param sender MarioState
---@param message string
local function on_chat_message(sender, message)
	local bubble_list = bubbles[sender.playerIndex]
	if #bubble_list == 3 then
		table.remove(bubble_list, 1)
	end

	local stripped_message = string.strip_colors(message)

	djui_hud_set_resolution(RESOLUTION_DJUI)
	djui_hud_set_font(FONT_ALIASED)

	local total_max_width = MAX_BUBBLE_WIDTH - BUBBLE_WIDTH_PADDING

	local lines = { "" }
	local current_line = 1

	local words = stripped_message:split(" ")

	for i, word in next, words do
		local working_line = lines[current_line]
		if i ~= 1 then working_line = working_line .. " " end
		working_line = working_line .. word

		local word_width = djui_hud_measure_text(word) * TEXT_SIZE
		if word_width >= total_max_width then
			working_line = lines[current_line]
			if i ~= 1 then working_line = working_line .. " " end
			for char_index = 1, word:len() do
				local character = word:sub(char_index, char_index)
				working_line = working_line .. character

				local line_width = djui_hud_measure_text(working_line) * TEXT_SIZE
				if line_width > total_max_width then
					current_line = current_line + 1
					working_line = character
				end
				lines[current_line] = working_line
			end
		end

		local line_width = djui_hud_measure_text(working_line) * TEXT_SIZE
		if line_width > total_max_width then
			current_line = current_line + 1
			working_line = word
		end
		lines[current_line] = working_line
	end

	local max_line_width = 0
	for i, line in next, lines do
		max_line_width = math.max(max_line_width, djui_hud_measure_text(line) * TEXT_SIZE)
	end

	---@type BubbleMessage
	local bubble_message = {
		sender_index = sender.playerIndex,
		timestamp = current_time,
		time_to_live = fif(sender.playerIndex == 0, 8, 12),
		message = message,
		message_s = stripped_message,
		message_l = lines,
		message_w = max_line_width
	}
	if sender.playerIndex == 0 then
		bubble_message.time_to_live = 8
	end
	table.insert(bubble_list, bubble_message)
end
hook_event(HOOK_ON_CHAT_MESSAGE, on_chat_message)

---@param origin Vec3f
---@param bubble BubbleMessage
---@param distance number
---@param tail? boolean
local function render_chat_bubble(origin, bubble, distance, tail)
	local scale = 1
	if distance > 500 then
		scale = math.sqrt(math.max(0.125, math.min(1, 500 / distance)))
	end

	local difference = current_time - bubble.timestamp
	local alpha = 1
	local time_to_fade = bubble.time_to_live - 1
	if difference > time_to_fade then
		alpha = math.max(0, 1 - (difference - time_to_fade))
	end

	tail = tail == true

	local x = math.floor(origin.x + 0.5)
	local y = math.floor(origin.y + 0.5)

	local lines = bubble.message_l

	local bubble_width = bubble.message_w + BUBBLE_WIDTH_PADDING * 2
	local bubble_height = TEXT_LINE_HEIGHT * #lines

	local text_alpha = 1
	if tail and difference <= 0.5 then
		-- this shit is so ass *holds back tears* (looks good though)
		bubble_width = bubble_width * (math.min(1, (difference + 0.6) / 0.7) ^ 2)
		bubble_height = bubble_height * (math.min(1, (difference + 0.3) / 0.4) ^ 2)
		text_alpha = (math.min(1, (difference + 0.1) / 0.3) ^ 2)
	end
	bubble_height = bubble_height + 48

	y = y - bubble_height * scale

	djui_hud_set_color(255, 255, 255, alpha * 255)
	if tail then
		render_bubble_with_tail(x, y, bubble_width, bubble_height, true, scale)
	else
		render_bubble(x, y, bubble_width, bubble_height, true, scale)
	end

	djui_hud_set_font(FONT_ALIASED)
	djui_hud_set_color(0, 0, 0, text_alpha * alpha * 255)
	for i, line in next, lines do
		local line_width = djui_hud_measure_text(line) * TEXT_SIZE * scale
		djui_hud_print_text(line, x - line_width / 2, y + (12 * scale), TEXT_SIZE * scale)
		y = y + (TEXT_LINE_HEIGHT * scale)
	end

	return bubble_height * scale
end

local function render_bubbles()
	local render_indices = { 0 } -- always render self

	-- Purge non-existent players & make list of marios for rendering
	local local_net_player = gNetworkPlayers[0]
	for i = 1, MAX_PLAYERS do
		local net_player = gNetworkPlayers[i]
		local bubble_list = bubbles[i]
		if net_player ~= nil and net_player.connected then
			if net_player.currActNum == local_net_player.currActNum and
				net_player.currAreaIndex == local_net_player.currAreaIndex and
				net_player.currLevelNum == local_net_player.currLevelNum then
				table.insert(render_indices, i)
			end
		else
			if #bubble_list > 0 then
				bubbles[i] = {}
			end
		end
	end

	-- Sort by distance descending
	local lakitu_position = gLakituState.curPos
	table.sort(render_indices, function(a, b)
		local mario_a = gMarioStates[a]
		local distance_a = vec3f_dist(mario_a.pos, lakitu_position)
		local mario_b = gMarioStates[b]
		local distance_b = vec3f_dist(mario_b.pos, lakitu_position)
		return distance_a > distance_b
	end)

	-- Render bubbles
	local djui_aspect_x, djui_aspect_y
	do
		djui_hud_set_resolution(RESOLUTION_N64)
		local n64_w = djui_hud_get_screen_width()
		local n64_h = djui_hud_get_screen_height()
		djui_hud_set_resolution(RESOLUTION_DJUI)
		local djui_w = djui_hud_get_screen_width()
		local djui_h = djui_hud_get_screen_height()
		djui_aspect_x = djui_w / n64_w
		djui_aspect_y = djui_h / n64_h
	end
	for _, i in next, render_indices do
		local mario = gMarioStates[i]

		local distance = vec3f_dist(mario.pos, lakitu_position)

		local head_pos = mario.marioBodyState.headPos
		local gfx_pos = mario.marioObj.header.gfx.pos
		local origin = { x = gfx_pos.x, y = head_pos.y + 80, z = gfx_pos.z }

		--- djui_hud_world_pos_to_screen_pos behaves weirdly if I don't do this :(
		djui_hud_set_resolution(RESOLUTION_N64)
		djui_hud_world_pos_to_screen_pos(origin, origin)

		if origin.z < 0 then
			djui_hud_set_resolution(RESOLUTION_DJUI)
			origin = { x = origin.x * djui_aspect_x, y = origin.y * djui_aspect_y, z = origin.z }

			local bubble_list = bubbles[i]
			while #bubble_list > 0 do
				if current_time - bubble_list[1].timestamp < 12 then
					break
				end
				table.remove(bubble_list, 1)
			end
			if #bubble_list > 0 then
				for i = #bubble_list, 1, -1 do
					origin.y = origin.y - render_chat_bubble(origin, bubble_list[i], distance, i == #bubble_list)
				end
			end
		end
	end
end
hook_event(HOOK_ON_HUD_RENDER, render_bubbles)
