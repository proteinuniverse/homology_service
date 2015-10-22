use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use File::Basename;

my $help = 0;
my ($in, $out, $coverage, $length, $skip);
my %skip_ids;
my $PRINT = 0;


GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
	'c=f'    => \$coverage,
  	'coverage=f' => \$coverage,
	'l=i'  => \$length,
	'length=i' => \$length,

) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 2,
          -noperldoc => 1,
         ) if $help;

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
  my ($metagenome_id, $contigs_file) = split /\s+/;
  if ( $skip_ids{$metagenome_id} >= 1) { print "skipping $metagenome_id\n"; next; }

  open CONTIGS, $contigs_file or die "can not open contigs file: $contigs_file";

  my($name,$path,$suffix) = fileparse($contigs_file,@suffixlist);
  my $filtered_file_name = $path . $name;
  $filtered_file_name .= '.' . $coverage . 'x' if $coverage;
  $filtered_file_name .= '.' . $length . 'bp' if $length;
  $filtered_file_name .= $suffix;
  open FILTERED, ">$filtered_file_name "or die "can not open filtered file";

  while(<CONTIGS>) { 
    my $cov = 0;
    my $id;
    my $len = 0;

    if (/>/) {
      # look at the id
      $id = $1 if />(\S+)/;
      $id = $1 if />(\S+)_length/;
      die "could not parse id" unless $id;
      # look at coverage
      $cov = $1 if /multi=([\d\.]+)/;
      $cov = $1 if /multi_([\d\.]+)/;
      die "could not parse coverage" unless $cov;
      # look at length
      $len = $1 if /len=(\d+)/;
      $len = $1 if /length_(\d+)/;
      die "could not parse length" unless $len;

      if ($cov >= $coverage && $len >= $length) {
        $PRINT = 1;
      }
      else {
        $PRINT = 0;
      }
    }

    if ($PRINT == 1) {
      print STDERR "problem" unless $_;
      print FILTERED $_;
      print STDERR "$id\t$len\t$cov\n" if />/;
    }
  } # end while contigs
  close FILTERED;
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

The input file, default is STDIN

=item   -o, --output

The output file, default is STDOUT

=item	-c, --coverage

The minimum coverage of contigs to keep.

=item	-l, --length

The minimum length of contigs to keep.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

