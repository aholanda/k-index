package main

import (
	"bufio"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
)

const (
	FileExt  = ".csv"
	FieldSep = ","
)

type HIndex struct {
	Idx      int
	FileName string
}

func (i *HIndex) getValue() int {
	return i.Idx
}

func (i *HIndex) getFileName() string {
	return i.FileName
}

func count_citations(line string) (c int) {
	start_citations := false
	sum := 0

	fields := strings.Split(line, FieldSep)

	if len(fields) <= 1 {
		return 0
	}

	for _, field := range fields {
		// TODO: make sure it does not depend on year.
		// Hoping nobody publish in 1900
		if field == "\"0\"" {
			start_citations = true
		}
		if start_citations {

			field = strings.Replace(field, "\"", "", -1)
			c, err := strconv.Atoi(field)
			if err != nil {
				log.Fatal(err)
			}
			sum = sum + c
		}
	}
	return sum
}

// "Title","Authors","Corporate Authors","Editors","Book Editors","Source Title","Publication Date","Publication Year","Volume","Issue","Part Number","Supplement","Special Issue","Beginning Page","Ending Page","Article Number","DOI","Conference Title","Conference Date","Total Citations","Average per Year","1900","1901","1902","1903","1904","1905","1906","1907","1908","1909","1910","1911","1912","1913","1914","1915","1916","1917","1918","1919","1920","1921","1922","1923","1924","1925","1926","1927","1928","1929","1930","1931","1932","1933","1934","1935","1936","1937","1938","1939","1940","1941","1942","1943","1944","1945","1946","1947","1948","1949","1950","1951","1952","1953","1954","1955","1956","1957","1958","1959","1960","1961","1962","1963","1964","1965","1966","1967","1968","1969","1970","1971","1972","1973","1974","1975","1976","1977","1978","1979","1980","1981","1982","1983","1984","1985","1986","1987","1988","1989","1990","1991","1992","1993","1994","1995","1996","1997","1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019"
func Calculate(fileName string) (n int, err error) {
	lineIgnored := regexp.MustCompile(`^.{0,3}Article|Timespan|AUTHOR`)

	file, err := os.Open(fileName)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	reader := bufio.NewReader(file)

	var line string
	i := 0
	for {
		line, _ = reader.ReadString('\n')
		// Remove any end of line
		line = strings.TrimRight(line, "\r\n")

		if lineIgnored.FindString(line) != "" {
			continue
		}

		// Process the line here.
		c := count_citations(line)

		// Prevent any well-formed line
		if c == 0 {
			continue
		}

		i = i + 1
		// Found h-index that is the last i
		if i > c {
			i = i - 1
			break
		}
	}
	return i, nil
}

func ProcessFiles() (hs []HIndex) {
	regex := "*" + FileExt
	fileNames := ListFiles(regex)
	for _, fn := range fileNames {
		h, _ := Calculate(fn)
		hs = append(hs, HIndex{h, fn})
	}
	return hs
}
