#include <stdio.h>
#include <errno.h>
void write(FILE *in, FILE *out, int amount) {
	char data[amount];
	fread(data, amount,1, in);
	fwrite(data, amount,1, out);
}

int main() {
	FILE *in  = fopen("rom.764", "rb");
	if(!in) {
		fprintf(stderr, "could not open rom.764, errno %i", (errno));
		return 3;
	}
	FILE *a = fopen("pinmame32_23/roms/pharo_l2/ic14.716", "wb");
	FILE *aa = fopen("ic14.716", "wb");
	FILE *b = fopen("pinmame32_23/roms/pharo_l2/ic20.716", "wb");
	FILE *bb = fopen("ic20.716", "wb");
	FILE *c = fopen("pinmame32_23/roms/pharo_l2/ic17.532", "wb");
	FILE *cc = fopen("ic17.532", "wb");
	fseek(in, 0x0000, SEEK_SET);
	write(in, a, 2048);
	fseek(in, 0x0000, SEEK_SET);
	write(in, aa, 2048);
	
	fseek(in, 0x800, SEEK_SET);
	write(in, b, 2048);
	fseek(in, 0x800, SEEK_SET);
	write(in, bb, 2048);
	
	fseek(in, 0x1000, SEEK_SET);
	write(in, c, 2048*2);
	fseek(in, 0x1000, SEEK_SET);
	write(in, cc, 2048*2);
	
	fseek(in, 0x0000, SEEK_END);
	if(ftell(in)!=8192) {
		fprintf(stderr, "file overflow! %i", ftell(in));
		return 1;
	}
	fclose(a);
	fclose(b);
	fclose(c);
	fclose(in);
	return 0;
}