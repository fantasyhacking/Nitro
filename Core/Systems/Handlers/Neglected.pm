package Neglected;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			gn => 'handleGetNeglected',
			an => 'handleAddNeglected',
			rn => ' handleRemoveNeglected'
		};
		return $obj;
}

method handleNeglected(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleGetNeglected($strData, $objClient) {
		my $strIgnored = join('%', map { $_ . '|' . $objClient->{penguin}->{ignored}->{$_}; } keys %{$objClient->{penguin}->{ignored}});
		$objClient->sendData('%xt%gn%-1%' . ($strIgnored ? $strIgnored : '%'));
}

method handleAddNeglected($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPID = $arrData[5];
		return if (!looks_like_number($intPID));
		return if (exists($objClient->{penguin}->{ignored}->{$intPID}));
		$objClient->{penguin}->{ignored}->{$intPID} = $objClient->{penguin}->{username};
		my $strIgnored = join(',', map { $_ . '|' . $objClient->{penguin}->{ignored}->{$_}; } keys %{$objClient->{penguin}->{ignored}});
		$self->{child}->{mysql}->updateIgnored($strIgnored, $objClient->{penguin}->{ID});
		$objClient->sendXT(['an', $objClient->{penguin}->{room}->{id}, $intPID]);
}

method handleRemoveNeglected($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPID = $arrData[5];
		return if (!looks_like_number($intPID));
		return if (!exists($objClient->{penguin}->{ignored}->{$intPID}));
		delete($objClient->{penguin}->{ignored}->{$intPID});
		my $strIgnored = join(',', map { $_ . '|' . $objClient->{penguin}->{ignored}->{$_}; } keys %{$objClient->{penguin}->{ignored}});
		$self->{child}->{mysql}->updateIgnored($strIgnored, $objClient->{penguin}->{ID});
		$objClient->sendXT(['rn', $objClient->{penguin}->{room}->{id}, $intPID]);
}

1;