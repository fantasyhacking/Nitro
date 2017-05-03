package MancalaSystem;

use strict;

use Method::Signatures;
use List::Util qw(first sum);
use List::MoreUtils qw(any);
use Data::Dumper;
use v5.10;

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{placement_types} = {
			InvalidHollow => '-1', 
			MoveComplete => 0,
			Won => 1,
			Tie => 2,
			NoSidesEmpty => 3,
			FreeTurn => 'f',
			Capture => 'c'
		};
		$obj->{board_map} = [4, 4, 4, 4, 4, 4, 0, 4, 4, 4, 4, 4, 4, 0];
		$obj->{current_player} = 1;
		$obj->{winner} = 0;
		$obj->{game_over} = 0;
		return $obj;
}

method convertToString() {
		return join(',', @{$self->{board_map}});
}

method changePlayer() {
		if ($self->{current_player} == 1) {
		    $self->{current_player} = 2; 
		} else {
			$self->{current_player} = 1; 
	    }
}

method validMove($hollow) {
		my $firstHollowCheck = any {$_ == $hollow} 0..5;
		my $secondHollowCheck = any {$_ == $hollow} 7..12;
		if ($self->{current_player} == 1 && $firstHollowCheck == 0) {
			return 0;
		}
		if ($self->{current_player} == 2 && $secondHollowCheck == 0) {
			return 0;
		}
		return 1;
}

method determineTie {
		if (sum(splice(@{$self->{board_map}}, 0, 6)) == 0 || sum(splice(@{$self->{board_map}}, 7, 6)) == 0) {
			if (sum(splice(@{$self->{board_map}}, 0, 6)) == sum(splice(@{$self->{board_map}}, 7, 6))) {
				return $self->{placement_types}->{Tie};
			}
		} else {
			return $self->{placement_types}->{NoSidesEmpty};
		}
}

method determineWin {
		if (sum(splice(@{$self->{board_map}}, 0, 6)) == 0 || sum(splice(@{$self->{board_map}}, 7, 6)) == 0) {
			if (sum(splice(@{$self->{board_map}}, 0, 6)) > sum(splice(@{$self->{board_map}}, 7, 6))) {
				$self->{winner} = 1;
			} else {
				$self->{winner} = 2;
			}
			return $self->{placement_types}->{Won};
		} else {
			return $self->{placement_types}->{NoSidesEmpty};
		}
}

method processBoard {
		my $tie = $self->determineTie;
		if ($tie == $self->{placement_types}->{Tie}) {
			return $tie;
		}
		my $win = $self->determineWin;
		if ($win == $self->{placement_types}->{Won}) {
			return $win;
		}
		return $self->{placement_types}->{MoveComplete};
}

method makeMove($hollow) {
		if ($self->validMove($hollow)) {
			my $capture = 0;
			my $hand = $self->{board_map}->[$hollow];
			$self->{board_map}->[$hollow] = 0;
			while ($hand > 0) {
				$hollow++;
				my $checkHollowExist = first {$ == $hollow} @{$self->{board_map}};
				if ($checkHollowExist == 0) {
					$hollow = 0;
				}
				my $myMancala = ($self->{current_player} == 1 ? 6 : 13);
				my $opponentMancala = ($self->{current_player} == 1 ? 13 : 6);			
				if ($hollow == $opponentMancala) {
					continue;
				}
				my $oppositeHollow = 12 - $hollow;
				if ($self->{current_player} == 1 && any {$_ == $hollow} 0..5 && $hand == 1 && $self->{board_map}->[$hollow] == 0) {
					$self->{board_map}->[$myMancala] += ($self->{board_map}->[$oppositeHollow] + 1);
					$self->{board_map}->[$oppositeHollow] = 0;
					$capture = 1;
					last;
				}
				if ($self->{current_player} == 2 && any {$_ == $hollow} 7..12 && $hand == 1 && $self->{board_map}->[$hollow] == 0) {
					$self->{board_map}->[$myMancala] += ($self->{board_map}->[$oppositeHollow] + 1);
					$self->{board_map}->[$oppositeHollow] = 0;
					$capture = 1;
					last;
				}
				$self->{board_map}->[$hollow]++;
				$hand--;
			}
			my $gameStatus = $self->processBoard;
			if ($gameStatus == $self->{placement_types}->{MoveComplete}) {
				if (($self->{current_player} == 1 && $hollow != 6) || ($self->{current_player} == 2 && $hollow != 13)) {
					$self->changePlayer;
					if ($capture) {
						return $self->{placement_types}->{Capture};
					}
				} else {
					return $self->{placement_types}->{FreeTurn};
				}
			}
			return $gameStatus;
		} else {
			return $self->{placement_types}->{InvalidHollow};
		}
}


1;
