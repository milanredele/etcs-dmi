#include <stdio.h>
#include <string.h>
#include <libgen.h>

#define MAX_ROW_SIZE 256

char* rgb_to_string (int rgb) {
	switch (rgb) {
		case 0xffffff:
			return "WHITE";
		case 0x0: 
			return "BLACK";
		case 0xC3C3C3:
		case 0xC7C7C7:
		case 0xC4C4C4:
		case 0xC2C3C3:
		case 0xC4C3C3:
		case 0xC5C5C5:
		case 0xC6C6C6:
		case 0xCFCDCE:
		case 0xCBCACA:
		case 0xCBCBC9:
		case 0xBEBFBF:
		case 0xB9BABB:
		case 0xB4B5B7:
			return "GREY";
		case 0x969696:
			return "MEDIUM_GREY";
		case 0x555555:
		case 0x525653:
		case 0x535354:
		case 0x535454:
		case 0x535456:
		case 0x535552:
		case 0x535554:
		case 0x535556:
		case 0x535657:
		case 0x535753:
		case 0x545453:
		case 0x545454:
		case 0x545553:
		case 0x545554:
		case 0x545555:
		case 0x545556:
		case 0x545557:
		case 0x545653:
		case 0x545654:
		case 0x545655:
		case 0x555454:
		case 0x555455:
		case 0x555553:
		case 0x555554:
		case 0x555556:
		case 0x555557:
		case 0x555653:
		case 0x555656:
		case 0x555658:
		case 0x565457:
		case 0x565553:
		case 0x565656:
		case 0x585457:
			return "DARK_GREY";
		case 0x31122:
		case 0x31121:
		case 0x31123:
		case 0x11023:
		case 0x11120:
		case 0x11121:
		case 0x11222:
		case 0x21120:
		case 0x21122:
		case 0x21022:
		case 0x21021:
		case 0x21023:
		case 0x21121:
		case 0x21124:
		case 0x21221:
		case 0x21222:
		case 0x30e20:
		case 0x31020:
		case 0x31021:
		case 0x31022:
		case 0x31023:
		case 0x31223:
		case 0x31222:
		case 0x31323:
		case 0x31324:
		case 0x41021:
		case 0x41020:
		case 0x41026:
		case 0x41121:
		case 0x41122:
		case 0x41123:
		case 0x41124:
		case 0x41222:
		case 0x41223:
		case 0x41224:
		case 0x51022:
		case 0x51024:
		case 0x51121:
		case 0x51221:
		case 0x51222:
		case 0x51223:
		case 0x51324:
		case 0x61425:
		case 0x61322:
		case 0x324:
		case 0x524:
		case 0x724:
		case 0x025:
		case 0x1020:
		case 0x1021:
		case 0x1121:
		case 0x1123:
		case 0x10D23:
		case 0x10E1F:
		case 0x10F20:
		case 0x20F20:
		case 0x81626:
		case 0x81627:
		case 0x81526:
		case 0xD1B2B:
		case 0x131626:
		case 0xC23:
		case 0x823:
		case 0x923:
		case 0xD1E:
		case 0xE1F:
		case 0xE20:
		case 0xF20:
		case 0x162232:
		case 0x1C221F:
		case 0x1C241F:
		case 0x1B211F:
		case 0x1B241F:
		case 0x17211F: //specifically for PL_26, it is really brownish
			return "DARK_BLUE";
		case 0x81839:
			return "SHADOW";
		case 0xDFDF00:
		case 0xDDDD00:
		case 0xDCDD00:
		case 0xDCDC01:
		case 0xDADA01:
		case 0xDADB00:
		case 0xC6C600:
		case 0xe2e200:
			return "YELLOW";
		case 0xEA9100:
			return "ORANGE";
		case 0xBF0002:
			return "RED";
		case 0x21314A:
			return "PASP_DARK";
		case 0x294A6B:
			return "PASP_LIGHT";	
		default:
			printf ("ERRORRRRRRRERROROROR:%X\n", rgb);
			return "UNKNOWN";
	}
}

void processBMP(char* filename)
{
    int i;
    FILE* f = fopen(filename, "rb");

    if(f == NULL){
        fprintf (stderr, "Bad file: %s\n", filename);
        return;
    }
    
    char* bname = basename (filename);
    
    bname[strlen(bname) - 4] = '\0'; //strip extension (.bmp)

    unsigned char info[54];
    fread(info, sizeof(unsigned char), 54, f); // read the 54-byte header

    // extract image height and width from header
    int width = *(int*)&info[18];
    int height = *(int*)&info[22];

		printf ("%s : constant T\n:= (Length => %d,\nWidth => %d,\nHeight => %d,\nBitmap => (\n", bname, width*height, width, height);

    int row_padded = (width*3 + 3) & (~3);
    if (row_padded > MAX_ROW_SIZE) {
    	fprintf (stderr, "Error: max supported width: %d\nInput width: %d\n", MAX_ROW_SIZE, row_padded);
    	return;
    }
    
    unsigned char data[MAX_ROW_SIZE];
    unsigned char tmp;

    for(int i = 0; i < height; i++)
    {
        fread(data, sizeof(unsigned char), row_padded, f);
        for(int j = 0; j < width*3; j += 3)
        {
            unsigned int rgb = 0;
            unsigned char *rgb_bytes = (char*)&rgb;
            rgb_bytes[0] = data[j];
            rgb_bytes[1] = data[j+1];
            rgb_bytes[2] = data[j+2];

						if ((i == height-1) && (j == width*3-3)){
	            printf ("%s", rgb_to_string(rgb));
	          } else {
	          	printf ("%s,", rgb_to_string(rgb));
	         }
         }
        printf ("\n");
    }
    
    printf ("));\n\n");

    fclose(f);
}

int main(int argc, char** argv) {
	if (argc < 2) {
		printf ("Usage: %s bmp [bmp [bmp [...]]]", argv[0]);
	}
	
	printf ("with General_Parameters; use General_Parameters;\n\n");
	printf ("package Symbol is\n\n");
	printf ("subtype Size_T is Positive range 1 .. 75;\n\n");
	printf ("subtype Length_T is Positive range 1 .. 75*46;\n\n");
	printf ("type Bitmap_T is array (Length_T range <>) of Color;\n\n");
	printf ("type T (Length : Length_T) is\n");
	printf ("record\n");
	printf ("Width  : Size_T;\n");
	printf ("Height : Size_T;\n");
	printf ("Bitmap : Bitmap_T (1 .. Length);\n");
	printf ("end record;\n\n");
	
	for (int i=1; i<argc; i++){
		processBMP (argv[i]);
	}
	
	printf ("\nend Symbol;");
	return 0;
}
