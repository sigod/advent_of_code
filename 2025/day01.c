#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int rotation_parse(char *line)
{
    int result;
    if (line[0] == 'L') result = -1;
    else if (line[0] == 'R') result = 1;
    else return 0;
    result *= atoi(&line[1]);
    return result;
}

struct Puzzle
{
    int dial;
    int answer1;
    int answer2;
};

void puzzle_rotate_dial(struct Puzzle *puzzle, int rotation)
{
    int turn = rotation > 0 ? 1 : -1;
    int turns = abs(rotation);
    while (turns > 0) {
        puzzle->dial += turn;
        if (puzzle->dial == -1) puzzle->dial = 99;
        else if (puzzle->dial == 100) puzzle->dial = 0;
        turns -= 1;
        if (puzzle->dial == 0) {
            puzzle->answer2 += 1;
        }
    }
    if (puzzle->dial == 0) {
        puzzle->answer1 += 1;
    }
}

int expected(struct Puzzle expected, struct Puzzle actual)
{
    if (expected.dial != actual.dial) {
        printf("dial: expected %d got %d\n", expected.dial, actual.dial);
        return 0;
    }
    if (expected.answer1 != actual.answer1) {
        printf("answer1: expected %d got %d\n", expected.answer1, actual.answer1);
        return 0;
    }
    if (expected.answer2 != actual.answer2) {
        printf("answer2: expected %d got %d\n", expected.answer2, actual.answer2);
        return 0;
    }
    return 1;
}

int test(void)
{
    struct Puzzle puzzle = {50, 0, 0}; if (!expected((struct Puzzle){50, 0, 0}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, +1000); if (!expected((struct Puzzle){50, 0, 10}, puzzle)) return 1;
    printf("test 1: OK\n");
    /* */
    puzzle = (struct Puzzle){50, 0, 0}; if (!expected((struct Puzzle){50, 0, 0}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, -68); if (!expected((struct Puzzle){82, 0, 1}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, -30); if (!expected((struct Puzzle){52, 0, 1}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, +48); if (!expected((struct Puzzle){0, 1, 2}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, -5); if (!expected((struct Puzzle){95, 1, 2}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, +60); if (!expected((struct Puzzle){55, 1, 3}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, -55); if (!expected((struct Puzzle){0, 2, 4}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, -1); if (!expected((struct Puzzle){99, 2, 4}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, -99); if (!expected((struct Puzzle){0, 3, 5}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, +14); if (!expected((struct Puzzle){14, 3, 5}, puzzle)) return 1;
    puzzle_rotate_dial(&puzzle, -82); if (!expected((struct Puzzle){32, 3, 6}, puzzle)) return 1;
    printf("test 2: OK\n");
    return 0;
}

int main(int argc, char *argv[])
{
    if (argc > 1 && strcmp(argv[1], "--test") == 0)
        return test();

    char *filename = "day01-input.txt";
    FILE* input_file = fopen(filename, "r");
    if (input_file == NULL) {
        printf("failed to open '%s'\n", filename);
        return 1;
    }
    char line_buffer[16];
    struct Puzzle puzzle = {50, 0, 0};
    while (!feof(input_file)) {
        char *line = fgets(line_buffer, sizeof line_buffer, input_file);
        if (line == NULL)
            break;
        int rotation = rotation_parse(line);
        if (rotation == 0) {
            printf("failed to parse line '%s'\n", line);
            return 1;
        }
        puzzle_rotate_dial(&puzzle, rotation);
    }
    printf("answer1: %d, answer2: %d\n", puzzle.answer1, puzzle.answer2);
    return 0;
}
