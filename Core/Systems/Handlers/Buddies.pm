package Buddies;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			gb => 'handleGetBuddies',
			br => 'handleBuddyRequest',
			ba => 'handleBuddyAccept',
			rb => 'handleRemoveBuddy',
			bf => 'handleBuddyFind'
		};
		return $obj;
}

method handleBuddies(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleGetBuddies($strData, $objClient) {
		my $strBuddies = join('%', map { $_ . '|' . $objClient->{penguin}->{buddies}->{$_} . '|' . $objClient->getOnline($_); } keys %{$objClient->{penguin}->{buddies}});
		$objClient->sendData('%xt%gb%-1%' . ($strBuddies ? $strBuddies : '%') . '%');
}

method handleBuddyRequest($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intBudID = $arrData[5];
		return if (!looks_like_number($intBudID));
		my $objPlayer = $objClient->getClientByID($intBudID);
		$objPlayer->{penguin}->{buddy_requests}->{$objClient->{penguin}->{ID}} = 1;
		$objPlayer->sendXT(['br', '-1', $objClient->{penguin}->{ID}, $objClient->{penguin}->{username}]);  
}

method handleBuddyAccept($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intBudID = $arrData[5];
		return if (!looks_like_number($intBudID));
		return if (exists($objClient->{penguin}->{buddies}->{$intBudID}));
		my $objPlayer = $objClient->getClientByID($intBudID);
		delete($objPlayer->{penguin}->{buddy_requests}->{$objClient->{penguin}->{ID}});
		$objClient->{penguin}->{buddies}->{$intBudID} = $objPlayer->{penguin}->{username};
		$objPlayer->{penguin}->{buddies}->{$objClient->{penguin}->{ID}} = $objClient->{penguin}->{username};
		my $strCBuddies = join(',', map { $_ . '|' . $objClient->{penguin}->{buddies}->{$_}; } keys %{$objClient->{penguin}->{buddies}});
		my $strPBuddies = join(',', map { $_ . '|' . $objPlayer->{penguin}->{buddies}->{$_}; } keys %{$objPlayer->{penguin}->{buddies}});
		$self->{child}->{mysql}->updateBuddies($strCBuddies, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->updateBuddies($strPBuddies, $objPlayer->{penguin}->{ID});
		$objPlayer->sendXT(['ba', '-1', $objClient->{penguin}->{ID}, $objClient->{penguin}->{username}]);
}

method handleRemoveBuddy($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intBudID = $arrData[5];
		return if (!looks_like_number($intBudID));
		return if (!exists($objClient->{penguin}->{buddies}->{$intBudID}));
		my $objPlayer = $objClient->getClientByID($intBudID);
		delete($objClient->{penguin}->{buddies}->{$objPlayer->{penguin}->{ID}});
		delete($objPlayer->{penguin}->{buddies}->{$objClient->{penguin}->{ID}});    
		my $strCBuddies = join(',', map { $_ . '|' . $objClient->{penguin}->{buddies}->{$_}; } keys %{$objClient->{penguin}->{buddies}});
		my $strPBuddies = join(',', map { $_ . '|' . $objPlayer->{penguin}->{buddies}->{$_}; } keys %{$objPlayer->{penguin}->{buddies}});
		$self->{child}->{mysql}->updateBuddies($strCBuddies, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->updateBuddies($strPBuddies, $objPlayer->{penguin}->{ID});
		$objPlayer->sendXT(['rb', '-1', $objClient->{penguin}->{ID}, $objClient->{penguin}->{username}]);
}

method handleBuddyFind($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intBudID = $arrData[5];
		return if (!looks_like_number($intBudID));
		my $objPlayer = $objClient->getClientByID($intBudID);
		return $objClient->getOnline($intBudID) == 1 ? $objClient->sendXT(['bf', '-1', $objPlayer->{penguin}->{room}->{id}]) : $objClient->sendXT(['bf', '-1', 0]);
}

1;
