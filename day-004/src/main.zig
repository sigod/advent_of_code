const std = @import("std");
const log = std.log;
const testing = std.testing;
const INPUT = @embedFile("./input.txt");

pub fn main() !void {
	log.info("first: {}", .{ solve_first(INPUT) });
	log.info("second: {}", .{ solve_second(INPUT) });
}

fn solve_first(input: []const u8) u32 {
	var sum: u32 = 0;
	var it = CardsParser.init(input);
	while (it.next()) |card| {
		const match_count = find_match_count(card);
		if (match_count > 0) {
			sum += std.math.pow(u32, 2, match_count - 1);
		}
	}
	return sum;
}

fn solve_second(input: []const u8) u32 {
	var cards: [1024]u32 = undefined;
	@memset(&cards, 0);

	var index: usize = 0;
	var it = CardsParser.init(input);
	while (it.next()) |card| {
		cards[index] += 1;

		const match_count = find_match_count(card);
		for (cards[index + 1..][0..match_count]) |*card_count| {
			card_count.* += cards[index];
		}

		index += 1;
	}

	var sum: u32 = 0;
	for (cards) |card_count| {
		sum += card_count;
	}
	return sum;
}

fn find_match_count(card: Card) u32 {
	var matches: u32 = 0;
	for (card.card_numbers) |number| {
		for (card.winning_numbers) |winning| {
			if (number == winning) {
				matches += 1;
				break;
			}
		}
	}
	return matches;
}

const Card = struct {
	number: u32,
	winning_numbers: []const u32,
	card_numbers: []const u32,
};

const CardsParser = struct {
	input: []const u8,
	index: usize,

	memory_winning_numbers: [128]u32 = undefined,
	memory_card_numbers: [128]u32 = undefined,

	pub fn init(input: []const u8) CardsParser {
		return .{
			.input = input,
			.index = 0,
		};
	}

	pub fn next(self: *CardsParser) ?Card {
		if (self.index >= self.input.len) {
			return null;
		}

		const new_line_index = std.mem.indexOfScalar(u8, self.input[self.index..], '\n').?;
		const line = self.input[self.index..][0..new_line_index];

		var it = std.mem.splitScalar(u8, line, ' ');

		if (!std.mem.eql(u8, it.next().?, "Card")) {
			@panic("the line didn't start with \"Card \"");
		}

		var card_number: u32 = undefined;
		while (it.next()) |slice| {
			if (std.mem.eql(u8, slice, "")) {
				continue;
			}
			const number_string = slice[0..slice.len - 1];
			card_number = std.fmt.parseInt(u32, number_string, 10) catch @panic("cannot parse number");
			break;
		}

		var winning_count: usize = 0;
		while (it.next()) |slice| {
			if (std.mem.eql(u8, slice, "")) {
				continue;
			}
			if (std.mem.eql(u8, slice, "|")) {
				break;
			}
			self.memory_winning_numbers[winning_count] = std.fmt.parseInt(u32, slice, 10) catch @panic("cannot parse number");
			winning_count += 1;
		}

		var number_count: usize = 0;
		while (it.next()) |slice| {
			if (std.mem.eql(u8, slice, "")) {
				continue;
			}
			self.memory_card_numbers[number_count] = std.fmt.parseInt(u32, slice, 10) catch @panic("cannot parse number");
			number_count += 1;
		}

		self.index += new_line_index + 1;

		return .{
			.number = card_number,
			.winning_numbers = self.memory_winning_numbers[0..winning_count],
			.card_numbers = self.memory_card_numbers[0..number_count],
		};
	}
};

test "CardsParser" {
	const input =
		\\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
		\\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
		\\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
		\\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
		\\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
		\\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
		\\
	;
	var it = CardsParser.init(input);
	try testing.expectEqualDeep(@as(?Card, .{ .number = 1, .winning_numbers = &[_]u32{ 41, 48, 83, 86, 17 }, .card_numbers = &[_]u32{ 83, 86,  6, 31, 17,  9, 48, 53 } }), it.next());
	try testing.expectEqualDeep(@as(?Card, .{ .number = 2, .winning_numbers = &[_]u32{ 13, 32, 20, 16, 61 }, .card_numbers = &[_]u32{ 61, 30, 68, 82, 17, 32, 24, 19 } }), it.next());
	try testing.expectEqualDeep(@as(?Card, .{ .number = 3, .winning_numbers = &[_]u32{  1, 21, 53, 59, 44 }, .card_numbers = &[_]u32{ 69, 82, 63, 72, 16, 21, 14,  1 } }), it.next());
	try testing.expectEqualDeep(@as(?Card, .{ .number = 4, .winning_numbers = &[_]u32{ 41, 92, 73, 84, 69 }, .card_numbers = &[_]u32{ 59, 84, 76, 51, 58,  5, 54, 83 } }), it.next());
	try testing.expectEqualDeep(@as(?Card, .{ .number = 5, .winning_numbers = &[_]u32{ 87, 83, 26, 28, 32 }, .card_numbers = &[_]u32{ 88, 30, 70, 12, 93, 22, 82, 36 } }), it.next());
	try testing.expectEqualDeep(@as(?Card, .{ .number = 6, .winning_numbers = &[_]u32{ 31, 18, 13, 56, 72 }, .card_numbers = &[_]u32{ 74, 77, 10, 23, 35, 67, 36, 11 } }), it.next());
	try testing.expectEqual(@as(?Card, null), it.next());
}

test "solve_first test input" {
	const input =
		\\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
		\\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
		\\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
		\\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
		\\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
		\\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
		\\
	;
	try testing.expectEqual(@as(u32, 13), solve_first(input));
}

test "solve_first puzzle input" {
	try testing.expectEqual(@as(u32, 32001), solve_first(INPUT));
}

test "solve_second test input" {
	const input =
		\\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
		\\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
		\\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
		\\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
		\\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
		\\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
		\\
	;
	try testing.expectEqual(@as(u32, 30), solve_second(input));
}

test "solve_second puzzle input" {
	try testing.expectEqual(@as(u32, 5037841), solve_second(INPUT));
}
