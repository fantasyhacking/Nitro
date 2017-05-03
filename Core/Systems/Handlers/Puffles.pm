package Puffles;

use strict;
use warnings;

use Method::Signatures;

use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			ps => 'handleSendPuffleFrame',
			pg => 'handleGetPuffle',
			pip => 'handlePufflePip',
			pir => 'handlePufflePir',
			ir => 'handlePuffleIsResting',
			ip => 'handlePuffleIsPlaying',
			if => 'handlePuffleIsFeeding',
			pw => 'handlePuffleWalk',
			pgu => 'handlePuffleUser',
			pf => 'handlePuffleFeedFood',
			pn => 'handleAdoptPuffle',
			pr => 'handlePuffleRest',
			pp => 'handlePufflePlay',
			pt => 'handlePuffleFeed',
			pm => 'handlePuffleMove',
			pb => 'handlePuffleBath'
		};
		return $obj;
}

method handlePuffles(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleSendPuffleFrame($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		my $intFrame = $arrData[6];
		return if (!looks_like_number($intPuffID) || !looks_like_number($intFrame));
		$objClient->sendRoom('%xt%ps%-1%' . $intPuffID . '%' . $intFrame . '%');
}

method handleGetPuffle($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPengID = $arrData[5];
		return if (!looks_like_number($intPengID));
		my $strPuffles = $self->{child}->{mysql}->getNonWalkingPuffles($intPengID);
		$objClient->sendXT(['pg', '-1', $strPuffles]);
}

method handlePufflePip($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $puffleID = $arrData[5];
		my $argTwo = $arrData[6];
		my $argThree = $arrData[7];
		return if (!looks_like_number($puffleID) || !looks_like_number($argTwo) || !looks_like_number($argThree));	
		my $petDetails = $self->{child}->{mysql}->getPuffleByOwner($puffleID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%pir%-1%' . $petDetails->{puffleID} . '%' . $argTwo . '%' . $argThree . '%');
}

method handlePufflePir($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		my $argTwo = $arrData[6];
		my $argThree = $arrData[7];
		return if (!looks_like_number($intPuffID) || !looks_like_number($argTwo) || !looks_like_number($argThree));	
		my $petDetails = $self->{child}->{mysql}->getPuffleByOwner($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%pir%-1%' . $petDetails->{puffleID} . '%' . $argTwo . '%' . $argThree . '%');
}

method handlePuffleIsResting($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		my $argTwo = $arrData[6];
		my $argThree = $arrData[7];
		return if (!looks_like_number($intPuffID) || !looks_like_number($argTwo) || !looks_like_number($argThree));
		my $petDetails = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%ir%-1%' . ($petDetails ? $petDetails : '%') . $argTwo . '%' . $argThree . '%');
}

method handlePuffleIsPlaying($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		my $argTwo = $arrData[6];
		my $argThree = $arrData[7];
		return if (!looks_like_number($intPuffID) || !looks_like_number($argTwo) || !looks_like_number($argThree));
		my $petDetails = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%ip%-1%' . ($petDetails ? $petDetails : '%') . $argTwo . '%' . $argThree . '%');
}

method handlePuffleIsFeeding($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		my $argTwo = $arrData[6];
		my $argThree = $arrData[7];
		return if (!looks_like_number($intPuffID) || !looks_like_number($argTwo) || !looks_like_number($argThree));
		my $petDetails = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%if%-1%' . $objClient->{penguin}->{wallet} . '%' . ($petDetails ? $petDetails : '%') .  $argTwo . '%' . $argThree . '%');
}

method handlePuffleWalk($strData, $objClient) {
       my @arrData = split('%', $strData);
       my $puffleID = $arrData[5];
       my $blnWalk = $arrData[6];
       return if (!looks_like_number($puffleID));
       return if (!looks_like_number($blnWalk));
       my $arrWalkingPuffle = $self->{child}->{mysql}->getWalkingPuffle($objClient->{penguin}->{ID});
	   $self->{child}->{mysql}->updateWalkingPuffle(0, $arrWalkingPuffle->{puffleID}, $objClient->{penguin}->{ID});
       my $petDetails = $self->{child}->{mysql}->getPuffleByOwner($puffleID, $objClient->{penguin}->{ID});
       if ($petDetails) {
           my $walkStr = $petDetails->{puffleID} . '|' . $petDetails->{puffleName} . '|' . $petDetails->{puffleType} . '|' . $petDetails->{puffleHealth} . '|' . $petDetails->{puffleEnergy} . '|' . $petDetails->{puffleRest} . '|0|0|0|0|0|0';
           if ($blnWalk eq 1) {
               my $intItem =  75 . $petDetails->{puffleType};
               $objClient->sendRoom('%xt%upa%-1%' . $objClient->{penguin}->{ID} . '%' . $intItem . '%');
               $self->{child}->{mysql}->updatePlayerClothing('hand', $intItem, $objClient);
               $objClient->{penguin}->{clothing}->{hand} = $intItem;
               $self->{child}->{mysql}->updateWalkingPuffle(1, $petDetails->{puffleID}, $objClient->{penguin}->{ID});
               $objClient->sendRoom('%xt%pw%-1%' . $objClient->{penguin}->{ID} . '%' . $walkStr . '|1%');
           } else {
               $objClient->sendRoom('%xt%upa%-1%' . $objClient->{penguin}->{ID} . '%0%');
               $self->{child}->{mysql}->updatePlayerClothing('hand', 0, $objClient);
               $objClient->{penguin}->{clothing}->{hand} = 0;
               $self->{child}->{mysql}->updateWalkingPuffle(0, $petDetails->{puffleID}, $objClient->{penguin}->{ID});
               $objClient->sendRoom('%xt%pw%-1%' . $objClient->{penguin}->{ID} . '%' . $walkStr . '|0%');
           }
       } 
}

method handlePuffleUser($strData, $objClient) {
		my $strPuffles = $self->{child}->{mysql}->getNonWalkingPuffles($objClient->{penguin}->{ID});
		$objClient->sendXT(['pgu', '-1', $strPuffles]);
} 

method handlePuffleFeedFood($strData, $objClient) {
       my @arrData = split('%', $strData);
       my $intPuffID = $arrData[5];
       return if (!looks_like_number($intPuffID));
       if ($objClient->{penguin}->{wallet} < 10) {
           return $objClient->sendError(401);
       }
       $self->{child}->{mysql}->changeRandPuffStat($intPuffID, $objClient->{penguin}->{ID});
       $self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleHealth', $self->{child}->{crypt}->generateRandomNumber(3, 10), $objClient->{penguin}->{ID}, 1);
       $self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleEnergy', $self->{child}->{crypt}->generateRandomNumber(7, 12), $objClient->{penguin}->{ID}, 1);
       $self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleRest', $self->{child}->{crypt}->generateRandomNumber(1, 7), $objClient->{penguin}->{ID}, 0);
       $self->{child}->{mysql}->deductFromWallet(10, $objClient);
       my $petDetails = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
       $objClient->sendRoom('%xt%pf%-1%' . $objClient->{penguin}->{wallet} . '%' . ($petDetails ? $petDetails : '%'));
}

method handleAdoptPuffle($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		my $strPuffName = $arrData[6];
		return if (!looks_like_number($intPuffID));
		return if ($strPuffName !~ /[\w ]+/);
		if ($objClient->{penguin}->{wallet} < 800) {
		   return $objClient->sendError(401);
		}
		my $strPuffle = $self->{child}->{mysql}->addPuffle($intPuffID, $strPuffName, $objClient);
		my $intAdoptTime = time;
		my $intPostcardType = 111;
		my $intPostcardID = $self->{child}->{mysql}->sendPostcard($objClient->{penguin}->{ID}, 'sys', 0, $strPuffName, $intPostcardType, $intAdoptTime);
		$objClient->sendXT(['mr', '-1', 'sys', 0, $intPostcardType, $strPuffName, $intAdoptTime, $intPostcardID]);
		$objClient->sendXT(['pn', '-1', $objClient->{penguin}->{wallet}, $strPuffle]);
		my $strPuffles = $self->{child}->{mysql}->getNonWalkingPuffles($objClient->{penguin}->{ID});
		$objClient->sendXT(['pgu', '-1', $strPuffles]);
}

method handlePuffleRest($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		return if (!looks_like_number($intPuffID));
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleHealth', $self->{child}->{crypt}->generateRandomNumber(6, 14), $objClient->{penguin}->{ID}, 1);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleRest', $self->{child}->{crypt}->generateRandomNumber(14, 19), $objClient->{penguin}->{ID}, 1);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleEnergy', $self->{child}->{crypt}->generateRandomNumber(7, 15), $objClient->{penguin}->{ID}, 1);
		my $strPuffle = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%pr%-1%' . ($strPuffle ? $strPuffle : '%'));
}

method handlePufflePlay($strData, $objClient) { 
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		return if (!looks_like_number($intPuffID));
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleEnergy', $self->{child}->{crypt}->generateRandomNumber(5, 10), $objClient->{penguin}->{ID}, 0);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleRest', $self->{child}->{crypt}->generateRandomNumber(5, 12), $objClient->{penguin}->{ID}, 0);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleHealth', $self->{child}->{crypt}->generateRandomNumber(4, 10), $objClient->{penguin}->{ID}, 1);
		my $strPuffle = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%pp%-1%' . ($strPuffle ? $strPuffle : '%') . int(rand(2)) . '%');
}

method handlePuffleFeed($strData, $objClient) { 
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		my $intAction = $arrData[6];
		return if (!looks_like_number($intPuffID));
		return if (!looks_like_number($intAction));
		if ($objClient->{penguin}->{wallet} < 5) {
		   return $objClient->sendError(401);
		}
		$self->{child}->{mysql}->changeRandPuffStat($intPuffID, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleHealth', $self->{child}->{crypt}->generateRandomNumber(3, 10), $objClient->{penguin}->{ID}, 1);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleEnergy', $self->{child}->{crypt}->generateRandomNumber(7, 12), $objClient->{penguin}->{ID}, 1);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleRest', $self->{child}->{crypt}->generateRandomNumber(1, 7), $objClient->{penguin}->{ID}, 0);
		$self->{child}->{mysql}->deductFromWallet(5, $objClient);
		my $strPuffle = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%pt%-1%' . $objClient->{penguin}->{wallet} . '%' . ($strPuffle ? $strPuffle : '%') . $intAction . '%');
}

method handlePuffleMove($strData, $objClient) {
       my @arrData = split('%', $strData);
       my $intPuffID = $arrData[5];
       my $intPosX = $arrData[6];
       my $intPosY = $arrData[7];
       return if (!looks_like_number($intPuffID));
       return if (!looks_like_number($intPosX));
       return if (!looks_like_number($intPosY));
       $objClient->sendRoom('%xt%pm%-1%' . $intPuffID . '%' . $intPosX . '%' . $intPosY . '%');
}

method handlePuffleBath($strData, $objClient) { 
		my @arrData = split('%', $strData);
		my $intPuffID = $arrData[5];
		return if (!looks_like_number($intPuffID));
		if ($objClient->{penguin}->{wallet} < 5) {
		   return $objClient->sendError(401);
		}
		$self->{child}->{mysql}->changeRandPuffStat($intPuffID, $objClient->{penguin}->{ID});
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleHealth', $self->{child}->{crypt}->generateRandomNumber(8, 13), $objClient->{penguin}->{ID}, 0);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleRest', $self->{child}->{crypt}->generateRandomNumber(13, 20), $objClient->{penguin}->{ID}, 0);
		$self->{child}->{mysql}->changePuffleStats($intPuffID, 'puffleEnergy', $self->{child}->{crypt}->generateRandomNumber(7, 12), $objClient->{penguin}->{ID}, 1);
		$self->{child}->{mysql}->deductFromWallet(5, $objClient);
		my $strPuffle = $self->{child}->{mysql}->getPuffle($intPuffID, $objClient->{penguin}->{ID});
		$objClient->sendRoom('%xt%pb%-1%' . $objClient->{penguin}->{wallet} . '%' . ($strPuffle ? $strPuffle : '%'));
}

1;
