use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Log::Message::Simple qw[:STD :CARP];
use File::Basename;

my $help = 0;
my $verbose = 1;
my ($in, $out, $num, $offset);

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
	'n=i'    => \$num,
	'number' => \$num,
	's=i'    => \$offset,
	'start=i'  => \$offset,
        'v'        => \$verbose,
        'verbose'  => \$verbose,
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


# do a little validation on the parameters
$num = 1 unless $num;

my ($ih, $oh, %skip);

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
if ( $ih ) {while(<$ih>) {chomp; $skip{$_}++;}}

for (my $x=0+$offset; $x< $num+$offset; $x++) {
  my $json_text = download_metadata_from_mgrast(1, $x);
  # log_metadata($json_text);

  my $json = JSON->new->allow_nonref;
  my $perl_scalar = $json->decode( $json_text );

  $json_text = download_reads_from_mgrast($perl_scalar->{'data'}->[0]->{'id'});
  # log_download($json_text);

  if (exists $skip{ $perl_scalar->{'data'}->[0]->{'id'} }) {
    msg( "skipping ", $perl_scalar->{'data'}->[0]->{'id'} , $verbose);
    $x--;
    next;
  }

  $perl_scalar = $json->decode( $json_text );
  download($perl_scalar->{'data'}->[0]->{'url'}, $perl_scalar->{'data'}->[0]->{'file_name'});  
  die unless verify_download($perl_scalar->{'data'}->[0]->{'file_name'}, $perl_scalar->{'data'}->[0]->{'file_md5'});

  print $oh $perl_scalar->{'data'}->[0]->{'id'}, "\t", $perl_scalar->{'data'}->[0]->{'file_name'}, "\n"; 

  msg( "done downloading " . $perl_scalar->{'data'}->[0]->{'file_name'}, $verbose);
}

# download functions
# this sub downloads a file
sub download {
  my $url = shift or die "must provide a url";
  my $outfile = shift or die "must provide outfile name";
  my $cmd  = 'curl -s -o ' . $outfile . ' \'';
  $cmd    .= $url;
  $cmd    .= '\'';
  msg("executing cmd: $cmd", $verbose);
  my $ret = `$cmd`;
  if ($?) {die "$?\ncould not execute command $cmd";}
  msg("done executing cmd: $cmd", $verbose);
  return $ret

}

sub verify_download {
  my $filename = shift or die "must provide filename";
  my $expected_md5 = shift or die "must prvide expected md5";

  my ($observed_md5, $filename)  =  split /\s+/, `md5sum $filename`; 
  msg ( "expected $filename: $expected_md5", $verbose);
  msg ( "observed $filename: $observed_md5", $verbose);
  return 1 if $observed_md5 eq $expected_md5;
  return 0 if $observed_md5 ne $expected_md5;
}
  
# api query functions
# this sub gets the metadata data structure
sub download_metadata_from_mgrast {
  my ($limit, $offset) = @_ or die "must provide limit and offset";
  my $cmd = 'curl -s \'http://api.metagenomics.anl.gov/1/metagenome?limit=';
  $cmd   .= $limit;
  $cmd   .= '&order=name&verbosity=metadata&sequence_type=WGS&offset=';
  $cmd   .= $offset;
  $cmd   .= '\'';
  msg("executing cmd: $cmd", $verbose);
  my $ret = `$cmd`;
  msg("done executing cmd: $cmd", $verbose);
  if ($?) {die "$?\ncould not execute command $cmd";}

  return $ret
}

# this sub gets the download data structure
sub download_reads_from_mgrast {
  my $metagenome_id = shift or die "must provide a metagenome_id";
  my $cmd  = 'curl -s \'http://api.metagenomics.anl.gov/1/';
  $cmd    .= 'download/';
  $cmd    .= $metagenome_id;
  $cmd    .= '\'';
  msg("executing cmd: $cmd", $verbose);
  my $json_text = `$cmd`;
  if ($?) {die "$?\ncould not execute command $cmd";}
  msg("done executing cmd: $cmd", $verbose);
  return $json_text;
}


# auxilliary print functions
# this sub prints information in the metadata data structure
sub log_metadata {
  my $json_text = shift or die "must provide json_text";

  my $json = JSON->new->allow_nonref;
  my $perl_scalar = $json->decode( $json_text );
  msg("metagenome" . "\t" .
      $perl_scalar->{'data'}->[0]->{'id'} . "\t" .
      scalar(@{$perl_scalar->{'data'}}) . "\t" .
      $perl_scalar->{'data'}->[0]->{'project'}->[0] . "\t" .
      $perl_scalar->{'data'}->[0]->{'sequence_type'} . "\t" .
      $perl_scalar->{'data'}->[0]->{'metadata'}->{'library'}->{'data'}->{'investigation_type'} . "\t" .
      $perl_scalar->{'data'}->[0]->{'metadata'}->{'library'}->{'data'}->{'seq_meth'} . "\t" .
      $perl_scalar->{'data'}->[0]->{'pipeline_parameters'}->{'assembled'} . "\t" .
      $perl_scalar->{'data'}->[0]->{'metadata'}->{'project'}->{'name'}, $verbose);
}
# this sub prints information in the download data structure
sub log_download {
  my $json_text = shift or die "must provide json_text";
  my $json = JSON->new->allow_nonref;
  my $perl_scalar = $json->decode( $json_text );
  msg("download" . "\t" .
      $perl_scalar->{'data'}->[0]->{'id'} . "\t" .
      scalar(@{$perl_scalar->{'data'}}) . "\t" .
      $perl_scalar->{'data'}->[0]->{'data_type'} . "\t" .
      $perl_scalar->{'data'}->[0]->{'file_format'} . "\t" .
      $perl_scalar->{'data'}->[0]->{'url'}, $verbose);

}






 

=pod

=head1	NAME

fetch_metagenome

=head1	SYNOPSIS

fetch_metagenome <options>

=head1	DESCRIPTION

The fetch_metagenome command ...

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item	-n, --number

The number of metagenomes to download. MGRAST API limits this to no more than 1000.

=item   -i, --input

The input file, default is STDIN. This is optional. If it is provided, it will contain a list of metagenome ids that will be skipped. That is to say, these metagenomes will not be downloaded.

=item   -o, --output

The output file, default is STDOUT. The output contains the metagenome id and the name of the file downloaded in tab delimited format.

=item	-s, --start

The start position in MGRAST to start downloading from. Also known as the offset fromt the first metagenome record in MGRAST.

=item	-v, --verbose

Sets logging to verbose. By default, logging goes to a file named fetch_metagenomes.log.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

