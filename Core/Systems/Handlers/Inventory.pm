package Inventory;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			gi => 'handleGetInventory',
			ai => 'handleAddItem',
			qpp => 'handleQueryPlayerPins',
			qpa => 'handleQueryPlayerAwards'
		};
		return $obj;
}

method handleInventory(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleGetInventory($strData, $objClient) {
		my @arrInventory = $self->{child}->{mysql}->getInventoryByID($objClient->{penguin}->{ID});
		my $strInventory = join('%', @arrInventory);
		$objClient->sendXT(['gi', '-1', $strInventory]);
}

method handleAddItem($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intItem = $arrData[5];
		return if (!looks_like_number($intItem));	
		if (!exists($self->{child}->{crumbs}->{item_crumbs}->{$intItem})) {
			  return $objClient->sendError(402);
		} 
		if (first {$_ == $intItem} @{$objClient->{penguin}->{inventory}}) {
			  return $objClient->sendError(400);
		} 
		if ($objClient->{penguin}->{wallet} < $self->{child}->{crumbs}->{item_crumbs}->{$intItem}->{cost}) {
			  return $objClient->sendError(401);
		}    			
		$self->{child}->{mysql}->addToInventory($intItem, $objClient->{penguin}->{ID});		
		$self->{child}->{mysql}->deductFromWallet($self->{child}->{crumbs}->{item_crumbs}->{$intItem}->{cost}, $objClient);		
		$objClient->sendXT(['ai', '-1', $intItem, $objClient->{penguin}->{wallet}]);			
}

method handleQueryPlayerAwards($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intID = $arrData[5];
		return if (!looks_like_number($intID));
		my @arrAwards = ();
		my @arrInventory = $self->{child}->{mysql}->getInventoryByID($intID);
		foreach (@arrInventory) {
			if (exists($self->{child}->{crumbs}->{item_crumbs}->{$_}) && $self->{child}->{crumbs}->{item_crumbs}->{$_}->{type} == 10) {
				push(@arrAwards, $_);
			}
		}
		my $strAwards = join('|', @arrAwards);
		$objClient->sendXT(['qpa', '-1', $intID, $strAwards]);
}

method handleQueryPlayerPins($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intID = $arrData[5];
		return if (!looks_like_number($intID));
		my @arrPins = ();
		my @arrInventory = $self->{child}->{mysql}->getInventoryByID($intID);
		foreach (@arrInventory) {
			if (exists($self->{child}->{crumbs}->{item_crumbs}->{$_}) && $self->{child}->{crumbs}->{item_crumbs}->{$_}->{type} == 8) {
				push(@arrPins, $_);
			}   
		}
		my $strPins = join('|', @arrPins) . time() . '|0';
		$objClient->sendXT(['qpp', '-1', $intID, $strPins]);
}

1;
