const std = @import("std");
const log = std.log;
const testing = std.testing;
const INPUT = @embedFile("./input.txt");

pub const std_options = struct {
	pub const log_level = .info;
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
	defer std.debug.assert(gpa.deinit() == .ok);
	const allocator = gpa.allocator();

	log.info("first: {}", .{ solve_1(INPUT) });
	log.info("second: {}", .{ try solve_2(allocator, INPUT) });
}

fn solve_1(input: []const u8) u64 {
	var it = GridIterator.init(input);
	while (it.next()) |_| {
	}

	return @divExact(it.count, 2);
}

test "solve_1 test input 1" {
	const input =
		\\-L|F7
		\\7S-7|
		\\L|7||
		\\-L-J|
		\\L|-JF
		\\
	;
	try testing.expectEqual(@as(u64, 4), solve_1(input));
}

test "solve_1 test input 2" {
	const input =
		\\7-F7-
		\\.FJ|7
		\\SJLL7
		\\|F--J
		\\LJ.LJ
		\\
	;
	try testing.expectEqual(@as(u64, 8), solve_1(input));
}

test "solve_1 puzzle input" {
	try testing.expectEqual(@as(u64, 6956), solve_1(INPUT));
}

fn solve_2(allocator: std.mem.Allocator, input: []const u8) !u64 {
	var it = GridIterator.init(input);

	const Cell = struct {
		x: usize,
		y: usize,
		slip: bool,
		visited: bool,
		enclosed: bool,
	};

	const width = it.width_grid * 2 - 1;
	const height = it.height * 2 - 1;
	var grid = try allocator.alloc(Cell, width * height);
	defer allocator.free(grid);
	for (0..height) |y| {
		for (0..width) |x| {
			grid[y * width + x] = .{
				.x = x,
				.y = y,
				.slip = x % 2 == 1 or y % 2 == 1,
				.visited = false,
				.enclosed = false,
			};
		}
	}
	while (it.next()) |pipe| {
		const x = pipe.x * 2;
		const y = pipe.y * 2;
		grid[y * width + x].visited = true;

		const slip_index = switch (pipe.direction) {
			.north => (y - 1) * width + x,
			.south => (y + 1) * width + x,
			.west => y * width + (x - 1),
			.east => y * width + (x + 1),
		};
		grid[slip_index].visited = true;
	}

	var flood_list = try std.ArrayList(usize).initCapacity(allocator, 8);
	defer flood_list.deinit();

	for (grid) |*start_cell| {
		if (start_cell.visited) {
			continue;
		}

		flood_list.clearRetainingCapacity();
		try flood_list.append(start_cell.y * width + start_cell.x);
		start_cell.*.visited = true;

		var is_enclosed = true;
		var i: usize = 0;
		while (i < flood_list.items.len) : (i += 1) {
			const cell = grid[flood_list.items[i]];

			if (cell.y > 0) {
				const index = (cell.y - 1) * width + cell.x;
				if (!grid[index].visited) {
					grid[index].visited = true;
					try flood_list.append(index);
				}
			}
			else {
				is_enclosed = false;
			}
			if (cell.y < height - 1) {
				const index = (cell.y + 1) * width + cell.x;
				if (!grid[index].visited) {
					grid[index].visited = true;
					try flood_list.append(index);
				}
			}
			else {
				is_enclosed = false;
			}
			if (cell.x > 0) {
				const index = cell.y * width + (cell.x - 1);
				if (!grid[index].visited) {
					grid[index].visited = true;
					try flood_list.append(index);
				}
			}
			else {
				is_enclosed = false;
			}
			if (cell.x < width - 1) {
				const index = cell.y * width + (cell.x + 1);
				if (!grid[index].visited) {
					grid[index].visited = true;
					try flood_list.append(index);
				}
			}
			else {
				is_enclosed = false;
			}
		}

		if (is_enclosed)
		{
			for (flood_list.items) |index| {
				grid[index].enclosed = true;
			}
		}
	}

	var count: u64 = 0;
	for (grid) |cell| {
		if (!cell.slip and cell.enclosed) {
			count += 1;
		}
	}
	return count;
}

test "solve_2 test input 1" {
	const input =
		\\...........
		\\.S-------7.
		\\.|F-----7|.
		\\.||.....||.
		\\.||.....||.
		\\.|L-7.F-J|.
		\\.|..|.|..|.
		\\.L--J.L--J.
		\\...........
		\\
	;
	try testing.expectEqual(@as(u64, 4), try solve_2(testing.allocator, input));
}

test "solve_2 test input 2" {
	const input =
		\\..........
		\\.S------7.
		\\.|F----7|.
		\\.||....||.
		\\.||....||.
		\\.|L-7F-J|.
		\\.|..||..|.
		\\.L--JL--J.
		\\..........
		\\
	;
	try testing.expectEqual(@as(u64, 4), try solve_2(testing.allocator, input));
}

test "solve_2 test input 3" {
	const input =
		\\.F----7F7F7F7F-7....
		\\.|F--7||||||||FJ....
		\\.||.FJ||||||||L7....
		\\FJL7L7LJLJ||LJ.L-7..
		\\L--J.L7...LJS7F-7L7.
		\\....F-J..F7FJ|L7L7L7
		\\....L7.F7||L7|.L7L7|
		\\.....|FJLJ|FJ|F7|.LJ
		\\....FJL-7.||.||||...
		\\....L---J.LJ.LJLJ...
		\\
	;
	try testing.expectEqual(@as(u64, 8), try solve_2(testing.allocator, input));
}

test "solve_2 test input 4" {
	const input =
		\\FF7FSF7F7F7F7F7F---7
		\\L|LJ||||||||||||F--J
		\\FL-7LJLJ||||||LJL-77
		\\F--JF--7||LJLJ7F7FJ-
		\\L---JF-JLJ.||-FJLJJ7
		\\|F|F-JF---7F7-L7L|7|
		\\|FFJF7L7F-JF7|JL---7
		\\7-L-JL7||F7|L7F-7F7|
		\\L.L7LFJ|||||FJL7||LJ
		\\L7JLJL-JLJLJL--JLJ.L
		\\
	;
	try testing.expectEqual(@as(u64, 10), try solve_2(testing.allocator, input));
}

test "solve_2 puzzle input" {
	try testing.expectEqual(@as(u64, 455), try solve_2(testing.allocator, INPUT));
}

const GridIterator = struct {
	width_line: usize,
	width_grid: usize,
	height: usize,

	x: usize,
	y: usize,
	direction: Direction,
	count: u64,

	grid: []const u8,

	const Item = struct {
		x: usize,
		y: usize,
		direction: Direction,
	};

	fn init(input: []const u8) GridIterator {
		const grid_width = std.mem.indexOfScalar(u8, input, '\n').?;
		const line_width = grid_width + 1;
		const height = std.mem.count(u8, input, "\n");

		const start_index = std.mem.indexOfScalar(u8, input, 'S').?;
		const y: usize = @divTrunc(start_index, line_width);
		const x: usize = start_index - y * line_width;

		return .{
			.width_line = line_width,
			.width_grid = grid_width,
			.height = height,
			.x = x,
			.y = y,
			.direction = .north,
			.count = 0,
			.grid = input,
		};
	}

	fn next(self: *GridIterator) ?Item {
		const char = self.char_at(self.x, self.y);
		if (char == 'S') {
			if (self.count > 0) {
				return null;
			}

			if (self.x > 0 and get_exit_direction(self.char_at(self.x - 1, self.y), .east) != null) {
				self.x -= 1;
				self.direction = .east;
			}
			else if (self.x < self.width_grid and get_exit_direction(self.char_at(self.x + 1, self.y), .west) != null) {
				self.x += 1;
				self.direction = .west;
			}
			else if (self.y > 0 and get_exit_direction(self.char_at(self.x, self.y - 1), .south) != null) {
				self.y -= 1;
				self.direction = .south;
			}
			else if (self.y < self.height and get_exit_direction(self.char_at(self.x, self.y + 1), .north) != null) {
				self.y += 1;
				self.direction = .north;
			}
			else {
				@panic("did not find valid direction from the starting position");
			}

			self.count += 1;
			return .{
				.x = self.x,
				.y = self.y,
				.direction = self.direction,
			};
		}

		const next_direction = get_exit_direction(char, self.direction).?;
		switch (next_direction) {
			.north => {
				self.y -= 1;
			},
			.east => {
				self.x += 1;
			},
			.south => {
				self.y += 1;
			},
			.west => {
				self.x -= 1;
			},
		}
		std.debug.assert(0 <= self.x and self.x < self.width_grid);
		std.debug.assert(0 <= self.y and self.y < self.width_grid);

		self.direction = flip_direction(next_direction);
		self.count += 1;
		return .{
			.x = self.x,
			.y = self.y,
			.direction = self.direction,
		};
	}

	inline fn char_at(self: GridIterator, x: usize, y: usize) u8 {
		return self.grid[y * self.width_line + x];
	}
};

const Direction = enum {
	north,
	east,
	south,
	west,
};

fn get_directions(c: u8) ?struct{ Direction, Direction } {
	return switch (c) {
		'-' => .{ .west, .east },
		'|' => .{ .north, .south },
		'L' => .{ .north, .east },
		'J' => .{ .north, .west },
		'F' => .{ .east, .south },
		'7' => .{ .west, .south },
		else => null,
	};
}

fn get_exit_direction(c: u8, entry: Direction) ?Direction {
	if (get_directions(c)) |directions| {
		if (entry == directions[0]) {
			return directions[1];
		}
		else if (entry == directions[1]) {
			return directions[0];
		}
		else {
			return null;
		}
	}
	return null;
}

fn flip_direction(direction: Direction) Direction {
	return switch (direction) {
		.north => .south,
		.south => .north,
		.east => .west,
		.west => .east,
	};
}
