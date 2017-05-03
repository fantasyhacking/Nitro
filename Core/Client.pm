package Client;

use strict;
use warnings;

use Method::Signatures;
use HTTP::Date qw(str2time);
use Math::Round qw(round);
use Scalar::Util qw(looks_like_number);
use Switch;
use JSON qw(decode_json);

method new($resParent, $resSock) {
       my $obj = bless {}, $self;
       $obj->{parent} = $resParent;
       $obj->{sock} = $resSock;
       $obj->{penguin} = {
			ID => 0,
			username => '',
			nickname => '',
			lkey => '',
			wallet => 5000,
			joindate => 0,
			inventory => [],
			clothing => {
				color => 0,
				body => 0,
				head => 0,
				face => 0,
				neck => 0,
				hand => 0,
				feet => 0,
				photo => 0,
			    flag => 0
			},
			ranking => {
				isStaff => 0,
				isMed => 0, 
				isMod => 0, 
				isAdmin => 0, 		
				rank => 1
			},
			buddies => {},
			buddy_requests => {},
			ignored => {},
			moderation => {
				isBanned => '', 
				isMuted => 0
			},
			room => {
				id => 0,
				xpos => 100,
				ypos => 100,
				frame=> 0,
			},
			invalidLogins => 0,
			ipAddress => '',
			digging => {
				lastTime => 0,
				tries => 0
			}
	   };
	   $obj->{igloos} = {
		   igloo => 0,
		   floor => 0,
		   music => 0,
		   furniture => '',
		   ownedFurns => {},
		   ownedIgloos => []
	   };
	   $obj->{epf} = {
			isagent => 0,
			status => 0,
			currentpoints => 0,
			totalpoints => 0
	   };
	   $obj->{stampbook} = {
			stamps => [],
			restamps => [],
			cover => ''
	   };
	   $obj->{gaming} = {
			tableID => 0,
			waddleRoom => 0,
			waddleId => 0
	   };
	   #spam system variables
	   $obj->{lastPackets} = {};
	   $obj->{lastPacketTime} = 0;
	   $obj->{lastHeartbeat} = 0;
	   $obj->{lastMessage} = '';
       return $obj;
}

method sendXT(\@arrArgs) {
		my $strPacket = '%xt%';
		$strPacket .= join('%', @arrArgs) . '%';
		$self->sendData($strPacket);
}

method sendData($strData) {
		if ($self->{sock}->connected) {
			$strData .= chr(0);
			$self->{sock}->write($strData);
		}
		$self->{parent}->{logger}->debug("Outgoing data: $strData") unless (!$self->{parent}->{config}->{nitro}->{debug}->{value});        
}

method sendRoom($strData) {
		foreach my $objPenguin (values %{$self->{parent}->{sock}->{clients}}) {
			if ($objPenguin->{penguin}->{room}->{id} == $self->{penguin}->{room}->{id}) {
                $objPenguin->sendData($strData);
            }
		}
}

method sendError($intError) {
		$self->sendData('%xt%e%-1%' . $intError . '%');
}

method loadInformation() {
	    my $intPenguinID = $self->{penguin}->{ID};
		my $arrPenguinInfo = $self->{parent}->{mysql}->fetchPenguinInfo($intPenguinID);
		my $arrIglooInfo = $self->{parent}->{mysql}->fetchIglooInfo($intPenguinID);
		my $arrEPFInfo = $self->{parent}->{mysql}->fetchEPFInfo($intPenguinID);
		my $arrStampsInfo = $self->{parent}->{mysql}->fetchStampsInfo($intPenguinID);
		$self->handleLoadPenguinInfo($arrPenguinInfo);
		$self->handleLoadIglooInfo($arrIglooInfo);
		$self->handleLoadEPFInfo($arrEPFInfo);
		$self->handleLoadStampsInfo($arrStampsInfo);
}

method handleLoadPenguinInfo($arrInfo) {
	   while (my ($strKey, $mixValue) = each(%{$arrInfo})) {
				switch ($strKey) {
					case ('joindate') {
						$self->{penguin}->{joindate} = round((time - str2time($mixValue)) / 86400);
					}
					case ('clothing') {
						if ($mixValue ne '') {
							my $arrData = decode_json($mixValue);
							foreach my $strKey (keys %{$arrData}) { 
								my $info = $arrData->{$strKey};
								while (my($key, $value) = each(%{$info})) {
									$self->{penguin}->{clothing}->{$key} = $value;
								}
							}
						}
					}
					case ('ranking') {
						if ($mixValue ne '') {
							my $arrData = decode_json($mixValue);
							foreach my $strKey (keys %{$arrData}) { 
								my $info = $arrData->{$strKey};
								while (my($key, $value) = each(%{$info})) {
									$self->{penguin}->{ranking}->{$key} = $value;
								}
							}
						}
					}
					case ('moderation') {
						if ($mixValue ne '') {
							my $arrData = decode_json($mixValue);
							foreach my $strKey (keys %{$arrData}) { 
								my $info = $arrData->{$strKey};
								while (my($key, $value) = each(%{$info})) {
									$self->{penguin}->{moderation}->{$key} = $value;
								}
							}
						}
					}			
					case ('inventory') {
						my @arrItems = split('%', $mixValue);
						foreach my $intItem (@arrItems) {
							if ($intItem ne '') {
								 push(@{$self->{penguin}->{inventory}}, $intItem);
							}
						}
					}
					case ('buddies') {
						my @arrBuddies = split(',', $mixValue);
						foreach my $intBuddy (@arrBuddies) {
							my ($intID, $strName) = split('\\|', $intBuddy);
							$self->{penguin}->{buddies}->{$intID} = $strName;
						}
					}
					case ('ignored') {
						my @arrIgnored = split(',', $mixValue);
						foreach my $intIgnored (@arrIgnored) {
							my ($intID, $strName) = split('\\|', $intIgnored);
							$self->{penguin}->{ignored}->{$intID} = $strName;
						}
					}
					else {
						$self->{penguin}->{$strKey} = $mixValue;
					}
				}
	   }
}

method handleLoadIglooInfo($arrInfo) {
		while (my ($strKey, $mixValue) = each(%{$arrInfo})) {
				switch ($strKey) {
					case ('ownedIgloos') {
						my @arrIgloos = split('\\|', $mixValue);
						foreach my $intIgloo (@arrIgloos) {
							push(@{$self->{igloos}->{ownedIgloos}}, $intIgloo);
						}
					}
					case ('ownedFurns') {
						my @arrFurns = split(',', $mixValue);
						foreach my $intFurn (@arrFurns) {
							 my ($intID, $intQuantity) = split('\\|', $intFurn);
							 $self->{igloos}->{ownedFurns}->{$intID} = $intQuantity;
						}
					} 
					else {
						$self->{igloos}->{$strKey} = $mixValue;
					}
				}
	   }
}

method handleLoadEPFInfo($arrInfo) {
		while (my ($strKey, $mixValue) = each(%{$arrInfo})) {
			$self->{epf}->{$strKey} = $mixValue;
		}
}

method handleLoadStampsInfo($arrInfo) {
		while (my ($strKey, $mixValue) = each(%{$arrInfo})) {
			switch ($strKey) {
				case ('stamps') {
					my @arrStamps = split('\\|', $mixValue);
					foreach my $intStamp (@arrStamps) {
						 push(@{$self->{stampbook}->{stamps}}, $intStamp);
					}
				}
				case ('restamps') {
					my @arrRestamps = split('\\|', $mixValue);
					foreach my $intRestamp (@arrRestamps) {
						 push(@{$self->{stampbook}->{restamps}}, $intRestamp);
					}
				} 
				else {
					$self->{stampbook}->{$strKey} = $mixValue;
				}
			}
		}
}

method buildPenguinString() {
		my @arrInfo = (
			$self->{penguin}->{ID},
			$self->{penguin}->{username}, 1,
			$self->{penguin}->{clothing}->{color},
			$self->{penguin}->{clothing}->{head},
			$self->{penguin}->{clothing}->{face},
			$self->{penguin}->{clothing}->{neck},
			$self->{penguin}->{clothing}->{body},
			$self->{penguin}->{clothing}->{hand},
			$self->{penguin}->{clothing}->{feet},
			$self->{penguin}->{clothing}->{flag},
			$self->{penguin}->{clothing}->{photo},
			$self->{penguin}->{room}->{xpos},
			$self->{penguin}->{room}->{ypos},
			$self->{penguin}->{room}->{frame}, 1,
			($self->{penguin}->{ranking}->{rank} * 146)
		);
		my $strPenguinInfo = join('|', @arrInfo);
		return $strPenguinInfo;
}

method joinRoom($intRoom = 100, $intX = 0, $intY = 0) {
		return if (!looks_like_number($intRoom));
		return if (!looks_like_number($intX));
		return if (!looks_like_number($intY));
		$self->removePlayerFromRoom($self->{penguin}->{ID});
		$self->{penguin}->{room}->{frame} = 0;
		if ($intRoom == 999) { 
			$self->{penguin}->{room}->{id} = $intRoom;
			$self->{penguin}->{room}->{xpos} = $intX;
			$self->{penguin}->{room}->{ypos} = $intY;
			return $self->sendXT(['jx', '-1', $intRoom]);
		}
		if (exists($self->{parent}->{crumbs}->{game_room_crumbs}->{$intRoom})) {  
			$self->{penguin}->{room}->{id} = $intRoom;
			$self->sendRoom('%xt%ap%-1%' . $self->buildPenguinString . '%');
			return $self->sendXT(['jg', '-1', $intRoom]);
		} elsif (exists($self->{parent}->{crumbs}->{room_crumbs}->{$intRoom}) || $intRoom > 1000) {
			$self->{penguin}->{room}->{id} = $intRoom;
			$self->{penguin}->{room}->{xpos} = $intX;
			$self->{penguin}->{room}->{ypos} = $intY;
			if ($intRoom <= 899 && $self->getRoomCount >= $self->{parent}->{crumbs}->{room_crumbs}->{$intRoom}->{limit}) {
				return $self->sendError(210);
			}
			my $strData = '%xt%jr%-1%'  . $intRoom . '%' . $self->buildRoomString;  
			$self->sendData($strData);
			$self->sendRoom('%xt%ap%-1%' . $self->buildPenguinString . '%');
	    }
}

method getRoomCount() {
		my $intCount = 0;
		map {
			if ($_->{penguin}->{room}->{id} == $self->{penguin}->{room}->{id}) {
				$intCount++;
			}
		} values %{$self->{parent}->{sock}->{clients}};
		return $intCount;
}

method buildRoomString() {
		my $strList = $self->buildPenguinString . '%';
		map {
			if ($_->{penguin}->{room}->{id} == $self->{penguin}->{room}->{id} && $_->{penguin}->{ID} != $self->{penguin}->{ID}) {
				$strList .= $_->buildPenguinString . '%';
			}
		} values %{$self->{parent}->{sock}->{clients}};
		return $strList;
}

method removePlayerFromRoom($intID) {
       $self->sendRoom('%xt%rp%-1%' . $intID . '%');
}

method getClientByID($intID) {
		foreach my $objPenguin (values %{$self->{parent}->{sock}->{clients}}) {
			if ($objPenguin->{penguin}->{ID} == $intID) {
				return $objPenguin;
			}
		}
}

method getClientByName($strName) {
		foreach my $objPenguin (values %{$self->{parent}->{sock}->{clients}}) {
			if (lc($objPenguin->{penguin}->{username}) eq lc($strName)) {
				return $objPenguin;
			}
		}
}

method getOnline($intID) {
       return if (!looks_like_number($intID));
       foreach my $objPenguin (values %{$self->{parent}->{sock}->{clients}}) {
		   if ($objPenguin->{penguin}->{ID} == $intID) {
			   return 1;
		   }
	   }
	   return 0;
}

method updatePuffleStatistics {
		my $intRandHealth = 0;
		my $intRandEnergy = 0;
		my $intRandRest = 0;
		my $intLastLogin = $self->{parent}->{mysql}->fetchPenguinInfo($self->{penguin}->{ID})->{llg};
		my $intTimeDifference = $self->{parent}->{crypt}->getTimeDifference($intLastLogin, time, 60);
		if ($intTimeDifference <= -60) {
			$intRandHealth = $self->{parent}->{crypt}->generateRandomNumber(1, 10);
			$intRandEnergy = $self->{parent}->{crypt}->generateRandomNumber(1, 10);
			$intRandRest = $self->{parent}->{crypt}->generateRandomNumber(1, 10);
		} else {
			$intRandHealth = 0;
			$intRandEnergy = 0;
			$intRandRest = 0;
		}
		my $arrPuffles = $self->{parent}->{mysql}->getPufflesByOwner($self->{penguin}->{ID});
		foreach my $resPuffle (values @{$arrPuffles}) {
			my $intPuffle = $resPuffle->{puffleID};
			if ($resPuffle->{puffleHealth} <= 5) {
				my $intPuffleType = 75 . $resPuffle->{puffleType};
				my $intPostcardType = 0;
				switch ($resPuffle->{puffleType}) {
					case (0) { $intPostcardType = 100; }
					case (1) { $intPostcardType = 101; }
					case (2) { $intPostcardType = 102; }
					case (3) { $intPostcardType = 103; }
					case (4) { $intPostcardType = 104; }
					case (5) { $intPostcardType = 105; }
					case (6) { $intPostcardType = 106; }
					case (7) { $intPostcardType = 169; }
					case (8) { $intPostcardType = 109; }
				}
				my $intPostcard = $self->{parent}->{mysql}->sendPostcard($self->{penguin}->{ID}, 'sys', 0, $resPuffle->{puffleName}, $intPostcardType);
				$self->sendXT(['mr', '-1', 'sys', 0, $intPostcardType, $resPuffle->{puffleName}, time, $intPostcard]);
				if ($self->{penguin}->{clothing}->{hand} == $intPuffleType) {
					$self->{parent}->{mysql}->updatePlayerClothing('hand', 0, $self);
				}
				$self->{parent}->{mysql}->deletePuffleByOwner($resPuffle->{puffleID}, $self->{penguin}->{ID});
			}
			my $intLastLogin = $self->{parent}->{mysql}->fetchPenguinInfo($self->{penguin}->{ID})->{llg};
			my $intTimeDifference = $self->{parent}->{crypt}->getTimeDifference($intLastLogin, time, 60);
			if ($resPuffle->{puffleEnergy} <= 45 && $intTimeDifference <= -30) {
				my $intPostcard = $self->{parent}->{mysql}->sendPostcard($self->{penguin}->{ID}, 'sys', 0, $resPuffle->{puffleName}, 110);
				$self->sendXT(['mr', '-1', 'sys', 0, 110, $resPuffle->{puffleName}, time, $intPostcard]);		
			}
			my $intHealth = $resPuffle->{puffleHealth} - $intRandHealth;
			my $intHunger = $resPuffle->{puffleEnergy} - $intRandEnergy;
			my $intRest = $resPuffle->{puffleRest} - $intRandRest;
			$self->{parent}->{mysql}->updatePuffleStats($intHealth, $intHunger, $intRest, $intPuffle, $self->{penguin}->{ID});
		}
}

method handleBuddyOnline {
       foreach (keys %{$self->{penguin}->{buddies}}) {
                if ($self->getOnline($_)) {
                    my $objPlayer = $self->getClientByID($_);
                    $objPlayer->sendXT(['bon', '-1', $self->{penguin}->{ID}]);
                }
       }
}

method handleBuddyOffline {
       foreach (keys %{$self->{penguin}->{buddies}}) {
                if ($self->getOnline($_)) {
                    my $objPlayer = $self->getClientByID($_);
                    $objPlayer->sendXT(['bof', '-1', $self->{penguin}->{ID}]);
                }
       }
}

method DESTROY {
		$self->handleBuddyOffline;
		$self->{parent}->{multiplayer}->leaveTable($self);
		$self->{parent}->{multiplayer}->leaveWaddle($self, $self->{gaming}->{waddleId}) if ($self->{gaming}->{waddleId} != 0);
		delete($self->{parent}->{gamesys}->{igloos}->{$self->{penguin}->{ID}});
		delete($self->{parent}->{sock}->{iplogger}->{$self->{penguin}->{ipAddress}});
		$self->removePlayerFromRoom($self->{penguin}->{ID});
}

1;
