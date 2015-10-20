use strict;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Log::Message::Simple qw[:STD :CARP];

### redirect log output
local $Log::Message::Simple::MSG_FH     = \*STDERR;
local $Log::Message::Simple::ERROR_FH   = \*STDERR;
local $Log::Message::Simple::DEBUG_FH   = \*STDERR;

my $help = 0;
my $verbose = 1;
my ($in, $out, $num);

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'input=s'  => \$in,
	'output=s' => \$out,
	'n=i'    => \$num,
	'number' => \$num,

) or pod2usage(0);


pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 2,
          -noperldoc => 1,
         ) if $help;


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
use strict;
use JSON;

if ( $ih ) {while(<$ih>) {chomp; $skip{$_}++;}}

for (my $x=0; $x< $num; $x++) {
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
}

# download functions
# this sub downloads a file
sub download {
  my $url = shift or die "must provide a url";
  my $outfile = shift or die "must provide outfile name";
  my $cmd  = 'curl -s -o ' . $outfile . ' \'';
  $cmd    .= $url;
  $cmd    .= '\'';
  my $ret = `$cmd`;
  if ($?) {die "$?\ncould not execute command $cmd";}
  return $ret

}

sub verify_download {
  my $filename = shift or die "must provide filename";
  my $expected_md5 = shift or die "must prvide expected md5";

  my ($observed_md5, $filename)  =  split /\s+/, `md5sum $filename`; 
  msg ( "expected: $expected_md5", $verbose);
  msg ( "observed: $observed_md5", $verbose);
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
  my $ret = `$cmd`;
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
  my $json_text = `$cmd`;
  if ($?) {die "$?\ncould not execute command $cmd";}
  return $json_text;
}


# auxilliary print functions
# this sub prints information in the metadata data structure
sub log_metadata {
  my $json_text = shift or die "must provide json_text";

  my $json = JSON->new->allow_nonref;
  my $perl_scalar = $json->decode( $json_text );
  print "metagenome", "\t";
  print $perl_scalar->{'data'}->[0]->{'id'}, "\t";
  print scalar(@{$perl_scalar->{'data'}}), "\t";
  print $perl_scalar->{'data'}->[0]->{'project'}->[0], "\t";
  print $perl_scalar->{'data'}->[0]->{'sequence_type'}, "\t";
  print $perl_scalar->{'data'}->[0]->{'metadata'}->{'library'}->{'data'}->{'investigation_type'}, "\t";
  print $perl_scalar->{'data'}->[0]->{'metadata'}->{'library'}->{'data'}->{'seq_meth'}, "\t";
  print $perl_scalar->{'data'}->[0]->{'pipeline_parameters'}->{'assembled'}, "\t";
  print $perl_scalar->{'data'}->[0]->{'metadata'}->{'project'}->{'name'}, "\n";
}
# this sub prints information in the download data structure
sub log_download {
  my $json_text = shift or die "must provide json_text";
  my $json = JSON->new->allow_nonref;
  my $perl_scalar = $json->decode( $json_text );
  print "download", "\t";

  print $perl_scalar->{'data'}->[0]->{'id'}, "\t";
  print scalar(@{$perl_scalar->{'data'}}), "\t";
  print $perl_scalar->{'data'}->[0]->{'data_type'}, "\t";
  print $perl_scalar->{'data'}->[0]->{'file_format'}, "\t";
  print $perl_scalar->{'data'}->[0]->{'url'}, "\n";

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

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;

