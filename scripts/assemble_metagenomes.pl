use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;

use Template;

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

our $cfg = {};
# TODO: use Config::Simple to specify which .tt file to use
# and then modify to support paired end or interleaved reads.
# Though, this is not needed for the specific task at hand.


if ($ih) { 
  while(<$ih>) {
    my($metagenome_id, $filename) = split /\s+/;
    die "$filename not readable" unless (-e $filename and -r $filename);
    my $vars = {se_reads => $filename,
		base     => "base", 
	       };
    my $tt = Template->new();
    my $cmd;
    $tt->process("megahit-se.tt", $vars, \$cmd)  or die $tt->error(), "\n";
    print STDERR "cmd: $cmd", "\n";
    !system $cmd or die "could not execute $cmd\n$!";
    print $oh $metagenome_id, "\t", $vars->{base} . '/final.contigs.fa';
    print STDERR "cmd: finished\n";
  }
}
else {
  die "no input found, input is required";
}




 

=pod

=head1	NAME

assemble_metagenome.pl

=head1	SYNOPSIS

assemble_metagenome.pl -i file -o file 

=head1	DESCRIPTION

The assemble_metagenome.pl script assembles a metagenome using an assembler and parameters defined in a template file.

=head1	LIMITATION

At the current time, only one fastq or fasta file is taken as input. Multiple fastq files need to be concatenated together prior to running this script.

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   -i, --input

The input file, default is STDIN. This is required. It is a tab delimited input, with one metagenome id and the read file(s). If multiple read files are to be processed, they must be comma separated with no whitespace. 

=item   -o, --output

The output file, default is STDOUT. This is the metagenome id and the assembly file in tab delimited format.

=back

=head1	AUTHORS

Thomas Brettin

=cut



1;

