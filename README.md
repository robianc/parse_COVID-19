# parse_COVID-19
A Perl code to load the COVID-19 Italian dataset into an Excel file

(C) Roberto Bianconi 2020 
License: http://dev.perl.org/licenses/artistic.html

Installation:

You may need yo install non core modules with cpan or cpanm.

Usage:

$ perl parse_COVID-19.pl

The program retrieves the daily JSON summary https://github.com/pcm-dpc/COVID-19/blob/master/dati-json/dpc-covid19-ita-regioni.json and creates in ./out folder an Excel file with one sheet for each region with data stored for each day.

The Excel file (not updated) is this one, see if it fits your needs: https://github.com/robianc/parse_COVID-19/blob/master/out/COVID-19.xlsx

The Excel also incudes the computation, for each i-th day, of deceased(i)/deceased(j) for j={i-1,i-2,...,i-10}. This ratio could give an indication on the trend of death counts compared to death counts j days before. 
