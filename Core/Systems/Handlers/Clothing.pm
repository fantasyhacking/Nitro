package Clothing;

use strict;
use warnings;

use Method::Signatures;

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			upc => 'handleUpdatePlayerClothing',
			uph => 'handleUpdatePlayerClothing',
			upf => 'handleUpdatePlayerClothing',
			upn => 'handleUpdatePlayerClothing',
			upb => 'handleUpdatePlayerClothing',
			upa => 'handleUpdatePlayerClothing',
			upe => 'handleUpdatePlayerClothing',
			upp => 'handleUpdatePlayerClothing',
			upl => 'handleUpdatePlayerClothing'
		};
		$obj->{item_types} = {
			uph => 'head', 
			upf => 'face', 
			upn => 'neck', 
			upb => 'body', 
			upa => 'hand', 
			upe => 'feet', 
			upp => 'photo', 
			upl => 'flag',
			upc => 'color'
		};
		return $obj;
}

method handlePenguinClothing(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleUpdatePlayerClothing($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $strCMD = $arrData[3];
		my $intItem = $arrData[5];
		my @arrCMD = split('#', $strCMD);
		my $strType = $arrCMD[1];
		return if (!exists($self->{item_types}->{$strType}));
		if ($strType eq 'upa' && $intItem == 0) {
			my $arrWalkingPuffle = $self->{child}->{mysql}->getWalkingPuffle($objClient->{penguin}->{ID});
			$self->{child}->{mysql}->updateWalkingPuffle(0, $arrWalkingPuffle->{puffleID}, $objClient->{penguin}->{ID});
			$objClient->sendRoom('%xt%' . $strType . '%-1%' . $objClient->{penguin}->{ID} . '%0%');
			$self->{child}->{mysql}->updatePlayerClothing('hand', 0, $objClient);
			$objClient->{penguin}->{clothing}->{hand} = 0;
			if ($objClient->{penguin}->{room}->{id} > 1000) {
				my $strPuffles = $self->{child}->{mysql}->getNonWalkingPuffles($objClient->{penguin}->{ID});
				$objClient->sendXT(['pgu', '-1', $strPuffles]);
				$objClient->joinRoom($objClient->{penguin}->{room}->{id}); # temp fix to make puffle reappear in the igloo after removing from walking
			}
		}	
		$objClient->sendRoom('%xt%' . $strType . '%-1%' . $objClient->{penguin}->{ID} . '%' . $intItem . '%');
		$self->{child}->{mysql}->updatePlayerClothing($self->{item_types}->{$strType}, $intItem, $objClient);
		$objClient->{penguin}->{clothing}->{$self->{item_types}->{$strType}} = $intItem;
}

1;
