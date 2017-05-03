use strict;
use warnings;

use Module::Find;

use Core::Extensions::Logger::Logger;
use Core::Extensions::Crumbs::Crumbs;

use Core::Boot::MySQL;
use Core::Boot::Socket;

use Core::Extensions::Cryptography::Cryptography;

use Core::Systems::FourSystem;
use Core::Systems::MancalaSystem;
use Core::Systems::SpamSystem;

use Core::Systems::Multiplayer;

usesub Core::Plugins;

usesub Core::Systems::Handlers;

use Core::Systems::LoginSystem;
use Core::Systems::GameSystem;

use Core::Nitro;
use Core::Client;

my $objServer = Nitro->new(['Config/Game.xml', 'Config/Database.xml']);

while (1) {
	$objServer->{sock}->handleListen;
}

1;
