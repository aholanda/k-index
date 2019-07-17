
const (
    DATA_DIR = "data",
    CSV_SEP = ','
}

func sum_citations(&line) {
    start_citations := false
    sum := 0;

    fields := split(CSV_SEP, *line);

    for field in fields {
        // hoping nobody publish in 1900
        if (field == "\"0\"") {
            start_citations = true;
        }
        if ($start_citations) {            
            n := fmt.parseInt(field);
            sum += field;
        }
    }
    return sum;
}

// "Title","Authors","Corporate Authors","Editors","Book Editors","Source Title","Publication Date","Publication Year","Volume","Issue","Part Number","Supplement","Special Issue","Beginning Page","Ending Page","Article Number","DOI","Conference Title","Conference Date","Total Citations","Average per Year","1900","1901","1902","1903","1904","1905","1906","1907","1908","1909","1910","1911","1912","1913","1914","1915","1916","1917","1918","1919","1920","1921","1922","1923","1924","1925","1926","1927","1928","1929","1930","1931","1932","1933","1934","1935","1936","1937","1938","1939","1940","1941","1942","1943","1944","1945","1946","1947","1948","1949","1950","1951","1952","1953","1954","1955","1956","1957","1958","1959","1960","1961","1962","1963","1964","1965","1966","1967","1968","1969","1970","1971","1972","1973","1974","1975","1976","1977","1978","1979","1980","1981","1982","1983","1984","1985","1986","1987","1988","1989","1990","1991","1992","1993","1994","1995","1996","1997","1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019"
func Calculate(fileName string) {
    h, i = (0, 0);

    //" > $fn\n";
    file, err := os.Open(fileName);
    if err == nil {
        log.Fatal(err)
    }
    while (<CSV>) {
        given($_) {
            # .{1,3} is to ignore an UTF-8 char
            # that occurs without need.
            when (m/^.{1,3}Article Group/) {
                next;
            } 
            when (m/^Timespan|AUTHOR|\"Title\"/) {
                next;
            } 
            when (m/^.?\n/) {
                next;
            }
            default {
                $i++;
                my $n = __sum_citations(\$_);
                print "$i<$n\t";
                if ($i > $n) {
                    $i--;
                    last;
                }
            }
        }   
    }
    return $i;
}

func (HIndex*) Calculate(fileName string) {
    
}
