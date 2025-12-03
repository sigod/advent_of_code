#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define true 1
#define false 0

int number_length(uint64_t id)
{
    int length = 0;
    while (id > 0) {
        length += 1;
        id /= 10;
    }
    return length;
}

int p1_is_invalid(uint64_t id)
{
    int length = number_length(id);
    if (length % 2 == 1)
        return false;
    uint64_t divisor = 1;
    for (int i = 0; i < length / 2; i += 1)
        divisor *= 10;
    uint64_t part0 = id % divisor;
    uint64_t part1 = (id / divisor) % divisor;
    return part0 == part1;
}

int p2_is_invalid(uint64_t id)
{
    int length = number_length(id);
    uint64_t divisor = 1;
    for (int part_len = 1; part_len <= length / 2; part_len += 1) {
        divisor *= 10;
        if (length % part_len != 0)
            continue;
        uint64_t part0 = id % divisor;
        uint64_t tmp_id = id / divisor;
        int invalid = true;
        while (tmp_id > 0) {
            uint64_t part = tmp_id % divisor;
            if (part != part0) {
                invalid = false;
                break;
            }
            tmp_id /= divisor;
        }
        if (invalid)
            return true;
    }
    return false;
}

uint64_t check_range(uint64_t a, uint64_t b, int (*is_invalid)(uint64_t))
{
    uint64_t sum = 0;
    for (uint64_t id = a; id <= b; id += 1) {
        if (is_invalid(id)) {
            sum += id;
        }
    }
    return sum;
}

int test(void)
{
    { /* part 1 */
        uint64_t sum = 0;
        sum += check_range(11, 22, p1_is_invalid);
        sum += check_range(95, 115, p1_is_invalid);
        sum += check_range(998, 1012, p1_is_invalid);
        sum += check_range(1188511880, 1188511890, p1_is_invalid);
        sum += check_range(222220, 222224, p1_is_invalid);
        sum += check_range(1698522, 1698528, p1_is_invalid);
        sum += check_range(446443, 446449, p1_is_invalid);
        sum += check_range(38593856, 38593862, p1_is_invalid);
        sum += check_range(565653, 565659, p1_is_invalid);
        sum += check_range(824824821, 824824827, p1_is_invalid);
        sum += check_range(2121212118, 2121212124, p1_is_invalid);
        if (sum != 1227775554) {
            printf("test1: expected 1227775554, found %lld\n", sum);
            return 1;
        }
        printf("test1: OK\n");
    }
    { /* part 2 */
        long long sum = 0;
        sum += check_range(11, 22, p2_is_invalid);
        sum += check_range(95, 115, p2_is_invalid);
        sum += check_range(998, 1012, p2_is_invalid);
        sum += check_range(1188511880, 1188511890, p2_is_invalid);
        sum += check_range(222220, 222224, p2_is_invalid);
        sum += check_range(1698522, 1698528, p2_is_invalid);
        sum += check_range(446443, 446449, p2_is_invalid);
        sum += check_range(38593856, 38593862, p2_is_invalid);
        sum += check_range(565653, 565659, p2_is_invalid);
        sum += check_range(824824821, 824824827, p2_is_invalid);
        sum += check_range(2121212118, 2121212124, p2_is_invalid);
        if (sum != 4174379265) {
            printf("test2: expected 4174379265, found %lld\n", sum);
            return 1;
        }
        printf("test2: OK\n");
    }
    return 0;
}

int main(int argc, char *argv[])
{
    if (argc > 1 && strcmp(argv[1], "--test") == 0)
        return test();
    char *filename = "day02-input.txt";
    FILE* input_file = fopen(filename, "r");
    if (input_file == NULL) {
        printf("failed to open '%s'\n", filename);
        return 1;
    }
    uint64_t sum1 = 0;
    uint64_t sum2 = 0;
    uint64_t a;
    uint64_t b;
    while (fscanf(input_file, "%lld-", &a) != EOF) {
        if (fscanf(input_file, "%lld,", &b) == EOF) {
            printf("invalid input file\n");
            return 1;
        }
        sum1 += check_range(a, b, p1_is_invalid);
        sum2 += check_range(a, b, p2_is_invalid);
    }
    printf("answer1: %lld, answer2: %lld\n", sum1, sum2);
    return 0;
}
