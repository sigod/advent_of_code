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

	const almanac = try almanac_parse(allocator, INPUT);
	defer almanac_free(almanac, allocator);

	log.info("first: {}", .{ solve_first(almanac) });
	log.info("second: {}", .{ try solve_second(allocator, almanac) });
}

fn solve_first(almanac: Almanac) i64 {
	var min_location: i64 = std.math.maxInt(i64);
	for (almanac.seeds) |seed| {
		var location = seed;
		for (&almanac.maps) |map| {
			for (map.transforms) |transform| {
				if (transform.range.start <= location and location < transform.range.finish) {
					location += transform.offset;
					break;
				}
			}
		}
		min_location = @min(location, min_location);
	}
	return min_location;
}

fn solve_second(allocator: std.mem.Allocator, almanac: Almanac) !i64 {
	var input_ranges = try std.ArrayList(Range).initCapacity(allocator, 32);
	defer input_ranges.deinit();
	var output_ranges = try std.ArrayList(Range).initCapacity(allocator, 32);
	defer output_ranges.deinit();

	var min_location: i64 = std.math.maxInt(i64);

	const pair_count = @divExact(almanac.seeds.len, 2);
	for (0..pair_count) |pair_index| {
		input_ranges.clearRetainingCapacity();
		try input_ranges.append(Range.new_with_length(almanac.seeds[pair_index * 2 + 0], almanac.seeds[pair_index * 2 + 1]));

		for (&almanac.maps) |map| {
			var transform_index: usize = 0;
			for (input_ranges.items) |input| {
				var input_start_trim = input.start;

				while (input_start_trim < input.finish and transform_index < map.transforms.len) {
					const transform = map.transforms[transform_index];
					if (transform.range.finish <= input_start_trim) {
						transform_index += 1;
						continue;
					}
					if (input.finish <= transform.range.start) {
						try output_ranges.append(Range.new(input_start_trim, input.finish));
						input_start_trim = input.finish;
						break;
					}
					if (Range.new(input_start_trim, input.finish).intersection(transform.range)) |intersection| {
						if (input_start_trim < intersection.start) {
							try output_ranges.append(Range.new(input_start_trim, intersection.start));
							input_start_trim = intersection.start;
						}
						try output_ranges.append(intersection.add_offset(transform.offset));
						input_start_trim = intersection.finish;
					}
				}

				if (input_start_trim < input.finish) {
					try output_ranges.append(Range.new(input_start_trim, input.finish));
					input_start_trim = input.finish;
				}
			}

			std.mem.sort(Range, output_ranges.items, void{}, Range.less_than_fn);
			std.mem.swap(@TypeOf(input_ranges), &input_ranges, &output_ranges);
			output_ranges.clearRetainingCapacity();
		}

		for (input_ranges.items) |final_range| {
			min_location = @min(min_location, final_range.start);
		}
	}

	return min_location;
}

const Almanac = struct {
	const MAX_MAPS: usize = 7;

	seeds: []i64,
	maps: [MAX_MAPS]Map,
};

const Map = struct {
	transforms: []Transform,
};

const Transform = struct {
	range: Range,
	offset: i64,

	fn new(destination: i64, source: i64, length: i64) Transform {
		return .{
			.range = Range.new_with_length(source, length),
			.offset = destination - source,
		};
	}

	fn less_than_fn(_: void, a: Transform, b: Transform) bool {
		return a.range.start < b.range.start;
	}
};

const Range = struct {
	start: i64,
	finish: i64,

	fn new(a: i64, b: i64) Range {
		return .{
			.start = a,
			.finish = b,
		};
	}

	fn new_with_length(start: i64, len: i64) Range {
		return .{
			.start = start,
			.finish = start + len,
		};
	}

	fn add_offset(self: Range, offset: i64) Range {
		return .{
			.start = self.start + offset,
			.finish = self.finish + offset,
		};
	}

	fn intersection(a: Range, b: Range) ?Range {
		const start = @max(a.start, b.start);
		const finish = @min(a.finish, b.finish);
		if (start < finish) {
			return Range.new(start, finish);
		}
		return null;
	}

	fn less_than_fn(_: void, a: Range, b: Range) bool {
		return a.start < b.start;
	}
};

fn almanac_free(self: Almanac, allocator: std.mem.Allocator) void {
	for (&self.maps) |*map| {
		allocator.free(map.transforms);
	}
	allocator.free(self.seeds);
}

fn almanac_parse(allocator: std.mem.Allocator, input: []const u8) !Almanac {
	var it = std.mem.splitAny(u8, input, " \n");

	if (!std.mem.eql(u8, it.next().?, "seeds:")) {
		@panic("the input does not start with \"seeds:\"");
	}

	var seeds = try std.ArrayList(i64).initCapacity(allocator, 32);

	while (it.next()) |slice| {
		if (slice.len == 0) {
			break;
		}
		const seed = try std.fmt.parseInt(i64, slice, 10);
		try seeds.append(seed);
	}

	var maps: [Almanac.MAX_MAPS]Map = undefined;
	for (&maps) |*map| {
		if (!std.mem.containsAtLeast(u8, it.next().?, 1, "-to-")) {
			@panic("missing map section (\"*-to-*\")");
		}
		if (!std.mem.eql(u8, it.next().?, "map:")) {
			@panic("missing map section (\"*** map:\")");
		}

		var transforms = try std.ArrayList(Transform).initCapacity(allocator, 64);
		var range_index: usize = 0;
		while (true) : (range_index += 1) {
			const next_slice = it.next().?;
			if (next_slice.len == 0) {
				break;
			}
			const destination = try std.fmt.parseInt(i64, next_slice, 10);
			const source = try std.fmt.parseInt(i64, it.next().?, 10);
			const length = try std.fmt.parseInt(i64, it.next().?, 10);
			try transforms.append(Transform.new(destination, source, length));
		}

		// NOTE: Sorting transforms here to simplify solution for the second part.
		std.mem.sort(Transform, transforms.items, void{}, Transform.less_than_fn);

		map.* = .{
			.transforms = try transforms.toOwnedSlice(),
		};
	}

	return .{
		.seeds = try seeds.toOwnedSlice(),
		.maps = maps,
	};
}

test almanac_parse {
	const input =
		\\seeds: 79 14 55 13
		\\
		\\seed-to-soil map:
		\\50 98 2
		\\52 50 48
		\\
		\\soil-to-fertilizer map:
		\\0 15 37
		\\37 52 2
		\\39 0 15
		\\
		\\fertilizer-to-water map:
		\\49 53 8
		\\0 11 42
		\\42 0 7
		\\57 7 4
		\\
		\\water-to-light map:
		\\88 18 7
		\\18 25 70
		\\
		\\light-to-temperature map:
		\\45 77 23
		\\81 45 19
		\\68 64 13
		\\
		\\temperature-to-humidity map:
		\\0 69 1
		\\1 0 69
		\\
		\\humidity-to-location map:
		\\60 56 37
		\\56 93 4
		\\
	;
	const result = try almanac_parse(testing.allocator, input);
	defer almanac_free(result, testing.allocator);
	try testing.expectEqualSlices(i64, &[_]i64{ 79, 14, 55, 13 }, result.seeds);
	try testing.expectEqualSlices(Transform, &[_]Transform{ Transform.new(52, 50, 48), Transform.new(50, 98,  2) }, result.maps[0].transforms);
	try testing.expectEqualSlices(Transform, &[_]Transform{ Transform.new(39,  0, 15), Transform.new( 0, 15, 37), Transform.new(37, 52,  2) }, result.maps[1].transforms);
	try testing.expectEqualSlices(Transform, &[_]Transform{ Transform.new(42,  0,  7), Transform.new(57,  7,  4), Transform.new( 0, 11, 42), Transform.new(49, 53,  8) }, result.maps[2].transforms);
	try testing.expectEqualSlices(Transform, &[_]Transform{ Transform.new(88, 18,  7), Transform.new(18, 25, 70) }, result.maps[3].transforms);
	try testing.expectEqualSlices(Transform, &[_]Transform{ Transform.new(81, 45, 19), Transform.new(68, 64, 13), Transform.new(45, 77, 23) }, result.maps[4].transforms);
	try testing.expectEqualSlices(Transform, &[_]Transform{ Transform.new( 1,  0, 69), Transform.new( 0, 69,  1) }, result.maps[5].transforms);
	try testing.expectEqualSlices(Transform, &[_]Transform{ Transform.new(60, 56, 37), Transform.new(56, 93,  4) }, result.maps[6].transforms);
}

test "solve_first example input" {
	const input =
		\\seeds: 79 14 55 13
		\\
		\\seed-to-soil map:
		\\50 98 2
		\\52 50 48
		\\
		\\soil-to-fertilizer map:
		\\0 15 37
		\\37 52 2
		\\39 0 15
		\\
		\\fertilizer-to-water map:
		\\49 53 8
		\\0 11 42
		\\42 0 7
		\\57 7 4
		\\
		\\water-to-light map:
		\\88 18 7
		\\18 25 70
		\\
		\\light-to-temperature map:
		\\45 77 23
		\\81 45 19
		\\68 64 13
		\\
		\\temperature-to-humidity map:
		\\0 69 1
		\\1 0 69
		\\
		\\humidity-to-location map:
		\\60 56 37
		\\56 93 4
		\\
	;
	const almanac = try almanac_parse(testing.allocator, input);
	defer almanac_free(almanac, testing.allocator);
	try testing.expectEqual(@as(i64, 35), solve_first(almanac));
}

test "solve_first puzzle input" {
	const almanac = try almanac_parse(testing.allocator, INPUT);
	defer almanac_free(almanac, testing.allocator);
	try testing.expectEqual(@as(i64, 111627841), solve_first(almanac));
}

test "solve_second example input" {
	const input =
		\\seeds: 79 14 55 13
		\\
		\\seed-to-soil map:
		\\50 98 2
		\\52 50 48
		\\
		\\soil-to-fertilizer map:
		\\0 15 37
		\\37 52 2
		\\39 0 15
		\\
		\\fertilizer-to-water map:
		\\49 53 8
		\\0 11 42
		\\42 0 7
		\\57 7 4
		\\
		\\water-to-light map:
		\\88 18 7
		\\18 25 70
		\\
		\\light-to-temperature map:
		\\45 77 23
		\\81 45 19
		\\68 64 13
		\\
		\\temperature-to-humidity map:
		\\0 69 1
		\\1 0 69
		\\
		\\humidity-to-location map:
		\\60 56 37
		\\56 93 4
		\\
	;
	const almanac = try almanac_parse(testing.allocator, input);
	defer almanac_free(almanac, testing.allocator);
	try testing.expectEqual(@as(i64, 46), try solve_second(testing.allocator, almanac));
}

test "solve_second puzzle input" {
	const almanac = try almanac_parse(testing.allocator, INPUT);
	defer almanac_free(almanac, testing.allocator);
	try testing.expectEqual(@as(i64, 69323688), try solve_second(testing.allocator, almanac));
}
