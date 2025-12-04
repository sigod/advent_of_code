#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

size_t count_adjacent(const char **grid, size_t width, size_t height, size_t x, size_t y)
{
    const int coords[8][2] = {
        {-1, -1},
        {-1, +0},
        {-1, +1},
        {+0, +1},
        {+1, +1},
        {+1, +0},
        {+1, -1},
        {+0, -1},
    };
    size_t count = 0;
    for (size_t i = 0; i < 8; i += 1) {
        int y_ = y + coords[i][0];
        int x_ = x + coords[i][1];
        if ((0 <= y_ && y_ < (int)height) && (0 <= x_ && x_ < (int)width))
            if (grid[y_][x_] == '@')
                count += 1;
    }
    return count;
}

int main(void)
{
    char *input;
    size_t input_len;
    {
        char *filename = "day04-input.txt";
        FILE* input_file = fopen(filename, "rb");
        if (input_file == NULL) {
            printf("failed to open '%s'\n", filename);
            return 1;
        }
        fseek(input_file, 0, SEEK_END);
        input_len = ftell(input_file);
        fseek(input_file, 0, SEEK_SET);
        input = malloc((sizeof *input) * input_len);
        if (!input) {
            printf("failed to allocate memory\n");
            return 0;
        }
        size_t bytes_read = fread(input, sizeof *input, input_len, input_file);
        if (bytes_read != input_len || ferror(input_file)) {
            printf("failed to read the contents of '%s'\n", filename);
            return 0;
        }
        fclose(input_file);
    }
    size_t width = 0;
    size_t height = 0;
    {
        for (; input[width] != '\n'; width += 1) {}
        for (size_t i = 0; i < input_len; i += 1) {
            if (input[i] == '\n')
                height += 1;
        }
        if (input[input_len - 1] != '\n')
            height += 1;
    }
    char **grid = malloc((sizeof *grid) * height);
    for (size_t i = 0, j = 0; i < height; i += 1) {
        grid[i] = &input[j];
        while (input[j] != '\n') {
            j += 1;
        }
        input[j] = '\0';
        j += 1;
    }
    size_t answer1 = 0;
    for (size_t x = 0; x < width; x += 1) {
        for (size_t y = 0; y < height; y += 1) {
            if (grid[y][x] != '@')
                continue;
            size_t count = count_adjacent(grid, width, height, x, y);
            if (count < 4)
                answer1 += 1;
        }
    }
    size_t answer2 = 0;
    size_t previously_removed;
    do {
        previously_removed = 0;
        for (size_t x = 0; x < width; x += 1) {
            for (size_t y = 0; y < height; y += 1) {
                if (grid[y][x] != '@')
                    continue;
                size_t count = count_adjacent(grid, width, height, x, y);
                if (count < 4) {
                    grid[y][x] = '.';
                    answer2 += 1;
                    previously_removed += 1;
                }
            }
        }
    } while (previously_removed > 0);
    printf("answer1: %zu, answer2: %zu\n", answer1, answer2);
    return 0;
}
