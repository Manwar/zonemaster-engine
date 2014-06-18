use Test::More;
use Zonemaster::Nameserver;

BEGIN { use_ok('Zonemaster::ASNLookup')};

my $datafile = 't/asn.data';
if ( not $ENV{ZONEMASTER_RECORD} ) {
    die "Stored data file missing" if not -r $datafile;
    Zonemaster::Nameserver->restore( $datafile );
    Zonemaster->config->get->{no_network} = 1;
}

my ($asn1, $prefix1) = Zonemaster::ASNLookup->get('8.8.8.8');
is $asn1, 15169, '8.8.8.8 is in 15169';
is $prefix1->prefix, '8.8.8.0/24', '8.8.8.8 is in 8.8.8.0/24';

my ($asn2, $prefix2) = Zonemaster::ASNLookup->get( '91.226.36.46' );
is $asn2, 1257, '91.226.36.46 is in 1257';
is $prefix2->prefix, '91.226.36.0/24', '91.226.36.46 is in 91.226.36.0/24';

my $asn3 = Zonemaster::ASNLookup->get( '2001:503:ba3e::2:30' );
is $asn3, 36619, '2001:503:ba3e::2:30 is in 36619';

my ($asn4, $prefix4) = Zonemaster::ASNLookup->get( '192.168.0.1' );
ok(!$asn4, 'RFC1918 address is in no AS');

if ( $ENV{ZONEMASTER_RECORD} ) {
    Zonemaster::Nameserver->save( $datafile );
}

done_testing;