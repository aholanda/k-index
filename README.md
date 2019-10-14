# K-INDEX

- Aim: Use [K-index](https://arxiv.org/abs/1609.05273v2) as a predictor of who will be awarded with a scientific prize.
- Testbed: gather most of the [Highly Cited Researchers](https://hcr.clarivate.com/) in Physics from Clarivate
  	   and try to predict the Nobel Laureates. The use of K-index is not limited to Nobel Laureates prediction.
	   We compare the results with the standard scientometric index used by Web of Science, the
	   h-index (Hirsch index).
- Manuscript: [arXiv:1910.02369](https://arxiv.org/abs/1910.02369), 2019.

## Research Team

- [Osame Kinouchi](https://publons.com/researcher/1537219/osame-kinouchi/);
- [Adriano J. Holanda](https://publons.com/researcher/1343572/adriano-de-jesus-holanda/);
- [George C. Cardoso](https://publons.com/researcher/1515858/george-c-cardoso/).

## Reproducibility

The results can be totally reproduced by performing the following instructions:

### Automatic

To reproduce the experiment, clone the repository, install `make`,
[`cweb`](https://www-cs-faculty.stanford.edu/~knuth/cweb.html) and a C
compiler and run

````
$ make
````

### Manual

The following steps are less automated but they have less dependencies:

- Download the data using the [link](https://drive.google.com/uc?export=download&id=1yuaGztX44jec657z_mSRcVv4cWG1sBaG);
- Unzip the downloaded data;
- Download the program binary [Linux-x86_64](k-nobel) or
  [Windows-x86_64](k-nobel.exe) according to the platform;
- Run the program in the same directory where the data were extracted.

## Documentation

- [Program documentation](k-nobel.pdf).

## Contributor

- [Luis Fernando Castro](https://github.com/ferdox2) - [fixes some
  grammatical and spelling
  errors](https://github.com/ajholanda/k-nobel/pull/9/).

## References

- J. E. Hirsch. ["An index to quantify an individual's scientific
research output,"](https://www.pnas.org/content/102/46/16569) *PNAS*
**102** (15) 16569-16572, 2005. [[*Wikpedia*
entry](https://en.wikipedia.org/wiki/H-index)]
- O. Kinouchi, L. D. H. Soares, G. C. Cardoso. ["A simple
impact index for scientific innovation and
recognition,"](https://arxiv.org/abs/1609.05273v2)
*arXiv*:1609.05273v2, 2017.
