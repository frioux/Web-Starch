#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Web::Starch;

my $expires = 60 * 60 * 8;
my $arg_expires = '+' . $expires . 's';

my $starch = Web::Starch->new_with_plugins(
    ['::CookieArgs'],
    store => { class => '::Memory' },
    expires          => $expires,
    cookie_name      => 'foo-session',
    cookie_domain    => 'foo.example.com',
    cookie_path      => '/bar',
    cookie_secure    => 0,
    cookie_http_only => 0,
);

subtest cookie_args => sub{
    my $session = $starch->session();

    my $args = $session->cookie_args();
    is( $args->{name}, 'foo-session', 'cookie name is correct' );
    is( $args->{value}, $session->id(), 'cookie value is session ID' );
    is( $args->{expires}, $arg_expires, 'cookie expires is correct' );
    is( $args->{domain}, 'foo.example.com', 'cookie domain is correct' );
    is( $args->{path}, '/bar', 'cookie path is correct' );
    is( $args->{secure}, 0, 'cookie secure is correct' );
    is( $args->{httponly}, 0, 'cookie httponly is correct' );

    $session->force_save();
    $session->delete();

    $args = $session->cookie_args();
    is( $args->{name}, 'foo-session', 'expired cookie name is correct' );
    is( $args->{value}, $session->id(), 'expired cookie value is session ID' );
    is( $args->{expires}, '-1d', 'expired cookie expires is correct' );
    is( $args->{domain}, 'foo.example.com', 'expired cookie domain is correct' );
    is( $args->{path}, '/bar', 'expired cookie path is correct' );
    is( $args->{secure}, 0, 'expired cookie secure is correct' );
    is( $args->{httponly}, 0, 'expired cookie httponly is correct' );
};

subtest cookie_set_args => sub{
    my $session = $starch->session();

    my $args = $session->cookie_set_args();
    is( $args->{expires}, $arg_expires, 'new session cookie expires is good' );

    $session->force_save();
    $session->delete();
    $args = $session->cookie_set_args();
    is( $args->{expires}, $arg_expires, 'expired session cookie expires is good' );
};

subtest cookie_delete_args => sub{
    my $session = $starch->session();

    my $args = $session->cookie_delete_args();
    is( $args->{expires}, '-1d', 'new session cookie expires is good' );

    $session->force_save();
    $session->delete();
    $args = $session->cookie_delete_args();
    is( $args->{expires}, '-1d', 'expired session cookie expires is good' );
};

done_testing;
