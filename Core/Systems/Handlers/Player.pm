package Player;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			sf => 'handleSendFrame',
			se => 'handleSendEmote',
			sq => 'handleSendQuickMessage',
			sa => 'handleSendAction',
			ss => 'handleSendSafeMessage',
			sg => 'handleSendGuideMessage',
			sj => 'handleSendJoke',
			sma => 'handleSendMascotMessage',
			sp => 'handleSendPosition',
			sb => 'handleThrowSnowball',
			glr => 'handleGetLatestRevision',
			gp => 'handleGetPlayer',
			h => 'handleHeartbeat'
		};
		return $obj;
}

method handlePlayerPackets(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleSendFrame($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intFrame = $arrData[5];
		return if (!looks_like_number($intFrame));
		$objClient->sendRoom('%xt%sf%-1%' . $objClient->{penguin}->{ID} . '%' . $intFrame . '%');
		$objClient->{penguin}->{room}->{frame} = $intFrame;
}

method handleSendEmote($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intEmote = $arrData[5];
		return if (!looks_like_number($intEmote));
		$objClient->sendRoom('%xt%se%-1%' . $objClient->{penguin}->{ID} . '%' . $intEmote . '%');
}

method handleSendQuickMessage($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intMessageID = $arrData[5];
		return if (!looks_like_number($intMessageID));
		$objClient->sendRoom('%xt%sq%-1%' . $objClient->{penguin}->{ID} . '%' . $intMessageID . '%');
}

method handleSendAction($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intAction = $arrData[5];
		return if (!looks_like_number($intAction));
		$objClient->sendRoom('%xt%sa%-1%' . $objClient->{penguin}->{ID} . '%' . $intAction . '%');
}

method handleSendSafeMessage($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intMessageID = $arrData[5];
		return if (!looks_like_number($intMessageID));
		$objClient->sendRoom('%xt%ss%-1%' . $objClient->{penguin}->{ID} . '%' . $intMessageID . '%');
}

method handleSendGuideMessage($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intMessageID = $arrData[5];
		return if (!looks_like_number($intMessageID));
		$objClient->sendRoom('%xt%sg%-1%' . $objClient->{penguin}->{ID} . '%' . $intMessageID . '%');
}

method handleSendJoke($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intJoke = $arrData[5];
		return if (!looks_like_number($intJoke));
		$objClient->sendRoom('%xt%sj%-1%' . $objClient->{penguin}->{ID} . '%' . $intJoke . '%');
}

method handleSendMascotMessage($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intMessageID = $arrData[5];
		return if (!looks_like_number($intMessageID));
		$objClient->sendRoom('%xt%sma%-1%' . $objClient->{penguin}->{ID} . '%' . $intMessageID . '%');
}

method handleSendPosition($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intX = $arrData[5];
		my $intY = $arrData[6];
		return if (!looks_like_number($intX));
		return if (!looks_like_number($intY));
		$objClient->sendRoom('%xt%sp%-1%' . $objClient->{penguin}->{ID} . '%' . $intX . '%' . $intY . '%');
		$objClient->{penguin}->{room}->{xpos} = $intX;
		$objClient->{penguin}->{room}->{ypos} = $intY;
}

method handleThrowSnowball($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intX = $arrData[5];
		my $intY = $arrData[6];
		return if (!looks_like_number($intX));
		return if (!looks_like_number($intY));
		$objClient->sendRoom('%xt%sb%-1%' . $objClient->{penguin}->{ID} . '%' . $intX . '%' . $intY . '%');
}

method handleGetLatestRevision($strData, $objClient) {
		$objClient->sendXT(['glr', '-1', 3555]);
}

method handleGetPlayer($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPID = $arrData[5];
		return if (!looks_like_number($intPID));
		my $strDetails = $self->{child}->{mysql}->getPlayerDetails($intPID);
		$objClient->sendData('%xt%gp%-1%' .($strDetails ? $strDetails : '') . '%');
}

method handleHeartbeat($strData, $objClient) {
		if ($objClient->{lastHeartbeat} > time) { #heartbeat spam protection
			return $self->{child}->{sock}->handleRemoveClient($objClient->{sock});	
		}
		$objClient->sendXT(['h', '-1']);
		$objClient->{lastHeartbeat} = time + 20.3;
}

1;
