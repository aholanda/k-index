package main

import (
	"log"
	"path/filepath"
)

// List files from data directory
func ListFiles(regex string) (fileNames []string) {
	fileNames, err := filepath.Glob("./" + DataDir + regex)
	if err != nil {
		log.Fatal(err)
	}
	return fileNames
}

func ProcessFiles(id IndexId) []*Index {
	var idx *Index
	var idxs []*Index
	var newIndex func() *Index
	var err error

	switch id {
	case HIndexId:
		newIndex = NewHIndex
	case KIndexId:
		newIndex = NewKIndex
	}

	regex := "*" + FileExtension(id)
	fileNames := ListFiles(regex)
	for _, fn := range fileNames {
		idx = newIndex()
		idx.FileName = fn
		idx.Value, err = idx.Calculate(fn)
		if err != nil {
			log.Fatal(err)
		}
		idxs = append(idxs, idx)
	}
	return idxs
}

func main() {
	var indices []*Index
	ids := [2]IndexId{HIndexId, KIndexId}
	for _, id := range ids {
		idxs := ProcessFiles(id)
		for _, idx := range idxs {
			indices = append(indices, idx)
		}
	}
	WriteRank(indices)
}
