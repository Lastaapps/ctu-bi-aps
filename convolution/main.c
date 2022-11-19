#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <math.h>
#include <string.h>

typedef struct Picture_t {
    uint8_t * data;
    uint8_t * out;
    size_t size;
    uint16_t width;
    uint16_t height;
    int inFile;
    int outFile;
    uint16_t offset;
} Picture;

void printAddressSpace() {
    char cmd[64];
    sprintf(cmd,"cat /proc/%d/maps", getpid());
    printf("---------------------\n Virtual address space: \n");
    system(cmd);
}

inline Picture openFile(const char* filename) {

    printf("Opening file: %s\n", filename);

    Picture pic;
    {
        FILE * fp;
        fp = fopen (filename, "r");
        fscanf(fp, "P6 %hu %hu", &pic.width, &pic.height);
        fclose(fp);
    }

    pic.offset = 0;
    {
        FILE * fp = fopen (filename, "rb");
        FILE * output = fopen("output.ppm" ,"wb");

        uint8_t newLinesToSkip = 4;
        uint8_t tmp;
        while (newLinesToSkip > 0) {
            fread(&tmp, sizeof(uint8_t), 1, fp);
            if (tmp == '\n') --newLinesToSkip;
            ++pic.offset;
            fwrite(&tmp, sizeof(uint8_t), 1, output);
        }

        fclose(fp);
        fclose(output);
    }

    pic.inFile = open(filename, O_RDONLY);
    pic.outFile = open("output.ppm", O_RDWR);

    {
        struct stat s;
        fstat(pic.inFile, &s);
        pic.size = s.st_size;
    }

    pic.data = (uint8_t*) mmap (
        NULL, pic.size,
        PROT_READ, MAP_PRIVATE, pic.inFile, 0
    );

    ftruncate(pic.outFile, pic.size);
    if (lseek(pic.outFile, pic.size - 1, SEEK_SET) == -1)
        return pic;
    if (write(pic.outFile, "", 1) == -1)
        return pic;
    pic.out = (uint8_t*) mmap (
        NULL, pic.size,
        PROT_READ | PROT_WRITE, MAP_SHARED, pic.outFile, 0
    );

    printAddressSpace();
    printf("%lu -> %lu, %u\n", pic.size, (pic.size - pic.offset) / 3 + pic.offset, pic.offset);

    return pic;
}

inline void saveHistogram(const size_t* histogram) {
    const size_t * h = histogram;
    FILE * output = fopen("output.txt" ,"w");
    printf("Histogram: %lu %lu %lu %lu %lu", h[0], h[1], h[2], h[3], h[4]);
    fprintf(output, "%lu %lu %lu %lu %lu", h[0], h[1], h[2], h[3], h[4]);
    fclose(output);
}

inline void closeFiles(const Picture* pic) {
    munmap(pic->data, pic->size);
    close(pic->inFile);

    msync (pic->out, pic->size, MS_SYNC);
    munmap(pic->out, pic->size);
    close(pic->outFile);
}

typedef struct Pixel_t {
    uint8_t r, g, b;
} Pixel;

#define blockIndex(block) ((block) / 3 * 3) * 64 / 3 + ((block) % 3) * 64 / 3;

inline void convovle(const Picture * pic, size_t * histogram) {
    // L1 cache has 64B block size

    Pixel*  in = (Pixel*) (pic->data + pic->offset);
    Pixel* out = (Pixel*) (pic->out  + pic->offset);

    uint16_t blockEnd = blockIndex(0);

    for (uint16_t block = 0; block < pic->width / (64 / 3) + 1; ++block) {

        const uint8_t blockStart = blockEnd;
        blockEnd = blockIndex(block + 1);
        blockEnd = blockEnd <= pic->width ? blockEnd : pic->width;

        printf(" %hu: %hu  -> %hu\n", block, blockStart, blockEnd);

        for (uint16_t row = 0; row < pic -> height; ++row) {
            for (uint16_t col = blockStart; col < blockEnd; ++col) {

                const size_t index = row * pic -> width + col;

                printf("(%u, %u) -> %lu\n", row, col, index);
                out[index] = in[index];
            }
        }
    }
}

int main(const int argsCount, const char** args) {
    const Picture pic = openFile(args[1]);
    size_t histogram[5];

    convovle(&pic, histogram);

    saveHistogram(histogram);
    closeFiles(&pic);
    return 0;
}
