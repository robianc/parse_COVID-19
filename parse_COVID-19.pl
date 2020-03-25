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

my $update = 1; # 1 to update with latest data 
my $ndays = 10; # number of days to include in analysis (last $ndays)
#------------------------------------------------------- no serviceable parts below
my @start_date = (2020,3,13);
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
    my ($date,$time) = split ("T",$record->{'data'});
    map { $covid{$record->{'denominazione_regione'}}{$date}{$_} = $record->{$_} } @vars;
}

my $st = join("/",reverse(@start_date));
my $nheaders2;
mkdir './out' unless (-e './out');
my $workbook = Excel::Writer::XLSX->new( './out/COVID-19.xlsx' );    # Step 1
my $format = $workbook->add_format();
$format->set_num_format( '0.00' );
my $dformat = $workbook->add_format( num_format => 'dd/mm/yyyy' );

my @regioni = keys %covid;
#my @regioni = ('Lombardia');
foreach my $regione (@regioni) {
    my $worksheet = $workbook->add_worksheet($regione);
    my $outfile = "./out/$regione.csv";
    open(OUT,">$outfile") or die $!;
    print OUT join(",",('Date',@vars));
    $worksheet->write_row(0,0,['Data',@vars]);
    for my $id (1..$ndays) {
        my $title = "d(i) / d(i-$id)";
        $worksheet->write(0,12+$id,$title);
#       my $titlen = "N / N-$id norm";
#       $worksheet->write(0,24+$id,$titlen);
    }
    my @dates = sort keys %{$covid{$regione}};
    my %deceduti;

    my $ifirst = $#dates - $ndays + 2;

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
            $worksheet->write($istart,12,$ndays-$id+1) if ($irow == $#dates+1);
            my $start_datetime = $dates[$istart-2];

            next unless ($deceduti{$start_datetime} > 0);
            my $formula = "=J$iend/J$istart";
            $worksheet->write_formula($irow,12+$id,$formula,$format);

        }
    }

    my $xfrom = xl_rowcol_to_cell($ifirst,12);

    my $xto = xl_rowcol_to_cell($irow,12);
    for my $id (1..$ndays) {
        my $yfrom = xl_rowcol_to_cell($ifirst,12+$id);
        my $yto = xl_rowcol_to_cell($irow,12+$id);

        my $aformula = "=EXP(INDEX(LINEST(LN($yfrom:$yto),$xfrom:$xto),1,2))";
        my $bformula = "=INDEX(LINEST(LN($yfrom:$yto),$xfrom:$xto),1)";

        my $yfromc = xl_rowcol_to_cell($irow+9,12+$id);
        my $ytoc = xl_rowcol_to_cell($irow+9+$ndays-1,12+$id);
        my $rformula = "=PEARSON($yfrom:$yto,$yfromc:$ytoc)";
        $worksheet->write_formula($irow+3,12+$id,$aformula);
        $worksheet->write_formula($irow+4,12+$id,$bformula);
        $worksheet->write_formula($irow+5,12+$id,$rformula);
        my $acell = xl_rowcol_to_cell($irow+3,12+$id);
        my $bcell = xl_rowcol_to_cell($irow+4,12+$id);
        my $gformula= "=INT(0.5-LN($acell)/$bcell)";
        $worksheet->write_formula($irow+6,12+$id,$gformula);
        my $gcell = xl_rowcol_to_cell($irow+6,12+$id);
        my $dcell = xl_rowcol_to_cell($ifirst-1,0);
        my $dformula= "=$gcell+$dcell";
        $worksheet->write_formula($irow+7,12+$id,$dformula,$dformat);

        $worksheet->write($irow+3,10,'y=a*exp(bx)');
        $worksheet->write($irow+3,12,'a');
        $worksheet->write($irow+4,12,'b');
        $worksheet->write($irow+5,12,'Pearson');
        my ($ye,$mo,$da) = split("-",$dates[$ifirst-2]);
        $worksheet->write($irow+6,12,"Estimated days from peak since $da/$mo/$ye");
        $worksheet->write($irow+7,12,"Estimated peak date:");

        for my $ii (1..$ndays) {
            my $xcell = xl_rowcol_to_cell($ifirst+$ii-1,12);
            my $cformula = "=$acell*EXP($bcell*$xcell)";
            $worksheet->write_formula($irow+8+$ii,12+$id,$cformula);
        }
    }
    close(OUT);

}
$workbook->close();
