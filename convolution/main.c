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

    // printf("Opening file: %s\n", filename);

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

    pic.out = (uint8_t*) mmap (
        NULL, pic.size,
        PROT_READ | PROT_WRITE, MAP_SHARED, pic.outFile, 0
    );

    // printAddressSpace();

    return pic;
}

inline void saveHistogram(const size_t* histogram) {
    const size_t * h = histogram;
    FILE * output = fopen("output.txt" ,"w");
    // printf("Histogram: %lu %lu %lu %lu %lu\n", h[0], h[1], h[2], h[3], h[4]);
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

    const Pixel* in = (Pixel*) (pic->data + pic->offset);
    Pixel* out = (Pixel*) (pic->out + pic->offset);

    const int32_t width = pic->width;
    const int32_t height = pic->height;
    const int32_t area = width * height;

    int32_t blockEnd = blockIndex(0);

    for (int32_t block = 0; block < width / (64 / 3) + 1; ++block) {

        const int32_t blockStart = blockEnd;
        blockEnd = blockIndex(block + 1);
        blockEnd = blockEnd <= pic->width ? blockEnd : pic->width;

        for (int32_t row = 0; row < height; ++row) {

            const int32_t rw  = row * width;

            uint8_t isBound = 0;
            int32_t rwm, rwp;
            uint8_t h;

            if ((rwm = rw - width) < 0 || (rwp = rw + width) >= area)
                isBound = 1;

            for (int32_t col = blockStart; col < blockEnd; ++col) {

                const int32_t it = rwm + col;
                const int32_t ib = rwp + col;

                int32_t il, ir;
                const int32_t ic = rw + col;

                if (!(isBound || (il = col - 1) < 0 || (ir = col + 1) >= width)) {
                    il += rw;
                    ir += rw;

#define toRange(c) ((c) > 255 ? 255 : (c) < 0 ? 0 : (c))
#define r(x) ((int32_t)(x).r)
#define g(x) ((int32_t)(x).g)
#define b(x) ((int32_t)(x).b)

                    int32_t c;
                    float histo;

                    c = 5 * r(in[ic]) - (r(in[it]) + r(in[ib]) + r(in[il]) + r(in[ir]));
                    c = toRange(c);
                    histo = 0.2126 * c;
                    out[ic].r = c;

                    c = 5 * g(in[ic]) - (g(in[it]) + g(in[ib]) + g(in[il]) + g(in[ir]));
                    c = toRange(c);
                    histo += 0.7152 * c;
                    out[ic].g = c;

                    c = 5 * b(in[ic]) - (b(in[it]) + b(in[ib]) + b(in[il]) + b(in[ir]));
                    c = toRange(c);
                    histo = round(histo + 0.0722 * c);
                    out[ic].b = c;

                    h = histo;
                } else {
                    out[ic] = in[ic];
                    h = round(0.2126 * in[ic].r + 0.7152 * in[ic].g  + 0.0722 * in[ic].b);
                }

                if (h > 152)
                    if (h > 203)
                        ++histogram[4];
                    else
                        ++histogram[3];
                else
                    if (h > 101)
                        ++histogram[2];
                    else if (h > 50)
                        ++histogram[1];
                    else
                        ++histogram[0];
            }
        }
    }
}

int main(const int argsCount, const char** args) {
    const Picture pic = openFile(args[1]);
    size_t histogram[5] = {0, 0, 0, 0, 0};

    convovle(&pic, histogram);

    saveHistogram(histogram);
    closeFiles(&pic);
    return 0;
}