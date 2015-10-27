use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Log::Message::Simple qw[:STD :CARP];
use File::Basename;
use Parsers;

### redirect log output
my ($scriptname,$scriptpath,$scriptsuffix) = fileparse($0, ".pl");
open STDERR, ">>$scriptname.log" or die "cannot open log file";
local $Log::Message::Simple::MSG_FH     = \*STDERR;
local $Log::Message::Simple::ERROR_FH   = \*STDERR;
local $Log::Message::Simple::DEBUG_FH   = \*STDERR;

my $help = 0;
my $verbose = 1;
my ($in, $out, %skip, $skip_file);

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
	'v'        => \$verbose,
	'verbose'  => \$verbose,
	's=s'	=> \$skip_file,
	'skip=s'   => \$skip_file,

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

if ($skip_file) { 
  open SKIP, $skip_file or die "could not open skip file $skip_file.";
  while (<SKIP>) {
    my ($id) = split /\s+/;
    $skip{$id}++;
  }
  close SKIP;
}


### main logic

if ($ih) { 
  while(<$ih>) {
    my($metagenome_id, $filename) = split /\s+/;
    if ( $skip{$metagenome_id} >= 1) { print "skipping $metagenome_id\n"; next; }
    die "$filename not readable" unless (-e $filename and -r $filename);

    my @suffixlist = qw (.tab);
    my ($name,$path,$suffix) = fileparse($filename,@suffixlist);
    my $outfile = $path . $name . ".locations.tab";
    open FLEXMD5, $filename or die "can not open $filename";
    open LOC, ">$outfile" or die "can not open $outfile";
    while( <FLEXMD5> ) {
      chomp;
      my ($md5, $defline, $aaseq) = split /\t/;
      my $h = Parsers::parse_glimmer_protein($defline);

      my $idx = ( $h->{left} + $h->{right} )/ 2;
      my $len = $h->{right} - $h->{left} + 1;
      print LOC ( $metagenome_id, "\t", $h->{cid}, "\t", $md5, "\t", 
                  $h->{left}, "\t", $h->{right}, "\t", $h->{strand}, "\t",
		  "$idx:$len", "\n");

    }
    close FLEXMD5;
    close LOC;

    msg ("done processing $filename", $verbose);
    print $oh "$metagenome_id\t$outfile\n";
  }
}
else {
  die "no input found, input is required";
}



 

=pod

=head1	NAME

find_location

=head1	SYNOPSIS

find_location <options>

=head1	DESCRIPTION

The find_location command ...

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   -i, --input

The input file, default is STDIN

=item   -o, --output

The output file, default is STDOUT

=item	-v, --verbose

Sets logging to verbose. By default, logging goes to STDERR.

=item	-s, --skip

An optional file with a list of metagenome ids to skip if found in the input.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

