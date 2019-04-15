#include <stdio.h>
#include <errno.h>
void write(FILE *in, FILE *out, int amount) {
	char data[amount];
	fread(data, amount,1, in);
	fwrite(data, amount,1, out);
}

int main(int argc, char* argv[]) {
	if(argc < 2) {
		fprintf(stderr, "usage: split rom_folder [type]\n eg pinmame32_23/roms/game_name/ (note trailing slash)\ntype: sys6 or sys7");
		return 1;
	}
	char* folder = argv[1];
	FILE *in  = fopen("rom.764", "rb");
	if(!in) {
		fprintf(stderr, "could not open rom.764, errno %i", (errno));
		return 3;
	}
	char path[100];
	FILE *a, *b, *c, *aa, *bb, *cc;
	if (argc >= 3 && !strcmp(argv[2], "sys7")) {
		sprintf(path, "%sic14.716", folder);
		a = fopen(path, "wb");
		sprintf(path, "%sic20.716", folder);
		b = fopen(path, "wb");
		sprintf(path, "%sic17.532", folder);
		c = fopen(path, "wb");
		aa = fopen("ic14.716", "wb");
		bb = fopen("ic20.716", "wb");
		cc = fopen("ic17.532", "wb");
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
	} else {
		sprintf(path, "%sgamerom.716", folder);
		a = fopen(path, "wb");
		sprintf(path, "%swhite1.716", folder);
		b = fopen(path, "wb");
		sprintf(path, "%swhite2.716", folder);
		c = fopen(path, "wb");
		aa = fopen("gamerom.716", "wb");
		bb = fopen("white1.716", "wb");
		cc = fopen("white2.716", "wb");

		fseek(in, 0x0000, SEEK_SET);
		write(in, a, 2048);
		fseek(in, 0x0000, SEEK_SET);
		write(in, aa, 2048);
		
		fseek(in, 0x1000, SEEK_SET);
		write(in, b, 2048);
		fseek(in, 0x1000, SEEK_SET);
		write(in, bb, 2048);
		
		fseek(in, 0x1800, SEEK_SET);
		write(in, c, 2048);
		fseek(in, 0x1800, SEEK_SET);
		write(in, cc, 2048);
	}
	
	
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