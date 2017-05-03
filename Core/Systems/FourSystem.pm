package FourSystem;

use strict;

use Method::Signatures;
use List::Util qw(first);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{placement_types} = {
			InvalidChipPlacement => 1, 
			ChipPlaced => 0,
			FoundFour => 1,
			Tie => 2,
			FourNotFound => 3
		};
		$obj->{board_map} = [[0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0]];
		$obj->{current_player} = 1;
		$obj->{game_over} = 0;
		return $obj;
}

method convertToString {
		return join(',', map { join(',', values @{$self->{board_map}->[$_]}); } keys @{$self->{board_map}});
}

method changePlayer {
		if ($self->{current_player} == 1) {
		    $self->{current_player} = 2; 
		} else {
			$self->{current_player} = 1; 
	    }
}

method validChipPlacement($column, $row) {
		if ($self->{board_map}->[$row]->[$column] != 0) {
			return 0;
		}
		return 1;
}

method isBoardFull {
		foreach my $intRow (keys @{$self->{board_map}}) {
			if ($intRow == 0) {
				return 0;
			}
		}
		return 1;
}

method determineColumnWin($column) {
		my $current_player = $self->{current_player};
		my $intStreak = 0;
		foreach my $intRow (@{$self->{board_map}}) {
			if (@$intRow[$column] == $current_player) {
				$intStreak++;
				if($intStreak == 4) {
					return $self->{placement_types}->{FoundFour};
				}
			} else {
				$intStreak = 0;
			}
		}
		return $self->{placement_types}->{FourNotFound};
}

method determineVerticalWin {
		my $intRows = scalar(keys @{$self->{board_map}});
		for (my $intColumn = 0; $intColumn < $intRows; $intColumn++) {
			my $foundFour = $self->determineColumnWin($intColumn);
			if($foundFour == $self->{placement_types}->{FoundFour}) {
				return $foundFour;
			}
		}
		return $self->{placement_types}->{FourNotFound};
}

method determineHorizontalWin {
		my $current_player = $self->{current_player};
		my $intRows = scalar(keys @{$self->{board_map}});
		my $intStreak = 0;
		for(my $intRow = 0; $intRow < $intRows; $intRow++) {
			my $intColumns = scalar(keys @{$self->{board_map}->[$intRow]});
			for (my $intColumn = 0; $intColumn < $intColumns; $intColumn++) {
				if ($self->{board_map}->[$intRow]->[$intColumn] == $current_player) {
					$intStreak++;
					if($intStreak == 4) {
						return $self->{placement_types}->{FoundFour};
					}
				} else {
					$intStreak = 0;
				}
			}
		}
		return $self->{placement_types}->{FourNotFound};
}

method determineDiagonalWin {
		my $current_player = $self->{current_player};
		my $rows = scalar(keys @{$self->{board_map}});
		my $streak = 0;
		for (my $row = 0; $row < $rows; $row++) {
			my $columns = scalar(keys @{$self->{board_map}->[$row]});
			for (my $column = 0; $column < $columns; $column++) {
				if ($self->{board_map}->[$row]->[$column] == $current_player) {
					if ($self->{board_map}->[$row + 1]->[$column + 1] == $current_player && $self->{board_map}->[$row + 2]->[$column + 2] == $current_player && $self->{board_map}->[$row + 3]->[$column + 3] == $current_player) {
						return $self->{placement_types}->{FoundFour};
					} elsif ($self->{board_map}->[$row - 1]->[$column + 1] == $current_player && $self->{board_map}->[$row - 2]->[$column + 2] == $current_player && $self->{board_map}->[$row - 3]->[$column + 3] == $current_player) {	
						return $self->{placement_types}->{FoundFour};
					} elsif ($self->{board_map}->[$row - 1]->[$column - 1] == $current_player && $self->{board_map}->[$row - 2]->[$column - 2] == $current_player && $self->{board_map}->[$row - 3]->[$column - 3] == $current_player) {
						return $self->{placement_types}->{FoundFour};
					}
				}
			}
		}
		return $self->{placement_types}->{FourNotFound};
}

method processBoard {
		my $fullBoard = $self->isBoardFull;
		if ($fullBoard == 1) {
			return $self->{placement_types}->{Tie};
		}
		my $horizontalWin = $self->determineHorizontalWin;
		if ($horizontalWin == $self->{placement_types}->{FoundFour}) {
			return $horizontalWin;
		}
		my $verticalWin = $self->determineVerticalWin;
		if ($verticalWin == $self->{placement_types}->{FoundFour}) {
			return $verticalWin;
		}
		my $diagonalWin = $self->determineDiagonalWin;
		if ($diagonalWin == $self->{placement_types}->{FoundFour}) {
			return $diagonalWin;
		}
		return $self->{placement_types}->{ChipPlaced};
}

method placeChip($column, $row) {
		if ($self->validChipPlacement($column, $row)) {
			$self->{board_map}->[$row]->[$column] = $self->{current_player};
			my $gameStatus = $self->processBoard;
			if ($gameStatus == $self->{placement_types}->{ChipPlaced}) {
				$self->changePlayer;
			}
			return $gameStatus;
		} else {
			return $self->{placement_types}->{InvalidChipPlacement};
		}
}


1;
