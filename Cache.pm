package Db::Mediasurface::Cache;
$VERSION = 0.01;
use strict;
use Carp;
use constant NEXT  => 0;
use constant KEY   => 1;
use constant VALUE => 2;

sub new
{
    my ($class, %arg) = @_;
    
    my $list = [ undef, undef, undef ];
    $list->[KEY] = $list; # special case -- points to end of list

    bless {
	_max_size  => $arg{size} || 1000,
	_curr_size => 0,
	_list     => $list
	}, $class;
}

sub get
{
    my ($self,$key) = @_;
    return unless defined $key;
    my $value = undef;
    for (my $prev = $self->{_list}; my $elem = $prev->[NEXT]; $prev = $elem){
	if ($elem->[KEY] eq $key){
	    $value = $elem->[VALUE];
	    if (defined $elem->[NEXT]){
		$prev->[NEXT] = $elem->[NEXT] || undef;
		$self->{_curr_size} --;
		$self->set($key,$value);
	    }
	    last;
	}
    }
    return $value;
}

sub set
{
    my ($self,%hash) = @_;
    foreach my $key (keys %hash){
	$self->unset($key);
	$self->{_list}->[KEY] = $self->{_list}->[KEY]->[NEXT] = [ undef, $key, $hash{$key} ];
	$self->{_curr_size} ++;
    }
    while ( $self->{_curr_size} > $self->{_max_size} ){
	$self->{_list}->[NEXT] = $self->{_list}->[NEXT]->[NEXT];
	$self->{_curr_size} --;
    }
}

sub unset
{
    my ($self,$key) = @_;
    return unless defined $key;
    for (my $prev = $self->{_list}; my $elem = $prev->[NEXT]; $prev = $elem){
	if ($elem->[KEY] eq $key){
	    $self->{_curr_size} --;
	    if (defined $elem->[NEXT]){
		$prev->[NEXT] = $elem->[NEXT];
	    } else {
		$prev->[NEXT] = undef;
		$self->{_list}->[KEY] = $prev;
	    }
	    last;
	}
    }
}

1;

=head1 NAME

Db::Mediasurface::Cache - caches a specified number of key-value pairs, disgarding underused pairs.

=head1 VERSION

This document refers to version 0.01 of DB::Mediasurface::Cache, released July 23, 2001.

=head1 SYNOPSIS

use Db::Mediasurface::Cache;
my $cache = Db::Mediasurface::Cache->new(size=>1000);

# in your event loop...
my $url = 'http://some.site.com/some/path?view=edititem&version=2';
my $id = undef;
unless (defined ($id = $cache->get($url))){
    $id = urldecode2id($url);
    $cache->set($url,$id);
}

=head1 DESCRIPTION

=head2 Overview

Mediasurface relies on retrieving a unique ID for almost every object lookup. This module aims to cache url->id lookups in memory. The module works with a linked list, which is significantly slower at lookups than a standard Perl hash. However, the linked list allows commonly used key-value pairs to be stored towards the 'fresh' end of the list, and seldomly used pairs to drift towards the 'stale' end, from where they will eventually be pushed into oblivion, should the cache reach its maximum size. Basically, it's a trade-off between size and speed - the module will perform best when you need to perform lots of lookups of a wide range of urls, but the majority of lookups are contained within a much smaller subset of urls. Be warned - this module will cause a *reduction* in performance if used for single lookups, or if lookups are non-repetitive.

=head2 Constructor

=over4

=item $cache = Db::Mediasurface::Cache->new(size=>1000);

This class method constructs a new cache. the size parameter can be used to set the maximum number of key-value pairs to be cached (defaults to 1000).

=back

=head2 Methods

=over4

=item $cache->set($key1,$value1,$key2,$value2...)

Sets key-value pairs.

=item $id = $cache->get($key1);

Gets the value of a given key. Returns the value, or undef if the key doesn't exist.

=item $cache->unset($key1);

Delete the key-value pair specified by the given key.

=back

=head1 AUTHOR

Nigel Wetters (nigel@wetters.net)

=head1 COPYRIGHT

Copyright (c) 2001, Nigel Wetters. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

