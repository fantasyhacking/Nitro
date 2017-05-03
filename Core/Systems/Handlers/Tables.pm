package Tables;

use strict;

use Method::Signatures;
use List::Util qw(first);
use Scalar::Util qw(looks_like_number);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			jt => 'handleJoinTable',
			gt => 'handleGetTables',
			lt => 'handleLeaveTable'
		};
		$obj->{tablePopulationById} = {};
		$obj->{playersByTableId} = {};
		$obj->{gamesByTableId} = {};
		$obj->{four_rooms} = [220, 221];
		$obj->{four_tables} = [200..207];
		$obj->{mancala_room} = 111;
		$obj->{mancala_tables} = [100..104];
		return $obj;
}

method handleTables(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method isValidFourRoom($intRoom) {
		my $blnValid = 0;
		if (first {$_ == $intRoom} @{$self->{four_rooms}}) {
			$blnValid = 1;
		} else {
			$blnValid = 0;
		}
		return $blnValid;
}

method isValidFourTable($intTable) {
		my $blnValid = 0;
		if (first {$_ == $intTable} @{$self->{four_tables}}) {
			$blnValid = 1;
		} else {
			$blnValid = 0;
		}
		return $blnValid;
}

method isValidMancalaTable($intTable) {
		my $blnValid = 0;
		if (first {$_ == $intTable} @{$self->{mancala_tables}}) {
			$blnValid = 1;
		} else {
			$blnValid = 0;
		}
		return $blnValid;
}

method handleGetTables($strData, $objClient) {
		my @arrData = split('%', $strData);
		my @tableIds = splice(@arrData, 5);
		my $intRoom = $objClient->{penguin}->{room}->{id};
		if ($self->isValidFourRoom($intRoom) || $self->{mancala_room} == $intRoom) {
			my $tablePopulation = "";		
			foreach my $intTable (@tableIds) {
				if (looks_like_number($intTable) && $self->isValidFourTable($intTable) && $self->isValidMancalaTable($intTable)) {
					if ($self->{tablePopulationById}->{$intTable}) {
						$tablePopulation .= sprintf("%d|%d", $intTable, scalar(keys %{$self->{tablePopulationById}->{$intTable}}));
						$tablePopulation .= "%";
					}
				}
			}		
			$objClient->sendData('%xt%gt%-1%' . $tablePopulation);
		} 
} 

method handleJoinTable($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intTable = $arrData[5];
		my $intRoom = $objClient->{penguin}->{room}->{id};
		if ($self->isValidFourRoom($intRoom) || $self->{mancala_room} == $intRoom) {
			if (looks_like_number($intTable) && $self->isValidFourTable($intTable)) {
				my $seatId = scalar(keys %{$self->{tablePopulationById}->{$intTable}});
				if ($self->{gamesByTableId}->{$intTable} == 0) {
					my $findFourGame = FourSystem->new($self);
					$self->{gamesByTableId}->{$intTable} = $findFourGame;
				}
				$seatId += 1;
				$objClient->sendData('%xt%jt%-1%' . $intTable . '%' . $seatId . '%');
				$objClient->sendRoom('%xt%ut%-1%' . $intTable . '%' . $seatId . '%');
				$self->{tablePopulationById}->{$intTable} = [$seatId => $objClient];
				$self->{playersByTableId}->{$intTable} = [$seatId => $objClient];	
				$objClient->{gaming}->{tableID} = $intTable;
			} # elsif (looks_like_number($intTable) && $self->isValidMancalaTable($intTable)) {
				##my $seatId = scalar(keys @{$self->{tablePopulationById}->[$intTable]});
				#if ($self->{gamesByTableId}->{$intTable} == 0) {
					#my $mancalaGame = MancalaSystem->new($self);
					#$self->{gamesByTableId}->{$intTable} = $mancalaGame;
				#}
				##push (@{$self->{tablePopulationById}->[$intTable]}, $objClient);
				##$seatId += 1;
				##$objClient->sendData('%xt%jt%-1%' . $intTable . '%' . $seatId . '%');
				##$objClient->sendRoom('%xt%ut%-1%' . $intTable . '%' . $seatId . '%');
				##push (@{$self->{playersByTableId}->[$intTable]}, $objClient);	
				##$objClient->{gaming}->{seatID} = $seatId;
				##$objClient->{gaming}->{tableID} = $intTable;
			#}
		}
}

method handleLeaveTable($strData, $objClient) {
		$self->{child}->{multiplayer}->leaveTable($objClient);
}


1;
