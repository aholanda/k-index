package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

const (
	// Buffer size to be set in IO operations
	BufferSize = 1000 // bytes
	// Default directory to store data files
	DataDir = "data/"
)

// Type to enumerate indexes
type IndexId int8

const (
	HIndexId IndexId = 0
	KIndexId IndexId = 1
)

func (id IndexId) String() string {
	names := [...]string{
		"h-index",
		"K-index",
	}

	if id < HIndexId || id > KIndexId {
		return "Unknown index"
	}

	return names[id]
}

func FileExtension(id IndexId) string {
	switch id {
	case HIndexId:
		return ".csv"
	case KIndexId:
		return ".tsv"
	default:
		log.Fatalf("Unknown index: %d\n", id)
	}
	// very unlikely
	return ""
}

// An Indexer interface propose a method to
// perform the index calculation that returns
// an int value corresponding to the index and
// an error if something goes wrong.
type Indexer interface {
	Calculate(fileName string) (n int, err error)
}

type FileAttrs struct {
	FileExt  string // File extension
	FieldSep string // What character separate fields
	// regex string composed by rules that may be
	// applied to ignore lines.
	LineIgnoredRegExp string
}

type Index struct {
	Value int // Index value.
	// File name to parse and calculate the index.
	FileName string
	// Common file attributes for the index.
	FileAttrs FileAttrs
	// parseLine() count the citations or citings
	// depending on the index.
	ParseLine func(string) int
}

func (i Index) GetFileName() string {
	return i.FileName
}

func (i Index) SetFileName(fileName string) {
	i.FileName = fileName
}

func (i Index) GetFileAttrs() FileAttrs {
	return i.FileAttrs
}

func (i Index) SetFileAttrs(fileAttrs FileAttrs) {
	i.FileAttrs = fileAttrs
}

func (i Index) GetValue() int {
	return i.Value
}

func (i Index) SetValue(value int) {
	i.Value = value
}

func (i Index) GetFuncParseLine() func(string) int {
	return i.ParseLine
}

func (i Index) SetFuncParseLine(pl func(string) int) {
	i.ParseLine = pl
}

// Read a file ignoring some lines.
// Use chanel to send the line to be processed.
func (self *Index) Read(fileName string, line chan string) {
	rules := self.FileAttrs.LineIgnoredRegExp
	lineIgnored := regexp.MustCompile(rules)

	file, err := os.Open(fileName)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	reader := bufio.NewReader(file)

	var ln string
	for {
		ln, err = reader.ReadString('\n')

		// Remove any end of line
		ln = strings.TrimRight(ln, "\r\n")
		if lineIgnored.FindString(ln) != "" || ln == "" {
			continue
		}

		if err != nil {
			close(line)
			break
		}

		// Process the line here.
		// Send the line to the parser.
		line <- ln
	}
}

func (self *Index) Calculate(fileName string) (n int, err error) {
	line := make(chan string)
	var i int
	// Mark if the index was calculated with the
	// available records
	hasEnoughRecords := false

	go self.Read(fileName, line)

	for i = 1; ; i++ {
		c := self.ParseLine(<-line)
		if i > c {
			i--
			hasEnoughRecords = true
			break
		}
	}
	if hasEnoughRecords == false {
		return -1, fmt.Errorf("There is not enough records to calculate index!")
	} else {
		return i, nil
	}
}

// List files from data directory
func ListFiles(regex string) (fileNames []string) {
	fileNames, err := filepath.Glob("./" + DataDir + regex)
	if err != nil {
		log.Fatal(err)
	}
	return fileNames
}
