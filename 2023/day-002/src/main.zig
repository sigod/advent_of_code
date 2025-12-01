const std = @import("std");
const log = std.log;
const input = @embedFile("./input.txt");

pub const std_options = struct {
	pub const log_level = .info;
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
	defer std.debug.assert(gpa.deinit() == .ok);
	const allocator = gpa.allocator();

	const games = try parse_game_list(allocator, input);
	defer free_game_list(allocator, games);

	log.info("first: {}", .{ solve_first(games) });
	log.info("second: {}", .{ solve_second(games) });
}

fn solve_first(games: []const Game) u32 {
	const max = Set{ .r = 12, .g = 13, .b = 14 };

	var result: u32 = 0;
	for (games) |game| {
		var valid = true;
		for (game.attempts) |attempt| {
			if (attempt.r > max.r or attempt.g > max.g or attempt.b > max.b) {
				valid = false;
				break;
			}
		}
		if (valid) {
			result += game.number;
		}
	}
	return result;
}

fn solve_second(games: []const Game) u32 {
	var result: u32 = 0;
	for (games) |game| {
		var max = Set{ .r = 0, .g = 0, .b = 0 };
		for (game.attempts) |attempt| {
			if (attempt.r > max.r) {
				max.r = attempt.r;
			}
			if (attempt.g > max.g) {
				max.g = attempt.g;
			}
			if (attempt.b > max.b) {
				max.b = attempt.b;
			}
		}
		const power = max.r * max.g * max.b;
		log.debug("game {} power {}", .{ game.number, power });
		result += power;
	}
	return result;
}

const Game = struct {
	number: u32,
	attempts: []Set,
};

const Set = struct {
	r: u32,
	g: u32,
	b: u32,
};

fn parse_game_list(allocator: std.mem.Allocator, puzzle_input: []const u8) ![]Game {
	const game_count = std.mem.count(u8, puzzle_input, "\n");
	var games = try allocator.alloc(Game, game_count);

	var game_index: usize = 0;
	var line_iter = std.mem.splitScalar(u8, puzzle_input, '\n');
	while (line_iter.next()) |line| {
		// Game 1: 1 blue, 1 red; 10 red; 8 red, 1 blue, 1 green; 1 green, 5 blue
		if (line.len == 0) {
			break;
		}

		const colon = std.mem.indexOfScalar(u8, line, ':').?;
		const game_number = try std.fmt.parseInt(u32, line["Game ".len..colon], 10);
		const game_set_line = line[colon + 2..];
		const attempt_count = std.mem.count(u8, game_set_line, ";") + 1;

		var game = &games[game_index];
		game.number = game_number;
		game.attempts = try allocator.alloc(Set, attempt_count);

		var attempt_index: usize = 0;
		var set_iter = std.mem.splitSequence(u8, game_set_line, "; ");
		while (set_iter.next()) |set_line| {
			// "8 red, 1 blue, 1 green"
			var attempt = &game.attempts[attempt_index];
			attempt.* = Set{ .r = 0, .g = 0, .b = 0 };

			var cube_iter = std.mem.splitSequence(u8, set_line, ", ");
			while (cube_iter.next()) |cube_line| {
				// "1 blue"
				const space = std.mem.indexOfScalar(u8, cube_line, ' ').?;
				const cube_count = try std.fmt.parseInt(u32, cube_line[0..space], 10);
				const cube_color = cube_line[space + 1..];
				if (std.mem.eql(u8, cube_color, "red")) {
					attempt.r = cube_count;
				}
				else if (std.mem.eql(u8, cube_color, "green")) {
					attempt.g = cube_count;
				}
				else if (std.mem.eql(u8, cube_color, "blue")) {
					attempt.b = cube_count;
				}
			}

			attempt_index += 1;
		}

		game_index += 1;
	}

	return games;
}

fn free_game_list(allocator: std.mem.Allocator, list: []const Game) void {
	for (list) |*game| {
		allocator.free(game.attempts);
	}
	allocator.free(list);
}
