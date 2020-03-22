# parse_COVID-19
A Perl code to load the COVID-19 Italian dataset into an Excel file

(C) Roberto Bianconi 2020 
License: http://dev.perl.org/licenses/artistic.html

Installation:

usage:

perl parse_COVID-19.pl

The program retrieves the daily JSON summary https://github.com/pcm-dpc/COVID-19/blob/master/dati-json/dpc-covid19-ita-regioni.json and creates in ./out folder an Excel file with one sheet for each region.

The Excel also incudes the computation, for each day i, of deceased(i) / deceased(j) for j=i-1 ... i-10. This ratio could give an indication on the trend of death counts based on counts j days before. 
