use strict;

# (C) rbianconi@enviroware.com
#https://github.com/robianc/parse_COVID-19

#License: http://dev.perl.org/licenses/artistic.html

use File::Slurp;
use JSON;
use Data::Dumper;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use Date::Calc qw (Delta_Days);

my $update = 1;
my $json_file = 'dpc-covid19-ita-regioni.json';
if ($update) {
    unlink $json_file if (-e $json_file);
    system("wget","https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-json/dpc-covid19-ita-regioni.json");
}
my $json = read_file($json_file);
my $data = from_json($json);
my %covid;

my @vars = qw(terapia_intensiva nuovi_attualmente_positivi tamponi totale_casi ricoverati_con_sintomi totale_attualmente_positivi dimessi_guariti totale_ospedalizzati deceduti isolamento_domiciliare);
my @records = @{$data};
foreach my $record (@records) {
    my ($date,$time) = split (" ",$record->{'data'});
    map { $covid{$record->{'denominazione_regione'}}{$date}{$_} = $record->{$_} } @vars;
}

my @start_date = (2020,3,13);
my $ndays = 10;

my $nheaders2;
mkdir './out' unless (-e './out');
my $workbook = Excel::Writer::XLSX->new( './out/COVID-19.xlsx' );    # Step 1
my $format = $workbook->add_format();
$format->set_num_format( '0.00' );
my @regioni = keys %covid;
foreach my $regione (@regioni) {
    my $worksheet = $workbook->add_worksheet($regione);
    my $outfile = "./out/$regione.csv";
    open(OUT,">$outfile") or die $!;
    print OUT join(",",('Date',@vars));
    $worksheet->write_row(0,0,['Data',@vars]);
    for my $id (1..$ndays) {
        my $title = "N / N-$id";
        $worksheet->write(0,12+$id,$title);
        my $titlen = "N / N-$id norm";
        $worksheet->write(0,24+$id,$titlen);
    }
    my @dates = sort keys %{$covid{$regione}};
    my %deceduti;

    my $ifirst;
    foreach my $date (@dates) {
        my ($ye,$mo,$da) = split("-",$date);
        $ifirst++;
        my $dd = Delta_Days(@start_date,$ye,$mo,$da);
        last if ($dd == 0);
    }

    my $irow = 0;
    foreach my $date (@dates) {
        $deceduti{$date} = $covid{$regione}{$date}{'deceduti'};
        $irow++;
        my ($ye,$mo,$da) = split("-",$date);
        my @out = ("$da/$mo/$ye");
        foreach my $var (@vars) {
            push @out, $covid{$regione}{$date}{$var};
        }
        $worksheet->write_row($irow,0,[@out]);
        print OUT join(",",@out),"\n";
        my $dd = Delta_Days(@start_date,$ye,$mo,$da);
        next if ($dd < 0);

        for my $id (1..$ndays) {
            my $iend = $irow+1;
            my $istart = $iend-$id;
            my $start_datetime = $dates[$istart-2];

            next unless ($deceduti{$start_datetime} > 0);
            my $formula = "=J$iend/J$istart";
            $worksheet->write_formula($irow,12+$id,$formula,$format);
            my $strnum = xl_rowcol_to_cell($irow,12+$id);
            my $strden = xl_rowcol_to_cell($ifirst,12+$id);
            my $formulan = "=$strnum/$strden";
            $worksheet->write_formula($irow,24+$id,$formulan,$format);
        }
    }
    close(OUT);
}
$workbook->close();
