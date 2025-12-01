const std = @import("std");
const log = std.log;
const testing = std.testing;
const INPUT = @embedFile("./input.txt");

pub const std_options = struct {
	pub const log_level = .info;
};

const HAND_SIZE: usize = 5;
const CARD_COUNT: usize = 13;
const CARD_VALUES = &[CARD_COUNT]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };
const CARD_VALUES_WITH_JOKER = &[CARD_COUNT]u8{ 'J', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'Q', 'K', 'A' };

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
	defer std.debug.assert(gpa.deinit() == .ok);
	const allocator = gpa.allocator();

	log.info("first: {}", .{ try solve_1(allocator, INPUT) });
	log.info("second: {}", .{ try solve_2(allocator, INPUT) });
}

fn solve_1(allocator: std.mem.Allocator, input: []const u8) !u64 {
	var hands = try parse_input(allocator, input);
	defer allocator.free(hands);
	std.sort.heap(Hand, hands, void{}, Hand.less_than_fn);
	var result: u64 = 0;
	for (hands, 1..) |hand, i| {
		result += hand.bid * @as(u64, @intCast(i));
	}
	return result;
}

test "solve_1 test input" {
	var input =
		\\32T3K 765
		\\T55J5 684
		\\KK677 28
		\\KTJJT 220
		\\QQQJA 483
		\\
	;
	try testing.expectEqual(@as(u64, 6440), try solve_1(testing.allocator, input));
}

test "solve_1 puzzle input" {
	try testing.expectEqual(@as(u64, 247961593), try solve_1(testing.allocator, INPUT));
}

const Hand = struct {
	kind: Kind,
	value: u20,
	bid: u64,

	fn less_than_fn(_: void, a: Hand, b: Hand) bool {
		if (a.kind == b.kind) {
			return a.value < b.value;
		}
		return @intFromEnum(a.kind) < @intFromEnum(b.kind);
	}
};

const Kind = enum(u8) {
	high_card = 1,
	one_pair,
	two_pair,
	three_of_a_kind,
	full_house,
	four_of_a_kind,
	five_of_a_kind,
};

fn parse_input(allocator: std.mem.Allocator, input: []const u8) ![]Hand {
	var list = try std.ArrayList(Hand).initCapacity(allocator, 8);
	errdefer list.deinit();
	var it = std.mem.tokenizeAny(u8, input, " \n");
	while (it.next()) |hand| {
		const bid = try std.fmt.parseInt(u64, it.next().?, 10);
		try list.append(.{
			.kind = find_kind(hand),
			.value = find_value(hand, CARD_VALUES),
			.bid = bid,
		});
	}
	return list.toOwnedSlice();
}

fn find_kind(hand: []const u8) Kind {
	std.debug.assert(hand.len == HAND_SIZE);
	const CountedCard = struct {
		card: u8,
		count: u8,
	};
	var cards = std.mem.zeroes([HAND_SIZE]CountedCard);
	var cards_count: usize = 0;

	for (hand) |new_card| {
		var not_found = true;
		for (cards[0..cards_count]) |*counted_card| {
			if (counted_card.card == new_card) {
				counted_card.count += 1;
				not_found = false;
			}
		}
		if (not_found) {
			cards[cards_count] = .{ .card = new_card, .count = 1 };
			cards_count += 1;
		}
	}

	const LocalFn = struct {
		fn less_than_fn(_: void, a: CountedCard, b: CountedCard) bool {
			return a.count < b.count;
		}
	};
	std.sort.heap(CountedCard, cards[0..cards_count], void{}, LocalFn.less_than_fn);

	switch (cards_count) {
		1 => return .five_of_a_kind,
		2 => return if (cards[0].count == 1) .four_of_a_kind else .full_house,
		3 => return if (cards[1].count == 1) .three_of_a_kind else .two_pair,
		4 => return .one_pair,
		5 => return .high_card,
		else => @panic("unrecognized hand kind"),
	}
}

test find_kind {
	try testing.expectEqual(Kind.five_of_a_kind, find_kind("AAAAA"));
	try testing.expectEqual(Kind.four_of_a_kind, find_kind("AA8AA"));
	try testing.expectEqual(Kind.full_house, find_kind("23332"));
	try testing.expectEqual(Kind.three_of_a_kind, find_kind("TTT98"));
	try testing.expectEqual(Kind.two_pair, find_kind("23432"));
	try testing.expectEqual(Kind.one_pair, find_kind("A23A4"));
	try testing.expectEqual(Kind.high_card, find_kind("23456"));
}

fn solve_2(allocator: std.mem.Allocator, input: []const u8) !u64 {
	var hands = blk: {
		var list = try std.ArrayList(Hand).initCapacity(allocator, 8);
		errdefer list.deinit();
		var it = std.mem.tokenizeAny(u8, input, " \n");
		while (it.next()) |hand| {
			const bid = try std.fmt.parseInt(u64, it.next().?, 10);
			try list.append(.{
				.kind = find_kind_with_joker(hand),
				.value = find_value(hand, CARD_VALUES_WITH_JOKER),
				.bid = bid,
			});
		}
		break :blk try list.toOwnedSlice();
	};
	defer allocator.free(hands);
	std.sort.heap(Hand, hands, void{}, Hand.less_than_fn);
	var result: u64 = 0;
	for (hands, 1..) |hand, i| {
		result += hand.bid * @as(u64, @intCast(i));
	}
	return result;
}

test "solve_2 test input" {
	var input =
		\\32T3K 765
		\\T55J5 684
		\\KK677 28
		\\KTJJT 220
		\\QQQJA 483
		\\
	;
	try testing.expectEqual(@as(u64, 5905), try solve_2(testing.allocator, input));
}

test "solve_2 puzzle input" {
	try testing.expectEqual(@as(u64, 248750699), try solve_2(testing.allocator, INPUT));
}

fn find_value(hand: []const u8, card_values: []const u8) u20 {
	std.debug.assert(hand.len == HAND_SIZE);
	var value: u20 = 0;
	for (hand) |card| {
		for (card_values, 0..) |matching_card, card_value| {
			if (card == matching_card) {
				value = value << 4 | @as(u4, @intCast(card_value));
				break;
			}
		}
	}
	return value;
}

test "find_value with joker" {
	try testing.expect(find_value("JKKK2", CARD_VALUES_WITH_JOKER) < find_value("QQQQ2", CARD_VALUES_WITH_JOKER));
	try testing.expect(find_value("T55J5", CARD_VALUES_WITH_JOKER) < find_value("T5555", CARD_VALUES_WITH_JOKER));
	try testing.expect(find_value("T5JJ5", CARD_VALUES_WITH_JOKER) < find_value("T55J5", CARD_VALUES_WITH_JOKER));
}

fn find_kind_with_joker(hand: []const u8) Kind {
	std.debug.assert(hand.len == HAND_SIZE);
	const CountedCard = struct {
		card: u8,
		count: u8,
	};
	var cards = std.mem.zeroes([HAND_SIZE]CountedCard);
	var cards_count: usize = 0;

	for (hand) |new_card| {
		var not_found = true;
		for (cards[0..cards_count]) |*counted_card| {
			if (counted_card.card == new_card) {
				counted_card.count += 1;
				not_found = false;
			}
		}
		if (not_found) {
			cards[cards_count] = .{ .card = new_card, .count = 1 };
			cards_count += 1;
		}
	}

	const LocalFn = struct {
		fn less_than_fn(_: void, a: CountedCard, b: CountedCard) bool {
			if (a.card == 'J') {
				return true;
			}
			if (b.card == 'J') {
				return false;
			}
			return a.count < b.count;
		}
	};
	std.sort.heap(CountedCard, cards[0..cards_count], void{}, LocalFn.less_than_fn);

	if (cards[0].card == 'J') {
		switch (cards_count) {
			1 => return .five_of_a_kind,
			2 => return .five_of_a_kind,
			// 1 + 1 + 3 or 1 + 2 + 2
			3 => return switch (cards[0].count) {
				// 1 + 1 + 3 or 1 + 2 + 2
				1 => if (cards[1].count == 1) .four_of_a_kind else .full_house,
				// 2 + 1 + 2
				2 => .four_of_a_kind,
				// 3 + 1 + 1
				3 => .four_of_a_kind,
				else => @panic("unrecognized hand kind"),
			},
			4 => return .three_of_a_kind,
			5 => return .one_pair,
			else => @panic("unrecognized hand kind"),
		}
	}

	switch (cards_count) {
		1 => return .five_of_a_kind,
		2 => return if (cards[0].count == 1) .four_of_a_kind else .full_house,
		3 => return if (cards[1].count == 1) .three_of_a_kind else .two_pair,
		4 => return .one_pair,
		5 => return .high_card,
		else => @panic("unrecognized hand kind"),
	}
}

test find_kind_with_joker {
	try testing.expect(find_kind_with_joker("32T3K") == .one_pair);
	try testing.expect(find_kind_with_joker("KK677") == .two_pair);
	try testing.expect(find_kind_with_joker("T55J5") == .four_of_a_kind);
	try testing.expect(find_kind_with_joker("KTJJT") == .four_of_a_kind);
	try testing.expect(find_kind_with_joker("QQQJA") == .four_of_a_kind);
}
