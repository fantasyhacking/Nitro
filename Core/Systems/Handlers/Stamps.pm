package Stamps;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			sse => 'handleSendStampEarned',
			gps => 'handleGetPlayersStamps',
			gmres => 'handleGetMyRecentlyEarnedStamps',
			gsbcd => 'handleGetStampBookCoverDetails',
			ssbcd => 'handleSetStampBookCoverDetails'
		};
		return $obj;
}

method handleStamps(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleSendStampEarned($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intStamp = $arrData[5];
		return if (!looks_like_number($intStamp));
		return if (!exists($self->{child}->{crumbs}->{stamp_crumbs}->{$intStamp}));
		return if (first {$_ == $intStamp} @{$self->{stamps}});
		push(@{$objClient->{stampbook}->{stamps}}, $intStamp);
		push(@{$objClient->{stampbook}->{restamps}}, $intStamp);
		my $strStamps = join('|', @{$objClient->{stampbook}->{stamps}});
		my $strRestamps = join('|', @{$objClient->{stampbook}->{restamps}});
		$self->{child}->{mysql}->updateStamps($strStamps, $strRestamps, $objClient->{penguin}->{ID});
		$objClient->sendXT(['aabs', '-1', $intStamp]);
}

method handleGetPlayersStamps($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intID = $arrData[5];
		return if (!looks_like_number($intID));
		my $strStamps = $self->{child}->{mysql}->getStampsByID($intID);
		$objClient->sendXT(['gps', '-1', $intID, $strStamps]);
}

method handleGetMyRecentlyEarnedStamps($strData, $objClient) {
		my $strStamps = join('|', @{$objClient->{stampbook}->{stamps}});
		my $strRestamps = join('|', @{$objClient->{stampbook}->{restamps}});
		$objClient->sendXT(['gmres', '-1', $strRestamps]);
		$self->{child}->{mysql}->updateStamps($strStamps, "", $objClient->{penguin}->{ID});
}

method handleGetStampBookCoverDetails($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intID = $arrData[5];
		return if (!looks_like_number($intID));
		my $strCover = $self->{child}->{mysql}->getStampbookCoverByID($intID);
		$objClient->sendData('%xt%gsbcd%-1%' . ($strCover ? $strCover : '1%1%1%1%'));		
}

method handleSetStampBookCoverDetails($strData, $objClient) {
		my @arrData = split('%', $strData);
		my @arrCover = ();
		foreach my $intData (keys @arrData) {
			if ($intData > 4) {
				push(@arrCover, $arrData[$intData]);
			}
		}
		my $strCover = join('%', @arrCover);
		$self->{child}->{mysql}->updateStampbookCover($strCover, $objClient->{penguin}->{ID});
		$objClient->sendData('%xt%ssbcd%-1%' . ($strCover ? $strCover : '%'));
}

1;
