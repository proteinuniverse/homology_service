use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Log::Message::Simple qw[:STD :CARP];

use Template;
use Config::Simple;
use File::Basename;

### redirect log output
local $Log::Message::Simple::MSG_FH     = \*STDERR;
local $Log::Message::Simple::ERROR_FH   = \*STDERR;
local $Log::Message::Simple::DEBUG_FH   = \*STDERR;

my $help = 0;
my $verbose = 0;
my ($in, $out, $skip);
my %skip_ids;
our $cfg;

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
	'v'        => \$verbose,
	'verbose'  => \$verbose,
	'skip=s'   => \$skip,
	's=s'	   => \$skip,

) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 2,
          -noperldoc => 1,
         ) if $help;


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

### main logic

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
        die "can not create Config object";
    print "using $ENV{KB_DEPLOYMENT_CONFIG} for configs\n";
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('homology_service.call_genes_tt','/homes/brettin/local/dev_container/modules/homology_service/templates/prodigal-np.tt');
}


if ($ih) {
  while(<$ih>) {
    my $cmd;
    my($metagenome_id, $filename) = split /\s+/;
    if ( $skip_ids{$metagenome_id} >= 1) { print "skipping $metagenome_id\n"; next; }
    if ( -s $filename == 0 ) { print "skipping $filename with size 0\n"; next; }
    die "$filename not readable" unless (-e $filename and -r $filename);
    my @suffixlist = qw (.fa .fna .fasta);
    my ($name,$path,$suffix) = fileparse($filename,@suffixlist);

    my $tt = Template->new( {'ABSOLUTE' => 1} );

    # specific
    my $genes_filename = $path . $name . ".gene_calls.faa";
    my $vars = { infile => $filename, outfile => $genes_filename };
    $tt->process($cfg->param('homology_service.call_genes_tt'), $vars, \$cmd)
      or die $tt->error(), "\n";

    print STDERR "cmd: $cmd", "\n";
    !system $cmd or die "could not execute $cmd\n$!";

    # specific
    print $oh $metagenome_id, "\t", $genes_filename, "\n";
    print STDERR "cmd: finished\n";
  }
} else {
  die "no input found, input is required";
}



=pod

=head1	NAME

call_genes

=head1	SYNOPSIS

call_genes <options>

=head1	DESCRIPTION

The call_genes command ...

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   -i, --input

The input file, default is STDIN. Expects a tab delimited set of metagenome_id [tab] filtered_contigs_filename records.

=item   -o, --output

The output file, default is STDOUT. This is a tab delimited set of metagenome_id [tab] gene_call_filename records.

=item	-v, --verbose

Sets logging to verbose. By default, logging goes to STDERR.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

