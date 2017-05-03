package Cryptography;

use strict;
use warnings;

use Method::Signatures;
use Bytes::Random::Secure qw(random_string_from);
use Math::Round qw(round);

method new {
		my $obj = bless {}, $self;
		return $obj;
}

method generateKey($intLength) {
		my $strKey = random_string_from(join( '', ('a' .. 'z'), ('A' .. 'Z'), ('0' .. '9'), ('_')), $intLength);
		return $strKey;
}

method generateRandomNumber($intMin, $intMax) {
		my $intRand = rand($intMax - $intMin);
		my $intFinal = int($intMin + $intRand);
		return $intFinal;
}

method getTimeDifference($intPastTime, $intCurrentTime, $intFormat) {
		my $intDifference = round(($intPastTime - $intCurrentTime) / $intFormat);
		return $intDifference; 
}

1;
