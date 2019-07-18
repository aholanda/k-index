package main

import "fmt"

func ProcessFiles(id IndexId) []*Index {
	var idx *Index
	var idxs []*Index
	var newIndex func() *Index

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
		idx.Value, _ = idx.Calculate(fn)
		idxs = append(idxs, idx)
	}
	return idxs
}

func main() {
	ids := [2]IndexId{HIndexId, KIndexId}
	for _, id := range ids {
		is := ProcessFiles(id)
		for _, i := range is {
			fmt.Printf("%v(%s)=%d\n", id, i.GetFileName(), i.GetValue())
		}
	}
}
