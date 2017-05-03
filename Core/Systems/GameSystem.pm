package GameSystem;

use strict;
use warnings;

use Method::Signatures;
use File::Basename;

use constant NORMAL_HANDLERS => {
	j => 'handleNavigation',
	b => 'handleBuddies',
	f => 'handleEPF',
	g => 'handleIgloo',
	n => 'handleNeglected',
	i => 'handleInventory',
	m => 'handleConversation',
	r => 'handleCoinDigging',
	o => 'handleStaffButtons',
	p => 'handlePuffles',
	u => 'handlePlayerPackets',
	l => 'handlePostcards',
	s => 'handlePenguinClothing',
	st => 'handleStamps',
	t => 'handleNewsPaper',
	ni => 'handleNinjas',
	a => 'handleTables',
	w => 'handleWaddles',
	e => 'handleESystems'
};

use constant GAME_HANDLERS => {
	zo => 'handleGameOver',
	m => 'handleMovePuck',
	gz => 'handleGetGame',
	jz => 'handleStartGame',
	lz => 'handleQuitGame',
	zm => 'handleSendMove',
	gw => 'handleGetWaddlesPopulationById',
	jw => 'handleSendJoinWaddleById',
	lw => 'handleLeaveWaddle',
};

=pod


'ni#gnr' => 'handleGetNinjaRanks',
'ni#gnl' => 'handleGetNinjaLevel',
'ni#gcd' => 'handleGetCards',
'ni#gfl' => 'handleGetFireLevel',
'ni#gwl' => 'handleGetWaterLevel',
'ni#gsl' => 'handleGetSnowLevel',

=cut

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->handleLoadSystems;
		$obj->{igloos} = {};
		return $obj;
}

method handleLoadSystems() {
		my $resHandle;
		opendir($resHandle, "Core/Systems/Handlers/");
		my @arrFileNames = grep(/\.pm$/, readdir($resHandle));
		closedir($resHandle);
		foreach my $strFile (@arrFileNames) {
			my $strSysName = basename($strFile, '.pm');
		    my $objSystem = $strSysName->new($self->{child});
			$self->{systems}->{$strSysName} = $objSystem;
		}
}

method handleStandardPackets($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $strPacket = $arrData[3];
		if (index($strData, '|') != -1 && $strPacket ne 'g#ur' && $strPacket ne 'm#sm' && $strPacket ne 'st#ssbcd') {
			return $self->{child}->{sock}->handleRemoveClient($objClient->{sock});
		}
		my @arrPacket = split('#', $strPacket);
		my $charHandle = $arrPacket[0];
		return if (!exists(NORMAL_HANDLERS->{$charHandle}));
		my $strSysHandler = NORMAL_HANDLERS->{$charHandle};
		map {
			if ($_->can($strSysHandler) && $objClient->{penguin}->{username} ne "" && defined($objClient->{penguin}->{username})) {
				$objClient->{lastPacketTime} = time;
				$self->{child}->{spamsys}->handlePacketSpam($strData, $objClient);
				$_->$strSysHandler([$arrPacket[1], $strData], $objClient);
		    }
		} values %{$self->{systems}};
}

method handleGamePackets($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $strPacket = $arrData[3];
		return if (!exists(GAME_HANDLERS->{$strPacket}));
		my $strSysHandler = GAME_HANDLERS->{$strPacket};
		if ($self->{child}->{multiplayer}->can($strSysHandler)) {
			$self->{child}->{multiplayer}->$strSysHandler($strData, $objClient);
		}
}

1;
