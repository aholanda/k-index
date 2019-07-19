package main

import (
	"html/template"
	"log"
	"os"
	"strings"
)

type Author struct {
	Name   string
	Area   string
	HIndex int
	KIndex int
}

type Rank struct {
	Authors []*Author
}

var areas = map[string]string{
	"aa":   "ASTRONOMY ASTROPHYSICS",
	"pamc": "PHYSICS ATOMIC MOLECULAR CHEMICAL",
	"pm":   "PHYSICS MULTIDISCIPLINARY",
	"ppf":  "PHYSICS PARTICLES FIELDS",
}

func (self *Author) setIndex(idx *Index) {
	val := idx.GetValue()
	if idx.Id == HIndexId {
		self.HIndex = val
	} else {
		self.KIndex = val
	}
}

func parseIndex(n2a map[string]*Author, idx *Index) {
	var name, area string
	fields := strings.Split(idx.GetFileName(), ".")
	fields = strings.Split(fields[0], "-")

	if len(fields) == 2 {
		name, area = fields[0], fields[1]
		name = strings.Replace(name, "data/", "", 1)
		area = areas[area]
	} else {
		log.Fatalf("Incorrect file name: %s\n", idx.GetFileName())
	}

	author, ok := n2a[name]
	if !ok {
		author = &Author{name, area, -1, -1}
		n2a[name] = author
	}
	author.setIndex(idx)
}

func process(idxs []*Index) []*Author {
	var authors []*Author
	name2author := make(map[string]*Author)

	for _, idx := range idxs {
		parseIndex(name2author, idx)
	}

	i := 0
	for _, author := range name2author {
		authors = append(authors, author)
		i++
	}
	return authors
}

func WriteRank(idxs []*Index) {
	var authors []*Author

	authors = process(idxs)

	tmpl := template.Must(template.ParseFiles("rank.tmpl"))
	err := tmpl.Execute(os.Stdout, Rank{authors})
	if err != nil {
		panic(err)
	}
}
