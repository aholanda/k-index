#!/usr/bin/env python3
# Inspired by: https://github.com/Clarivate-SAR/incites-retrieve/blob/master/batch_lookup_v1.py

import csv, os, sys

from urllib.request import urlopen, Request
from urllib.parse import urlencode
from itertools import zip_longest as zipl

# local
from wos_lite import WoSLite
from utils import print_error_and_exit

ESCI = False # Set to True to include ESCI in results
# Number of UTs to send to InCites at once - 100 is limit set by API.
BATCH_SIZE = 100

# Define the fields for the output file. In lieu of putting the entire
# result set into memory before writing out, we must explicitly list the
# fields to account for the unlikely case that the first batch of results
# is missing fields that would be returned in a subsequent batch.
fields = ["ISI_LOC",
          "ARTICLE_TYPE",
          "TOT_CITES",
          "JOURNAL_EXPECTED_CITATIONS",
          "JOURNAL_ACT_EXP_CITATIONS",
          "IMPACT_FACTOR",
          "AVG_EXPECTED_RATE",
          "PERCENTILE",
          "NCI",
          "ESI_MOST_CITED_ARTICLE",
          "HOT_PAPER",
          "IS_INTERNATIONAL_COLLAB",
          "IS_INSTITUTION_COLLAB",
          "IS_INDUSTRY_COLLAB",
          "OA_FLAG",
          "RNUM"]
def grouper(iterable, n, fillvalue=None):
    """
    Group iterable into n sized chunks.
    See: http://stackoverflow.com/a/312644/758157
    """
    args = [iter(iterable)] * n
    return zipl(*args, fillvalue=fillvalue)

def main():

    found = []
    to_check = []
    with open(sys.argv[1]) as infile:
        for row in csv.DictReader(infile):
            d = {}
            for k, v in row.items():
                if k.lower().strip() == "ut":
                    to_check.append(v.strip().replace("WOS:", ""))

    found = []

    writer = csv.DictWriter(sys.stdout, fieldnames=fields)
    writer.writeheader()
    for idx, batch in enumerate(grouper(to_check, BATCH_SIZE)):
        eprint("Processing batch", idx)
        found = get(batch)
        for grp in found:
            writer.writerow(grp)
        time.sleep(.5)

def check_key():
    if 'WOS_KEY' not in os.environ:
        print_error_and_exit('Environment variable "WOS_KEY" was not set, '
                             'please set it with the Web of Science'
                             ' developer key provided by Clarivate'
                             ' Analytics.')

    return os.environ['WOS_KEY']

if __name__ == "__main__":
    key = check_key()

    batch = ['01288946', '000235983900007', '000253436400011']
    wos = WoSLite(key)
    wos.get(batch)
