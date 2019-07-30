@** Introduction.

@c
@<Include files@>@;
@<Data structures@>@;
@<Internal variables@>@;

@ @c
int main(int argc, char **argv) {
    @<Load authors information@>@;
    @<Calculate h index@>@;
    @<Calculate K index@>@;

    @<Free up memory@>@;
    return 0;
}

@** Authors. Information about research authors were stored into 
{\tt index.csv} file. They consist into name, Web of Science or Google 
Scolar or Publons research id and a link to a page containing more 
information about the citations. Not all authors have research id, 
 when this occurs, we assign a number and link to the Web of Science 
 page. The data structure for author loads this information, and indeed 
  the author's h-index and K-index. 

@d MAX_STR_LEN 256

@<Data structures@>=
struct author {
    char name[MAX_STR_LEN];
    char researchid[MAX_STR_LEN];
    char url[MAX_STR_LEN];
    int h;
    int k;
};

@ An array of structs is used to store the authors' information.

@<Internal...@>=
static struct author **authors;
static char *fn;
static char buffer[MAX_STR_LEN];
static int A=0; /* number of authors */
static int i=0; /* general-purpose counter */

@ Read authors information.

@<Include...@>=
#include <stdio.h>
#include <stdlib.h>

@ @<Load authors info...@>=
fn = "authors.idx";
FILE *fp = fopen(fn, "r");
char line[MAX_STR_LEN];
if (fp) {
    while (fgets(line, sizeof(line), fp) != NULL) {
        A++;
        /* reallocate the array of authors struct with to pointer elements */
        authors = (struct author**)realloc(authors, A*sizeof(struct author*));
        @<Begin to fill authors struct@>@;

    }
    fclose(fp);
} else {
    perror(fn);
}

@ @<Include...@>=
#include <string.h>

@ 

@d IDX_SEP ";\n"

@<Begin to fill authors struct@>=
struct author *aut = (struct author*)malloc(sizeof(struct author));
i = 0; /* information index */
char *p;
p = strtok(line, IDX_SEP);
while (p != NULL) {
    switch(i) {
        case 0:
        strncpy(aut->researchid, p, MAX_STR_LEN);
        break;
        case 1:
        strncpy(aut->name, p, MAX_STR_LEN);
        break;
        case 2:
        strncpy(aut->url, p, MAX_STR_LEN);
        break;
        default:
        break;
    }
    p = strtok(NULL, IDX_SEP);
    i++;
}
authors[A-1] = aut;

@* H Index.

@d DATA_DIRECTORY "data/" /* directory containing all data */
@d H_EXT ".csv" /* file used to calculate h-index extension */

@<Calculate h index@>=
for (i=0; i<A; i++) {/* for each author */
    @<Process csv file@>@;

    printf("%s\n", buffer);
}

@ @<Process csv file@>=
strncpy(buffer, DATA_DIRECTORY, sizeof(DATA_DIRECTORY));
strncat(buffer, authors[i]->researchid, sizeof(authors[i]->researchid));
strncat(buffer, H_EXT, sizeof(H_EXT));
fn = buffer;
fp = fopen(fn, "r");
if (fp) {
    while (fgets(line, sizeof(line), fp) != NULL) {
        @<Parse line to evaluate citation@>@;
    }
} else {
    perror(fn);
}

@ 

@d CSV_SEP ","

@<Parse line counting citations@>=
if (strstr(line, "AUTHOR") != NULL) {
    continue;
}

@ @<Calculate K index@>=

@ @<Free up memory@>=
for (i=0; i<A; i++)
    free(authors[i]);
free(authors);