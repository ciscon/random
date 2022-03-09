/*
 * reads from stdin, cleans text, outputs to stdout
 */

#include <stdio.h>
#include <string.h>

#define MAXLINE 1024*10

static char chartbl[256];

/*
====================
CleanString_Init

sets chararcter table for quake text cleaning
====================
*/
void CleanString_Init (void)
{
    int i;

	for (i = 0; i < 256; i++)
		chartbl[i] = (((i&127) < 32 || (i&127) > 126)) ? '_' : (i&127);
	
	for (i = 18; i < 28 ; i++)
		chartbl[i] = (i - 18 + 48);

	// brackets
    chartbl[29] = chartbl[29+128] = chartbl[128] = '(';
    chartbl[31] = chartbl[31+128] = chartbl[130] = ')';
    chartbl[16] = chartbl[16 + 128]= '[';
    chartbl[17] = chartbl[17 + 128] = ']';
	chartbl[91] = chartbl[91 + 128] = '[';
    chartbl[93] = chartbl[93 + 128] = ']';
    chartbl[16] = chartbl[16 + 128] = '[';
    chartbl[17] = chartbl[17 + 128] = ']';
    chartbl[123] = chartbl[123 + 128] = '{';
    chartbl[125] = chartbl[125 + 128] = '}';

    // dot
    chartbl[5] = chartbl[14] = chartbl[15] = chartbl[28] = chartbl[46] = '.';
    chartbl[5 + 128] = chartbl[14 + 128] = chartbl[15 + 128] = chartbl[28 + 128] = chartbl[46 + 128] = '.';

    // !
    chartbl[33] = chartbl[33 + 128] = '!';

    // #
    chartbl[35] = chartbl[35 + 128] = '#';

    // %
    chartbl[37] = chartbl[37 + 128] = '%';

    // &
    chartbl[38] = chartbl[38 + 128] = '&';

    // '
    chartbl[39] = chartbl[39 + 128] = '\'';

    // (
    chartbl[40] = chartbl[40 + 128] = '(';

    // )
    chartbl[41] = chartbl[41 + 128] = ')';

    // +
    chartbl[43] = chartbl[43 + 128] = '+';

    // -
    chartbl[45] = chartbl[45 + 128] = '-';

    // @
    chartbl[64] = chartbl[64 + 128] = '@';

	//special
	chartbl[10] = chartbl[13] = '\n';
	chartbl[13] = '\n';
	chartbl [129] = chartbl[28] = chartbl[14] = chartbl[15] = '-';

}

char* Q_CleanStringString (unsigned char *name)
{
    static char text[1024*1024];
    char *out = text;

    if (!name || !*name)
    {
        *out = '\0';
        return text;
    } 
    *out = chartbl[*name++];

    while (*name && ((out - text) < (int) sizeof(text))) {
        *++out = chartbl[*name++];
		//printf("[ %d %c ]", *name, *name);
	}

    *++out = 0;
    return text;
}

void main(){
	unsigned char text[MAXLINE];
	int textSize = 0;
	const char separator = '\n';
	char c;

	CleanString_Init();

	while (!feof(stdin) && (textSize < MAXLINE))  {
		c = getchar();
		text[textSize] = c;
		if (c == separator || textSize+1 == MAXLINE || c == '\0' || c == EOF){ 
			printf("%s",Q_CleanStringString(text));
			memset(&text[0], 0, sizeof(text));
			textSize=0;
		} else {
			textSize++;
		}
	}
}


