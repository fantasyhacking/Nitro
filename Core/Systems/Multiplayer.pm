package Multiplayer;

use strict;
use warnings;

use Method::Signatures;
use Math::Round qw(round);
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);
use List::MoreUtils qw(first_index);
use Switch;

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{puck} = '0%0%0%0%';	
		return $obj; 
}

method handleMovePuck($strData, $objClient) {
		my @arrData = split('%', $strData);
		my @arrPuck = splice(@arrData, 5);
		if ($objClient->{penguin}->{room}->{id} == 802) {
			$self->{puck} = join('%', @arrPuck); 
			$objClient->sendRoom('%xt%zm%-1%' . $objClient->{penguin}->{ID} . '%' . $self->{puck});
		}
}

method handleGameOver($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intEarned = $arrData[5];
		if ($intEarned > 99999 || $intEarned < 0) {
			$objClient->sendError(5);
			return $self->{child}->{sock}->handleRemoveClient($objClient->{sock});
		}
		my $intCoins = round(($intEarned / 10));
		$self->{child}->{mysql}->addToWallet($intCoins, $objClient);
}

method leaveTable($objClient) {
		my $tableId = $objClient->{gaming}->{tableID};
		if ($tableId ne 0) {
			my $seatId = $objClient->{gaming}->{seatID};
			my $isPlayer = first_index { $_ eq $objClient} @{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]};
			if ($isPlayer < 2 && !$self->{child}->{gamesys}->{systems}->{Tables}->{gamesByTableId}->{$tableId}->{game_over}) {
				foreach my $objPlayer (values @{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]}) {
					$objPlayer->sendData('%xt%cz%-1%' . $objPlayer->{penguin}->{username} . '%');
				}
			}	
			$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId] = [];
			$self->{child}->{gamesys}->{systems}->{Tables}->{tablePopulationById}->[$tableId] = [];
			$objClient->sendRoom('%xt%ut%-1%' . $tableId . '%' . $seatId . '%');
			$objClient->{gaming}->{tableID} = undef;
			if (scalar(@{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]}) == 0) {
				$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId] = [];
				delete($self->{child}->{gamesys}->{systems}->{Tables}->{gamesByTableId}->{$tableId});
			}
		}
}

method handleStartGame($strData, $objClient) {
		my $tableId = $objClient->{gaming}->{tableID};
		if ($tableId ne 0) {	
			my $seatId = 0;	
			while (my ($intSeat, $objPenguin) = each (%{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->{$tableId}})) {	
				$objPenguin->sendData('%xt%jz%-1%' . $intSeat . '%');
				$seatId = $intSeat;
			}
			if ($seatId < 2) {
				while (my ($intSeat, $objPenguin) = each (%{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->{$tableId}})) {
					$objPenguin->sendData('%xt%uz%-1%' . $intSeat . '%' . $objPenguin->{penguin}->{username} . '%');
				}
				if($seatId == 1) {
					foreach my $objPlayer (values %{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->{$tableId}}) {
						$objPlayer->sendData('%xt%sz%-1%0%');
					}
				}
			}
		}
}

method handleGetGame($strData, $objClient) {
		if ($objClient->{penguin}->{room}->{id} == 802) {
			$objClient->sendData('%xt%gz%-1%' . $self->{puck} . '%');
		} elsif ($objClient->{penguin}->{room}->{id} == 220 || $objClient->{penguin}->{room}->{id} == 221) {
			my $tableId = $objClient->{gaming}->{tableID};
			my @arrUsernames = ();
			foreach my $objPlayer (values %{$self->{child}->{gamesys}->{systems}->{Tables}->{tablePopulationById}->[$tableId]}) {		
				push (@arrUsernames, $objPlayer->{penguin}->{username});
			}
			my ($firstPlayer, $secondPlayer) = @arrUsernames;
			my $boardString = $self->{child}->{gamesys}->{systems}->{Tables}->{gamesByTableId}->{$tableId}->convertToString;	
			$objClient->sendData('%xt%gz%-1%' . $firstPlayer . '%' . ($secondPlayer ? $secondPlayer : '') . '%' . $boardString . '%');
		}
}

method handleSendMove($strData, $objClient) {
		#if ($objClient->{penguin}->{room}->{id} == 220 || $objClient->{penguin}->{room}->{id} == 221) {
			#my @arrData = split('%', $strData);
			#if ($objClient->{gaming}->{tableID} != 0) {
				#my $tableId = $objClient->{gaming}->{tableID};
				#my $isPlayer = first_index { $_ eq $objClient} @{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]};
				#my $gameReady = scalar(keys @{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]});
				#if ($isPlayer < 2 && $gameReady >= 2) {
					#if ($self->{child}->{gamesys}->{systems}->{Tables}->isValidFourTable($tableId)) {
						#my $chipColumn = $arrData[5];
						#my $chipRow = $arrData[6];
						#if (looks_like_number($chipColumn) && looks_like_number($chipRow)) {
							#my $seatId = $objClient->{gaming}->{seatID};
							#my $libID = $seatId + 1;
							#if ($self->{child}->{gamesys}->{systems}->{Tables}->{gamesByTableId}->{$tableId}->{current_player} == $libID) {
								#my $gameStatus = $self->{child}->{gamesys}->{systems}->{Tables}->{gamesByTableId}->{$tableId}->placeChip($chipColumn, $chipRow);
								#foreach my $recepient (values @{$self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]}) {
									#$recepient->sendData('%xt%zm%-1%' . $seatId . '%' . $chipColumn . '%' . $chipRow . '%');
								#}
								#my $opponentSeatId = $seatId == 0 ? 1 : 0;
								#switch ($gameStatus) {
									#case (1) {
										#$self->{child}->{gamesys}->{systems}->{Tables}->{gamesByTableId}->{$tableId}->{game_over} = 1;
										#$self->{child}->{mysql}->addToWallet(10, $objClient);
										#$self->{child}->{mysql}->addToWallet(5, $self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]->[$opponentSeatId]);
									#}
									#case (2) {
										#$self->{child}->{gamesys}->{systems}->{Tables}->{gamesByTableId}->{$tableId}->{game_over} = 1;
										#$self->{child}->{mysql}->addToWallet(10, $objClient);
										#$self->{child}->{mysql}->addToWallet(10, $self->{child}->{gamesys}->{systems}->{Tables}->{playersByTableId}->[$tableId]->[$opponentSeatId]);
									#}
								#}
							#}
						#}
					#} 
				#} 
			#} 
		#} 
}

1;
