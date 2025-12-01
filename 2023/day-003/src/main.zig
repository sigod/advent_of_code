const std = @import("std");
const log = std.log;
const testing = std.testing;
const INPUT = @embedFile("./input.txt");

pub const std_options = struct {
	pub const log_level = .info;
};

pub fn main() !void {
	log.info("first: {}", .{ solve_first(INPUT) });
	log.info("second: {}", .{ solve_second(INPUT) });
}

fn solve_first(input: []const u8) u32 {
	var sum: u32 = 0;
	var it = SchematicIterator.init(input);
	while (it.next()) |number| {
		if (number.part != null) {
			sum += number.number;
		}
	}
	return sum;
}

fn solve_second(input: []const u8) u32 {
	const Gear = struct {
		part1: u32,
		part2: u32,
		connections: usize,
	};
	var memory: [32 * 1024]u8 = undefined;
	var buf = std.heap.FixedBufferAllocator.init(&memory);
	var gear_map = std.hash_map.AutoHashMap(usize, Gear).init(buf.allocator());
	defer gear_map.deinit();

	var it = SchematicIterator.init(input);
	while (it.next()) |number| {
		if (number.part) |part| {
			if (part.part != '*') {
				continue;
			}
			var result = gear_map.getOrPut(part.loc) catch @panic("OOM");
			if (!result.found_existing) {
				result.value_ptr.*.connections = 0;
			}
			result.value_ptr.*.connections += 1;
			if (result.value_ptr.*.connections == 1) {
				result.value_ptr.*.part1 = number.number;
			}
			else if (result.value_ptr.*.connections == 2) {
				result.value_ptr.*.part2 = number.number;
			}
		}
	}

	var sum: u32 = 0;
	var gear_it = gear_map.valueIterator();
	while (gear_it.next()) |gear| {
		if (gear.connections == 2) {
			sum += gear.part1 * gear.part2;
		}
	}
	return sum;
}

const PartNumber = struct {
	number: u32,
	part: ?PartInfo,
};

const PartInfo = struct {
	part: u8,
	loc: usize,
};

const SchematicIterator = struct {
	input: []const u8,
	width: usize,
	height: usize,
	x: usize,
	y: usize,

	pub fn init(input: []const u8) SchematicIterator {
		const width = std.mem.indexOfScalar(u8, input, '\n').? + 1;
		const height = input.len / width;
		return .{
			.input = input,
			.width = width,
			.height = height,
			.x = 0,
			.y = 0,
		};
	}

	pub fn next(self: *SchematicIterator) ?PartNumber {
		while (self.width * self.y + self.x < self.input.len) {
			const index = self.width * self.y + self.x;
			const char = self.input[index];
			if (char == '\n') {
				self.y += 1;
				self.x = 0;
			}
			else if (std.ascii.isDigit(char)) {
				var end_index: usize = undefined;
				for (index..self.input.len) |i| {
					if (!std.ascii.isDigit(self.input[i])) {
						end_index = i;
						break;
					}
				}
				const number_string = self.input[index..end_index];
				const number = std.fmt.parseInt(u32, number_string, 10) catch @panic("not a number");
				const x_end = end_index - self.width * self.y;
				const part = self.find_part(self.x, x_end - 1);
				self.x = x_end;
				return PartNumber{
					.number = number,
					.part = part,
				};
			}
			else {
				self.x += 1;
			}
		}
		return null;
	}

	fn find_part(self: *SchematicIterator, begin: usize, end: usize) ?PartInfo {
		const x_lower = if (begin == 0) 0 else begin - 1;
		const x_upper = @min(end + 1, self.width);
		// line above
		if (self.y > 0) {
			const y = self.y - 1;
			var x = x_lower;
			while (x <= x_upper) : (x += 1) {
				const index = self.width * y + x;
				const char = self.input[index];
				if (is_part_symbol(char)) {
					return .{
						.part = char,
						.loc = index,
					};
				}
			}
		}
		// line below
		if (self.y + 1 < self.height - 1) {
			const y = self.y + 1;
			var x = x_lower;
			while (x <= x_upper) : (x += 1) {
				const index = self.width * y + x;
				const char = self.input[index];
				if (is_part_symbol(char)) {
					return .{
						.part = char,
						.loc = index,
					};
				}
			}
		}
		// left
		if (begin > 0) {
			const index = self.width * self.y + begin - 1;
			const char = self.input[index];
			if (is_part_symbol(char)) {
				return .{
					.part = char,
					.loc = index,
				};
			}
		}
		// right
		if (end + 1 < self.width) {
			const index = self.width * self.y + end + 1;
			const char = self.input[index];
			if (is_part_symbol(char)) {
				return .{
					.part = char,
					.loc = index,
				};
			}
		}
		return null;
	}

	fn is_part_symbol(char: u8) bool {
		if (char == '\n') {
			return false;
		}
		if (char == '.') {
			return false;
		}
		if (std.ascii.isDigit(char)) {
			return false;
		}
		return true;
	}
};

test "SchematicIterator" {
	const input =
		\\467..114..
		\\...*......
		\\..35..633.
		\\......#...
		\\617*......
		\\.....+.58.
		\\..592.....
		\\......755.
		\\...$.*....
		\\.664.598..
		\\
	;
	var it = SchematicIterator.init(input);
	try testing.expectEqual(@as(?PartNumber, .{ .number = 467, .part = .{ .part = '*', .loc = 14 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 114, .part = null }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 35, .part = .{ .part = '*', .loc = 14 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 633, .part = .{ .part = '#', .loc = 39 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 617, .part = .{ .part = '*', .loc = 47 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 58, .part = null }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 592, .part = .{ .part = '+', .loc = 60 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 755, .part = .{ .part = '*', .loc = 93 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 664, .part = .{ .part = '$', .loc = 91 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, .{ .number = 598, .part = .{ .part = '*', .loc = 93 } }), it.next());
	try testing.expectEqual(@as(?PartNumber, null), it.next());
}

test "solve_first test data" {
	const input =
		\\467..114..
		\\...*......
		\\..35..633.
		\\......#...
		\\617*......
		\\.....+.58.
		\\..592.....
		\\......755.
		\\...$.*....
		\\.664.598..
		\\
	;
	try testing.expectEqual(@as(u32, 4361), solve_first(input));
}

test "solve_first puzzle data" {
	try testing.expectEqual(@as(u32, 532331), solve_first(INPUT));
}

test "solve_second test data" {
	const input =
		\\467..114..
		\\...*......
		\\..35..633.
		\\......#...
		\\617*......
		\\.....+.58.
		\\..592.....
		\\......755.
		\\...$.*....
		\\.664.598..
		\\
	;
	try testing.expectEqual(@as(u32, 467835), solve_second(input));
}

test "solve_second puzzle data" {
	try testing.expectEqual(@as(u32, 82301120), solve_second(INPUT));
}
