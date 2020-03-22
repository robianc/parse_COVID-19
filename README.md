# parse_COVID-19
A Perl code to load the COVID-19 Italian dataset into an Excel file

(C) Roberto Bianconi 2020 
License: http://dev.perl.org/licenses/artistic.html

Installation:

You may need to install these Perl modules with cpan or cpanm. 

On Ubuntu, for example:
```
$ sudo apt-get cpanminus
$ sudo cpanm JSON
$ sudo cpanm File::Slurp
$ sudo cpanm Excel::Writer::XLSX
$ sudo cpanm Date::Calc
```
On Windows you can install www.strawberryperl.com and then:
```
> cpanm JSON
> cpanm File::Slurp
> cpanm Excel::Writer::XLSX
> cpanm Date::Calc
```

Usage:
```
$ perl parse_COVID-19.pl
```

The program retrieves the daily JSON summary https://github.com/pcm-dpc/COVID-19/blob/master/dati-json/dpc-covid19-ita-regioni.json and creates in ./out folder an Excel file with one sheet for each region with data stored for each day.

Set within code `$update = 0` to disable JSON file download.

The Excel file (not updated) is this one, see if it fits your needs: https://github.com/robianc/parse_COVID-19/blob/master/out/COVID-19.xlsx

The Excel also incudes the computation, for each region and each i-th day, of deceased(i)/deceased(j) for j={i-1,i-2,...,i-10}. This ratio could give an indication on the trend of death counts compared to death counts j days before. 
