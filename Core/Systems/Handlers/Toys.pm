package Toys;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			at => 'handleAddToy',
			rt => 'handleRemoveToy'
		};
		return $obj;
}

method handleNewsPaper(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleAddToy($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPID = $arrData[5];
		return if (!looks_like_number($intPID));
		$objClient->sendXT(['at', '-1', $intPID, 1]);
}

method handleRemoveToy($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPID = $arrData[5];
		return if (!looks_like_number($intPID));
		$objClient->sendXT(['rt', '-1', $intPID]);
}

1;
