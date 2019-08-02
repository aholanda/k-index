CFLAGS := -g

all: k-nobel k-nobel.pdf
	./k-nobel

k-nobel: k-nobel.c

k-nobel.pdf: k-nobel.tex
	pdftex $<

clean:
	$(RM) k-nobel k-nobel.c k-nobel.dvi k-nobel.pdf k-nobel.tex \
	      k-nobel.idx k-nobel.log k-nobel.scn k-nobel.toc

.PHONY: all clean
