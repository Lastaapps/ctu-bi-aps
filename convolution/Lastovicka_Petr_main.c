#pragma GCC optimize("unroll-loops")

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
    FILE * input;
    FILE * output;
    uint16_t offset;
} Picture;

void printAddressSpace() {
    char cmd[64];
    sprintf(cmd,"cat /proc/%d/maps", getpid());
    printf("---------------------\n Virtual address space: \n");
    system(cmd);
}

inline void openFile(Picture * pic, const char* filename) {

    int inFile = open(filename, O_RDONLY);
    int outFile = open("output.ppm", O_RDWR | O_CREAT | O_TRUNC, 0660);
    // fdopen does not require files to be manually closed

    int offset;
    {
        FILE * input = fdopen(inFile, "r");
        fscanf(input, "P6 %hu %hu 255", &pic -> width, &pic -> height);
        offset = ftell(input) + 1;

        FILE * output = fdopen(outFile ,"wb");
        fprintf(output, "P6\n%d\n%d\n255\n", pic -> width, pic -> height);
        fflush(output);

        pic -> input = input;
        pic -> output = output;
    }

    size_t size = lseek(inFile, 0, SEEK_END);
    lseek(inFile, 0, SEEK_SET);

    pic -> data = (uint8_t*) mmap (
            NULL, size,
            PROT_READ, MAP_PRIVATE, inFile, 0
            );

    ftruncate(outFile, size);

    pic -> out = (uint8_t*) mmap (
            NULL, size,
            PROT_READ | PROT_WRITE, MAP_SHARED, outFile, 0
            );

    pic -> offset = offset;
    pic -> size = size;
    pic -> inFile = inFile;
    pic -> outFile = outFile;

    // printAddressSpace();
}

uint32_t sumInteval(const uint32_t * histogram, uint8_t from, uint8_t to) {
    uint32_t sum = 0;
    for (uint8_t i = from; i < to; ++i)
        sum += histogram[i];
    sum += histogram[to];
    return sum;
}

inline void saveHistogram(uint32_t* histogram) {
    uint32_t * h = histogram;
    FILE * output = fopen("output.txt" ,"w");

    h[0] = sumInteval(h, 0, 50);
    h[1] = sumInteval(h, 51, 101);
    h[2] = sumInteval(h, 102, 152);
    h[3] = sumInteval(h, 153, 203);
    h[4] = sumInteval(h, 204, 255);

    printf("%u %u %u %u %u\n", h[0], h[1], h[2], h[3], h[4]);
    fprintf(output, "%u %u %u %u %u", h[0], h[1], h[2], h[3], h[4]);
    fclose(output);
}

inline void closeFiles(const Picture* pic) {
    munmap(pic->data, pic->size);
    fclose(pic -> input);
    close(pic->inFile);

    msync (pic->out, pic->size, MS_SYNC);
    munmap(pic->out, pic->size);
    fclose(pic -> output);
    close(pic->outFile);
}

typedef struct Pixel_t {
    uint8_t r, g, b;
} Pixel;

#define toHisto(r, g, b) (uint8_t) (0.2126 * (r) + 0.7152 * (g)  + 0.0722 * (b) + 0.5)
#define toRange(c) ((c) > 255 ? 255 : (c) < 0 ? 0 : (c))

inline void copyRows(const Pixel* in, Pixel* out, uint32_t * histogram,  uint32_t i, uint32_t to) {
    for (; i < to; ++i) {
        Pixel ii = in[i];
        out[i] = ii;

        ++histogram[toHisto(ii.r, ii.g, ii.b)];
    }
}

inline void convovle(const Picture * pic, uint32_t * histogram) {

    const Pixel* in = (Pixel*) (pic->data + pic->offset);
    Pixel* out = (Pixel*) (pic->out + pic->offset);

    const int32_t width = pic->width;
    const int32_t height = pic->height;

    copyRows(in, out, histogram, 0, width);

    for (int32_t row = 1; row < height - 1; ++row) {

        const int32_t rw  = row * width;
        {
            Pixel ii = in[rw];
            out[rw] = ii;
            ++histogram[toHisto(ii.r, ii.g, ii.b)];
        }

        for (int32_t col = 1; col < width - 1; ++col) {

            const int32_t ic = rw + col;

            int32_t r, g, b;
            Pixel ii;

            ii = in[ic];
            r = 5 * ii.r; g = 5 * ii.g; b = 5 * ii.b;

            ii = in[ic - width];
            r -= ii.r; g -= ii.g; b -= ii.b;

            ii = in[ic + width];
            r -= ii.r; g -= ii.g; b -= ii.b;

            ii = in[ic - 1];
            r -= ii.r; g -= ii.g; b -= ii.b;

            ii = in[ic + 1];
            r -= ii.r; g -= ii.g; b -= ii.b;

            r = toRange(r);
            g = toRange(g);
            b = toRange(b);

            out[ic].r = r;
            out[ic].g = g;
            out[ic].b = b;

            ++histogram[toHisto(r, g, b)];
        }

        {
            const int32_t rwp = rw + width - 1;
            Pixel ii = in[rwp];
            out[rwp] = ii;
            ++histogram[toHisto(ii.r, ii.g, ii.b)];
        }
    }

    {
        const uint32_t area = height * width;
        copyRows(in, out, histogram, area - width, area);
    }
}

int main(const int argsCount, const char** args) {
    Picture pic;
    openFile(&pic, args[1]);
    uint32_t histogram[256] = {0};

    convovle(&pic, histogram);

    saveHistogram(histogram);
    closeFiles(&pic);
    return 0;
}
