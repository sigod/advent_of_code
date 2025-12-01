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

fn solve_1(allocator: std.mem.Allocator, input: []const u8) !i64 {
	var sum: i64 = 0;
	var line_it = std.mem.tokenizeScalar(u8, input, '\n');
	while (line_it.next()) |line| {
		const history = try parse_history(allocator, line);
		defer allocator.free(history);
		var diff_lines = try compute_diff_lines(allocator, history);
		defer free_diff_lines(allocator, diff_lines);

		var next_value: i64 = history[history.len - 1];
		for (diff_lines) |diff_line| {
			next_value += diff_line[diff_line.len - 1];
		}
		sum += next_value;
	}
	return sum;
}

test "solve_1 test input" {
	const input =
		\\0 3 6 9 12 15
		\\1 3 6 10 15 21
		\\10 13 16 21 30 45
		\\
	;
	try testing.expectEqual(@as(i64, 114), try solve_1(testing.allocator, input));
}

test "solve_1 puzzle input" {
	try testing.expectEqual(@as(i64, 1757008019), try solve_1(testing.allocator, INPUT));
}

fn solve_2(allocator: std.mem.Allocator, input: []const u8) !i64 {
	var sum: i64 = 0;
	var line_it = std.mem.tokenizeScalar(u8, input, '\n');
	while (line_it.next()) |line| {
		const history = try parse_history(allocator, line);
		defer allocator.free(history);
		var diff_lines = try compute_diff_lines(allocator, history);
		defer free_diff_lines(allocator, diff_lines);

		var next_value: i64 = 0;
		for (1..diff_lines.len + 1) |rev_i| {
			const diff_line = diff_lines[diff_lines.len - rev_i];
			next_value = diff_line[0] - next_value;
		}
		next_value = history[0] - next_value;
		sum += next_value;
	}
	return sum;
}

test "solve_2 test input" {
	const input =
		\\0 3 6 9 12 15
		\\1 3 6 10 15 21
		\\10 13 16 21 30 45
		\\
	;
	try testing.expectEqual(@as(i64, 2), try solve_2(testing.allocator, input));
}

test "solve_2 puzzle input" {
	try testing.expectEqual(@as(i64, 995), try solve_2(testing.allocator, INPUT));
}

fn parse_history(allocator: std.mem.Allocator, line: []const u8) ![]i64 {
	var values = try std.ArrayList(i64).initCapacity(allocator, 8);
	errdefer values.deinit();
	var it = std.mem.tokenizeScalar(u8, line, ' ');
	while (it.next()) |value_slice| {
		try values.append(try std.fmt.parseInt(i64, value_slice, 10));
	}
	return try values.toOwnedSlice();
}

fn compute_diff_lines(allocator: std.mem.Allocator, history: []const i64) ![][]i64 {
	var diff_lines = try std.ArrayList([]i64).initCapacity(allocator, 8);
	var prev_diff_line = history;
	while (prev_diff_line.len > 1) {
		var diff_line = try allocator.alloc(i64, prev_diff_line.len - 1);

		var i: usize = 1;
		while (i < prev_diff_line.len) : (i += 1) {
			diff_line[i - 1] = prev_diff_line[i] - prev_diff_line[i - 1];
		}

		try diff_lines.append(diff_line);
		prev_diff_line = diff_line;

		var all_equal = true;
		for (diff_line[1..]) |diff| {
			if (diff_line[0] != diff) {
				all_equal = false;
			}
		}
		if (all_equal) {
			break;
		}
	}
	return try diff_lines.toOwnedSlice();
}

fn free_diff_lines(allocator: std.mem.Allocator, diff_lines: [][]const i64) void {
	for (diff_lines) |diff_line| {
		allocator.free(diff_line);
	}
	allocator.free(diff_lines);
}
