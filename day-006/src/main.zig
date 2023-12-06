const std = @import("std");
const log = std.log;
const testing = std.testing;
const INPUT =
	\\Time:        61     70     90     66
	\\Distance:   643   1184   1362   1041
	\\
;

pub const std_options = struct {
	pub const log_level = .info;
};

pub fn main() !void {
	log.info("first: {}", .{ try solve_1(INPUT) });
	log.info("second: {}", .{ solve_2(INPUT) });
}

fn solve_1(input: []const u8) !u64 {
	const Race = struct {
		time: u64,
		distance: u64,
	};
	var buffer: [4]Race = undefined;
	var races: []Race = &buffer;

	{
		var race_count: usize = 0;
		var line_it = std.mem.splitScalar(u8, input, '\n');
		{
			const line_time = line_it.next().?["Time:".len..];
			var time_it = std.mem.splitScalar(u8, line_time, ' ');
			while (time_it.next()) |maybe_time| {
				if (maybe_time.len == 0) {
					continue;
				}
				buffer[race_count].time = try std.fmt.parseInt(u64, maybe_time, 10);
				race_count += 1;
			}
		}
		{
			const line_distance = line_it.next().?["Distance:".len..];
			var index: usize = 0;
			var distance_it = std.mem.splitScalar(u8, line_distance, ' ');
			while (distance_it.next()) |maybe_distance| {
				if (maybe_distance.len == 0) {
					continue;
				}
				if (index > race_count) {
					return error.ValueCountsDoNotMatch;
				}
				buffer[index].distance = try std.fmt.parseInt(u64, maybe_distance, 10);
				index += 1;
			}
		}
		races = buffer[0..race_count];
	}

	var result: u64 = 1;
	for (races) |race| {
		var count: u64 = 0;
		var hold_time: u64 = 0;
		while (hold_time <= race.time) : (hold_time += 1) {
			const distance_result = (race.time - hold_time) * hold_time;
			if (distance_result > race.distance) {
				count += 1;
			}
		}
		result *= count;
	}
	return result;
}

test "solve_1 test input" {
	const input =
		\\Time:      7  15   30
		\\Distance:  9  40  200
		\\
	;
	try testing.expectEqual(@as(u64, 288), try solve_1(input));
}

test "solve_1 puzzle input" {
	try testing.expectEqual(@as(u64, 293046), try solve_1(INPUT));
}

fn solve_2(input: []const u8) u64 {
	var time: u64 = 0;
	var distance: u64 = 0;

	{
		var line_it = std.mem.splitScalar(u8, input, '\n');

		const line_time = line_it.next().?["Time:".len..];
		for (line_time) |char| {
			if (std.ascii.isDigit(char)) {
				time = time * 10 + (char - '0');
			}
		}
		const line_distance = line_it.next().?["Distance:".len..];
		for (line_distance) |char| {
			if (std.ascii.isDigit(char)) {
				distance = distance * 10 + (char - '0');
			}
		}
	}

	var count: u64 = 0;
	var hold_time: u64 = 0;
	while (hold_time <= time) : (hold_time += 1) {
		const distance_result = (time - hold_time) * hold_time;
		if (distance_result > distance) {
			count += 1;
		}
	}
	return count;
}

test "solve_2 test input" {
	const input =
		\\Time:      7  15   30
		\\Distance:  9  40  200
		\\
	;
	try testing.expectEqual(@as(u64, 71503), solve_2(input));
}

test "solve_2 puzzle input" {
	try testing.expectEqual(@as(u64, 35150181), solve_2(INPUT));
}
