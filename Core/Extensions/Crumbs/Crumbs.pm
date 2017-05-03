package Crumbs; #rewrite this shit

use strict;
use warnings;

use Method::Signatures; 
use JSON qw(decode_json);
use File::Basename;
use File::Slurp;
use Cwd;

method new($resChild) {
       my $obj = bless {}, $self;
       $obj->{child} = $resChild;
	   $obj->{jsons} =  {
               items => 'paper_items.json',
               igloos => 'igloos.json',
               floors => 'igloo_floors.json',
               furns => 'furniture_items.json',
               rooms => 'rooms.json',
               stamps => 'stamps.json',
               pcards => 'postcards.json'
       };  
       $obj->{methods} = {
               paper_items => 'loadItems',
               igloos => 'loadIgloos',
               igloo_floors => 'loadFloors',
               furniture_items => 'loadFurnitures',
               rooms => 'loadRooms',
               stamps => 'loadStamps',
               postcards => 'loadPostcards',
       };
       $obj->{directory} = cwd . '/Misc/JSONS/';
       return $obj;
}

method loadCrumbs {
       my %arrInfo = ();
       foreach (values %{$self->{jsons}}) {
                my $strFile = $self->{directory} . $_;
                my ($strName,  $strParent, $strExt) = fileparse($strFile, qr/\.[^.]*$/);
                my $arrData = read_file($strFile) ;
                $arrInfo{$strName} = $arrData;
       }
       while (my ($strKey, $arrData) = each(%arrInfo)) {
              if (exists($self->{methods}->{$strKey})) {
                  my $strMethod = $self->{methods}->{$strKey};
                  if (defined(&{$strMethod})) {
                      $self->$strMethod(decode_json($arrData));
                  }
              }
       }
}

method loadItems($arrItems) {
		foreach (sort @{$arrItems}) {
			if ($_->{is_epf}) {
				%{$self->{epf_crumbs}->{$_->{paper_item_id}}} = (points => $_->{cost});               
			} else {
				%{$self->{item_crumbs}->{$_->{paper_item_id}}} = (cost => $_->{cost}, type => $_->{type}, is_bait => $_->{is_bait});
			}
		}
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{item_crumbs}}) . ' Items');
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{epf_crumbs}}) . ' EPF Items');
}

method loadStamps($arrStamps) {
		foreach my $arrIndexStamps (sort @{$arrStamps}) {
			foreach my $arrIndexTwoStamps (sort %{$arrIndexStamps}) {
				if (ref($arrIndexTwoStamps) eq 'ARRAY') {
					foreach my $strStamp (sort @{$arrIndexTwoStamps}) {
						%{$self->{stamp_crumbs}->{$strStamp->{stamp_id}}} = (rank => $strStamp->{rank});
					}	
				}
			}
		}
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{stamp_crumbs}}) . ' Stamps');
}

method loadIgloos($arrIgloos) {
		foreach (sort keys %{$arrIgloos}) {	  
			%{$self->{igloo_crumbs}->{$arrIgloos->{$_}->{igloo_id}}} = (cost => $arrIgloos->{$_}->{cost});    
		}
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{igloo_crumbs}}) . ' Igloos');
}

method loadFloors($arrFloors) {
		foreach (sort @{$arrFloors}) {
			%{$self->{floor_crumbs}->{$_->{igloo_floor_id}}} = (cost => $_->{cost});
		}
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{floor_crumbs}}) . ' Floors');
}

method loadFurnitures($arrFurns) {
		foreach (sort @{$arrFurns}) {
			%{$self->{furniture_crumbs}->{$_->{furniture_item_id}}} = (cost => $_->{cost});
		}
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{furniture_crumbs}}) . ' Furnitures');
}

method loadRooms($arrRooms) {
		foreach (sort keys %{$arrRooms}) {
			my $intRoom = $arrRooms->{$_}->{room_id};
			my $intLimit = $arrRooms->{$_}->{max_users};
			my $strKey = $arrRooms->{$_}->{room_key};
			if ($strKey ne '') {
				%{$self->{room_crumbs}->{$intRoom}} = (name => $strKey, limit => $intLimit);
			} else {
				%{$self->{game_room_crumbs}->{$intRoom}} = (limit => $intLimit);
			}
		}
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{room_crumbs}}) . ' Rooms');
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{game_room_crumbs}}) . ' Game Rooms');
}

method loadPostcards($arrPostcards) {
		while (my ($intCardID, $intCardCost) = each(%{$arrPostcards})) {
			%{$self->{mail_crumbs}->{$intCardID}}  = (cost => $intCardCost);
		}
		$self->{child}->{logger}->info('Successfully loaded ' . scalar(keys %{$self->{mail_crumbs}}) . ' Postcards');
}

1;
