package main

import (
	"log"
	"strconv"
	"strings"
)

func NewKIndex() *Index {
	idx := &Index{
		FileAttrs: FileAttrs{
			FileExt:           FileExtension(KIndexId),
			FieldSep:          "\t",
			LineIgnoredRegExp: `^PT`,
		},
	}
	idx.ParseLine = idx.CountCitings
	return idx
}

func (self *Index) CountCitings(line string) int {
	fields := strings.Split(line, self.FileAttrs.FieldSep)

	// A protection against errors or not syntatically correct record.
	if len(fields) < 3 {
		return 0
	}
	c, err := strconv.Atoi(fields[42])
	if err != nil {
		log.Fatal(err)
	}
	return c
}
