#include <stdio.h>

int main(int argc, char* argv[]) {
    char* file = argc == 2 ? argv[1] : "os.lst";
    FILE* fp = fopen(file, "r");
    int seen[32769];
    for (int i=0; i<32769; i++)
        seen[i] = 0;
    int hex = 0;
    int line = 0;
    int errors = 0;
    do {
        line++;
        fseek(fp, 8, SEEK_CUR);
        int hex2;
        char c;
        fscanf(fp, "%x", &hex2);
        fgetc(fp);
        c = fgetc(fp);
        fscanf(fp, "%*[^\n]");
        if (c == ' ') continue;
        if (hex2 != hex) {
            if (hex2 > 32768 || (hex2 > 0x67FF && hex2 < 0x7000) || (hex2 < 0x6000 && hex2 > 0)) {
                fprintf(stderr, "out of bounds %x on line %i\n", hex2, line);
                errors++;
            }


            if (seen[hex2]) {
                fprintf(stderr, "overwritten location %x on lines %i and %i\n", hex2, seen[hex2], line);
                errors++;
            }
            seen[hex2] = line;
        }
        hex = hex2;
    } while (!feof(fp));
    fclose(fp);

    int start = 0;
    for (int i = 0x6000; i<=0x7FFF; i++) {
        if (i > 0x67FF && i < 0x7000) seen[i] = 1;
        if (!seen[i] && !start) start = i;
        if (seen[i]) {
            if (start && i - start - 1 > 4)
                printf("unused space from %x to %x (%i bytes)\n", start, i - 1, i - 1 - start);
            start = 0;
        }
    }

    return errors;
}