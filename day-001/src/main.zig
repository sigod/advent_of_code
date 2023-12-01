const std = @import("std");
const log = std.log;
const input = @embedFile("./input.txt");

pub fn main() !void {
	log.info("first solution: {}", .{ solve_as_first_half() });
	log.info("second solution: {}", .{ solve_as_second_half() });
}

fn solve_as_first_half() u32 {
	var sum: u32 = 0;
	var digit_1: u32 = 0;
	var digit_2: u32 = 0;
	var digit_1_not_found: bool = true;

	for (input) |char| {
		switch (char) {
			'0'...'9' => {
				const digit: u32 = @intCast(char - '0');
				if (digit_1_not_found) {
					digit_1 = digit;
					digit_2 = digit;
					digit_1_not_found = false;
				}
				else {
					digit_2 = digit;
				}
			},
			'\n' => {
				if (digit_1_not_found) {
					log.info("no digits found in the current line...", .{});
					continue;
				}

				const next_value = digit_1 * 10 + digit_2;
				sum += next_value;
				digit_1_not_found = true;
			},
			else => {},
		}
	}

	return sum;
}

fn solve_as_second_half() u32 {
	var sum: u32 = 0;
	var digit_1: u32 = 0;
	var digit_2: u32 = 0;
	var digit_1_not_found: bool = true;

	var i: usize = 0;
	while (i < input.len) : (i += 1) {
		var next_digit: ?u32 = null;

		const char: u8 = input[i];
		if (char == '\n') {
			if (digit_1_not_found) {
				log.info("no digits found in the current line...", .{});
				continue;
			}

			const next_value = digit_1 * 10 + digit_2;
			sum += next_value;
			digit_1_not_found = true;
		}
		else if ('0' <= char and char <= '9') {
			next_digit = @intCast(char - '0');
		}
		else {
			const DIGIT_WORDS = [_][]const u8{
				"one",
				"two",
				"three",
				"four",
				"five",
				"six",
				"seven",
				"eight",
				"nine",
			};
			for (DIGIT_WORDS, 1..) |word, possible_digit| {
				if (std.mem.startsWith(u8, input[i..], word)) {
					next_digit = @intCast(possible_digit);
					break;
				}
			}
		}

		if (next_digit) |digit| {
			if (digit_1_not_found) {
				digit_1 = digit;
				digit_2 = digit;
				digit_1_not_found = false;
			}
			else {
				digit_2 = digit;
			}
		}
	}

	return sum;
}
