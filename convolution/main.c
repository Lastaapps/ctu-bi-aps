#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

typedef struct Picture_t {
    uint8_t * data;
    uint8_t * out;
    size_t size;
    uint16_t width;
    uint16_t height;
} Picture;

inline Picture openFile(const char* filename) {

    printf("Opening file: %s\n", filename);

    Picture pic;
    {
        FILE * fp;
        fp = fopen (filename, "r");
        fscanf(fp, "P6 %hu %hu", &pic.width, &pic.height);
        fclose(fp);
    }

    uint8_t offset = 0;
    {
        FILE * fp = fopen (filename, "rb");
        FILE * output = fopen("output.ppm" ,"wb");

        uint8_t newLinesToSkip = 4;
        uint8_t tmp;
        while (newLinesToSkip > 0) {
            fread(&tmp, sizeof(uint8_t), 1, fp);
            if (tmp == '\n') --newLinesToSkip;
            ++offset;
            fwrite(&tmp, sizeof(uint8_t), 1, output);
        }

        fclose(fp);
        fclose(output);
    }

    int file = open(filename, O_RDONLY);
    int output = open("output.ppm", O_RDONLY);

    struct stat s;
    fstat(file, &s);
    pic.size = s.st_size;

    pic.data = (uint8_t*) mmap (
        NULL, pic.size,
        PROT_READ, MAP_PRIVATE, file, 0
    ) + offset;
    pic.out = (uint8_t*) mmap (
        NULL, pic.size,
        PROT_READ, MAP_PRIVATE, output, 0
    ) + offset;

    return pic;
}

inline void saveHistogram(const size_t* histogram) {
    const size_t * h = histogram;
    FILE * output = fopen("output.txt" ,"w");
    fprintf(output, "%lu %lu %lu %lu %lu", h[0], h[1], h[2], h[3], h[4]);
    fclose(output);
}

inline void closeFiles(const Picture* pic) {
    munmap(pic->data, pic->size);
    munmap(pic->out, pic->size);
}

inline void convovle(const Picture pic, size_t * histogram) {

}

int main(const int argsCount, const char** args) {
    const Picture pic = openFile(args[1]);
    size_t histogram[5];

    convovle(pic, histogram);

    saveHistogram(histogram);
    closeFile(pic);
    return 0;
}
