use strict;
use warnings;

use Test::More tests => 19;

my $dbname = '/tmp/dbix-placeholder-named-test.db';

use_ok('DBI');
use_ok('DBIx::Placeholder::Named');

END {
    unlink $dbname if -f $dbname;
}

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$dbname",
    '', '',
    {
        PrintError         => undef,
        RaiseError         => undef,
        ShowErrorStatement => undef,
        RootClass          => 'DBIx::Placeholder::Named',
    }
);
ok($dbh);

{
    my $query = q{THIS IS NOT A SQL QUERY};
    my $sth   = $dbh->prepare($query);
    is( $sth, undef, $query );
}

{
    my $query = q{CREATE TABLE test (id int, name varchar)};
    my $sth   = $dbh->prepare($query);
    ok( $sth, $query );
    my $rv = $sth->execute();
    ok( $rv, $query . ': execute()' );
}

{
    my $query = q{SELECT * FROM test WHERE id = :id};
    my $sth   = $dbh->prepare($query);
    ok( $sth, $query );
    my $rv = $sth->execute( {} );
    is( $rv, '0E0' );
}

{
    my $query = q{INSERT INTO test VALUES (:id, :name)};
    my $sth   = $dbh->prepare($query);
    ok( $sth, $query );
    my $rv = $sth->execute( { id => 1, name => 'Igor', } );
    ok( $rv, $query . ': execute()' );
}

{
    my $query =
      q{UPDATE test SET id = :new_id, name = :new_name WHERE id = :id};
    my $sth = $dbh->prepare($query);
    ok( $sth, $query );
    my $rv = $sth->execute( { id => 1, new_id => 2, new_name => 'Fulano', } );
    ok( $rv, $query . ': execute()' );
}

{
    my $query = q{SELECT id, name FROM test WHERE id = :id};
    my $sth   = $dbh->prepare($query);
    ok( $sth, $query );
    my $rv = $sth->execute( { id => 2, } );
    ok( $rv, $query . ': execute()' );

    my $hash_ref = $sth->fetchrow_hashref;

    is_deeply( $hash_ref, { id => 2, name => 'Fulano' } );
}

{
    my $query =
      q{INSERT INTO test (id, name) VALUES (:id, '0000-00-00 11:11:11')};
    my $sth = $dbh->prepare($query);
    ok( $sth, $query );
    my $rv = $sth->execute( { id => 2, } );
    ok( $rv, $query . ': execute()' );
}

{
    my $query =
      q{INSERT INTO test (id, name) VALUES (?, '0000-00-00 11:11:11')};
    my $sth = $dbh->prepare($query);
    ok( $sth, $query );
    my $rv = $sth->execute(5);
    ok( $rv, $query . ': execute()' );
}

$dbh->disconnect;

