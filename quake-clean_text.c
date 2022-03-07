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
        chartbl[i] = (((i&127) < 'a' || (i&127) > 'z') && ((i&127) < '0' || (i&127) > '9')) ? '_' : (i&127);

	//some exceptions
	chartbl[32] =  ' ';
	chartbl[58] =  ':';
	chartbl[44] =  ',';
	chartbl[10] =  '\n';

    // numbers
    for (i = 18; i < 29; i++)
        chartbl[i] = chartbl[i + 128] = i + 30;

    // allow lowercase only
    for (i = 'A'; i <= 'Z'; i++)
        chartbl[i] = chartbl[i+128] = i + 'a' - 'A';

    // brackets
    chartbl[29] = chartbl[29+128] = chartbl[128] = '(';
    chartbl[31] = chartbl[31+128] = chartbl[130] = ')';
    chartbl[16] = chartbl[16 + 128]= '[';
    chartbl[17] = chartbl[17 + 128] = ']';

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

    // ^
    //  chartbl[94] = chartbl[94 + 128] = '^';


    chartbl[91] = chartbl[91 + 128] = '[';
    chartbl[93] = chartbl[93 + 128] = ']';

    chartbl[16] = chartbl[16 + 128] = '[';
    chartbl[17] = chartbl[17 + 128] = ']';

    chartbl[123] = chartbl[123 + 128] = '{';
    chartbl[125] = chartbl[125 + 128] = '}';

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

    while (*name && ((out - text) < (int) sizeof(text)))
	    if ((*out == '_' && chartbl[*name] == '_'))
            name++;
        else *++out = chartbl[*name++];

    *++out = 0;
    return text;
}

void main(){
	unsigned char text[MAXLINE];
	int textSize = 0;
	const char separator = '\n';
	char c;

	CleanString_Init();

	while ((c = getchar()) != EOF && textSize < MAXLINE)  {
		text[textSize] = c;
		if (c == separator){ 
			printf("%s",Q_CleanStringString(text));
			memset(&text[0], 0, sizeof(text));
			textSize=0;
		} else {
			textSize++;
		}
	}
}


