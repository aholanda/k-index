package main

import (
	"fmt"
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
	//ids := [2]IndexId{HIndexId, KIndexId}
	ids := [1]IndexId{KIndexId}
	for _, id := range ids {
		is := ProcessFiles(id)
		for _, i := range is {
			fmt.Printf("%v(%s)=%d\n", id, i.GetFileName(), i.GetValue())
		}
	}
}
