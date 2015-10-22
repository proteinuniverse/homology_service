use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;

use Template;
use Config::Simple;

my $help = 0;
my ($in, $out, %skip, $skip_file);
our $cfg;

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
	's=s'	=> \$skip_file,
	'skip=s'   => \$skip_file,
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

if ($skip_file) { 
  open SKIP, $skip_file or die "could not open skip file $skip_file.";
  while (<SKIP>) {
    my ($id) = split /\s+/;
    $skip{$id}++;
  }
  close SKIP;
}

# main logic

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "can not create Config object";
    print "using $ENV{KB_DEPLOYMENT_CONFIG} for configs\n";
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('homology_service.assembly_tt','/homes/brettin/local/dev_container/modules/homology_service/templates/megahit-se.tt');
}


if ($ih) { 
  while(<$ih>) {
    my $cmd;
    my($metagenome_id, $filename) = split /\s+/;
    if ( $skip{$metagenome_id} >= 1) { print "skipping $metagenome_id\n"; next; }
    die "$filename not readable" unless (-e $filename and -r $filename);

    my $vars = { se_reads => $filename, out_dir => $metagenome_id };
    my $tt = Template->new( {'ABSOLUTE' => 1} );

    $tt->process($cfg->param('homology_service.assembly_tt'), $vars, \$cmd)
      or die $tt->error(), "\n";

    print STDERR "cmd: $cmd", "\n";

    !system $cmd or die "could not execute $cmd\n$!";

    print $oh $metagenome_id, "\t", $vars->{out_dir} . '/final.contigs.fa\n';

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

=item	-s, --skip

A file that contains a list of metagenome ids to skip. That is, don't assemble these metagenomes. The file can be tab delimited with the id in the first column making the output of this command a suitable file for the -skip option in a future run.

=back

=head1	AUTHORS

Thomas Brettin

=cut



1;

