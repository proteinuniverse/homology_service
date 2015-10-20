use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;

my $help = 0;
my ($in, $out);

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,

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






 

=pod

=head1	NAME

assemble_metagenome.pl

=head1	SYNOPSIS

assemble_metagenome.pl <options>

=head1	DESCRIPTION

The assemble_metagenome.pl command ...

=head1	LIMITATION

At the current time, only one fastq or fasta file is taken as input. Multiple fastq files need to be concatenated together prior to running this script.

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   -i, --input

The input file, default is STDIN. This is required. It contains the list of metagenomes to assemble.

=item   -o, --output

The output file, default is STDOUT. This is the metagenome id and the assembly file in tab delimited format.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

