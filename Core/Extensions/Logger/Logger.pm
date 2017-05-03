package Logger;

use strict;
use warnings;

use Method::Signatures;
use feature qw(say);
use Cwd;
use if $^O eq 'MSWin32', "Win32::Console::ANSI"; 
use Term::ANSIColor;

method new() {
       my $obj = bless {}, $self;
       return $obj;
}

method debug($message) {
		my $strMessage = 'DEBUG - ' . $message;
		say color('bold green'), $strMessage;
		$self->writeLog('[' . localtime . ']: ' . $message, $self->getLogFile);
}

method info($message) {
		my $strMessage = 'INFO - ' . $message;
		say color('bold yellow'), $strMessage;
		$self->writeLog('[' . localtime . ']: ' . $message, $self->getLogFile);
}

method warning($message) {
		my $strMessage = 'WARNING - ' . $message;
		say color('bold red'), $strMessage;
		$self->writeLog('[' . localtime . ']: ' . $message, $self->getLogFile);
}

method error($message) {
		my $strMessage = 'ERROR - ' . $message;
		say color('bold cyan'), $strMessage;
		$self->writeLog('[' . localtime . ']: ' . $message, $self->getLogFile);
}

method fatal($message) {
		my $strMessage = 'FATAL - ' . $message;
		say color('bold magenta'), $strMessage;
		$self->writeLog('[' . localtime . ']: ' . $message, $self->getLogFile);
}

method notice($message) {
		my $strMessage = 'NOTICE - ' . $message;
		say color('bold white'), $strMessage;
		$self->writeLog('[' . localtime . ']: ' . $message, $self->getLogFile);
}

method getLogFile {
		my $resFile = cwd() . '/Core/Extensions/Logger/Logs.log';
		return $resFile;
}

method writeLog($strText, $resFile) {
       my $resHandle;
       open($resHandle, '>>', $resFile);
       say $resHandle $strText;
       close($resHandle);
}

1;
