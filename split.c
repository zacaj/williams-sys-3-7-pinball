#include <stdio.h>

void write(FILE *in, FILE *out) {
	char data[2048];
	fread(data, 2048,1, in);
	fwrite(data, 2048,1, out);
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
	
	fseek(in, 0x0000, SEEK_END);
	if(ftell(in)!=8192) {
		fprintf(stderr, "file overflow!");
		return 1;
	}
	fseek(in, 0x0800, SEEK_SET);
	while(ftell(in)<0x1000) {
		if(fgetc(in) != 0) {
			fprintf(stderr, "overflow at %x!", ftell(in) + 0x6000);
			return 2;
		}
	}
	fclose(a);
	fclose(b);
	fclose(c);
	fclose(in);
	return 0;
}