@** Introduction.

@c
@<Include files@>@;
@<Data structures@>@;
@<Internal variables@>@;
@<Static functions@>@;

@ @c
int main(int argc, char **argv) {
    @<Load authors information@>@;
    @<Calculate h index@>@;
    @<Calculate K index@>@;
    @<Write results to a file@>@;

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

@d MAX_LINE_LEN 1<<12

@<Internal...@>=
static struct author **authors;
static char *fn, *p; /* file name and generic pointer */
static FILE *fp; /* file pointer */
static char buffer[MAX_STR_LEN];
static char line[MAX_LINE_LEN]; /* store file lines */
static int A=0; /* number of authors */
static int i=0, j=0; /* general-purpose counters */

@ Read authors information.

@<Include...@>=
#include <stdio.h>
#include <stdlib.h>

@ @<Load authors info...@>=
fn = "authors.idx";
fp = fopen(fn, "r");
if (fp) {
    while (fgets(line, sizeof(line), fp) != NULL) {
        A++;
        /* reallocate the array of authors struct with to pointer elements */
        authors = (struct author**)realloc(authors, A*sizeof(struct author*));
        @<Begin to fill authors structure@>@;

    }
    fclose(fp);
} else {
    perror(fn);
}

@ @<Include...@>=
#include <string.h>

@

@d IDX_SEP ";\n"

@<Begin to fill authors structure@>=
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
}

@ @<Process csv file@>=
strncpy(buffer, DATA_DIRECTORY, sizeof(DATA_DIRECTORY));
strncat(buffer, authors[i]->researchid, sizeof(authors[i]->researchid));
strncat(buffer, H_EXT, sizeof(H_EXT));
fn = buffer;
fp = fopen(fn, "r");
if (fp) {
    int h=1; /* temporary h-index */
    while (fgets(line, sizeof(line), fp) != NULL) {
        @<Parse the line counting citations@>@;
    }
    fclose(fp);
} else {
    perror(fn);
}

@

@<Parse the line counting citations@>=
@<Ignore the header of citations file@>@;

@ @<Ignore the header of citations file@>=
if (strstr(line, "AUTHOR") != NULL) {
    continue;
} else if (strstr(line, "Timespan=All") != NULL) {
    continue;
} else if (strstr(line, "\"Title\",") != NULL) {
    continue;
} else if (line[0] == '\n') { /* start with new line */
    continue;
} else {
    @<Count the citations and check if the h-index was found@>@;
}

@** h-index.

@d CSV_SEP ",\"\n"
@d SKIP_FIELDS 30

@<Count the citations and check if the h-index was found@>=
{ int c=0;
  j=0;
  p = strtok(line, CSV_SEP);
  while (p != NULL) {
        if (j > SKIP_FIELDS) {
	      	 c += atoi(p);
        }
        p = strtok(NULL, CSV_SEP);
        j++;
  }
  if (h > c) { /* found h */
     h--;
     authors[i]->h = h;
     break;
  }

  h++;
}

@** K-index. If an author receives at least K citations, where each
one of these K citations have get at least K citation, then the
author's K-index was found. On Web of Science homepage, the procedure
to find the K of an author is as follows:

\begingroup
\parindent=2cm
\item{$\star$} Search for an author's publications;
\item{$\star$} Click on the link {\it Create Citation Report\/};
\item{$\star$} Click on the link {\it Citing Articles without self-citations\/};
\item{$\star$} Traverse the list, stoping when the rank position of the article were
      greater than the {\it Times Cited\/};
\item{$\star$} Subtract on from the rank position, this is the K value.
\endgroup\smallskip

To calculate in batch mode, we downloaded a file with the data to
calculate the K by clicking on the button {\it Export...\/} and
selecting {\it Fast 5K\/} format that saves the same data, with limit
of 5.000 records, where each field is separated by one or more tabs
that is represented by the macro |TSV_SEP|. The files were saved with
a ".tsv" extension inside |DATA_DIRECTORY|. All authors' files are
traversed, parsed and K-index is calculated. The results are saved in
a file.

@ @<Calculate K index@>=
for (i=0; i<A; i++) {/* for each author */
    @<Process tsv file@>@;
}

@ To open the proper file the Researcher ID is concatenated with
|DATA_DIRECTORY| as prefix and the file extension |K_EXT| as suffix.

@d K_EXT ".tsv"

@<Process tsv file@>=
strncpy(buffer, DATA_DIRECTORY, sizeof(DATA_DIRECTORY));
strncat(buffer, authors[i]->researchid, sizeof(authors[i]->researchid));
strncat(buffer, K_EXT, sizeof(K_EXT));
fn = buffer;
fp = fopen(fn, "r");
if (fp) {
    int k=1; /* temporary K-index */
    while (fgets(line, sizeof(line), fp) != NULL) {
        @<Parse the line counting citings@>@;
    }
    fclose(fp);
} else {
    perror(fn);
}

@ The file with citings has few lines to ignore, basically it's only one
that begins with "PT $\backslash$t" (ignore double quotes). A line that begins
with new line command ignored too, but only for caution.

@<Parse the line counting citings@>=
if (strstr(line, "PT\t") != NULL) {
    continue;
} else if (line[0] == '\n') { /* start with new line */
    continue;
} else {
    @<Find the citings and check if the K-index was found@>@;
}

@ |K_SKIP| represents the fields to be skiped before {\it Times Cited\/}
value is reached. Its value is not fixed and for this reason it was
implemented a tricky way to get the {\it Times Cited\/} value: after
|K_SKIP| is passed, each field is accumulated in a queue and when the
end of the record is reached, the queue is dequeue three times to get
the {\it Times Cited\/} value. This position offset of {\it Times
Cited\/} value from the end is fixed for all files.

@d TSV_SEP "\t"
@d K_SKIP 7 /* number of fields that can be skiped with safety */

@<Find the citings and check if the K-index was found@>=
{ int c=0;
  j=0;
  p = strtok(line, TSV_SEP);
  while (p != NULL) {
	if (j > K_SKIP) {
	      enqueue(p);
	}
	j++;
        p = strtok(NULL, TSV_SEP);
  }

  for (j=0; j<3; j++) {
      p = dequeue();
      if (p == NULL)
          queue_panic();
   }
    c = atoi(p);
    queue_reset();

   if (k > c) { /* found k */
       k--;
       authors[i]->k = k;
      break;
  }
  k++;
}

@** Queue. A humble queue is implemented to store few pointers using
FIFO policy. The queue is composed by an array of pointers and an index
|idx| that marks the top element of the queue.

@<Internal...@>=
static char *stack[64];
static int idx=0;

@ Elements are inserted at the top of the queue by invoking
|enqueue| and using |char *p| as parameter. The index |idx|
is incremented to the number of elements in the queue and
|idx-1| is the top of the queue.

@<Static...@>=
static void enqueue(char *p) {
       if (p == NULL)
         return;

 	stack[idx++] = p;
}

@ Elements from the top of the queue are removed by |dequeue|
function. If there is no element in the queue, |NULL| is returned.

@<Static...@>=
static char* dequeue() {
       if (idx <= 0)
          return NULL;
	else
	  return stack[--idx];
}

@ When for some reason, an error related with the queue occurs
|queue_panic| may be invoked, exiting from the execution program.

@d ERR_QUEUE -0x1

@<Static...@>=
static void queue_panic() {
       fprintf(stderr, "Queue is very empty.\n");
       exit(ERR_QUEUE);
}

@ To reset the queue, |idx| is zeroed.

@<Static...@>=
static void queue_reset() {
       idx = 0;
}


@** Output. The results are writen as a table in markdown format.
A space is needed between the bars and the content.

@<Write results to a file@>=
fn = "k-nobel.md";
fp = fopen(fn, "w");
if (!fp)
   perror(fn);

fprintf(fp, "| Author | h | k |\n");
fprintf(fp, "|--------|---|---|\n");
for (i=0; i<A; i++) {
    fprintf(fp, "| [%s](%s) | %d | %d |\n",
       authors[i]->name, authors[i]->url,
       authors[i]->h, authors[i]->k);
}
fclose(fp);
fprintf(stderr, "* Wrote \"%s\"\n", fn);

@ Memory allocated for the array of pointers |authors| is freed.

@<Free up memory@>=
for (i=0; i<A; i++)
    free(authors[i]);
free(authors);

@** Index.