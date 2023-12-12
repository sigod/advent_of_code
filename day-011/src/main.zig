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

	log.info("first: {}", .{ try solve_1(allocator, INPUT) });
	log.info("second: {}", .{ try solve_2(allocator, INPUT) });
}

fn solve_1(allocator: std.mem.Allocator, input: []const u8) !u64 {
	return try solve(allocator, input, 2);
}

test "solve_1 test input" {
	const input =
		\\...#......
		\\.......#..
		\\#.........
		\\..........
		\\......#...
		\\.#........
		\\.........#
		\\..........
		\\.......#..
		\\#...#.....
		\\
	;
	try testing.expectEqual(@as(u64, 374), try solve_1(testing.allocator, input));
}

test "solve_1 puzzle input" {
	try testing.expectEqual(@as(u64, 10228230), try solve_1(testing.allocator, INPUT));
}

fn solve_2(allocator: std.mem.Allocator, input: []const u8) !u64 {
	return try solve(allocator, input, 1000000);
}

test "solve_2 puzzle input" {
	try testing.expectEqual(@as(u64, 447073334102), try solve_2(testing.allocator, INPUT));
}

fn solve(allocator: std.mem.Allocator, input: []const u8, expansion_rate: i64) !u64 {
	const width_grid = std.mem.indexOfScalar(u8, input, '\n').?;
	const width_line = width_grid + 1;
	const height = std.mem.count(u8, input, "\n");

	var rows = try allocator.alloc(i64, height);
	defer allocator.free(rows);
	{
		rows[0] = 0;
		for (1..height) |y| {
			var is_empty = true;
			for (input[y * width_line..][0..width_grid]) |char| {
				if (char == '#') {
					is_empty = false;
					break;
				}
			}
			if (is_empty) {
				rows[y] = rows[y - 1] + expansion_rate;
			}
			else {
				rows[y] = rows[y - 1] + 1;
			}
		}
	}
	var columns = try allocator.alloc(i64, width_grid);
	defer allocator.free(columns);
	{
		columns[0] = 0;
		for (1..width_grid) |x| {
			var is_empty = true;
			for (0..height) |y| {
				if (input[y * width_line + x] == '#') {
					is_empty = false;
					break;
				}
			}
			if (is_empty) {
				columns[x] = columns[x - 1] + expansion_rate;
			}
			else {
				columns[x] = columns[x - 1] + 1;
			}
		}
	}

	const Galaxy = struct {
		x: usize,
		y: usize,
	};
	const galaxy_count = std.mem.count(u8, input, "#");
	var galaxies = try allocator.alloc(Galaxy, galaxy_count);
	defer allocator.free(galaxies);
	var found: usize = 0;
	for (0..height) |y| {
		for (0..width_grid) |x| {
			if (input[y * width_line + x] == '#') {
				galaxies[found] = .{
					.x = x,
					.y = y,
				};
				found += 1;
			}
		}
	}

	var sum: u64 = 0;
	for (0..galaxy_count) |i| {
		for (i..galaxy_count) |j| {
			if (i == j) {
				continue;
			}
			const a = galaxies[i];
			const b = galaxies[j];
			const distance = @abs(columns[b.x] - columns[a.x]) + @abs(rows[b.y] - rows[a.y]);
			sum += @intCast(distance);
		}
	}
	return sum;
}

test "solve test input 10 expansion" {
	const input =
		\\...#......
		\\.......#..
		\\#.........
		\\..........
		\\......#...
		\\.#........
		\\.........#
		\\..........
		\\.......#..
		\\#...#.....
		\\
	;
	try testing.expectEqual(@as(u64, 1030), try solve(testing.allocator, input, 10));
}

test "solve test input 100 expansion" {
	const input =
		\\...#......
		\\.......#..
		\\#.........
		\\..........
		\\......#...
		\\.#........
		\\.........#
		\\..........
		\\.......#..
		\\#...#.....
		\\
	;
	try testing.expectEqual(@as(u64, 8410), try solve(testing.allocator, input, 100));
}
