#include <stdio.h>

void write(FILE *in, FILE *out) {
	char data[2048];
	fread(data, 2048,1, in);
	fwrite(data, 2048,1, out);
	fclose(out);
}

int main() {
	FILE *in  = fopen("test.obj", "rb");
	FILE *a = fopen("pinmame32_23/roms/lzbal_l2/gamerom.716", "wb");
	FILE *b = fopen("pinmame32_23/roms/lzbal_l2/green1.716", "wb");
	FILE *c = fopen("pinmame32_23/roms/lzbal_l2/green2.716", "wb");
	write(in, a);
	fseek(in, 0x1000, SEEK_SET);
	write(in, b);
	fseek(in, 0x1800, SEEK_SET);
	write(in, c);
	fclose(in);
	return 0;
}