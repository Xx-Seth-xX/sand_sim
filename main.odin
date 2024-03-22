package main

import "core:c"
import "core:mem"
import "core:math/rand"
import "core:fmt"
import ray "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 800
WINDOW_TITLE :: "Sand Sim"

GRID_WIDTH :: 300
GRID_HEIGHT :: 300
GRID :: [GRID_WIDTH * GRID_HEIGHT]ray.Color

grid_buff1: GRID
// grid_buff2: GRID
grid := &grid_buff1
// back_grid := &grid_buff2


grid_update :: proc() {
	// mem.zero_slice(back_grid[:])
	for y := GRID_HEIGHT - 1; y > 0; y -= 1 {
		for x := 0; x < GRID_WIDTH; x += 1 {
			this := grid[x + GRID_WIDTH * y]
			right: ray.Color
			left: ray.Color
			upper := grid[x + GRID_WIDTH * (y - 1)]
			upper_right: ray.Color
			upper_left: ray.Color
			if x > 0 {
				upper_left = grid[x - 1 + GRID_WIDTH * (y - 1)]
				left = grid[x - 1 + GRID_WIDTH * y]
			}
			if x < GRID_WIDTH - 1 {
				upper_right = grid[x + 1 + GRID_WIDTH * (y - 1)]
				right = grid[x + 1 + GRID_WIDTH * y]
			}
			if this == 0 {
				switch {
				case upper != 0:
					grid[x + GRID_WIDTH * (y - 1)] = 0
					grid[x + GRID_WIDTH * y] = upper
				case upper_left != 0 && left != 0:
					grid[x - 1 + GRID_WIDTH * (y - 1)] = 0
					grid[x + GRID_WIDTH * y] = upper_left
				case upper_right != 0 && right != 0:
					grid[x + 1 + GRID_WIDTH * (y - 1)] = 0
					grid[x + GRID_WIDTH * y] = upper_right
				}
			}
		}
	}
	// temp := grid
	// grid = back_grid
	// back_grid = temp
}

window_to_grid :: proc(screen_pos: ray.Vector2) -> ray.Vector2 {
	x_ratio :: f32(GRID_WIDTH) / WINDOW_WIDTH
	y_ratio :: f32(GRID_HEIGHT) / WINDOW_HEIGHT 

	return ray.Vector2{screen_pos.x * x_ratio, screen_pos.y * y_ratio}
}

main :: proc() {
	ray.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer ray.CloseWindow()

	grid_tex := ray.Texture {
		width   = GRID_WIDTH,
		height  = GRID_HEIGHT,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}
	grid_tex.id = ray.rlLoadTexture(
		&grid,
		grid_tex.width,
		grid_tex.height,
		c.int(grid_tex.format),
		c.int(grid_tex.mipmaps),
	)
	defer ray.UnloadTexture(grid_tex)

	current_hue : f32 = 0
	ray.UpdateTexture(grid_tex, grid)

	ray.SetTargetFPS(60)

	for !ray.WindowShouldClose() {

		mouse_pos := window_to_grid(ray.GetMousePosition())

		if ray.IsMouseButtonDown(.LEFT) {
			pos := [2]int{int(mouse_pos.x), int(mouse_pos.y)}
			for x in (pos.x - 3)..=(pos.x + 3) {
				for y in (pos.y - 3)..=(pos.y + 3) {
					if x < 0 || x >= GRID_WIDTH || y < 0 || y >= GRID_HEIGHT {
						continue
					}
					if grid[x + GRID_WIDTH * y] == 0 && rand.float32() <= 0.5 {
						grid[x + GRID_WIDTH * y] = ray.ColorFromHSV(current_hue, 1, 1) 
					}
				}
			}
			current_hue += 1.0
			if current_hue >= 360 {
				current_hue -= 360
			}
		}
		
		grid_update()
		ray.UpdateTexture(grid_tex, grid)

		ray.BeginDrawing()
		ray.ClearBackground(ray.BLACK)

		ray.DrawTexturePro(
			grid_tex,
			ray.Rectangle{0, 0, GRID_WIDTH, GRID_HEIGHT},
			ray.Rectangle{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT},
			ray.Vector2{0, 0},
			0,
			ray.WHITE,
		)

		ray.EndDrawing()
	}
}
