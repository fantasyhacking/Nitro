package SpamSystem;

use strict;
use warnings;

use Method::Signatures;
use List::Util qw(any);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{clients} = {};
		$obj->{spam_list} = [
			'u#sp', 's#upc', 's#uph', 's#upf', 's#upn', 
			's#upb', 's#upa', 's#upe', 's#upp', 's#upl', 
			'l#ms', 'b#br', 'j#jr', 'u#se', 'u#sa', 'u#sg',
			'u#sma', 'u#sb', 'u#gp',  'u#ss', 'u#sq', 
			'u#sj', 'u#sl', 'u#sg', 'm#sm', 'u#sf'
		];
		return $obj;
}

method handlePacketSpam($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $strPacket = $arrData[3];
		if (any {$_ eq $strPacket} @{$self->{spam_list}}) {
			if (!exists($self->{clients}->{$objClient->{penguin}->{ID}})) {
				$self->{clients}->{$objClient->{penguin}->{ID}} = {$strPacket => 0};
			} else {
				my $currTime = time;
				my $intStamp = $currTime;
				if (!$objClient->{lastPacket}->{$strPacket}) {
					$objClient->{lastPacket}->{$strPacket} = $intStamp;
				}
				if ($objClient->{lastPacket}->{$strPacket} > ($currTime - 6)) {
					if (!exists($self->{clients}->{$objClient->{penguin}->{ID}}->{$strPacket})) {
						$self->{clients}->{$objClient->{penguin}->{ID}}->{$strPacket} = 1;
					} elsif ($self->{clients}->{$objClient->{penguin}->{ID}}->{$strPacket} < 10) {
						$self->{clients}->{$objClient->{penguin}->{ID}}->{$strPacket} += 1;
					} elsif ($self->{clients}->{$objClient->{penguin}->{ID}}->{$strPacket} >= 10) {
						delete($self->{clients}->{$objClient->{penguin}->{ID}});
						return $self->{child}->{sock}->handleRemoveClient($objClient->{sock});	
					}
				} else {
					$self->{clients}->{$objClient->{penguin}->{ID}}->{$strPacket} = 1;
				}
				$objClient->{lastPacket}->{$strPacket} = $intStamp;
			}
		}
				
}

1;
