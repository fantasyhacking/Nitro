package StaffButtons;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			k => 'handleKickButton',
			m => 'handleMuteButton',
			b => 'handleBanButton'
		};
		return $obj;
}


method handleStaffButtons(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleKickButton($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intID = $arrData[5];
		return if (!looks_like_number($intID));
		my $objPlayer = $objClient->getClientByID($intID);
		return if ($objPlayer->{penguin}->{ranking}->{rank} > 4);
		if ($objClient->{penguin}->{ranking}->{isStaff}) {
			$objPlayer->sendError(5);
			$self->{child}->{sock}->handleRemoveClient($objPlayer->{sock});
		}
}

method handleMuteButton($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intID = $arrData[5];
		return if (!looks_like_number($intID));
		my $objPlayer = $objClient->getClientByID($intID);
		return if ($objPlayer->{penguin}->{ranking}->{rank} > 3);
		if ($objClient->{penguin}->{ranking}->{isStaff}) {
			if (!$objPlayer->{penguin}->{moderation}->{isMuted}) {
				$self->{child}->{mysql}->updateModerationInfo($objPlayer, 'isMuted', 1);
			} elsif ($objPlayer->{penguin}->{moderation}->{isMuted}) {
				$self->{child}->{mysql}->updateModerationInfo($objPlayer, 'isMuted', 0);
			}
		}
}

method handleBanButton($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intID = $arrData[5];
		return if (!looks_like_number($intID));
		my $objPlayer = $objClient->getClientByID($intID);
		return if ($objPlayer->{penguin}->{ranking}->{rank} > 4);
		if ($objClient->{penguin}->{ranking}->{isStaff}) {
			if ($objPlayer->{penguin}->{moderation}->{isBanned} eq '') {
				$self->{child}->{mysql}->updateModerationInfo($objPlayer, 'isBanned', 'PERMANENT');
				$objPlayer->sendError(603);
				$self->{child}->{sock}->handleRemoveClient($objPlayer->{sock});
			}
		}
}

1;
