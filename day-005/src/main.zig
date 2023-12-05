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
			for (map.ranges) |range| {
				if (range.source <= location and location < range.source + range.len) {
					location += range.dest - range.source;
					break;
				}
			}
		}
		min_location = @min(location, min_location);
	}
	return min_location;
}

fn solve_second(allocator: std.mem.Allocator, almanac: Almanac) !i64 {
	const Range = struct {
		start: i64,
		len: i64,

		fn less_than_fn(_: void, a: @This(), b: @This()) bool {
			return a.start < b.start;
		}
	};

	var input_ranges = try std.ArrayListUnmanaged(Range).initCapacity(allocator, 64);
	defer input_ranges.deinit(allocator);
	var output_ranges = try std.ArrayListUnmanaged(Range).initCapacity(allocator, 64);
	defer output_ranges.deinit(allocator);

	var min_location: i64 = std.math.maxInt(i64);

	const pair_count = @divExact(almanac.seeds.len, 2);
	for (0..pair_count) |pair_index| {
		input_ranges.clearRetainingCapacity();
		const seed = try input_ranges.addOne(allocator);
		seed.* = Range{
			.start = almanac.seeds[pair_index * 2 + 0],
			.len = almanac.seeds[pair_index * 2 + 1],
		};

		for (&almanac.maps) |map| {
			var transform_index: usize = 0;
			for (input_ranges.items) |input| {
				var input_start_trim = input.start;

				while (input_start_trim < input.start + input.len and transform_index < map.ranges.len) {
					const transform = map.ranges[transform_index];
					if (transform.source + transform.len <= input_start_trim) {
						transform_index += 1;
						continue;
					}
					if (input.start + input.len <= transform.source) {
						try output_ranges.append(allocator, .{
							.start = input_start_trim,
							.len = (input.start + input.len) - input_start_trim,
						});
						input_start_trim = input.start + input.len;
						break;
					}

					const start = @max(input_start_trim, transform.source);
					const finish = @min(input.start + input.len, transform.source + transform.len);
					if (start < finish) {
						if (input_start_trim < start) {
							try output_ranges.append(allocator, .{
								.start = input_start_trim,
								.len = start - input_start_trim,
							});
							input_start_trim = start;
						}
						try output_ranges.append(allocator, .{
							.start = start + (transform.dest - transform.source),
							.len = finish - start,
						});
						input_start_trim = finish;
					}
				}

				if (input_start_trim < input.start + input.len) {
					try output_ranges.append(allocator, .{
						.start = input_start_trim,
						.len = (input.start + input.len) - input_start_trim,
					});
					input_start_trim = input.start + input.len;
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
	pub const MAX_MAPS: usize = 7;

	seeds: []i64,
	maps: [MAX_MAPS]Map,
};

const Map = struct {
	ranges: []RangeMap,
};

const RangeMap = struct {
	dest: i64,
	source: i64,
	len: i64,
};

fn almanac_free(self: Almanac, allocator: std.mem.Allocator) void {
	for (&self.maps) |*map| {
		allocator.free(map.ranges);
	}
	allocator.free(self.seeds);
}

fn almanac_parse(allocator: std.mem.Allocator, input: []const u8) !Almanac {
	var it = std.mem.splitAny(u8, input, " \n");

	if (!std.mem.eql(u8, it.next().?, "seeds:")) {
		@panic("the input does not start with \"seeds:\"");
	}

	var seeds = try std.ArrayListUnmanaged(i64).initCapacity(allocator, 32);

	while (it.next()) |slice| {
		if (slice.len == 0) {
			break;
		}
		const seed = try std.fmt.parseInt(i64, slice, 10);
		try seeds.append(allocator, seed);
	}

	var maps: [Almanac.MAX_MAPS]Map = undefined;
	for (&maps) |*map| {
		if (!std.mem.containsAtLeast(u8, it.next().?, 1, "-to-")) {
			@panic("missing map section (\"*-to-*\")");
		}
		if (!std.mem.eql(u8, it.next().?, "map:")) {
			@panic("missing map section (\"*** map:\")");
		}

		var ranges = try std.ArrayListUnmanaged(RangeMap).initCapacity(allocator, 64);
		var range_index: usize = 0;
		while (true) : (range_index += 1) {
			const next_slice = it.next().?;
			if (next_slice.len == 0) {
				break;
			}
			var range = try ranges.addOne(allocator);
			range.dest = try std.fmt.parseInt(i64, next_slice, 10);
			range.source = try std.fmt.parseInt(i64, it.next().?, 10);
			range.len = try std.fmt.parseInt(i64, it.next().?, 10);
		}

		// NOTE: Sorting ranges here to simplify solution for the second part.
		const LocalFn = struct {
			fn less_than_fn(_: void, a: RangeMap, b: RangeMap) bool {
				return a.source < b.source;
			}
		};
		std.mem.sort(RangeMap, ranges.items, void{}, LocalFn.less_than_fn);

		map.* = .{
			.ranges = try ranges.toOwnedSlice(allocator),
		};
	}

	return .{
		.seeds = try seeds.toOwnedSlice(allocator),
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
	try testing.expectEqualSlices(RangeMap, &[_]RangeMap{ .{ .dest = 52, .source = 50, .len = 48 }, .{ .dest = 50, .source = 98, .len =  2 } }, result.maps[0].ranges);
	try testing.expectEqualSlices(RangeMap, &[_]RangeMap{ .{ .dest = 39, .source =  0, .len = 15 }, .{ .dest =  0, .source = 15, .len = 37 }, .{ .dest = 37, .source = 52, .len =  2 } }, result.maps[1].ranges);
	try testing.expectEqualSlices(RangeMap, &[_]RangeMap{ .{ .dest = 42, .source =  0, .len =  7 }, .{ .dest = 57, .source =  7, .len =  4 }, .{ .dest =  0, .source = 11, .len = 42 }, .{ .dest = 49, .source = 53, .len =  8 } }, result.maps[2].ranges);
	try testing.expectEqualSlices(RangeMap, &[_]RangeMap{ .{ .dest = 88, .source = 18, .len =  7 }, .{ .dest = 18, .source = 25, .len = 70 } }, result.maps[3].ranges);
	try testing.expectEqualSlices(RangeMap, &[_]RangeMap{ .{ .dest = 81, .source = 45, .len = 19 }, .{ .dest = 68, .source = 64, .len = 13 }, .{ .dest = 45, .source = 77, .len = 23 } }, result.maps[4].ranges);
	try testing.expectEqualSlices(RangeMap, &[_]RangeMap{ .{ .dest =  1, .source =  0, .len = 69 }, .{ .dest =  0, .source = 69, .len =  1 } }, result.maps[5].ranges);
	try testing.expectEqualSlices(RangeMap, &[_]RangeMap{ .{ .dest = 60, .source = 56, .len = 37 }, .{ .dest = 56, .source = 93, .len =  4 } }, result.maps[6].ranges);
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
