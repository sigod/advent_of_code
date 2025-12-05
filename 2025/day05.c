#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

struct Range
{
    uint64_t begin;
    uint64_t end;
};

int range_comp(const void *a, const void *b)
{
    struct Range *range_a = (struct Range *)a;
    struct Range *range_b = (struct Range *)b;
    if (range_a->begin < range_b->begin) return -1;
    if (range_a->begin > range_b->begin) return 1;
    return 0;
}

size_t merge_ranges(struct Range *ranges, size_t count)
{
    qsort(ranges, count, sizeof ranges[0], range_comp);
    size_t top = 0;
    for (size_t i = 1; i < count; i += 1) {
        if ((ranges[top].begin <= ranges[i].begin && ranges[i].begin <= ranges[top].end)
            || (ranges[top].end + 1 == ranges[i].begin))
        {
            if (ranges[top].end < ranges[i].end)
                ranges[top].end = ranges[i].end;
            continue;
        }
        if (top + 1 < i) {
            ranges[top + 1] = ranges[i];
        }
        top += 1;
    }
    return top + 1;
}

int main(void)
{
    struct Range ranges[256];
    size_t range_count = 0;
    char *filename = "day05-input.txt";
    FILE* input_file = fopen(filename, "r");
    if (input_file == NULL) {
        printf("failed to open '%s'\n", filename);
        return 1;
    }
    while (!feof(input_file)) {
        char line_buffer[64];
        char *line = fgets(line_buffer, sizeof line_buffer, input_file);
        if (line == NULL) {
            printf("invalid input file\n");
            return 1;
        }
        if (line[0] == '\n') {
            break;
        }
        if (sscanf_s(line, "%lld-%lld\n", &ranges[range_count].begin, &ranges[range_count].end) != 2) {
            printf("invalid input file\n");
            return 1;
        }
        range_count += 1;
    }
    range_count = merge_ranges(ranges, range_count);
    size_t answer1 = 0;
    uint64_t id;
    while (fscanf_s(input_file, "%lld\n", &id) != EOF) {
        for (size_t i = 0; i < range_count; i += 1) {
            if (ranges[i].begin <= id && id <= ranges[i].end) {
                answer1 += 1;
                break;
            }
        }
    }
    uint64_t answer2 = 0;
    for (size_t i = 0; i < range_count; i += 1) {
        answer2 += ranges[i].end - ranges[i].begin + 1;
    }
    printf("answer1: %zd, answer2: %lld\n", answer1, answer2);
    return 0;
}
