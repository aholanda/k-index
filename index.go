package main

import (
	"log"
	"path/filepath"
)

const (
	// Buffer size to be set in IO operations
	BufferSize = 1000 // bytes
	// Default directory to store data files
	DataDir = "data/"
)

// An Index interface propose a method to
// perform the index calculation that returns
// an int value corresponding to the index and
// an error if something goes wrong.
type Index interface {
	Calculate(fileName string) (n int, err error)
}

// List files from data directory
func ListFiles(regex string) (fileNames []string) {
	fileNames, err := filepath.Glob("./" + DataDir + regex)
	if err != nil {
		log.Fatal(err)
	}
	return fileNames
}
