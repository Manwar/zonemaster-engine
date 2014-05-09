use Test::More;
use File::Temp qw[:POSIX];

BEGIN {
    use_ok( 'Zonemaster' );
    use_ok( 'Zonemaster::Test' );
    use_ok( 'Zonemaster::Nameserver' );
}

my $datafile = q{t/zonemaster.data};
if ( not $ENV{ZONEMASTER_RECORD} ) {
    die q{Stored data file missing} if not -r $datafile;
    Zonemaster::Nameserver->restore( $datafile );
    Zonemaster->config->{no_network} = 1;
}

isa_ok( Zonemaster->logger, 'Zonemaster::Logger' );
isa_ok( Zonemaster->config, 'Zonemaster::Config' );

my %module = map { $_ => 1 } Zonemaster::Test->modules;

ok($module{Consistency}, 'Consistency');
ok($module{Delegation}, 'Delegation');
ok($module{Syntax}, 'Syntax');
ok($module{Connectivity}, 'Connectivity');

my %methods = Zonemaster->all_methods;
ok(exists($methods{Basic}), 'all_methods');

my @tags = Zonemaster->all_tags;
ok((grep {/BASIC:HAS_NAMESERVERS/} @tags), 'all_tags');

my %module;
Zonemaster->logger->callback(sub {
    my ($e) = shift;

    if ($e->tag eq 'MODULE_VERSION') {
        $module{$e->args->{module}} = $e->args->{version};
    }
});
my @results = Zonemaster->test_zone('nic.se');

ok($module{'Zonemaster::Test::Address'}, 'Zonemaster::Test::Address did run.' );
ok($module{'Zonemaster::Test::Basic'}, 'Zonemaster::Test::Basic did run.' );
ok($module{'Zonemaster::Test::Connectivity'}, 'Zonemaster::Test::Connectivity did run.' );
ok($module{'Zonemaster::Test::Consistency'}, 'Zonemaster::Test::Consistency did run.' );
ok($module{'Zonemaster::Test::DNSSEC'}, 'Zonemaster::Test::DNSSEC did run.' );
ok($module{'Zonemaster::Test::Delegation'}, 'Zonemaster::Test::Delegation did run.' );
ok($module{'Zonemaster::Test::Nameserver'}, 'Zonemaster::Test::Nameserver did run.' );
ok($module{'Zonemaster::Test::Syntax'}, 'Zonemaster::Test::Syntax did run.' );
ok($module{'Zonemaster::Test::Zone'}, 'Zonemaster::Test::Zone did run.');

my $filename = tmpnam();
Zonemaster->save_cache($filename);
my $save_entry = Zonemaster->logger->entries->[-1];
Zonemaster->preload_cache($filename);
my $restore_entry = Zonemaster->logger->entries->[-1];
is($save_entry->tag, 'SAVED_NS_CACHE', 'Saving worked.');
is($save_entry->args->{file}, $filename, 'To the right file name.');
is($restore_entry->tag, 'RESTORED_NS_CACHE', 'Restoring worked.');
is($restore_entry->args->{file}, $filename, 'From the right file name.');
unlink($filename);

if ( $ENV{ZONEMASTER_RECORD} ) {
    Zonemaster::Nameserver->save( $datafile );
}

done_testing;
