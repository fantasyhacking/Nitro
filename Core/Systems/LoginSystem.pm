package LoginSystem;

use strict;
use warnings;

use Method::Signatures;
use Math::Round qw(round);
use Scalar::Util qw(looks_like_number);
use Passwords;
use Digest::SHA qw(sha256_hex);

use constant XML_HANDLERS => {
	    'verChk' => 'handleVersionCheck',                      			                    
		'login' => 'handleGameLogin'
};

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		return $obj;
}

method handleCrossDomainPolicy($objClient) {
		$objClient->sendData("<cross-domain-policy><allow-access-from domain='*' to-ports='" . $self->{child}->{config}->{nitro}->{port}->{value} . "'/></cross-domain-policy>");
}

method handleVersionCheck($strXML, $objClient) {
		return $strXML->{msg}->{body}->{ver}->{v}->{value} == 153 ? $objClient->sendData("<msg t='sys'><body action='apiOK' r='0'></body></msg>") : $objClient->sendData("<msg t='sys'><body action='apiKO' r='0'></body></msg>");
}

method handleGameLogin($strXML, $objClient) {
		if (scalar(keys %{$self->{child}->{sock}->{clients}}) >= 1000) {
			$objClient->sendError(103);
			return $self->handleRemoveClient($objClient->{sock});
		}
		my $strUsername = $strXML->{msg}->{body}->{login}->{nick}->{value};
		my $strPassword = $strXML->{msg}->{body}->{login}->{pword}->{value};
		if ($strUsername !~ /^\w+$/) {
			return $objClient->sendError(100);
		}
		if (length($strPassword) < 64) {
			$objClient->sendError(101);
			return $self->{child}->{sock}->handleRemoveClient($objClient);
		}
		my $blnUsernameExist = $self->{child}->{mysql}->checkUsernameExists($strUsername);
		if (!$blnUsernameExist) {
			return $objClient->sendError(100);
		}
		my $blnIncorrectPass = $self->checkPassword($strUsername, $strPassword);
		if (!$blnIncorrectPass) {
			$objClient->sendError(101);
			my $intAttempts = $self->{child}->{mysql}->getInvalidLogins($strUsername);
			return $self->{child}->{mysql}->updateInvalidLogins(($intAttempts + 1), $strUsername);
		}
		my $intLoginAttempts = $self->{child}->{mysql}->getInvalidLogins($strUsername);
		if ($intLoginAttempts >= 5) {
			return $objClient->sendError(150);
		}
		my $mixBanned = $self->{child}->{mysql}->getBannedStatusByUsername($strUsername);
		if ($mixBanned eq 'PERMANENT') {
			return $objClient->sendError(603);	              
		} elsif (looks_like_number($mixBanned)) {
			if ($mixBanned > time) {
				my $intTime = $self->{child}->{crypt}->getTimeDifference($mixBanned, time, 3600);
				return $objClient->sendError(601 . '%' . $intTime);	
			}              
		}
		if ($self->{child}->{config}->{nitro}->{type}->{value} eq 'game') {
			my $strRandKey = sha256_hex($self->{child}->{crypt}->generateKey(12));
			my $strEncryptedKey = password_hash($strRandKey, PASSWORD_DEFAULT, ('cost' => 12, 'salt' => $self->{child}->{crypt}->generateKey(16)));
			$self->{child}->{mysql}->updateLoginKey($strEncryptedKey, $strUsername);
			$objClient->sendData('%xt%l%-1%' . $self->{child}->{mysql}->getPenguinID($strUsername) . '%' . $strRandKey . '%');
			$objClient->{penguin}->{ID} = $self->{child}->{mysql}->getPenguinID($strUsername);
			$objClient->loadInformation;
			$objClient->handleBuddyOnline;
		}
}

method checkPassword($strUsername, $strPassword) {
	    my $strDBPass = $self->{child}->{mysql}->getPenguinPassword($strUsername);    
	    if (password_verify(uc($strPassword), $strDBPass)) {
			return 1;
		} else {
			return 0;
		}
}

1;
