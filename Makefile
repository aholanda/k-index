CFLAGS := -g -Wall
PKG := apt
INSTALL := install
WINCC := x86_64-w64-mingw32-gcc

DATA_URL := 'https://drive.google.com/uc?export=download&id=1yuaGztX44jec657z_mSRcVv4cWG1sBaG'

all: k-nobel k-nobel.pdf data
	./k-nobel

k-nobel: k-nobel.c

k-nobel.exe: k-nobel.c
	$(WINCC) $< -o $@

k-nobel.pdf: k-nobel.tex
	pdftex $<

data: dataset.zip
	unzip $<

deps:
	`which sudo` $(PKG) $(INSTALL) cwebx gcc gcc-mingw-w64-x86-64

dataset.zip:
	wget --no-check-certificate -r $(DATA_URL) -O $@

clean:
	$(RM) k-nobel k-nobel.c k-nobel.dvi k-nobel.pdf k-nobel.tex \
	      k-nobel.idx k-nobel.log k-nobel.scn k-nobel.toc

.PHONY: all clean
