#!/usr/bin/env perl
use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Log::Message::Simple qw[:STD :CARP];
use File::Basename;
use Template;
use Config::Simple;
use Digest::MD5 qw(md5_hex);
use Digest::MD5 qw(md5_base64);
use Math::Fleximal;

### redirect log output
my ($scriptname,$scriptpath,$scriptsuffix) = fileparse($0, ".pl");
open STDERR, ">>$scriptname.log" or die "cannot open log file";
local $Log::Message::Simple::MSG_FH     = \*STDERR;
local $Log::Message::Simple::ERROR_FH   = \*STDERR;
local $Log::Message::Simple::DEBUG_FH   = \*STDERR;

my $help = 0;
my $verbose = 0;
my ($in, $out, %skip, $skip_file);
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
	's=s'	   => \$skip_file,
	'skip=s'   =>\$skip_file,

) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output     => \*STDOUT,
          -verbose    => 2,
          -noperldoc  => 1,
         ) if $help;


### set up i/o handles
my ($ih, $oh);

if ($in) {
    open $ih, "<", $in or die "Cannot open input file $in: $!";
}
else  {
    die "MUST SPECIFY -i <filename>!  NEW WORLD ORDER!!!\n";
    #$ih = \*STDIN;
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

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
        die "can not create Config object";
    print "using $ENV{KB_DEPLOYMENT_CONFIG} for configs\n";
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('homology_service.md5_tt','/homes/brettin/local/dev_container/modules/homology_service/templates/md5.tt');
}


### main logic

if ( $ih ) {
  while (<$ih>) {
    # general
    my($metagenome_id, $filename) = split /\s+/;
    if ( $skip{$metagenome_id} >= 1) { print "skipping $metagenome_id\n"; next; }
    if ( -s $filename == 0 ) { print "skipping $filename with size 0\n"; next; }
    die "$filename not readable" unless (-e $filename and -r $filename);

    # parse input file name into it's parts
    my @suffixlist = qw (.fa .fna .fasta .faa);
    my ($name,$path,$suffix) = fileparse($filename,@suffixlist);	

    open GENES, $filename or die "could not open $filename";
    my $seq_name  =  '';
    my $seq_md5   =  '';
    my $seq       =  '';

    # create output file name for md5 file
    my $md5_file = $path . $name . ".md5.tab";
    open MD5FILE, ">$md5_file" or die "could not open $md5_file";

    while ( <GENES> ) {
      next unless /\S/;
      chomp;
      if ( /^>/ ) {

        # print previous record
    	if($seq_name && $seq) {
          $seq_name   =~ s/^\s*\>\s+|\s+$//;
          $seq =~ s/\*$//;
          # $seq_md5  = hex2alpha(md5_hex($seq));
          $seq_md5  = md5_hex($seq);
          print MD5FILE ("$seq_md5\t$in\t$seq_name\t$seq\n");
        }
      
        # grab new seqname and reset sequence
	$seq_name = $_;
	$seq = '';
      }
      else {
	$seq .= uc $_;
      }
    } # end while GENES

    # print the last record
    if($seq_name && $seq) {
      $seq_name   =~ s/\s+$//;
      $seq =~ s/\*$//;
      $seq_md5  = hex2alpha(md5_hex($seq));
      print MD5FILE ("$seq_md5\t$seq_name\t$seq\n");
    }

    close GENES;
    close MD5FILE;

    # print filter output record 
    print $oh $metagenome_id, "\t", $md5_file, "\n";
  }

} else {
	die "no input found, input is required";
}    

# Converts a hex representation of a number into
# one that uses more alphanumerics.  (ie base 62)
sub hex2alpha {
  Math::Fleximal->new(
      lc(shift), [0..9, 'a'..'f']
    )->change_flex(
      [0..9,'a'..'z','A'..'Z']
    )->to_str();
}


 

=pod

=head1	NAME

use_md5

=head1	SYNOPSIS

use_md5 <options>

=head1	DESCRIPTION

The use_md5 command ...

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

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

