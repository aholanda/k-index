\def\title{K-INDEX}

@** Introduction. This is {\sc K-INDEX}, an implementation and a testbed
 of a scientometric measure to rank research authors using the citations
 of articles' citations. The testbed is its use to try to predict the
 the recipient of scientific awards. We use the Web of Science data
 as input and use the results for the prediction of Nobel Laureates
 of Physics.

@ The following code is structured in a way that each section has a
well defined boundary in terms of use of variables and functionality.
We try to separate the technicalities, like memory management, from
logical statements related to the index calculation.

@p
#include <stdio.h>
#include <stdlib.h>
@h@#
@<Include headers@>@;
@<Macro declarations@>@;
@<Type definitions@>@;
@<Data structures@>@;
@<Internal variables@>@;
@<Static functions@>@;
@<Functions@>@;

@ @c
int main(int argc, char **argv) {
    @<Local variables@>@;
    @<Parse program arguments@>@;
    @<Initialize the variables that need memory allocation@>@;
    @<Load the ids of Nobel Laureates@>@;
    @<Load authors information@>@;
    @<Calculate K index@>@;
    @<Sort the authors@>@;
    @<Write results to a file@>@;
    @<Write a table with the twelve larger ks in latex format@>@;
    @<Free up memory@>@;
    return 0;
}

@ Some internal functions are defined to embed repetitive tasks like check null
pointers and print error messages.

@ |Fopen| function try to open a file named |filename| and if it fails
the error message is thrown out, stopping the execution of the
program.

@<Static...@>=
static FILE *Fopen(char *filename, char *mode) {
       FILE *f;

       f = fopen(filename, mode);
       if (!f) {
       	  panic("Could not open \"%s\"\n", filename);
       }
       return f;
}

@ The function |Fclose| tests it the file pointer in not null before
closing it.

@<Static...@>=
static void Fclose(FILE *f) {
       if (f)
       	  fclose(f);
}

@ The |mem_free| function check the nullity of the address pointed by
|ptr| before deallocation.

@<Static...@>=
static void mem_free(void *ptr, int line) {
     if (ptr) @\
     	free(ptr);
}

@ |CALLOC| macro hide the use of macro |__LINE__| that is the number
of current line where it is used. When an memory allocation error
occurs the line where |CALLOC| is used is informed by |mem_calloc|.

@<Macro...@>=
#define CALLOC(count,nbytes) mem_calloc((count), (nbytes), (int)__LINE__)

@ The function |mem_calloc| is an wrapper to |calloc| to check it the
pointer returned is not null.

@<Static...@>=
static void *mem_calloc(int count, int nbytes, int line) {
       void *ptr;
       ptr = calloc(count, nbytes);
       if (!ptr) {
       	  fprintf(stderr, "%d: Null pointer\n", line), abort();
       }
       return ptr;
}

@ |FREE| macro wraps |mem_free| with proper arguments and zeroed
|ptr|.

@<Macro...@>=
#define FREE(ptr) ((void)(mem_free((ptr), __LINE__), (ptr)=0))

@ The |panic| function is used when the program enters in a condition
that was not expected to be in. It stops the program execution and
prints a message |msg|. If there was a sure expectation that nothing
bad can occurs, a definition of |NDEBUG| as macro turn off the
|panic| function.

@<Macro...@>=
#undef panic
#ifdef NDEBUG
#define panic(msg) ((void)0)
#else
extern void panic(int msg);
#define panic(fmt, ...) \
	(fprintf(stderr, "%d:PANIC: " fmt, (int)__LINE__, ##__VA_ARGS__), abort())
#endif

@** Input. The data to be processed comes from CSV (comma-separated
 values) and TSV (tab-separated vaules) files containing, among other
 data, the papers and its number of citations (CSV) or number of
 citings (TSV) of researchers. Each file stores data about one
 researcher.  The citing is the number of citations received by a
 paper that cites the researcher paper in question. The CSV files are
 used to calculate the $h$-index and TSV are used to find the
 $K$-index. An index file with author's identification and some
 information like his/her homepage is used to associate the data
 files. For example, an author with an Researcher ID equals to
 ''Z-1111-1900'' has the articles' citings in a file named
 ''Z-1111-1900.txt''.

@* One or more files as input.

@<Parse program arguments@>=
if (argc >= 2) {
    for (i=1; i<argc; i++) {
    	fn = argv[i];
	fprintf(stderr, " %s, k=%d\n", fn, do_k(fn));
    }
    exit(1);
}

@* A directory with files as input. The data files were saved inside in the value of
 |DATA_DIRECTORY| macro directory.

@d DATA_DIRECTORY "data"

@* Fetching authors' record. The macro |AUTHORS_DATA_FN| is set with
 the file name that contains information about researchers
 (authors). Each line of the file has the name, Web of Science, Google
 Scholar or Publons research id and a link to a page containing more
 information about the author's publications. Not all authors have
 researcher id, when this occurs, we assign a number and link to the
 Web of Science page. The author's $h$-index and $K$-index are
 assigned to the fields |h| and |K|, respectively.

@d AUTHORS_DATA_FN "identifiers.dat"
@d MAX_STR_LEN 256

@<Data structures@>=
typedef struct author_struct {
    char id[MAX_STR_LEN];
    int h;
    int k;
    char timestamp[MAX_STR_LEN]; /* last modification of record */
} Author;

@ |MAX_LINE_LEN| is the maximum length of each line, the value is very
high because some papers have too many authors.

@d MAX_LINE_LEN 1<<16

@<Local...@>=
 char buffer[MAX_LINE_LEN]; /* buffer to store strings */
 int i=0, j=0; /* general-purpose counters */

@ An array of structures is used to store the |authors|' information.
 The global variable |A| is set with the number of authors processed
 at the time it is read.

@<Internal...@>=
 char *fn; /* file name */
 FILE *fp; /* file pointer */
 char line[MAX_LINE_LEN]; /* store file lines */
 char *ptr;
static Array *authors; /* store authors' info */

@ The maximum number of authors is dictated by the macro
|MAX_N_AUTHORS| and the array of |authors| is initialized using
this value.

@D MAX_N_AUTHORS 0x2000

@<Initialize...@>=
authors = Array_new(MAX_N_AUTHORS, sizeof(Author));

@ Authors basic information was picked from the Web of Science page,
more specifically at \hfil\break {\tt
https://hcr.clarivate.com/\#categories\%3Dphysics} that is the page of
most cited authors in physics. They are stored in a file named
|ids.idx| that is opened to load this information.

@<Load authors info...@>=
fp = Fopen(AUTHORS_DATA_FN, "r"); @/
while (fgets(line, MAX_LINE_LEN, fp) != NULL) { @/
      if (is_comment(line)) @/
      	 continue; @/

      @<Begin to fill authors structure@>@;
}
Fclose(fp);

@ Memory allocated for the array of pointers |authors| is freed.

@<Free up memory@>=
Array_free(authors);

@ @<Include...@>=
#include <string.h> /* strtok() */

@ The fields are separated by semicolon inside |authors.idx|, a record in
the file looks like\smallskip

\centerline{\tt L-000-000;Joe Doe;http//joedoe.joe}\medskip

\noindent where the first field {\tt L-000-000} is the Research ID or ORCID,
when the author doesn't have an identifier, a custom
number is assigned. The second field {\tt Joe Doe} is the author name
and the third field is the link to the page that contains information
about author's publications. A structure is loaded with these data and
a pointer to this structure is passed to the array |authors|.  Lately,
$h$-index and $K$-index will be calculated and assigned to the proper
field in the structure.

@d IDX_SEP ";\n"

@<Begin to fill authors structure@>=
i = 0; /* information index */
ptr = strtok(line, IDX_SEP);
while (ptr != NULL) {
    switch(i) {
        case 0:
        strncpy(aut.id, ptr, MAX_STR_LEN);
        break;
        case 1:
        aut.h = atoi(ptr);
	if (aut.h <= 0) {
	   fprintf(stderr, "==> h=%d <==\n", aut.h);
	   panic("Wrong value of h-index");
	}
	/* Initialize K too */
	aut.k = 0;
        break;
        case 4:
        strncpy(aut.timestamp, ptr, MAX_STR_LEN);
        break;
        default:
        break;
    }
    ptr = strtok(NULL, IDX_SEP);
    i++;
}

 Array_append(authors, &aut);


@ |aut| is used to point to new allocated |Author| structure adress
while the fields are assigned with the proper values.

@<Local...@>=
Author aut; /* temporary variable */

@ In all custom files used to parse the data, the hash character ''\#''
is used to indicate that after it the following tokens must be
interpreted as comments.

@<Static...@>=
int is_comment(char *line) { @/
    if (!line)
       goto exit_is_comment; @/

      if (line[0] == '#')
	    return 1;

    exit_is_comment:
      return 0;
}

@* Fetching Nobel laureates. We have to discard researchers that
already was awarded with the Nobel Prize. Up to 2018, there was 935
laureates. We put more chairs in the room to accommodate future
laureates. A simple array is used to store the IDs and a linear search
is performed. As the number of winners is not high, this simple
scheme, even though not so efficient, is used to avoid complexities.

@d N_LAUREATES 935
@d MORE_ROOM 128

@ The Nobel Laureates identifier are inserted in the |list| array;

@<Internal...@>=
static Array *list;

@ The |Array| data structure is used to manage sequential allocation
 of related elements. The data is copied to |array| field, the |cap|
 field is the maximum number of elements provided by the array,
 |length| is the number of elements occupied in the array and |size|
 is the number of bytes occupied by each element. All elements are of
 the same size.

@<Type...@>=
typedef struct array_struct {
       void *array;
       int cap; /* capacity of the array in number of elements */
       int length; /* number of elements used */
       int size; /* size in bytes of each element of the array */
} Array;

@ To create an array, memory is allocated for the structure and the
data.

@<Static...@>=
static Array *Array_new(int capacity, int size) {
       Array *ary;
       ary = CALLOC(1, sizeof(Array));
       ary->array = CALLOC(capacity, size);
       ary->cap = capacity;
       ary->size = size;
       ary->length = 0;
       return ary;
}

@ An element is get by accessing the ith element in the
array taking into account the size of each element.

@<Static...@>=
static void *Array_get(Array *ary, int i) {
       assert(ary);
       assert(i >= 0 && i < ary->length);
       return ary->array + i*ary->size;
}

@ An element is put in the array by copying the bytes of the
element |elem| starting at the proper position |i| and taking
into account the size of each element.

@<Static...@>=
static void Array_put(Array *ary, int i, void *elem) {
       assert(ary);
       assert(i >= 0 && i < ary->cap);
       assert(elem);
       memcpy(ary->array + i*ary->size, elem, ary->size);
}

@ @<Static...@>=
static void Array_append(Array *ary, void *elem) {
       assert(ary);
       assert(elem);
       memcpy(ary->array + ary->length*ary->size, elem, ary->size);
       ary->length++;
}

@ Memory of array structure are freed by deallocating the data field
|array| and the structure itself.

@<Static...@>=
static void Array_free(Array *ary) {
       FREE(ary->array);
       FREE(ary);
}

@ |Array_length| returns the number of elements in the |array|.

@<Static...@>=
static int Array_length(Array *array) {
       assert(array);
       assert(array->length >= 0);
       return array->length;
}

@ @<Static...@>=
static int Array_size(Array *array) {
       assert(array);
       assert(array->size > 0);
       return array->size;
}

@ The function |assert| is used to check some invariants or integrity
constraints of the data.

@<Include...@>=
#include <assert.h>

@ A file |NOBEL_FN| with the identification number (id) of the Nobel
Laureates is used to check if the researcher already win the prize.

/* file name with ids of Nobel Laureates */
@d NOBEL_FN "laureates_in.dat"

@<Load the ids of Nobel Laureates@>=
fp = Fopen(NOBEL_FN, "r");
while (fgets(line, MAX_LINE_LEN, fp) != NULL) {
      if (is_comment(line))
      	 continue;

      /* Remove the new line */
      line[strcspn(line, "\r\n")] = 0;

      @<Insert the hash id...@>@;
}
Fclose(fp);

@ The |list| array is initialized with enough space to put lareuates.

@<Initialize...@>=
list = Array_new(N_LAUREATES+MORE_ROOM, MAX_STR_LEN);

@ Each new Laureate id is inserted in the array list and the number of
elements in the list is incremented. No overflow checking is done.

@<Insert the hash id at the end of the list@>=
Array_append(list, line);

@ @<Free up memory@>=
 Array_free(list);

@ The function |is_nobel_laureate| check in the list od laureates with
IDs if the author |a| id is in the list. The string comparison does
not take into account if an id is prefix of another one because this
is very unlikely to occur.

@<Static...@>=
static int is_nobel_laureate(Author *aut) {
       int i;
       char *id = aut->id;

       for (i=0; i<list->length; i++) {
       	   if (strncmp(Array_get(list, i), id, MAX_STR_LEN)==0)
	      return 1;
       }
       return 0;
}

@** Indices calculation. There is procedure in this program to
calculate the scientometric index $K$. The $h$ is the Hirsch index
proposed by Hirsch [J.~E.~Hirsch, ``An index to quantify an
individual's scientific research output,'' {\sl PNAS\/ \bf 102}~(15)
16569--16572, 2005]. It is obtained at Web of Science, so no further
procedure is needed. The $K$ stands for Kinouchi index and was
prososed by O. Kinouchi {\it et al.\/}~[O.~Kinouchi, L.~D.~H.~Soares,
G.~C.~Cardoso, ``A simple centrality index for scientific social
recognition'', {\sl Physica~A\/ \bf 491}~(1), 632--640].
@^Hirsch, Jorge Eduardo@>
@^Cardoso, George Cunha@>
@^Kinouch, Osame@>
@^Soares, Leonardo D. H.@>

@* h-index. The number of papers is in decreasing order of citations
that the number of citations is greater than the paper position is the
$h$-index.  On Web of Science homepage, the procedure to find the $h$ of
an author is as follows:

\begingroup
\parindent=2cm
\item{$\bullet$} Search for an author's publications by {\sl Author\/}
 or {\sl Author Identifiers};
\item{$\bullet$} Click on the link {\it Create Citation Report\/};
\item{$\bullet$} The $h$-index is showed at the top of the page.
\endgroup\smallskip

The $h$-index value is stored in the author record structure and saved
in ``authors.idx'' file.

@* K-index. If an author receives at least K citations, where each
one of these K citations have get at least K citations, then the
author's $K$-index was found. On Web of Science homepage, the procedure
to find the K of an author looks like below:

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
calculate the $K$ by clicking on the button {\it Export...\/} and
selecting {\it Fast 5K\/} format that saves the same data, with limit
of 5.000 records, where each field is separated by one or more tabs
that is assigned to the macro |TSV_SEP|.

@ @<Calculate K index@>=
N = Array_length(authors);
for (i=0; i<N; i++) {/* for each author */
    @<Process tsv file@>@;
}

@ @<Local...@>=
int N=0;

@ To open the proper file the Researcher ID is concatenated with
|DATA_DIRECTORY| as prefix and the file extension |EXT| as suffix.

@d EXT "txt"

@<Process tsv file@>=
paut = Array_get(authors, i);
snprintf(buffer, MAX_LINE_LEN, "%s/%s.%s", DATA_DIRECTORY, \
		 paut->id, EXT);
fn = buffer;
paut->k = do_k(fn);

@ @<Function...@>=
int do_k(char *filename) {
    int pos; /* temporary variable to store the paper position */
    int ncits, old_ncits; /* current and old value of number of citings */
    int j=0;

    fp = Fopen(fn, "r");

     pos=1;
     ncits=0, old_ncits = 1000000;

     while (fgets(line, sizeof(line), fp) != NULL) {
       	   @<Parse the line counting citings@>@;
     }
     Fclose(fp);

     return pos;
}

@ @<Local variables@>=


@ The file with citings has few lines to ignore, basically it is only one
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

@ |SKIP| represents the fields to be skipped before {\it Times Cited\/}
value is reached. Its value is not fixed and for this reason it was
implemented a tricky way to get the {\it Times Cited\/} value: after
|SKIP| is passed, each field is accumulated in a queue and when the
end of the record is reached, the queue is dequeue three times to get
the {\it Times Cited\/} value. This position offset of {\it Times
Cited\/} value from the end is fixed for all files.

@d TSV_SEP "\t"
@d SKIP 7 /* number of fields that can be skipped with safety */

@<Find the citings and check if the K-index was found@>=
{ ncits=0;
  j=0;
  ptr = strtok(line, TSV_SEP);
  while (ptr != NULL) {
	if (j > SKIP) {
	      push(ptr);
	}
	j++;
        ptr = strtok(NULL, TSV_SEP);
  }

  for (j=0; j<3; j++)
         ptr = pop();

   assert(ptr);
   ncits = atoi(ptr);
   stack_reset();

   @<Check invariant of citings@>@;

   old_ncits = ncits;

   if (pos > ncits) { /* found k */
       pos--;

       break;
  }
  pos++;
}

@ @<Local var...@>=
char *ptr; /* Generic pointer */

@ The articles are listed in descending order of number of citings.
 For this reason, the old value of number of citings |old_ncits|
 must not be lesser than current value just parsed |ncits|. The
 verification stops the program execution if this invariant is not
 obeyed.

@<Check invariant of citings@>=
if (old_ncits < ncits) {
   fprintf(stderr, "==> %d<%d <==\n", old_ncits, ncits);
   panic("Previous number of citings is lesser the the current one.");
}

@** Stack. A humble stack is implemented to store few pointers using
FIFO policy. The stack is composed by an array of pointers named
|data| and an index named |top| to point to the next index to add
element in the stack. Three stacks are declared, one for storing
temporary values of the fields during $K$-index calculation, other to
store temporary values of citation and other to store temporary values
of citings.

@d STACK_LEN 0x10000

@<Internal...@>=
static struct {
       char *data[STACK_LEN];
       int top;
} stack;

@ Elements are inserted at the top of the stack by invoking |push| and
using |char *ptr| as parameter. The index |idx| is incremented to the
number of elements in the stack and |top-1| is the index of the
element in the top.

@<Static...@>=
static void push(char *ptr) {
       if (ptr == NULL) {
          panic("Tring to push NULL value to the stack");
	}

 	stack.data[stack.top++] = ptr;

	if (stack.top == STACK_LEN) {
	   panic("Stack overflow");
	}
}

@ Elements from the top of the stack are removed by |pop| function. If
there is no element in the stack, |NULL| is returned.

@<Static...@>=
static char* pop() {
       if (stack.top <= 0)
          panic("Stack underflow");
	else
	  return stack.data[--stack.top];
}

@ To reset the stack, |top| is assigned to zero.

@<Static...@>=
static void stack_reset() {
       stack.top = 0;
}

@** Sorting. The authors are classified in descending order
according to their $K$-index. The insertion-sort algorithm
is used to simplify the code and according to the number of entries
is not so large.

@<Sort the authors@>=
N = Array_length(authors);
for (i=1; i<N; i++) {
    memcpy(&aut, Array_get(authors, i), Array_size(authors));
    for (j=i-1; j>=0; j--) {
    	qaut = (Author*)Array_get(authors, j);
	if (aut.k < qaut->k)
	   break;

    	Array_put(authors, j+1, qaut);
    }
    Array_put(authors, j+1, &aut);
}

@ @<Local...@>=
register Author *qaut;

@** Output. The results are written as a table in markdown format to
the file name assigned to |RANK_FN|.  A space is needed between the
bars and the content.

@d RANK_FN "rank.md"

@<Write results to a file@>=
fp = Fopen(RANK_FN, "w");
fprintf(fp, "| N | Author | h | K |\n");
fprintf(fp, "|---|--------|---|---|\n");
N = Array_length(authors);
for (i=0; i<N; i++) {
    paut = Array_get(authors, i);

    /* Mark Nobel Laureates */
    if (is_nobel_laureate(paut))
	ptr = "**"; @\
    else
	ptr = ""; @\

    fprintf(fp, "| %d | %s%s%s | %d | %d |\n",
    	i+1, ptr, paut->id, ptr, paut->h, paut->k);
}
Fclose(fp);
fprintf(stderr, "* Wrote \"%s\"\n", RANK_FN);

@ @<Internal...@>=
static Author *paut;

@ A table with the twelve larger $K$s to be included in the manuscript
is written in LaTeX format.

@<Write a table with the twelve larger ks in latex format@>=
fn = "table.tex";
fp = Fopen(fn, "w");
fprintf(fp, "\\begin{tabular}{cccc} \\\\ \\hline\n");
fprintf(fp, "\\bf N & \\bf Author &\\bg h &\\bf K \\\\ \\hline\n");
for (i=0; i<12; i++) {
    paut = Array_get(authors, i);
    fprintf(fp, " %d & %s & %d & %d \\\\\n",
       i+1,
       paut->id,
       paut->h,
       paut->k);
}
fprintf(fp, "\\hline\\end{tabular}\n");
Fclose(fp);
fprintf(stderr, "* Wrote \"%s\"\n", fn);

@** Index.
