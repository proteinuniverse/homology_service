use strict;
use warnings;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Log::Message::Simple qw[:STD :CARP];
use File::Basename;
use Parsers;

my ($in, $out, $skip);
my %skip_ids;

### set default values
my $help = 0;
my $verbose = 1;
my $coverage = 1;
my $length = 1;
my $assembler = 'megahit';
my $PRINT = 0;

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
        'v'        => \$verbose,
        'verbose'  => \$verbose,
	'c=f'    => \$coverage,
  	'coverage=f' => \$coverage,
	'l=i'  => \$length,
	'length=i' => \$length,
	'a=s'	=> \$assembler,
	'assembler=s' => \$assembler,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 2,
          -noperldoc => 1,
         ) if $help;

### redirect log output
my ($scriptname,$scriptpath,$scriptsuffix) = fileparse($0, ".pl");
open STDERR, ">>$scriptname.log" or die "cannot open log file";
local $Log::Message::Simple::MSG_FH     = \*STDERR;
local $Log::Message::Simple::ERROR_FH   = \*STDERR;
local $Log::Message::Simple::DEBUG_FH   = \*STDERR;

### set up i/o handles
my ($ih, $oh);
if ($in) {
    open $ih, "<", $in or die "Cannot open input file $in: $!";
}
elsif (! (-t STDIN))  {
    $ih = \*STDIN;
}
if ($out) {
    open $oh, ">", $out or die "Cannot open output file $out: $!";
}
else {
    $oh = \*STDOUT;
}

if ($skip) {
  open SKIP, $skip or die "could not open skip file $skip";
  while (<SKIP>) {
    my ($id) = split /\s+/;
    $skip_ids{$id}++;
  }
  close SKIP;
}

my @suffixlist = qw(.fa .fna .fasta);

# main logic
while(<$ih>){
  # for this metagenome
  my ($metagenome_id, $contigs_file) = split /\s+/;
  if ( $skip_ids{$metagenome_id} >= 1) { msg ("skipping $metagenome_id in skip file", $verbose); next; }
  if (-s $contigs_file == 0) { msg ("skipping $metagenome_id size is 0", $verbose); next; }
  open CONTIGS, $contigs_file or die "can not open contigs file: $contigs_file";

  # prepare filtered output file
  my($name,$path,$suffix) = fileparse($contigs_file,@suffixlist);
  my $filtered_file_name = $path . $name;
  $filtered_file_name .= '.' . $coverage . 'x' if $coverage;
  $filtered_file_name .= '.' . $length . 'bp' if $length;
  $filtered_file_name .= $suffix;

  # prepare the summary output file
  my $summary_file = $path . $name;
  $summary_file .= ".sum";

  open FILTERED, ">$filtered_file_name "or die "can not open filtered file";
  open SUMMARY,  ">$summary_file" or die "can not open summary file: $summary_file";

  # examine each contig
  msg("exminging contigs in $contigs_file", $verbose);
  while(<CONTIGS>) { 
    my $cov = 0;
    my $id;
    my $len = 0;

    if (/>/) {
      my $href = Parsers::parse_assembly($_, $assembler);
      if ($href->{coverage} >= $coverage && $href->{length} >= $length) {
        $PRINT = 1;
        print SUMMARY "$metagenome_id\t$href->{contig_id}\t$assembler\t$href->{length}\t$href->{coverage}\n";
      }
      else {
        $PRINT = 0;
      }
    }

    if ($PRINT == 1) {
      carp "nothing on the standard line" unless $_;
      print FILTERED $_;
    }
  } # end while contigs

  close FILTERED;
  close SUMMARY;
  print $oh "$metagenome_id\t$filtered_file_name\n";

} # end while input handle


 

=pod

=head1	NAME

filter_megahit_contigs.pl

=head1	SYNOPSIS

filter_megahit_contigs.pl <options>

=head1	DESCRIPTION

The filter_megahit_contigs.pl command ...

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   -i, --input

The input file, default is STDIN. It should be a tab delimted set of metagenome_id [tab] contig_file_name records.

=item   -o, --output

The output file, default is STDOUT. This is a tab delimited set of metagenome_id [tab] filtered_contig_file_name records.

=item	-c, --coverage

The minimum coverage of contigs to keep.

=item	-l, --length

The minimum length of contigs to keep.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

