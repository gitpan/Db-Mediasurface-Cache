package Db::Mediasurface::Cache;
$VERSION = 0.03;
use strict;
use Carp;
use constant NEXT  => 0;
use constant KEY   => 1;
use constant VALUE => 2;

sub new
{
    my ($class, %arg) = @_;
    my $list;
    if (defined $arg{size}){
	$list = [ undef, undef, undef ];
	$list->[KEY] = $list; # special case -- points to end of list
    }
    bless {
	_max_size  => $arg{size} || undef,
	_curr_size => 0,
	_list     => $list
	}, $class;
}

sub get
{
    my ($self,$key) = @_;
    return unless defined $key;
    my $value = undef;
    if (defined $self->{_max_size}){
	for (my $prev = $self->{_list}; my $elem = $prev->[NEXT]; $prev = $elem){
	    if ($elem->[KEY] eq $key){
		$value = $elem->[VALUE];
		if (defined $elem->[NEXT]){
		    $prev->[NEXT] = $elem->[NEXT];
		    $self->{_list}->[KEY] = $self->{_list}->[KEY]->[NEXT] = [ undef, $key, $value ];
		}
		last;
	    }
	}
    } else {
	if (exists $self->{_list}->{$key}){
	    $value = $self->{_list}->{$key};
	}
    }
    return $value;
}

sub set
{
    my ($self,%hash) = @_;
    if (defined $self->{_max_size}){
	foreach my $key (keys %hash){
	    $self->unset($key);
	    $self->{_list}->[KEY] = $self->{_list}->[KEY]->[NEXT] = [ undef, $key, $hash{$key} ];
	    $self->{_curr_size} ++;
	}
	while ( $self->{_curr_size} > $self->{_max_size} ){
	    $self->{_list}->[NEXT] = $self->{_list}->[NEXT]->[NEXT];
	    $self->{_curr_size} --;
	}
    } else {
	foreach my $key (keys %hash){
	    $self->{_list}->{$key} = $hash{$key};
	}
    }
}

sub unset
{
    my ($self,$key) = @_;
    return unless defined $key;
    if (defined $self->{_max_size}){
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
    } else {
	if (exists $self->{_list}->{$key}){
	    delete $self->{_list}->{$key};
	}
    }
}

1;

=head1 NAME

Db::Mediasurface::Cache - caches a specified number of key-value pairs, disgarding underused pairs.

=head1 VERSION

This document refers to version 0.03 of DB::Mediasurface::Cache, released July 24, 2001.

=head1 SYNOPSIS

use Db::Mediasurface::Cache;

my $url = 'http://some.site.com/some/path?version=2';

my $id = undef;

my $cache = Db::Mediasurface::Cache->new( size => 1000 );

unless (defined ($id = $cache->get($url)))
{
    $id = urldecode2id($url);
    $cache->set($url,$id);
}

=head1 DESCRIPTION

=head2 Overview

Mediasurface relies on retrieving a unique ID for almost every object lookup. This module aims to cache url->id lookups in memory. The module works with a linked list, which is significantly slower at lookups than a standard Perl hash. However, the linked list allows commonly used key-value pairs to be stored towards the 'fresh' end of the list, and seldomly used pairs to drift towards the 'stale' end, from where they will eventually be pushed into oblivion, should the cache reach its maximum size. Basically, it's a trade-off between size and speed - the module will perform best when you need to perform lots of lookups of a wide range of urls, but the majority of lookups are contained within a much smaller subset of urls. Be warned - this module will cause a *reduction* in performance if used for single lookups, or if lookups are non-repetitive.

=head2 Constructor

=over 4

=item $cache = Db::Mediasurface::Cache->new(size=>1000);

This class method constructs a new cache. the size parameter can be used to set the maximum number of key-value pairs to be cached. If size is omitted, the cache defaults to using a straight hash, which is a *lot* faster than the linked list method, but which has no protection from eating all your available RAM [NOTE: this is a change in behaviour from version 0.02].

=back

=head2 Methods

=over 4

=item $cache->set($key_1,$value_1...$key_n,$value_n)

=item $cache->set(%key_value_hash)

Sets key-value pairs.

=item $id = $cache->get($key1);

Gets the value of a given key. Returns the value, or undef if the key doesn't exist.

=item $cache->unset($key1);

Delete the key-value pair specified by the given key.

=back

=head1 AUTHOR

Nigel Wetters (nwetters@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2001, Nigel Wetters. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

