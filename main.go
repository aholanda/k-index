package main

import "fmt"

func main() {
	hs := ProcessHFiles()
	for _, h := range hs {
		fmt.Printf("h(%s)=%d\n", h.GetFileName(), h.GetValue())
	}
}
