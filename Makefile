PROJ := k-index
INSTALL :=  apt install
CFLAGS := -g -Wall
WINCC := x86_64-w64-mingw32-gcc

DATAZIP := /tmp/dataset.zip
DATADIR := data
DATAURL := 'https://drive.google.com/uc?export=download&id=1yuaGztX44jec657z_mSRcVv4cWG1sBaG'

MAN1DIR := ${HOME}/.local/man/man1

.SILENT:

rank.md: $(DATADIR)
	./$(PROJ)

$(PROJ): $(PROJ).c man
	$(CC) $(CFLAGS) $< -o $@

$(PROJ).exe: $(PROJ).c
	$(WINCC) $(CFLAGS) $< -o $@

$(PROJ).pdf: $(PROJ).tex
	pdftex $<

$(DATADIR): $(DATAZIP)
	unzip $<

$(DATAZIP):
	wget --no-check-certificate -r $(DATAURL) -O $@

man: $(PROJ).1
	-if [ ! -d $(MAN1DIR) ]; then mkdir -vp $(MAN1DIR); fi
	-cp $< $(MAN1DIR)

deps:
	`which sudo` $(INSTALL) cwebx gcc gcc-mingw-w64-x86-64

clean:
	$(RM) $(PROJ) *.c *.exe \
		*.dvi *.idx *.log *.pdf *.scn *.tex *.toc

tidy: clean
	$(RM) -r $(DATADIR) $(DATAZIP)


.PHONY: all clean deps man
