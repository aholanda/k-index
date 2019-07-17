package main

import "fmt"

func main() {
	hs := ProcessFiles()
	for _, h := range hs {
		fmt.Printf("h(%s)=%d\n", h.getFileName(), h.getValue())
	}
}
