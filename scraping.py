#!/usr/bin/env python3

import requests
from bs4 import BeautifulSoup

page = requests.get('https://apps.webofknowledge.com/summary.do?product=WOS&parentProduct=WOS&search_mode=TotalCitingArticles&parentQid=&qid=13&SID=6EovFZaU9YVGLeW32ix&&page=4')

soup = BeautifulSoup(page.text, 'html.parser')

print(soup)
