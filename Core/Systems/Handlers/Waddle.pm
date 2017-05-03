package Waddle;

use strict;
use warnings;

use Method::Signatures;

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			jx => 'handleSendWaddle'
		};
		return $obj;
}

method handleWaddles(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleSendWaddle($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intRoom = $arrData[5];
		my $intX = $arrData[6];
		my $intY = $arrData[7];
		if ($objClient->{gaming}->{waddleRoom} != 0) {
			$objClient->joinRoom($intRoom, $intX, $intY);
		}
}

1;
