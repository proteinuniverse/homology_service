use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;

my $help = 0;
my ($in, $out, $coverage, $length);
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


# do a little validation on the parameters


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


# main logic



while(<$ih>){
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
    print $oh $_;
    print STDERR "$id\t$len\t$cov\n" if />/;
  }
}



 

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

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

