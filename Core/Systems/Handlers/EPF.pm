package EPF;

use strict;
use warnings;

use Method::Signatures;
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {
			epfai => 'handleEPFAddItem',
			epfga => 'handleEPFGetAgent',
			epfgr => 'handleEPFGetRevision',
			epfgf => 'handleEPFGetField',
			epfsf => 'handleEPFSetField',
			epfsa => 'handleEPFSetAgent',
			epfgm => 'handleEPFGetMessage'
		};
		return $obj;
}

method handleEPF(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleEPFAddItem($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intItem = $arrData[5];
		return if (!looks_like_number($intItem));
		if (!exists($self->{child}->{crumbs}->{epf_crumbs}->{$intItem})) {
		   return $objClient->sendError(402);
		} elsif (first {$_ == $intItem} @{$objClient->{penguin}->{inventory}}) {
		   return $objClient->sendError(400);
		} elsif ($objClient->{epf}->{currentpoints} < $self->{child}->{crumbs}->{epf_crumbs}->{$intItem}->{points}) {
		   return $objClient->sendError(405);
		}
		$self->{child}->{mysql}->addToInventory($intItem, $objClient->{penguin}->{ID});	
		$self->{child}->{mysql}->deductEPFPoints($self->{child}->{crumbs}->{epf_crumbs}->{$intItem}->{points}, $objClient);	
		$objClient->sendXT(['epfai', '-1', $intItem, $objClient->{epf}->{currentpoints}]);
}

method handleEPFGetAgent($strData, $objClient) {
		$objClient->sendXT(['epfga', '-1', $objClient->{epf}->{isagent}]);
}

method handleEPFGetRevision($strData, $objClient) {
		$objClient->sendXT(['epfgr', '-1', $objClient->{epf}->{totalpoints}, $objClient->{epf}->{currentpoints}]);
}

method handleEPFGetField($strData, $objClient) {
		$objClient->sendXT(['epfgf', '-1', $objClient->{epf}->{status}]);
}

method handleEPFSetField($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $intStatus = $arrData[5];
		return if (!looks_like_number($intStatus));
		$self->{child}->{mysql}->updateEPFOPStatus($intStatus, $objClient);
		$objClient->sendXT(['epfsf', '-1', $intStatus]);
}

method handleEPFSetAgent($strData, $objClient) {
		if (!$objClient->{epf}->{isagent}) {
			$self->{child}->{mysql}->updateEPFAgent(1, $objClient);
			$objClient->sendXT(['epfsa', '-1', 1]);
			$objClient->sendXT(['epfga', '-1', 1]);
		}
}

method handleEPFGetMessage($strData, $objClient) {
		my @arrInfo = ('u wot m8', time, 15);
		$objClient->sendXT(['epfgm', '-1', $objClient->{penguin}->{ID}, join('|', @arrInfo)]);
}

1;
