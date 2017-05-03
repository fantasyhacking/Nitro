package Socket;

use strict;
use warnings;

use Method::Signatures;
use IO::Socket::INET;
use IO::Select;
use Switch;

method new($resChild) {
       my $obj = bless {}, $self;
       $obj->{child} = $resChild;
       $obj->{jobStamp} = 0;
       $obj->{clients} = {};
       $obj->{iplogger} = {};
       $obj->{handles} = {s => 'handleStandardPackets', z => 'handleGamePackets'};
       return $obj;
}

method createSocket($intPort) {
       $self->{socket} = IO::Socket::INET->new(LocalAddr => 0, LocalPort => $intPort, Proto => 0, Listen => SOMAXCONN, ReuseAddr => 1, Blocking => 0);
       $self->{listener} = IO::Select->new($self->{socket});
}

method handleListen() {
		my @arrSocks = $self->{listener}->can_read(0);
		foreach (@arrSocks) {
			if ($_ == $self->{socket}) {
				$self->handleAddClient;
				next;
			}
			eval {
				my $objClient = $self->getClientBySock($_);              
				my $strBuffer;
				my $intBytes = $_->sysread($strBuffer, 65536);
				return if (not defined $intBytes);
				if ($intBytes == 0) {
					return $self->handleRemoveClient($objClient->{sock});
				}                        
				$self->handleData($strBuffer, $objClient);    
			};
			$self->{child}->{logger}->fatal($@) if ($@);
		}
}

method handleAddClient {
		my $resSocket = $self->{socket}->accept;
		$self->{listener}->add($resSocket);
		my $intKey = fileno($resSocket);
		my $objClient = Client->new($self->{child}, $resSocket);
		my $strIP = $self->getClientIPAddr($resSocket);
		$self->{clients}->{$intKey} = $objClient;
		$objClient->{penguin}->{ipAddress} = $strIP;
        $self->{iplogger}->{$strIP} = ($self->{iplogger}->{$strIP}) ? $self->{iplogger}->{$strIP} + 1 : 1;
		if (exists($self->{iplogger}->{$strIP}) && $self->{iplogger}->{$strIP} > 3) {
			return $self->handleRemoveClient($resSocket);
		} 
}

method getClientIPAddr($resSock) {
       my $strAddr = $resSock->peeraddr;
       my $strIP = inet_ntoa($strAddr);
       return $strIP;
}

method handleRemoveClient($resSocket) {
		map {
			if (exists($self->{clients}->{$_})) {
				if ($self->{clients}->{$_}->{sock} == $resSocket) {
					$self->{listener}->remove($resSocket);
					$resSocket->close;
					delete($self->{clients}->{$_});
				}
			}
		} keys %{$self->{clients}};
}

method handleData($strData, $objClient) {
		my @arrData = split(chr(0), $strData);
		foreach (@arrData) {     
			$self->{child}->{logger}->debug("Incoming data: $_") unless (!$self->{child}->{config}->{nitro}->{debug}->{value}); 
			my $chrType = substr($_, 0, 1);
			switch ($chrType) {                    
					case ('<') {
						$self->handleXMLData($_, $objClient);
					}
					case ('%') {
						$self->handleXTData($_, $objClient);
					}
					else {
						$self->handleRemoveClient($objClient->{sock});
					}
			}
		}
}

method handleXMLData($strData, $objClient) {
		if ($strData eq '<policy-file-request/>') {
			return $self->{child}->{loginsys}->handleCrossDomainPolicy($objClient);
		}	
		my $strXML = $self->{child}->parseXML('text', $strData);
		if (!$strXML) {
			return $self->handleRemoveClient($objClient->{sock});
		}
		if ($strXML->{msg}->{t}->{value} eq 'sys') {
			my $strAction = $strXML->{msg}->{body}->{action}->{value};
			return if (!exists($self->{child}->{loginsys}->XML_HANDLERS->{$strAction}));
			my $strHandler = $self->{child}->{loginsys}->XML_HANDLERS->{$strAction};
			if ($self->{child}->{loginsys}->can($strHandler)) {
				$self->{child}->{loginsys}->$strHandler($strXML, $objClient);
			}
		}
}

method handleXTData($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $charStandardHandler = $arrData[2];
		return if (!exists($self->{handles}->{$charStandardHandler}));
		my $strHandler = $self->{handles}->{$charStandardHandler};
		if ($self->{child}->{gamesys}->can($strHandler)) {
			$self->{child}->{gamesys}->$strHandler($strData, $objClient);
		}
}

method getClientBySock($resSock) {
		foreach my $objPenguin (values %{$self->{clients}}) {
			if ($objPenguin->{sock} == $resSock) {
				return $objPenguin;
			}
		}
}

1;
