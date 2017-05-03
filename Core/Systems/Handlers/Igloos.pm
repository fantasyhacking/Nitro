package Igloos;

use strict;
use warnings;

use Method::Signatures;

use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			af => 'handleAddFurniture',
			ao => 'handleUpdateIgloo',
			au => 'handleAddIgloo',
			ag => 'handleUpdateFloor',
			um => 'handleUpdateMusic',
			gm => 'handleGetIglooDetails',
			go => 'handleGetOwnedIgloos',
			or => 'handleOpenIgloo',
			cr => 'handleCloseIgloo',
			gf => 'handleGetOwnedFurniture',
			ur => 'handleGetFurnitureRevision',
			gr => 'handleGetOpenedIgloos'
		};
		return $obj;
}


method handleIgloo(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleGetIglooDetails($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPengID = $arrData[5];
		return if (!looks_like_number($intPengID));
		my $arrInfo = $self->{child}->{mysql}->getIglooDetailsByID($intPengID);
		my $intIgloo = $arrInfo->{igloo};
		my $intMusic = $arrInfo->{music};
		my $intFloor = $arrInfo->{floor};
		my $strFurn = $arrInfo->{furniture};
		$objClient->sendData('%xt%gm%-1%' . $intPengID . '%' . ($intIgloo ? $intIgloo : 1) . '%' . ($intMusic ? $intMusic : 0) . '%' . ($intFloor ? $intFloor : 0) . '%' .  ($strFurn ? $strFurn : '') . '%');
}

method handleGetOpenedIgloos($strData, $objClient) {
		my $strIgloos = $self->loadIglooMap;
		if ($strIgloos eq "") {
		   $objClient->sendData('%xt%gr%-1%'); 
		} else {
		   $objClient->sendData('%xt%gr%-1%' . $strIgloos . '%'); 
		}
}

method loadIglooMap {
       my $strMap = join('%', map { $_ . '|' . $self->{child}->{gamesys}->{igloos}->{$_}; } keys %{$self->{child}->{gamesys}->{igloos}});
       return $strMap;
}

method handleOpenIgloo($strData, $objClient) {
		$self->{child}->{gamesys}->{igloos}->{$objClient->{penguin}->{ID}} = $objClient->{penguin}->{username};
}

method handleCloseIgloo($strData, $objClient) {
		delete($self->{child}->{gamesys}->{igloos}->{$objClient->{penguin}->{ID}});
}

method handleAddFurniture($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intFurn = $arrData[5];
		return if (!looks_like_number($intFurn));
		if (!exists($self->{child}->{crumbs}->{furniture_crumbs}->{$intFurn})) {
			return $objClient->sendError(402);
		} 
		if ($objClient->{penguin}->{wallet} < $self->{child}->{crumbs}->{furniture_crumbs}->{$intFurn}->{cost}) {
		   return $objClient->sendError(401);
		}
		my $quantity = 1;
		if (exists($objClient->{igloos}->{ownedFurns}->{$intFurn})) {
			$quantity += $objClient->{igloos}->{ownedFurns}->{$intFurn};           
		}
		if ($quantity >= 900) {
			return $objClient->sendError(403);
		}
		$objClient->{igloos}->{ownedFurns}->{$intFurn} = $quantity;  
		my $strFurns = join(',', map { $_ . '|' . $objClient->{igloos}->{ownedFurns}->{$_}; } keys %{$objClient->{igloos}->{ownedFurns}});
		$self->{child}->{mysql}->updateFurnInventory($strFurns, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->deductFromWallet($self->{child}->{crumbs}->{furniture_crumbs}->{$intFurn}->{cost}, $objClient);
		$objClient->sendXT(['af', '-1', $intFurn, $objClient->{penguin}->{wallet}]);
}

method handleUpdateIgloo($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intIgloo = $arrData[5];
		return if (!looks_like_number($intIgloo));
		$objClient->{igloos}->{igloo} = $intIgloo;
		$self->{child}->{mysql}->updateIglooType($intIgloo, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->updateFloorType(0, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->updateIglooFurniture('', $objClient->{penguin}->{ID});
		$objClient->sendXT(['ao', '-1', $intIgloo, $objClient->{penguin}->{wallet}]);
}

method handleAddIgloo($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intIgloo = $arrData[5];
		return if (!looks_like_number($intIgloo));
		if (!exists($self->{child}->{crumbs}->{igloo_crumbs}->{$intIgloo})) {
			  return $objClient->sendError(402);
		} 
		if (first {$_ == $intIgloo} @{$objClient->{igloos}->{ownedIgloos}}) {
			  return $objClient->sendError(400);
		} 
		if ($objClient->{penguin}->{wallet} < $self->{child}->{crumbs}->{igloo_crumbs}->{$intIgloo}->{cost}) {
			  return $objClient->sendError(401);
		}   
		push(@{$objClient->{igloos}->{ownedIgloos}}, $intIgloo); 
		my $strIgloos = join('|', @{$objClient->{igloos}->{ownedIgloos}});
		$self->{child}->{mysql}->updateIglooInventory($strIgloos, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->deductFromWallet($self->{child}->{crumbs}->{igloo_crumbs}->{$intIgloo}->{cost}, $objClient);
		$objClient->sendXT(['au', '-1', $intIgloo, $objClient->{penguin}->{wallet}]);
}

method handleUpdateFloor($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intFloor = $arrData[5];
		return if (!looks_like_number($intFloor));
		if (!exists($self->{child}->{crumbs}->{floor_crumbs}->{$intFloor})) {
		   return $objClient->sendError(402);
		} 
		if ($objClient->{penguin}->{wallet} < $self->{child}->{crumbs}->{floor_crumbs}->{$intFloor}->{cost}) {
		   return $objClient->sendError(401);
		}
		$objClient->{igloos}->{floor} = $intFloor;
		$self->{child}->{mysql}->updateFloorType($intFloor, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->deductFromWallet($self->{child}->{crumbs}->{floor_crumbs}->{$intFloor}->{cost}, $objClient);
		$objClient->sendXT(['ag', '-1', $intFloor, $objClient->{penguin}->{wallet}]);
}

method handleUpdateMusic($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intMusic = $arrData[5];
		return if (!looks_like_number($intMusic));
		$objClient->{igloos}->{music} = $intMusic;
		$self->{child}->{mysql}->updateIglooMusic($intMusic, $objClient->{penguin}->{ID});
		$objClient->sendXT(['um', '-1', $intMusic]);
}

method handleGetOwnedIgloos($strData, $objClient) {
		my $strIgloos = join('|', @{$objClient->{igloos}->{ownedIgloos}});
		$strIgloos ? $objClient->sendXT(['go', '-1', $strIgloos]) : $objClient->sendXT(['go', '-1', '1']);
}

method handleGetOwnedFurniture($strData, $objClient) {
		my $strFurns = "";
		while (my ($intFurnID, $intCount) = each(%{$objClient->{igloos}->{ownedFurns}})) {
			  $strFurns .= '%' . $intFurnID . '|' . $intCount;
		}
		$strFurns = substr($strFurns, 1);
		$objClient->sendXT(['gf', '-1', $strFurns]);
}

method handleGetFurnitureRevision($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $strFurns = "";
		while (my ($intKey, $strValue) = each(@arrData)) {
			  if ($intKey > 4) {
				  $strFurns .= ',' . $strValue;
			  }
		}
		$self->{child}->{mysql}->updateIglooFurniture($strFurns, $objClient->{penguin}->{ID});
}

1;
