package Digging;

use strict;
use warnings;

use Method::Signatures;

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {cdu => 'handleCoinsDigUpdate'};
		return $obj;
}

method handleCoinDigging(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleCoinsDigUpdate($strData, $objClient) {
		# I guess this should fix the spamming
		if ($objClient->{penguin}->{digging}->{tries} <= 5 && time > $objClient->{penguin}->{digging}->{lastTime}) {
			my $intCoins = $self->{child}->{crypt}->generateRandomNumber(1, 100);
			$self->{child}->{mysql}->addToWalletWithoutPack($intCoins, $objClient);
			$objClient->sendXT(['cdu', '-1', $intCoins, $objClient->{penguin}->{wallet}]);
			$objClient->{penguin}->{digging}->{lastTime} = (time + 1);
			$objClient->{penguin}->{digging}->{tries} += 1;
		} else {
			$self->{child}->{logger}->warning($objClient->{penguin}->{username} . ' is trying to mine too fast');
		}
		if (time > ($objClient->{penguin}->{digging}->{lastTime} + 10)) {
			$objClient->{penguin}->{digging}->{tries} = 0;
		}
}


1;
