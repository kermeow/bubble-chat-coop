local bubble_texture = get_texture_info("bubble_bg")
---@type NineSlice
local bubble_slice = { left = 48, right = 48, top = 48, bottom = 48 }
local tail_texture = get_texture_info("bubble_tail")

function render_bubble(x, y, w, h, centered, scale)
	if centered then
		x = x - (w / 2) * scale
	end
	render_nine_slice(bubble_texture, x - (18 * scale), y - (18 * scale), (w + 36) * scale, (h + 36) * scale,
		bubble_slice, scale)
end

function render_bubble_with_tail(x, y, w, h, centered, scale)
	if centered then
		x = x - (w / 2) * scale
	end
	render_bubble(x, y, w, h, false, scale)
	djui_hud_render_texture(tail_texture, x + ((w / 2) - 16) * scale, y + math.floor((h - 12) * scale), scale, scale)
end
