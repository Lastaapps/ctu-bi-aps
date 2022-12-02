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

inline uint32_t sumInteval(const uint32_t * histogram, uint8_t from, uint8_t to) {
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

inline void convovle(const Picture * pic, uint32_t * histogram) {

    const Pixel* in = (Pixel*) (pic->data + pic->offset);
    Pixel* out = (Pixel*) (pic->out + pic->offset);

    const int32_t width = pic->width;
    const int32_t heightMin1 = pic->height - 1;

    for (int32_t row = 0; row <= heightMin1; ++row) {

        const int32_t rw  = row * width;
        int32_t rwm, rwp;

        int8_t isBound = row == heightMin1 || (rwm = rw - width) < 0;

        rwp = rw + width;

        for (int32_t col = 0; col < width; ++col) {

            int32_t h;
            int32_t il, ir;
            const int32_t ic = rw + col;

            if (!(isBound || (il = col - 1) < 0 || (ir = col + 1) >= width)) {
                il += rw;
                ir += rw;
                const int32_t it = rwm + col;
                const int32_t ib = rwp + col;

#define toRange(c) ((c) > 255 ? 255 : (c) < 0 ? 0 : (c))

                int32_t r, g, b;
                Pixel ii;

                ii = in[ic];
                r = 5 * ii.r; g = 5 * ii.g; b = 5 * ii.b;

                ii = in[it];
                r -= ii.r; g -= ii.g; b -= ii.b;

                ii = in[ib];
                r -= ii.r; g -= ii.g; b -= ii.b;

                ii = in[il];
                r -= ii.r; g -= ii.g; b -= ii.b;

                ii = in[ir];
                r -= ii.r; g -= ii.g; b -= ii.b;

                r = toRange(r);
                g = toRange(g);
                b = toRange(b);

                out[ic].r = r;
                out[ic].g = g;
                out[ic].b = b;
                h = 0.2126 * r + 0.7152 * g  + 0.0722 * b + 0.5;

            } else {
                Pixel ii = in[ic];
                out[ic] = ii;
                h = 0.2126 * ii.r + 0.7152 * ii.g  + 0.0722 * ii.b + 0.5;
            }


            ++histogram[h];
        }
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
