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
	const NodeCompact = struct {
		left: u16,
		right: u16,
	};

	const Node = struct {
		name: []const u8,
		left_name: []const u8,
		right_name: []const u8,
	};
	var raw_nodes = try std.ArrayList(Node).initCapacity(allocator, 8);
	defer raw_nodes.deinit();

	var it = std.mem.tokenizeAny(u8, input, " \n=(,)");
	const instructions = it.next().?;
	while (it.next()) |node_name| {
		const left = it.next().?;
		const right = it.next().?;

		try raw_nodes.append(.{
			.name = node_name,
			.left_name = left,
			.right_name = right,
		});
	}

	var nodes = try allocator.alloc(NodeCompact, raw_nodes.items.len);
	defer allocator.free(nodes);
	for (raw_nodes.items, 0..) |target_node, handle| {
		for (raw_nodes.items, 0..) |node, index| {
			if (std.mem.eql(u8, node.left_name, target_node.name)) {
				nodes[index].left = @intCast(handle);
			}
			if (std.mem.eql(u8, node.right_name, target_node.name)) {
				nodes[index].right = @intCast(handle);
			}
		}
	}

	const exit_node_handle: usize = blk: {
		for (raw_nodes.items, 0..) |node, handle| {
			if (std.mem.eql(u8, node.name, "ZZZ")) {
				break :blk handle;
			}
		}
		@panic("exit node not found");
	};
	var current_handle: usize = blk: {
		for (raw_nodes.items, 0..) |node, handle| {
			if (std.mem.eql(u8, node.name, "AAA")) {
				break :blk handle;
			}
		}
		@panic("entry node not found");
	};

	var count: u64 = 0;
	while (count < std.math.maxInt(u64)) {
		for (instructions) |instruction| {
			if (current_handle == exit_node_handle) {
				return count;
			}
			if (instruction == 'L') {
				current_handle = nodes[current_handle].left;
			}
			else {
				current_handle = nodes[current_handle].right;
			}
			count += 1;
		}
	}
	@panic("failed to find the exit");
}

test "solve_1 test input 1" {
	var input =
		\\RL
		\\
		\\AAA = (BBB, CCC)
		\\BBB = (DDD, EEE)
		\\CCC = (ZZZ, GGG)
		\\DDD = (DDD, DDD)
		\\EEE = (EEE, EEE)
		\\GGG = (GGG, GGG)
		\\ZZZ = (ZZZ, ZZZ)
		\\
	;
	try testing.expectEqual(@as(u64, 2), try solve_1(testing.allocator, input));
}

test "solve_1 test input 2" {
	var input =
		\\LLR
		\\
		\\AAA = (BBB, BBB)
		\\BBB = (AAA, ZZZ)
		\\ZZZ = (ZZZ, ZZZ)
		\\
	;
	try testing.expectEqual(@as(u64, 6), try solve_1(testing.allocator, input));
}

test "solve_1 puzzle input" {
	try testing.expectEqual(@as(u64, 22199), try solve_1(testing.allocator, INPUT));
}

fn solve_2(allocator: std.mem.Allocator, input: []const u8) !u64 {
	const Node = struct {
		name: []const u8,
		left_name: []const u8,
		right_name: []const u8,
		left_handle: usize,
		right_handle: usize,

		fn is_entry(self: @This()) bool {
			return self.name[2] == 'A';
		}
		fn is_exit(self: @This()) bool {
			return self.name[2] == 'Z';
		}
	};
	var nodes = try std.ArrayList(Node).initCapacity(allocator, 8);
	defer nodes.deinit();

	var it = std.mem.tokenizeAny(u8, input, " \n=(,)");
	const instructions = it.next().?;
	while (it.next()) |node_name| {
		var node = try nodes.addOne();
		node.name = node_name;
		node.left_name = it.next().?;
		node.right_name = it.next().?;
	}
	for (nodes.items, 0..) |target_node, handle| {
		for (nodes.items) |*node| {
			if (std.mem.eql(u8, node.left_name, target_node.name)) {
				node.left_handle = handle;
			}
			if (std.mem.eql(u8, node.right_name, target_node.name)) {
				node.right_handle = handle;
			}
		}
	}

	const exit_count: usize = blk: {
		var entries: usize = 0;
		var exits: usize = 0;
		for (nodes.items) |node| {
			if (node.is_entry()) {
				entries += 1;
			}
			else if (node.is_exit()) {
				exits += 1;
			}
		}
		std.debug.assert(entries == exits);
		break :blk exits;
	};

	const ExitCache = struct {
		is_computed: bool,
		steps: u64,
		compact_handle: usize,
	};
	const ExitToExit = struct {
		cached: []ExitCache,
		node_handle: usize,
		compact_handle: usize,
	};
	var exit_to_exit = try allocator.alloc(ExitToExit, exit_count);
	defer {
		for (exit_to_exit) |exit| {
			allocator.free(exit.cached);
		}
		allocator.free(exit_to_exit);
	}
	{
		var i: usize = 0;
		for (nodes.items, 0..) |node, handle| {
			if (node.is_exit()) {
				var exit = &exit_to_exit[i];
				exit.cached = try allocator.alloc(ExitCache, instructions.len);
				exit.node_handle = handle;
				exit.compact_handle = i;
				i += 1;
			}
		}
	}

	const ExitInfo = struct {
		steps: u64,
		node_handle: usize,
	};
	const LocalFn = struct {
		fn find_next_exit(nodes_: []const Node, start_handle: usize, instructions_: []const u8, start_index: usize) ExitInfo {
			var count: u64 = 0;
			var index = start_index;
			var handle = start_handle;
			while (true) {
				while (index < instructions_.len) {
					if (instructions_[index] == 'L') {
						handle = nodes_[handle].left_handle;
					}
					else {
						handle = nodes_[handle].right_handle;
					}
					count = std.math.add(u64, count, 1) catch @panic("could not find next exit in 2^64 iterations");
					index += 1;

					if (nodes_[handle].is_exit()) {
						return .{
							.steps = count,
							.node_handle = handle,
						};
					}
				}
				index = 0;
			}
		}

		fn find_compact_handle(exit_nodes: []const ExitToExit, node_handle: usize) usize {
			for (exit_nodes) |exit| {
				if (exit.node_handle == node_handle) {
					return exit.compact_handle;
				}
			}
			@panic("unable to find compact handle");
		}
	};

	const Location = struct {
		steps: u64,
		compact_handle: usize,
	};
	var locations = try allocator.alloc(Location, exit_count);
	defer allocator.free(locations);
	{
		var location_count: usize = 0;
		for (nodes.items, 0..) |node, start_handle| {
			if (node.is_entry()) {
				const next_exit = LocalFn.find_next_exit(nodes.items, start_handle, instructions, 0);
				var location = &locations[location_count];
				location.steps = next_exit.steps;
				location.compact_handle = LocalFn.find_compact_handle(exit_to_exit, next_exit.node_handle);
				location_count += 1;
			}
		}
	}

	var max_steps: u64 = locations[0].steps;
	var index: usize = 0;
	while (index < locations.len) {
		var location = &locations[index];
		if (location.steps == max_steps) {
			index += 1;
		}
		else if (location.steps > max_steps) {
			max_steps = location.steps;
			index = 0;
		}
		else {
			const instruction_index = location.steps % instructions.len;
			const current_exit = exit_to_exit[location.compact_handle];
			var next = &current_exit.cached[instruction_index];
			if (!next.is_computed) {
				const next_exit = LocalFn.find_next_exit(nodes.items, current_exit.node_handle, instructions, instruction_index);
				next.steps = next_exit.steps;
				next.compact_handle = LocalFn.find_compact_handle(exit_to_exit, next_exit.node_handle);
				next.is_computed = true;
			}
			location.steps += next.steps;
			location.compact_handle = next.compact_handle;
		}
	}
	return max_steps;
}

test "solve_2 test input" {
	var input =
		\\LR
		\\
		\\11A = (11B, XXX)
		\\11B = (XXX, 11Z)
		\\11Z = (11B, XXX)
		\\22A = (22B, XXX)
		\\22B = (22C, 22C)
		\\22C = (22Z, 22Z)
		\\22Z = (22B, 22B)
		\\XXX = (XXX, XXX)
		\\
	;
	try testing.expectEqual(@as(u64, 6), try solve_2(testing.allocator, input));
}

test "solve_2 puzzle input" {
	try testing.expectEqual(@as(u64, 13334102464297), try solve_2(testing.allocator, INPUT));
}
