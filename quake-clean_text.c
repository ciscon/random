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

	//allow all normal characters
    for (i = 0; i < 256; i++)
        chartbl[i] = ( (i&127) < 32 || (i&127) > 127 ) ? '_' : (i&127);

	chartbl[10] =  '\n';
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


