@** Introduction. K-NOBEL is a project to try to predict the future
Laureates of Nobel prize of Physics using $K$-index to rank the
researchers. Another parameter, $h$-index, is used to evaluate the
error threshold, since $h$-index is used by Web of Science as one of
the indices to predict the Laureates of Nobel prize.

The program has the following structure:

@c
#include <stdio.h>
#include <stdlib.h>
@<Include files@>@;
@<Macro declarations@>@;
@<Data structures@>@;
@<Internal variables@>@;
@<Static functions@>@;

@ @c
int main(int argc, char **argv) {
    @<Local variables@>@;
    @<Parse program arguments@>@;
    @<Load the ids of Nobel Laureates@>@;
    @<Load authors information@>@;
    @<Calculate K index@>@;
    @<Sort the authors@>@;
    @<Write results to a file@>@;
    @<Write a table with the twelve larger ks in latex format@>@;
    @<Free up memory@>@;
    @<Print information about flags@>@;
    return 0;
}

@ Some internal functions are defined to embed repetitive tasks like check null
pointers and print error messages.

@<Static...@>=
static FILE *Fopen(char *filename, char *mode) {
       FILE *f;

       f = fopen(filename, mode);
       if (!f) {
       	  fprintf(stderr, "Could not open %s\n", filename);
	  exit(-1);
       }
       return f;
}

@ @<Static...@>=
static void Fclose(FILE *f) {
       if (f)
       	  fclose(f);
}

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
#define panic(msg) (fprintf(stderr, "%s:%d: PANIC: %s\n", \
       __FILE__, (int)__LINE__, msg), abort())
#endif

@* Verbose mode. The flag {\tt -v} is provided to print the existing comments
inside data files and any other useful information to the user.

@d VERBOSE_FLAG  "-v"

@<Parse program arguments@>=
if (argc==2 && !strncmp(argv[1], VERBOSE_FLAG, 3)) @/
   verbose = 1;

@ The |verbose| Boolean variable marks if the output of the program is
extended with the comments inside data files. The default behavior is
to write to the output the name the generated files.

@<Internal...@>=
static int verbose=0;

@ Warn the user about the {\tt -v} if the flag was not used.

@<Print information about flags@>=
if (!verbose) @/
   fprintf(stderr, "- use \"%s -v\" to print information about data set.\n", argv[0]);

@ The flag {\tt -vvv} causes the program to print the values of the
indices moments before they are reached. It's used to check the
correctness of the algorithms used to calculated the indices. The
Boolean variable used to mark the mode is |confess|.

@d CONFESS_FLAG  "-vvv"

@<Internal...@>=
static int confess=0;

@ The program doesn't accept both flags, {\tt -v} and {\tt -vvv}, to
avoid an output complexity in terms of information and to set a
boundary between the two tasks.

@<Parse program arguments@>=
if (argc==2 && !strncmp(argv[1], CONFESS_FLAG, 5)) @/
   	confess = 1;

@ The user of the program is warned about the flag {\tt -vvv} if the
  flag was not used.

@<Print information about flags@>=
if (!confess) @/
   fprintf(stderr, "- use \"%s -vvv\" to show details about \
K-index calculation.\n", argv[0]);

@ In confess mode, a queue is necessary to not lost previous values of
some variable already processed. The queue is implemented using a
circular array where the field |front| is the index of the first
element and |rear| the index of last element. There's no problem in
overwriting some queue elements because only a limited number of
values |PREV_NVALS| lesser than the queue length |QLEN| are of
interest.

@d QLEN 32 /* queue length */
@d PREV_NVALS 5 /* number of elements of interest in the queue */

@<Internal...@>=
static struct queue_struct {
       int array[QLEN];
       int front, rear;
} queue;

@ Add the value |idx| in the rear of the queue.

@<Static...@>=
static void enqueue(int idx) {
       queue.array[queue.rear++] = idx;

       if (queue.rear == QLEN) @/
       	   queue.rear = 0;
}

@ The function |queue_is_empty| returns 1 when the queue is empty.

@<Static...@>=
static int queue_is_empty() {
        return queue.rear <= queue.front;
}

@ The function |dequeue_from_rear| removes the element in the rear of
the queue returning it. There is no need to remove elements in front
of the queue.

@<Static...@>=
static int dequeue_from_rear() {
       int idx;

       if (queue.rear <= queue.front) {
       	  panic("Queue is empty");
       }

       idx = queue.array[--queue.rear];

       return idx;
}

@ The queue fields |front| and |rear| are initialized using
|queue_reset|.

@<Static...@>=
static void queue_reset() {
       queue.front = queue.rear = 0;
}

@** Input data. The data to be processed comes from CSV
 (comma-separated values) and TSV (tab-separated vaules) files
 containing, among other data, the papers and its number of citations
 (CSV) or number of citings (TSV) of researchers. Each file stores
 data about one researcher.  The citing is the number of citations
 received by a paper that cites the researcher paper in question. The
 CSV files are used to calculate the $h$-index and TSV are used to
 find the $K$-index. An index file with author's identification and
 some information like his/her homepage is used to associate the data
 files. For example, an author with an Researcher ID equals to
 ''Z-1111-1900'' has the papers' citations in a file called
 ''Z-1111-1900.csv'' and the papers' citings in a file named
 ''Z-1111-1900.tsv''. The data files were saved inside in the value of
 |DATA_DIRECTORY| macro directory.

@d DATA_DIRECTORY "data/"

@* Fetching authors' record. The macro |AUTHORS_DATA_FN| is set with
 the file name that contains information about researchers
 (authors). Each line of the file has the name, Web of Science, Google
 Scholar or Publons research id and a link to a page containing more
 information about the author's publications. Not all authors have
 researcher id, when this occurs, we assign a number and link to the
 Web of Science page. The author's $h$-index and $K$-index are
 assigned to the fields |h| and |K|, respectively.

@d AUTHORS_DATA_FN "authors.idx"
@d MAX_STR_LEN 256

@<Data structures@>=
struct author {
    char name[MAX_STR_LEN];
    char researchid[MAX_STR_LEN];
    char url[MAX_STR_LEN];
    int h;
    int k;
    char timestamp[MAX_STR_LEN]; /* last modification of record */
};

@ |MAX_LINE_LEN| is the maximum length of each line, the value is very
high because some papers have too many authors.

@d MAX_LINE_LEN 1<<16

@<Local...@>=
 struct author *aut; /* temporary variable */
 char *fn, *p; /* file name and generic pointer */
 FILE *fp; /* file pointer */
 char buffer[MAX_STR_LEN]; /* buffer to store strings */
 char line[MAX_LINE_LEN]; /* store file lines */
 int i=0, j=0; /* general-purpose counters */

@ An array of structures is used to store the |authors|' information.
 The global variable |A| is set with the number of authors processed
 at the time it is read.

@<Internal...@>=
static struct author **authors; /* store authors' info */
static int A=0; /* number of authors */

@ Authors basic information was picked from the Web of Science page,
more specifically at \hfil\break {\tt
https://hcr.clarivate.com/\#categories\%3Dphysics} that is the page of
most cited authors in physics. They are stored in a file named
|authors.idx| that is openned to load this information.

@<Load authors info...@>=
fp = Fopen(AUTHORS_DATA_FN, "r"); @/
while (fgets(line, MAX_LINE_LEN, fp) != NULL) { @/
      if (is_comment(line)) @/
      	 continue; @/

      @<Reallocate the array of authors structure with to pointer elements@>@;
      @<Begin to fill authors structure@>@;

}
Fclose(fp);

@ To add a new author to the |authors| array, a reallocation of space
to it is needed because the array has the capacity exactly equals to
the current number of authors.

@<Reallocate the array of authors...@>=
 authors = (struct author**)realloc(authors, get_no_authors()*sizeof(struct author*));

@ The number of research authors is calculated by adding one to global
variable |A| that is the next free array index.

@<Static...@>=
static int get_no_authors() {
       return A+1;
}

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
aut = (struct author*)malloc(sizeof(struct author));
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
        case 3:
        aut->h = atoi(p);
	if (aut->h <= 0) {
	   fprintf(stderr, "==> h=%d <==\n");
	   panic("Wrong value of h-index, run confess mode.");
	}
        break;
        case 4:
        strncpy(aut->timestamp, p, MAX_STR_LEN);
        break;
        default:
        break;
    }
    p = strtok(NULL, IDX_SEP);
    i++;
}

if (!is_nobel_laureate(aut)) {
   authors[A++] = aut;
}

@ In all custom files used to parse the data, the hash character ''\#''
is used to indicate that after it the following tokens must be
interpreted as comments.

@<Static...@>=
int is_comment(char *line) {
    if (!line)
       goto exit_is_comment;

      if (line[0] == '#') {
            if (verbose)
      	       printf("%s", line);

	    return 1;
     }

    exit_is_comment:
      return 0;
}

@* Fetching Nobel Laureates. We have to discard researchers that
already was laureated with the Nobel Prize. Up to 2018, there was 935
laureates that awarded Nobel Prize. We put more chairs in the room to
accomodate future laureated researchers. A simple array is used to
store the IDs and a linear search is performed. As the number of
winners is not high, this simple scheme, even though not so efficient,
is used to avoid complexities.

@d N_LAUREATES 935
@d MORE_ROOM 128

@<Internal...@>=
static struct arr {
       char array[N_LAUREATES+MORE_ROOM][MAX_STR_LEN];
       int n; /* number of elements used */
} list;

@ A file |NOBEL_FN| with the identification number (id) of the Nobel
Laureates is used to check if the researcher already win the prize.

/* file name with ids of Nobel Laureates */
@d NOBEL_FN "laureates.dat"

@<Load the ids of Nobel Laureates@>=
fp = Fopen(NOBEL_FN, "r");
while (fgets(line, MAX_LINE_LEN, fp) != NULL) {
      if (is_comment(line))
      	 continue;

      /* Remove the new line */
      line[strcspn(line, "\r\n")] = 0;

      @<Insert research id in the list@>@;
}
Fclose(fp);

@ Each new Laureate id is inserted in the array list and the number of
elements in the list is incremented. No overflow checking is done.

@<Insert research id in the list@>=
strncpy(list.array[list.n++], line, sizeof(line));

@ The function |is_nobel_laureate| check in the laureated list with
IDs if the author |a| id is in the list. The string comparison does
not take into account if an id is prefix of another one because this
is very unlikely to occur.

@<Static...@>=
static int is_nobel_laureate(struct author *a) {
       int i;
       char *id = a->researchid;

       for (i=0; i<list.n; i++) {
       	   if (strncmp(list.array[i], id, sizeof(id))==0)
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

@* $h$-index. The number of papers is in decreasing order of citations
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

@* $K$-index. If an author receives at least K citations, where each
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
fp = Fopen(fn, "r");

 pos=1;
 ncits=0, old_ncits = 1000000;

if (confess) {
     fprintf(stderr, "%d. %s\n", i+1, authors[i]->name);
      queue_reset();
}

while (fgets(line, sizeof(line), fp) != NULL) {
       @<Parse the line counting citings@>@;
}
Fclose(fp);

@ @<Local variables@>=
 int pos; /* temporary variable to store the paper position */
 int ncits, old_ncits; /* current and old value of number of citings */

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

@ |K_SKIP| represents the fields to be skipped before {\it Times Cited\/}
value is reached. Its value is not fixed and for this reason it was
implemented a tricky way to get the {\it Times Cited\/} value: after
|K_SKIP| is passed, each field is accumulated in a queue and when the
end of the record is reached, the queue is dequeue three times to get
the {\it Times Cited\/} value. This position offset of {\it Times
Cited\/} value from the end is fixed for all files.

@d TSV_SEP "\t"
@d K_SKIP 7 /* number of fields that can be skipped with safety */

@<Find the citings and check if the K-index was found@>=
{ int ncits=0;
  j=0;
  p = strtok(line, TSV_SEP);
  while (p != NULL) {
	if (j > K_SKIP) {
	      push(p);
	}
	j++;
        p = strtok(NULL, TSV_SEP);
  }

  for (j=0; j<3; j++) @/
      p = pop();

   ncits = atoi(p);
   stack_reset();

   @<Check parsing integrity of citings@>@;
   @<Enqueue temporary index value@>@;

   old_ncits = ncits;

   if (pos > ncits) { /* found k */
       pos--;
       authors[i]->k = pos;

       @<Write the last values@>@;

       break;
  }
  pos++;
}

@ The articles are listed in descending order of number of citings.
 For this reason, the old value of number of citings |old_ncits|
 must not be lesser than current value just parsed |ncits|. The
 verification stops the program execution if this invariant is not
 obeyed.

@<Check parsing integrity of citings@>=
if (old_ncits < ncits) {
   fprintf(stderr, "==> %d<%d <==\n", old_ncits, ncits);
   panic("Previous number of citings is lesser the the current one.");
}

@ @<Enqueue temporary index value@>=
if (confess) @/
   enqueue(ncits);

@ @<Write the last values@>=
if (confess) { @/
   register int ii;

   fprintf(stderr, "==> found K=%d <==\n <> Last values\n", authors[i]->k);
   for (ii=0; ii<PREV_NVALS; ii++) {
       if (queue_is_empty())
       	  break;

       fprintf(stderr, " K: pos=%d, ncits=%d\n", (pos-- +1), \
               dequeue_from_rear());
   }
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

@ Elements are inserted at the top of the stack by invoking |enstack|
and using |char *p| as parameter. The index |idx| is incremented to
the number of elements in the stack and |top-1| is the index of the
element in the top.

@<Static...@>=
static void push(char *p) {
       if (p == NULL) {
          panic("Tring to push NULL in the stack");
	}

 	stack.data[stack.top++] = p;

	if (stack.top == STACK_LEN) {
	   panic("Stack overflow");
	}
}

@ Elements from the top of the stack are removed by |pop|
function. If there is no element in the stack, |NULL| is returned.

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
for (i=1; i<A; i++) {
    aut = authors[i];
    for (j=i-1; j>=0 && aut->k>authors[j]->k; j--) {
    	authors[j+1] = authors[j];
    }
    authors[j+1] = aut;
}

@** Output. The results are written as a table in markdown format to
the file name assigned to |RANK_FN|.  A space is needed between the
bars and the content.

@d RANK_FN "k-nobel.md"

@<Write results to a file@>=
fp = fopen(RANK_FN, "w");
if (!fp) {
   perror(fn);
   exit(-4);
}
fprintf(fp, "| N | Author | h | K |\n");
fprintf(fp, "|---|--------|---|---|\n");
for (i=0; i<A; i++) {
    fprintf(fp, "| %d | [%s](%s) | %d | %d |\n",
    	i+1,
       authors[i]->name, authors[i]->url,
       authors[i]->h, authors[i]->k);
}
fclose(fp);
fprintf(stderr, "* Wrote \"%s\"\n", RANK_FN);

@ A table with the twelve larger $K$s to be included in the manuscript
is written in LaTeX format.

@<Write a table with the twelve larger ks in latex format@>=
fn = "table.tex";
fp = fopen(fn, "w");
if (!fp) {
   perror(fn);
   exit(-8);
}
fprintf(fp, "\\begin{tabular}{cccc} \\\\ \\hline\n");
fprintf(fp, "\\bf N & \\bf Author &\\bg h &\\bf K \\\\ \\hline\n");
for (i=0; i<12; i++) {
    fprintf(fp, " %d & %s & %d & %d \\\\\n",
       i+1,
       authors[i]->name,
       authors[i]->h,
       authors[i]->k);
}
fprintf(fp, "\\hline\\end{tabular}\n");
fclose(fp);
fprintf(stderr, "* Wrote \"%s\"\n", fn);


@ Memory allocated for the array of pointers |authors| is freed.  As
the memory deallocation is the last task to be executed, a simple
usage notification is appended before the task.

@<Free up memory@>=
for (i=0; i<A; i++)
    free(authors[i]);
free(authors);

@** Index.
