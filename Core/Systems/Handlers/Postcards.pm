package Postcards;

use strict;
use warnings;

use Method::Signatures;
use HTML::Entities;
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			mst => 'handleMailStart',
			mg => 'handleMailGet',
			ms => 'handleMailSend',
			md => 'handleMailDelete',
			mdp => 'handleMailDeletePlayer',
			mc => 'handleMailChecked'
		};
		return $obj;
}

method handlePostcards(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleMailStart($strData, $objClient) {
		my $intUnread = $self->{child}->{mysql}->getUnreadPostcards($objClient->{penguin}->{ID});
		my $intPostcards =  $self->{child}->{mysql}->getReceivedPostcards($objClient->{penguin}->{ID});
		$objClient->sendXT(['mst', '-1', $intUnread, $intPostcards]);
}

method handleMailGet($strData, $objClient) {
		my $strCards = $self->{child}->{mysql}->getPostcards($objClient->{penguin}->{ID});
		$objClient->sendData('%xt%mg%-1%' . $strCards . '%');
}

method handleMailSend($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $recepientID = $arrData[5];
		my $postcardType = $arrData[6];
		my $postcardNotes = decode_entities(($arrData[7] ? $arrData[7] : ''));
		return if (!looks_like_number($recepientID) || !looks_like_number($postcardType) || !defined($postcardNotes));
		return if (!exists($self->{child}->{crumbs}->{mail_crumbs}->{$postcardType}));
		if ($objClient->{penguin}->{wallet} < 10) {
		   $objClient->sendXT(['ms', '-1', $objClient->{penguin}->{wallet}, 2]);
		} else {
		   my $objPlayer = $objClient->getClientByID($recepientID);
		   my $timestamp = time;
		   my $postcardID = $self->{child}->{mysql}->sendPostcard($recepientID, $objClient->{penguin}->{username}, $objClient->{penguin}->{ID}, $postcardNotes, $postcardType, $timestamp);
		   if ($objClient->getOnline($recepientID)) {
			   $objPlayer->sendData('%xt%mr%-1%' . $objClient->{penguin}->{username} . '%' . $objClient->{penguin}->{ID} . '%' . $postcardType . '%%' . $timestamp . '%' . $postcardID . '%');
			   $objClient->sendXT(['ms', '-1', $objClient->{penguin}->{wallet}, 1]);
		   } else {
			   $objClient->sendXT(['ms', '-1', $objClient->{penguin}->{wallet}, 1]);
		   }
		   $self->{child}->{mysql}->deductFromWallet(10, $objClient);
		}
}

method handleMailDelete($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPostcard = $arrData[5];
		return if (!looks_like_number($intPostcard));
		$self->{child}->{mysql}->deletePostcardByID($intPostcard, $objClient->{penguin}->{ID});
		$objClient->sendXT(['md', '-1', $intPostcard]);
}

method handleMailDeletePlayer($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intPengID = $arrData[5];
		return if (!looks_like_number($intPengID));
		$self->{child}->{mysql}->deletePostcardsByMailer($objClient->{penguin}->{ID}, $intPengID);
		my $intCount = $self->{child}->{mysql}->getReceivedPostcards($objClient->{penguin}->{ID});
		$objClient->sendXT(['mdp', '-1', $intCount]);
}

method handleMailChecked($strData, $objClient) {
		$self->{child}->{mysql}->updatePostcardRead($objClient->{penguin}->{ID});
		$objClient->sendXT(['mc', '-1', 1]);
}

1;
