---@class NineSlice
---@field left integer
---@field right integer
---@field top integer
---@field bottom integer

---@param texture TextureInfo
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param center NineSlice
---@param texture_scale? number
function render_nine_slice(texture, x, y, w, h, center, texture_scale)
	texture_scale = texture_scale or 1

	local scaled_center = {
		left = center.left * texture_scale,
		right = center.right * texture_scale,
		top = center.top * texture_scale,
		bottom = center.bottom * texture_scale,
	}

	local center_x, center_y = x + scaled_center.left, y + scaled_center.top
	local center_w = w - (scaled_center.left + scaled_center.right)
	local center_h = h - (scaled_center.top + scaled_center.bottom)
	local center_tile_x, center_tile_y = center.left, center.top
	local center_tile_w = texture.width - (center.left + center.right)
	local center_tile_h = texture.height - (center.top + center.bottom)

	-- Render center
	djui_hud_render_texture_tile(texture,
		center_x, center_y,
		center_w / center_tile_w, center_h / center_tile_h,
		center_tile_x, center_tile_y,
		center_tile_w, center_tile_h
	)

	local top_h = scaled_center.top
	local top_tile_h = center.top

	local bottom_y = y + h - scaled_center.bottom
	local bottom_h = scaled_center.bottom
	local bottom_tile_y = texture.height - center.bottom
	local bottom_tile_h = center.bottom

	-- Render left
	local left_w = scaled_center.left
	local left_tile_w = center.left
	djui_hud_render_texture_tile(texture,
		x, y,
		left_w / left_tile_w, top_h / top_tile_h,
		0, 0,
		left_tile_w, top_tile_h
	)
	local left_center_aspect = center_tile_h / left_tile_w
	djui_hud_render_texture_tile(texture,
		x, center_y,
		left_center_aspect * left_w / left_tile_w, center_h / center_tile_h,
		0, center_tile_y,
		left_tile_w, center_tile_h
	)
	djui_hud_render_texture_tile(texture,
		x, bottom_y,
		left_w / left_tile_w, bottom_h / bottom_tile_h,
		0, bottom_tile_y,
		left_tile_w, bottom_tile_h
	)

	-- Render middle
	local top_center_aspect = top_tile_h / center_tile_w
	djui_hud_render_texture_tile(texture,
		center_x, y,
		top_center_aspect * center_w / center_tile_w, top_h / top_tile_h,
		center_tile_x, 0,
		center_tile_w, top_tile_h
	)
	local bottom_center_aspect = bottom_tile_h / center_tile_w
	djui_hud_render_texture_tile(texture,
		center_x, bottom_y,
		bottom_center_aspect * center_w / center_tile_w, bottom_h / bottom_tile_h,
		center_tile_x, bottom_tile_y,
		center_tile_w, bottom_tile_h
	)

	-- Render right
	local right_x = x + w - scaled_center.right
	local right_w = scaled_center.right
	local right_tile_x = texture.width - center.right
	local right_tile_w = center.right
	djui_hud_render_texture_tile(texture,
		right_x, y,
		right_w / right_tile_w, top_h / top_tile_h,
		right_tile_x, 0,
		right_tile_w, top_tile_h
	)
	local right_center_aspect = center_tile_h / right_tile_w
	djui_hud_render_texture_tile(texture,
		right_x, center_y,
		right_center_aspect * right_w / right_tile_w, center_h / center_tile_h,
		right_tile_x, center_tile_y,
		right_tile_w, center_tile_h
	)
	djui_hud_render_texture_tile(texture,
		right_x, bottom_y,
		right_w / right_tile_w, bottom_h / bottom_tile_h,
		right_tile_x, bottom_tile_y,
		right_tile_w, bottom_tile_h
	)
end
