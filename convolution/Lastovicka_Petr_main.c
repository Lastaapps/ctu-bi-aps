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

inline void saveHistogram(const size_t* histogram) {
    const size_t * h = histogram;
    FILE * output = fopen("output.txt" ,"w");
    printf("%lu %lu %lu %lu %lu\n", h[0], h[1], h[2], h[3], h[4] + h[5]);
    fprintf(output, "%lu %lu %lu %lu %lu", h[0], h[1], h[2], h[3], h[4] + h[5]);
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

#define blockIndex(block) ((block) / 3 * 3) * 64 / 3 + ((block) % 3) * 64 / 3;

inline void convovle(const Picture * pic, size_t * histogram) {
    // L1 cache has 64B block size

    const Pixel* in = (Pixel*) (pic->data + pic->offset);
    Pixel* out = (Pixel*) (pic->out + pic->offset);

    const int32_t width = pic->width;
    const int32_t height = pic->height;
    const int32_t area = width * height;

    int32_t blockEnd = blockIndex(0);

    const int32_t blockCount = width / (64 / 3) + 1;
    for (int32_t block = 0; block < blockCount; ++block) {

        const int32_t blockStart = blockEnd;
        blockEnd = blockIndex(block + 1);
        blockEnd = blockEnd <= width ? blockEnd : width;

        for (int32_t row = 0; row < height; ++row) {

            int8_t isBound = 0;
            const int32_t rw  = row * width;
            int32_t rwm, rwp;

            if ((rwm = rw - width) < 0 || (rwp = rw + width) >= area)
                isBound = 1;

            for (int32_t col = blockStart; col < blockEnd; ++col) {

                int32_t h;
                int32_t il, ir;
                const int32_t ic = rw + col;

                if (!(isBound || (il = col - 1) < 0 || (ir = col + 1) >= width)) {
                    il += rw;
                    ir += rw;
                    const int32_t it = rwm + col;
                    const int32_t ib = rwp + col;

#define toRange(c) ((c) > 255 ? 255 : (c) < 0 ? 0 : (c))

// Is 20% slower than the original
// #define rr(x, i) ((int32_t)(*(((uint8_t*) &(x)) + i)))
//                     for (uint8_t i = 0; i < 3; ++i) {
//                         c = 5 * rr(in[ic], i) - (rr(in[it], i) + rr(in[ib], i) + rr(in[il], i) + rr(in[ir], i));
//                         c = toRange(c);
//                         *(((uint8_t*) &(out[ic])) + i) = c;
//                         switch(i){
//                             case 0:
//                                 histo = 0.2126 * c;
//                                 continue;
//                             case 1:
//                                 histo += 0.7152 * c;
//                                 continue;
//                             case 2:
//                                 h = round(histo + 0.0722 * c);
//                                 continue;
//                         }
//                     }

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
                    h = roundf(0.2126 * r + 0.7152 * g  + 0.0722 * b);

                    // Improved original
// #define r(x) ((int32_t)(x).r)
// #define g(x) ((int32_t)(x).g)
// #define b(x) ((int32_t)(x).b)
                    //int32_t c;
                    //float histo;
                    //const Pixel * iic = in + ic;
                    //const Pixel * iit = in + it;
                    //const Pixel * iib = in + ib;
                    //const Pixel * iil = in + il;
                    //const Pixel * iir = in + ir;
                    //Pixel * oo = out + ic;

                    //c = 5 * r(*iic) - (r(*iit) + r(*iib) + r(*iil) + r(*iir));
                    //c = toRange(c);
                    //histo = 0.2126 * c;
                    //oo->r = c;

                    //c = 5 * g(*iic) - (g(*iit) + g(*iib) + g(*iil) + g(*iir));
                    //c = toRange(c);
                    //histo += 0.7152 * c;
                    //oo->g = c;

                    //c = 5 * b(*iic) - (b(*iit) + b(*iib) + b(*iil) + b(*iir));
                    //c = toRange(c);
                    //h = roundf(histo + 0.0722 * c);
                    //oo->b = c;

                } else {
                    Pixel ii = in[ic];
                    out[ic] = ii;
                    h = roundf(0.2126 * ii.r + 0.7152 * ii.g  + 0.0722 * ii.b);
                }


                // Slow
                // ++histogram[h / (256 / 5)];
                // Better than the slow above
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
    Picture pic;
    openFile(&pic, args[1]);
    size_t histogram[6] = {0, 0, 0, 0, 0, 0};

    convovle(&pic, histogram);

    saveHistogram(histogram);
    closeFiles(&pic);
    return 0;
}
