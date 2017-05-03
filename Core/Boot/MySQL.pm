package MySQL;

use strict;
use warnings;

use Method::Signatures;
use Mojo::mysql;
use JSON qw(decode_json encode_json);
use Math::Round qw(round);
use DBI;

method new($resChild) {
       my $obj = bless {}, $self;
       $obj->{child} = $resChild;
       return $obj;
}

method connectMySQL($strHost, $strUsername, $strPassword, $strDatabase) { # making use of DBI because Mojo doesn't return errors, some cock shit right there
		my $dbh = DBI->connect("DBI:mysql:database=$strDatabase:host=$strHost", $strUsername, $strPassword);
		if (!$dbh) {
			$self->{child}->{logger}->error('Failed to connect to the MySQL server');
			exit;
		} else {
			my $connection = Mojo::mysql->new('mysql://' . $strUsername . ':' . $strPassword . '@' . $strHost . '/' . $strDatabase);
			$self->{connection} = $connection;
			$self->{child}->{logger}->info('Successfully connected to the MySQL server');
		}
}

method checkUsernameExists($strName) {
		if ($strName !~ /^\w+$/){
			return 0;
		}
		my $arrResults = $self->{connection}->db->query('select username from kittens where username = ?', $strName);
		while (my $arrData = $arrResults->hash) {
			if (uc($strName) eq uc($arrData->{username})) {
				return 1;
			} else {
				return 0;
			} 
		}
}

method getPenguinPassword($strName) {
		my $arrResults = $self->{connection}->db->query('select password from kittens where username = ?', $strName);
		while (my $arrData = $arrResults->hash) {
				return $arrData->{password};
		}
}


method getPenguinLoginKey($strName) {
	    my $arrResults = $self->{connection}->db->query('select lkey from kittens where username = ?', $strName);
		while (my $arrData = $arrResults->hash) {
				return $arrData->{lkey};
		}
}

method getPenguinID($strName) {
		my $arrResults = $self->{connection}->db->query('select ID from kittens where username = ?', $strName);
		while (my $arrData = $arrResults->hash) {
				return $arrData->{ID};
		}
}

method getPenguinNickname($strName) {
		my $arrResults = $self->{connection}->db->query('select nickname from kittens where username = ?', $strName);
		while (my $arrData = $arrResults->hash) {
				return $arrData->{nickname};
		}
}

method updateLoginKey($strKey, $strName) {
	   $self->{connection}->db->query('update kittens set lkey = ? where username = ?', $strKey, $strName);
}

method fetchPenguinInfo($intPID) {
		my $arrResults = $self->{connection}->db->query('select * from kittens where ID = ?', $intPID);
		while (my $arrData = $arrResults->hash) {
				return $arrData;
		}
}

method fetchIglooInfo($intPID) {
		my $arrResults = $self->{connection}->db->query('select * from igloos where ID = ?', $intPID);
		while (my $arrData = $arrResults->hash) {
				return $arrData;
		}
}

method fetchEPFInfo($intPID) {
		my $arrResults = $self->{connection}->db->query('select * from epf where ID = ?', $intPID);
		while (my $arrData = $arrResults->hash) {
				return $arrData;
		}
}

method fetchStampsInfo($intPID) {
		my $arrResults = $self->{connection}->db->query('select * from stamps where ID = ?', $intPID);
		while (my $arrData = $arrResults->hash) {
				return $arrData;
		}
}

method getPlayerDetails($intPID) {
		my $arrResults = $self->{connection}->db->query('select username, clothing, ranking from kittens where ID = ?', $intPID);
		while (my $arrData = $arrResults->hash) {
			my $strName = $arrData->{username};
			my $arrClothing = decode_json($arrData->{clothing});
			my $arrRanking = decode_json($arrData->{ranking});
			my @arrDetails = (
				$intPID, 
				$strName, 1, 
				$arrClothing->{clothing}->{color}, 
				$arrClothing->{clothing}->{head}, 
				$arrClothing->{clothing}->{face}, 
				$arrClothing->{clothing}->{neck}, 
				$arrClothing->{clothing}->{body}, 
				$arrClothing->{clothing}->{hand}, 
				$arrClothing->{clothing}->{feet}, 
				$arrClothing->{clothing}->{flag}, 
				$arrClothing->{clothing}->{photo}, 0, 0, 0, 
				($arrRanking->{ranking}->{rank} * 146)
			);
			my $strDetails = join('|', @arrDetails);
			return $strDetails;
		}
}

method getWallet($intID) {
		my $arrResults = $self->{connection}->db->query('select wallet from kittens where ID = ?', $intID);
		while (my $arrData = $arrResults->hash) {
			my $intWallet = $arrData->{wallet};
			return $intWallet;
		}
}

method deductEPFPoints($intPoints, $objClient) {
		my $intUpdatedPoints = ($objClient->{epf}->{currentpoints} - $intPoints);
		$self->{connection}->db->query('update epf set currentpoints = ? where ID = ?', $intUpdatedPoints, $objClient->{penguin}->{ID});
		$objClient->{epf}->{currentpoints} = $intUpdatedPoints;	
		my $arrEPFInfo = $self->fetchEPFInfo($objClient->{penguin}->{ID});
		$objClient->handleLoadEPFInfo($arrEPFInfo);
}

method updateEPFOPStatus($blnStat, $objClient) {
		$self->{connection}->db->query('update epf set status = ? where ID = ?', $blnStat, $objClient->{penguin}->{ID});
		$objClient->{epf}->{status} = $blnStat;
}

method updateEPFAgent($blnEpf, $objClient) {
		$self->{connection}->db->query('update epf set isagent = ? where ID = ?', $blnEpf, $objClient->{penguin}->{ID});
		$objClient->{epf}->{isagent} = $blnEpf;
}

method deductFromWallet($intAmount, $objClient) {
		my $intUpdatedWallet = ($objClient->{penguin}->{wallet} - $intAmount);
		$self->{connection}->db->query('update kittens set wallet = ? where ID = ?', $intUpdatedWallet, $objClient->{penguin}->{ID});
		$objClient->{penguin}->{wallet} = $intUpdatedWallet;	
		my $arrPenguinInfo = $self->fetchPenguinInfo($objClient->{penguin}->{ID});
		$objClient->handleLoadPenguinInfo($arrPenguinInfo);
}

method addToWalletWithoutPack($intAmount, $objClient) {
		my $intUpdatedWallet = ($objClient->{penguin}->{wallet} + $intAmount);
		$self->{connection}->db->query('update kittens set wallet = ? where ID = ?', $intUpdatedWallet, $objClient->{penguin}->{ID});	
		$objClient->{penguin}->{wallet} = $intUpdatedWallet;
		$objClient->loadInformation;
}

method addToWallet($intAmount, $objClient) {
		my $intUpdatedWallet = ($objClient->{penguin}->{wallet} + $intAmount);
		$self->{connection}->db->query('update kittens set wallet = ? where ID = ?', $intUpdatedWallet, $objClient->{penguin}->{ID});	
		$objClient->{penguin}->{wallet} = $intUpdatedWallet;
		$objClient->sendData('%xt%zo%-1%' . $objClient->{penguin}->{wallet} . '%');
}

method updateFurnInventory($strFurns, $intPengID) {
		$self->{connection}->db->query('update igloos set ownedFurns = ? where ID = ?', $strFurns, $intPengID);
}

method getInventoryByID($intID) {
		my @arrInventory = ();
		my $arrResults = $self->{connection}->db->query('select inventory from kittens where ID = ?', $intID);
		while (my $arrData = $arrResults->hash) {
			my $strInventory = $arrData->{inventory};
			my @arrItems = split('%', $strInventory);
			foreach (@arrItems) {
				push(@arrInventory, $_);
			}
		}
		return @arrInventory;
}

method addToInventory($intItem, $intID) {
		my @arrInventory = $self->getInventoryByID($intID);
		push(@arrInventory, $intItem);
		my $strInventory = join('%', @arrInventory);
		$self->{connection}->db->query('update kittens set inventory = ? where ID = ?', $strInventory, $intID);
}

method updatePlayerClothing($strType, $intItem, $objClient) {
		my $arrClothing = {
			"clothing" => {
				"head" => 0,
				"face" => 0,
				"neck" => 0,
				"body" => 0,
				"hand" => 0,
				"feet" => 0,
				"flag" => 0,
				"photo" => 0
			}
		};
		map {
			$arrClothing->{clothing}->{$_} = $objClient->{penguin}->{clothing}->{$_};
		} keys %{$objClient->{penguin}->{clothing}};
		$arrClothing->{clothing}->{$strType} = $intItem;
		my $strClothing = encode_json(\%{$arrClothing});
		$self->{connection}->db->query('update kittens set clothing = ? where ID = ?', $strClothing, $objClient->{penguin}->{ID});
}
method updateModerationInfo($objClient, $strType, $mixStatus) {
		my $arrModerating = {
			"moderation" => {
				"isBanned" => 0,
				"isMuted" => 0
			}
		};
		map {
			$arrModerating->{moderation}->{$_} = $objClient->{penguin}->{moderation}->{$_};
		} keys %{$objClient->{penguin}->{moderation}};
		$arrModerating->{moderation}->{$strType} = $mixStatus;
		$objClient->{penguin}->{moderation}->{$strType} = $mixStatus;
		my $strModerating = encode_json(\%{$arrModerating});
		$self->{connection}->db->query('update kittens set moderation = ? where ID = ?', $strModerating, $objClient->{penguin}->{ID});
}

method updateBuddies($strBuddies, $intID) {
		$self->{connection}->db->query('update kittens set buddies = ? where ID = ?', $strBuddies, $intID);
}

method updateIgnored($strIgnored, $intID) {
		$self->{connection}->db->query('update kittens set ignored = ? where ID = ?', $strIgnored, $intID);
}

method updateStamps($strStamps, $strRecurringStamps, $intID) {
		$self->{connection}->db->query('update stamps set stamps = ?, restamps = ? where ID = ?', $strStamps, $strRecurringStamps, $intID);
}

method updateStampbookCover($strCover, $intID) {
		$self->{connection}->db->query('update stamps set cover = ? where ID = ?', $strCover, $intID);
}

method getStampsByID($intID) {
		my $arrResults = $self->{connection}->db->query('select stamps from stamps where ID = ?', $intID);
		while (my $arrData = $arrResults->hash) {
			my $strStamps = $arrData->{stamps};
			return $strStamps;
		}
}

method getStampbookCoverByID($intID) {
		my $arrResults = $self->{connection}->db->query('select cover from stamps where ID = ?', $intID);
		while (my $arrData = $arrResults->hash) {
			my $strCover = $arrData->{cover};
			return $strCover;
		}
}

method getIglooDetailsByID($intPengID) {
		my $arrResults = $self->{connection}->db->query('select igloo, floor, music, furniture from igloos where ID = ?', $intPengID);
		while (my $arrData = $arrResults->hash) {
			return $arrData;
		}
}

method updateIglooType($intIgloo, $intPengID) {
		$self->{connection}->db->query('update igloos set igloo = ? where ID = ?', $intIgloo, $intPengID);
}

method updateIglooInventory($strIgloos, $intPengID) {
		$self->{connection}->db->query('update igloos set ownedIgloos = ? where ID = ?', $strIgloos, $intPengID);
}

method updateFloorType($intFloor, $intPengID) {
		$self->{connection}->db->query('update igloos set floor = ? where ID = ?', $intFloor, $intPengID);
}

method updateIglooMusic($intMusic, $intPengID) {
		$self->{connection}->db->query('update igloos set music = ? where ID = ?', $intMusic, $intPengID);
}

method updateIglooFurniture($strFurns, $intPengID) {
		$self->{connection}->db->query('update igloos set furniture = ? where ID = ?', $strFurns, $intPengID);
}

method getPufflesByID($intPengID) {
		my $string  = $self->{connection}->db->query("select * from puffles where ownerID = ?", $intPengID)->hashes->map(sub {
									$_->{puffleID} . '|' . $_->{puffleName} . '|' . $_->{puffleType} . '|' . $_->{puffleEnergy} . '|' . $_->{puffleHealth} . '|' . $_->{puffleRest}
		})->join('%');
		return $string;
}

method getPufflesByOwner($intPengID) {
		my $arrPuffles  = $self->{connection}->db->query("select * from puffles where ownerID = ?", $intPengID)->hashes;
		return $arrPuffles;
}

method getPuffleByOwner($intPuffID, $intOwnerID) {
		my $arrResults = $self->{connection}->db->query('select * from puffles where puffleID = ? and ownerID = ?', $intPuffID, $intOwnerID);
		while (my $arrData = $arrResults->hash) {
			return $arrData;
		}
}

method getPuffle($intPuffID, $intOwnerID) {
		my $arrResults = $self->{connection}->db->query('select * from puffles where puffleID = ? and ownerID = ?', $intPuffID, $intOwnerID);
		my $strPuffle = "";
		while (my $arrData = $arrResults->hash) {
				$strPuffle .= $arrData->{puffleID} . '|' . $arrData->{puffleName} . '|' . $arrData->{puffleType} . '|' . $arrData->{puffleHealth} . '|' . $arrData->{puffleEnergy} . '|' . $arrData->{puffleRest} . '%';
		}
		return $strPuffle;
}

method getWalkingPuffle($intPengID) {
		my $arrResults = $self->{connection}->db->query('select * from puffles where ownerID = ? and puffleWalking = ?', $intPengID, 1);
		while (my $arrData = $arrResults->hash) {
			return $arrData;
		}
}

method updateWalkingPuffle($blnWalking, $intPuffle, $intOwner) {
		$self->{connection}->db->query('update puffles set puffleWalking = ? where puffleID = ? and ownerID = ?', $blnWalking, $intPuffle, $intOwner);
}

method getNonWalkingPuffles($intPengID) {
		my $strPuffles = $self->{connection}->db->query('select * from puffles where ownerID = ? and puffleWalking = ?', $intPengID, 0)->hashes->map(sub{ 
				$_->{puffleID} . '|' . $_->{puffleName} . '|' . $_->{puffleType} . '|' . $_->{puffleEnergy} . '|' . $_->{puffleHealth} . '|' . $_->{puffleRest}
		})->join('%');
		return $strPuffles;
}

method changeRandPuffStat($intPuffle, $intPengID) {
		my $arrInfo = $self->getPuffleByOwner($intPuffle, $intPengID);
		my $intRandHealth = $self->{child}->{crypt}->generateRandomNumber(1, 10);
		my $intRandEnergy = $self->{child}->{crypt}->generateRandomNumber(1, 10);
		my $intRandRest = $self->{child}->{crypt}->generateRandomNumber(1, 10);
		my $intNewHealth = $arrInfo->{puffleHealth} - $intRandHealth;
		my $intNewEnergy = $arrInfo->{puffleEnergy} - $intRandEnergy;
		my $intNewRest = $arrInfo->{puffleRest} - $intRandRest;
		$self->updatePuffleStatByType('puffleHealth', $intNewHealth, $intPuffle, $intPengID);
		$self->updatePuffleStatByType('puffleEnergy', $intNewEnergy, $intPuffle, $intPengID);
		$self->updatePuffleStatByType('puffleRest', $intNewRest, $intPuffle, $intPengID);
}


method updatePuffleStatByType($strType, $intStat, $intPuffle, $intPengID) {
		$self->{connection}->db->query("update puffles set $strType = ? where puffleID = ? and ownerID = ?", $intStat, $intPuffle, $intPengID);
}

method getPuffleStatByType($strType, $intPuffle, $intPengID) {    
		my $arrResults = $self->{connection}->db->query("select $strType from puffles where puffleID = ? and ownerID = ?", $intPuffle, $intPengID);
		while (my $arrData = $arrResults->hash) {
				return $arrData;
		}
}

method changePuffleStats($intPuffle, $strType, $intCount, $intPengID, $blnInc = 1) {
		my $arrInfo = $self->getPuffleStatByType($strType, $intPuffle, $intPengID);
		my $intStat = $arrInfo->{$strType};
		$blnInc ? ($intStat += $intCount) : ($intStat -= $intCount);
		if ($intStat > 100) {
		   $intStat -= ($intStat - 100);
		} else {
		   $intStat = $intStat;
		}
		$self->updatePuffleStatByType($strType, $intStat, $intPuffle, $intPengID);
}

method updatePuffleStats($intHealth, $intHunger, $intRest, $intPuffle, $intOwner) {
		$self->{connection}->db->query('update puffles set puffleHealth = ?, puffleEnergy =?, puffleRest = ? where puffleID = ? and ownerID = ?', $intHealth, $intHunger, $intRest, $intPuffle, $intOwner);
}

method addPuffle($intPuffType, $strPuffName, $objClient) {
       my $intPuffID = $self->{connection}->db->query('insert into puffles (ownerID, puffleName, puffleType) values (?, ?, ?)', $objClient->{penguin}->{ID}, $strPuffName, $intPuffType)->last_insert_id;
       $self->deductFromWallet(800, $objClient);
       my $strPuffle = $intPuffID . '|' . $strPuffName . '|' . $intPuffType . '|100|100|100';
       return $strPuffle;
}

method sendPostcard($intRecepient, $strMailer = 'sys', $intMailer = 0, $strNotes = 'Cool', $intType = 1, $intTimestamp = time) {
		my $intPostcardID = $self->{connection}->db->query('insert into postcards (recepient, mailerName, mailerID, notes, postcardType, timestamp) values (?, ?, ?, ?, ?, ?)', $intRecepient, $strMailer, $intMailer, $strNotes, $intType, $intTimestamp)->last_insert_id;
		return $intPostcardID;
}

method getInvalidLogins($strUsername) {
		my $arrResults = $self->{connection}->db->query('select `invalid_logins` from kittens where username = ?', $strUsername);
		while (my $arrData = $arrResults->hash) {
			my $intAttempts = $arrData->{invalid_logins};
			return $intAttempts;
		}
}

method updateInvalidLogins($intCount, $strUsername) {
		$self->{connection}->db->query('update kittens set invalid_logins = ? where username = ?', $intCount, $strUsername);
}

method getBannedStatusByUsername($strUsername) {
		my $arrResults = $self->{connection}->db->query('select moderation from kittens where username = ?', $strUsername);
		while (my $mixValue = $arrResults->hash) {
				my $arrData = decode_json($mixValue->{moderation});
				my $mixedBannedStatus = $arrData->{moderation}->{isBanned};
				return $mixedBannedStatus;
		}
}

method updateLastLogin($intPengID, $intTime = time) {
	   $self->{connection}->db->query('update kittens set llg = ? where ID = ?', $intTime, $intPengID);
}

method deletePuffleByOwner($intPuffle, $intOwner) {
		$self->{connection}->db->query('delete from puffles where puffleID = ? and ownerID = ?', $intPuffle, $intOwner);
}

method getUnreadPostcards($intPengID) {
		my $arrResult = $self->{connection}->db->query('select isRead from postcards where recepient = ? and isRead = ?', $intPengID, 0)->hashes;
		my $intUnread = scalar(@{$arrResult});
		return $intUnread;
}

method getReceivedPostcards($intPengID) {
		my $arrResult = $self->{connection}->db->query('select recepient from postcards where recepient = ?', $intPengID)->hashes;
		my $intReceived = scalar(@{$arrResult});
		return $intReceived;
}

method getPostcards($intPengID) {
		my $strCards = $self->{connection}->db->query('select * from postcards where recepient = ?', $intPengID)->hashes;
		my $strPostcards = "";
		foreach (values @{$strCards}) {
			$strPostcards .= $_->{mailerName} . '|' . $_->{mailerID} . '|' . $_->{postcardType} . '|' . $_->{notes} . '|' . $_->{timestamp} . '|' . $_->{postcardID} . '%';
		}
		return substr($strPostcards, 0, -1);
}

method deletePostcardByID($intPostcard, $intPengID) {
		$self->{connection}->db->query('delete from postcards where postcardID = ? and recepient = ?', $intPostcard, $intPengID);
}

method deletePostcardsByMailer($intRecepient, $intSender) {
		$self->{connection}->db->query('delete from postcards where recepient = ? and mailerID = ?', $intRecepient, $intSender);
}

method updatePostcardRead($intPengID) {
		$self->{connection}->db->query('update postcards set isRead = ? where recepient = ?', 1, $intPengID);
}

method checkJoinedIglooContest($intPengID) {
		my $arrContestants  = $self->{connection}->db->query('select * from igloo_contest where ID = ?', $intPengID)->hashes;
		return $arrContestants;
}

method getLastDonations($intPengID) {
		my $arrDoners  = $self->{connection}->db->query('select * from donations where ID = ?', $intPengID)->hashes;
		return $arrDoners;
}

method deleteExistingContestant($intPengID) {
		$self->{connection}->db->query('delete from igloo_contest where `ID` = ?', $intPengID);
}

method signupIglooContest($intPengID, $strPengName) {
		$self->{connection}->db->query('insert into igloo_contest (ID, username) values (?, ?)', $intPengID, $strPengName);
}

method deleteExistingDonation($intPengID) {
		$self->{connection}->db->query('delete from donations where `ID` = ?', $intPengID);
}

method makeCoinDonation($intPengID, $strPengName, $intDonation) {
		$self->{connection}->db->query('insert into donations (ID, username, donation) values (?, ?, ?)', $intPengID, $strPengName, $intDonation);
}

1;
