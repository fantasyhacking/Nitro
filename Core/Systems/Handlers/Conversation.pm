package Conversation;

use strict;
use warnings;

use Method::Signatures;
use HTML::Entities;

method new($resChild) {
		my $obj = bless {}, $self;
		$obj->{child} = $resChild;
		$obj->{handlers} = {sm => 'handleSendMessage'};
		return $obj;
}

method handleConversation(\@arrData, $objClient) {
		my $strHandle = $arrData[0];
		my $strData = $arrData[1];
		return if (!exists($self->{handlers}->{$strHandle}));
		my $strMethod = $self->{handlers}->{$strHandle};
		if ($self->can($strMethod)) {
			$self->$strMethod($strData, $objClient);
		}
}

method handleSendMessage($strData, $objClient) {
		my @arrData = split('%', $strData);
		my $strMessage = decode_entities($arrData[6]);
		return if ($strMessage eq ''); #no blank messages
		#no urls in messages
		return if ($strMessage =~ /((?<=[^a-zA-Z0-9])(?:https?\:\/\/|[a-zA-Z0-9]{1,}\.{1}|\b)(?:\w{1,}\.{1}){1,5}(?:com|org|pw|edu|gov|uk|net|ca|de|jp|fr|au|us|ru|ch|it|nl|se|no|es|mil|iq|io|ac|ly|sm){1}(?:\/[a-zA-Z0-9]{1,})*)/mg);
		return if ($strMessage eq $objClient->{lastMessage}); #spam protect against same messages
		$objClient->{lastMessage} = $strMessage;
		$objClient->sendRoom('%xt%sm%-1%' .  $objClient->{penguin}->{ID} . '%' . $strMessage . '%');
}

1;
