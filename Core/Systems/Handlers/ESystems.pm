package ESystems;

use strict;
use warnings;

use Method::Signatures;
use HTTP::Date qw(str2time);
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			sig => 'handleSignIglooContest',
			dc => 'handleDonateCoins'
		};
		return $obj;
}

method handleESystems(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleSignIglooContest($strData, $objClient) {
		my $intID = $objClient->{penguin}->{ID};
		my $strUsername = $objClient->{penguin}->{username};
		my $arrContestants = $self->{child}->{mysql}->checkJoinedIglooContest($intID);
		foreach (values @{$arrContestants}) {
			my $intLastSigned = str2time($_->{signup_time});
			my $intTimeDiff = $self->{child}->{crypt}->getTimeDifference($intLastSigned, time, 86400);
			if ($intTimeDiff < 1) { # check if last signed up time is less than 24 hours
				$self->{child}->{mysql}->deleteExistingContestant($intID);
				return $self->{child}->{mysql}->signupIglooContest($intID, $strUsername);
			} else {
				return $objClient->sendError(913);
			}
		}
}

method handleDonateCoins($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intDonation = $arrData[6];
		return if (!looks_like_number($intDonation));
		my $intID = $objClient->{penguin}->{ID};
		my $strUsername = $objClient->{penguin}->{username};
		my $arrDonations = $self->{child}->{mysql}->getLastDonations($intID);	
		foreach my $strDoner (values @{$arrDonations}) {
			my $intLastDonatedTime = str2time($strDoner->{donate_time});
			my $intTimeDiff = $self->{child}->{crypt}->getTimeDifference($intLastDonatedTime, time, 60);
			if ($intTimeDiff == -60) { # check if last donated time is equals to an hour
				if ($intDonation > $objClient->{penguin}->{wallet} ||  $objClient->{penguin}->{wallet} <= 0) {
					return $objClient->sendError(401);
				}
				$self->{child}->{mysql}->deleteExistingDonation($intID);
				$self->{child}->{mysql}->makeCoinDonation($intID, $strUsername, $intDonation);
				$self->{child}->{mysql}->deductFromWallet($intDonation, $objClient);
				my $arrPenguinInfo = $self->{child}->{mysql}->fetchPenguinInfo($objClient->{penguin}->{ID});
				return $objClient->handleLoadPenguinInfo($arrPenguinInfo);
			} else {
				return $objClient->sendError(213);
			}
		}	
}

1;
