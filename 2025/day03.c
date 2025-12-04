#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define true 1
#define false 0

uint64_t find_joltage(char *bank, int desired_length)
{
    int len = strlen(bank);
    int to_remove = len - desired_length;
    char batteries[16];
    int top = -1;
    for (int i = 0; i < len; i += 1) {
        while (to_remove > 0 && top >= 0 && batteries[top] < bank[i]) {
            top -= 1;
            to_remove -= 1;
        }
        if (top + 1 < desired_length) {
            top += 1;
            batteries[top] = bank[i];
        }
        else {
            to_remove -= 1;
        }
    }
    batteries[top + 1] = '\0';
    uint64_t result = atoll(batteries);
    return result;
}

int expect(char *bank, int expected)
{
    int actual = find_joltage(bank, 2);
    if (actual != expected) {
        printf("%s: expected %d, but got %d\n", bank, expected, actual);
        return false;
    }
    return true;
}

int test(void)
{
    { /* part 1 */
        uint64_t sum = 0;
        sum += find_joltage("987654321111111", 2);
        sum += find_joltage("811111111111119", 2);
        sum += find_joltage("234234234234278", 2);
        sum += find_joltage("818181911112111", 2);
        if (sum != 357) {
            printf("test1: expected 357, found %lld\n", sum);
            return 1;
        }
    }
    { /* part 2 */
        uint64_t sum = 0;
        sum += find_joltage("987654321111111", 12);
        sum += find_joltage("811111111111119", 12);
        sum += find_joltage("234234234234278", 12);
        sum += find_joltage("818181911112111", 12);
        if (sum != 3121910778619) {
            printf("test1: expected 3121910778619, found %lld\n", sum);
            return 1;
        }
    }
    return 0;
}

int main(int argc, char *argv[])
{
    if (argc > 1 && strcmp(argv[1], "--test") == 0)
        return test();
    char *filename = "day03-input.txt";
    FILE* input_file = fopen(filename, "r");
    if (input_file == NULL) {
        printf("failed to open '%s'\n", filename);
        return 1;
    }
    char line_buffer[128];
    uint64_t sum1 = 0;
    uint64_t sum2 = 0;
    while (fscanf(input_file, "%s\n", line_buffer) != EOF) {
        char *line = line_buffer;
        sum1 += find_joltage(line, 2);
        sum2 += find_joltage(line, 12);
    }
    printf("answer1: %lld, answer2: %lld\n", sum1, sum2);
    return 0;
}
