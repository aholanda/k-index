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

// An Indexer interface propose a method to
// perform the index calculation that returns
// an int value corresponding to the index and
// an error if something goes wrong.
type Indexer interface {
	Calculate(fileName string) (n int, err error)
}

type Index struct {
	Value int // Index value.
	// File name to parse and calculate the index.
	FileName string
	// Common file attributes for the index.
	FileAttrs *FileAttrs
}

type FileAttrs struct {
	FileExt  string // File extension
	FieldSep string // What character separate fields
	// regex string composed by rules that may be
	// applied to ignore lines.
	LineIgnoredRegExp string
}

func (i Index) GetFileName() string {
	return i.FileName
}

func (i Index) SetFileName(fileName string) {
	i.FileName = fileName
}

func (i Index) GetValue() int {
	return i.Value
}

// Read a file ignoring some lines.
// Use chanel to send the line to be processed.
func Read(fileAttrs FileAttrs, fileName string, line chan string) {
	rules := fileAttrs.LineIgnoredRegExp
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
		fmt.Println(ln)
		line <- ln
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
