#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Session::State::Cookie;
use Plack::Session::Store::MongoDB;

use t::lib::TestSessionHash;

my $conn;
eval { $conn = MongoDB::Connection->new(host => 'localhost', port => 27017); };

SKIP: {
	skip "MongoDB needs to be running for this test.", 1 if $@;

	t::lib::TestSessionHash::run_all_tests(
		store  => Plack::Session::Store::MongoDB->new(db_name => 'plack_test_sessions'),
		state  => Plack::Session::State->new,
		env_cb => sub {
			open my $in, '<', \do { my $d };
			my $env = {
				'psgi.version'    => [ 1, 0 ],
				'psgi.input'      => $in,
				'psgi.errors'     => *STDERR,
				'psgi.url_scheme' => 'http',
				SERVER_PORT       => 80,
				REQUEST_METHOD    => 'GET',
				QUERY_STRING      => join "&" => map { $_ . "=" . $_[0]->{ $_ } } keys %{$_[0] || +{}},
			};
		},
	);

	# drop the database
	$conn->get_database('plack_test_sessions')->drop;
}

done_testing;