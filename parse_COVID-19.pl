use strict;

use File::Slurp;
use JSON;
use Data::Dumper;
use Excel::Writer::XLSX;

my $json_file = 'dpc-covid19-ita-regioni.json';
unlink $json_file if (-e $json_file);
system("wget","https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-json/dpc-covid19-ita-regioni.json");
my $json = read_file($json_file);
my $data = from_json($json);
my %covid;

my @vars = qw(terapia_intensiva nuovi_attualmente_positivi tamponi totale_casi ricoverati_con_sintomi totale_attualmente_positivi dimessi_guariti totale_ospedalizzati deceduti isolamento_domiciliare);
my @records = @{$data};
foreach my $record (@records) {
    map { $covid{$record->{'denominazione_regione'}}{$record->{'data'}}{$_} = $record->{$_} } @vars;
}

mkdir './out' unless (-e './out');
my $workbook = Excel::Writer::XLSX->new( './out/COVID-19.xlsx' );    # Step 1
my @regioni = keys %covid;
foreach my $regione (@regioni) {
    my $worksheet = $workbook->add_worksheet($regione);
    my $outfile = "./out/$regione.csv";
    open(OUT,">$outfile") or die $!;
    print OUT join(",",('Date',@vars));
    $worksheet->write_row(0,0,['Date',@vars]);
    my $ii = 0;
    my @datetimes = sort keys %{$covid{$regione}};
    foreach my $datetime (@datetimes) {
        $ii++;
        my ($date,$time) = split (" ",$datetime);
        my ($ye,$mo,$da) = split("-",$date);
        my @out = ("$da/$mo/$ye");
        foreach my $var (@vars) {
            push @out, $covid{$regione}{$datetime}{$var};
        }
        $worksheet->write_row($ii,0,[@out]);
        print OUT join(",",@out),"\n";
    }
    close(OUT);
}
$workbook->close();
