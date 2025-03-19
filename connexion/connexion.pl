#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;                      # Source code is encoded using UTF-8.
use open ':encoding(UTF-8)';   # Set default encoding for file handles.
BEGIN { binmode(STDOUT, ':encoding(UTF-8)'); }  # HTML
BEGIN { binmode(STDERR, ':encoding(UTF-8)'); }  # Error log

use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Date::Calc qw(:all);
use Time::Local;

# D�claration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our $dbh;
my %parametres =();
my $recharge;
#$mois += 1;
#$annee += 1900;

#########################################################################################
# Date de cr�ation de Technologies et Services
our @date_ts = (2003, 1, 1);
our $erreur;
my ($msg_erreur, $etat);

my %erreur = (
		'1'	=> "*Erreur : le login n'est pas correct. Sa taille est comprise entre [4, 20]. Il ne doit pas contenir des caract�res interdits.",
		'2'	=> "*Erreur sur le login ou le mot de passe.",
		'3'	=> "D�lai d'inactivit� d�pass�, Veuillez vous reconnecter",
	);	

our $cgi = new CGI;
#$cgi = new CGI;

our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "probl�me de connexion � la base de donn�es db447674934 : $!";
	# D�claration du r�pertoire de base
	$rep = '../jude/V3.0';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib/";
}
else {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "probl�me de connexion � la base de donn�es collaborateur : $!";
	$rep = '../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}
use Etechnoserv qw(info_id lecture_parametres visu_parametres);
use Connexion;

#####################################################################################"
# D�claration pour javascript
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# D�claration des feuilles de styles
my %style = (
       'src'               => "$rep/styles/etechnoserv.css",
);

lecture_parametres(\%parametres);
#R�cup�ration du param�tre .Connexion  partie droite de l'ent�te
my $connexion = $cgi->param(".Connexion");
my $ecran_actuel = '';

#print "connexion = $connexion";

#$cgi->autoEscape(undef);
	
if(defined($connexion) && ($connexion eq 'Envoi')) {
	my $login = $cgi->param("login");
	my $pswd = $cgi->param("pswd");
# Faire les v�rifications de login et pswd comme dans le javascript (� faire
	if((verif_login($login) == 1) && (connexion_db($login, $pswd) == 1)) {
		print $cgi->redirect("$rep_pl/donnees_sociales/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
		exit;
#			affiche_menu_connexion(2);
	}
# Verif_login() ou connexion_db() ont renvoy� une erreur
	else{
		print $cgi->redirect("$rep_pl/etechnoserv.pl?err=$erreur");
		exit;
	}
}
elsif(defined($connexion) && ($connexion = 'Déconnexion')) {
	#print $cgi->print("connexion = $connexion");
	deconnexion();
    print $cgi->redirect("$rep_pl/etechnoserv.pl");
    exit;
}
else {
#R�cup�ration du param�tre .Etat n�cessaire pour g�rer le menu droit
	$etat = $cgi->param(".Etat");
	if(defined($etat) && ($etat eq 'Compte')) {
		if(verif_tps_connexion() == 0) { #D�lai d'attente d�pass�
			print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
			exit;
		}
		print $cgi->redirect("$rep_pl/compte/identification/show.pl?ident_id=".$cgi->param('ident_id')."&ident_user=".$cgi->param('ident_user'));
		exit;
	}
}


#####################################################################################################
########### Les fonctions et proc�dures #############################################################


sub entete_standard {
  my $url = $cgi->url;
  print $cgi->header('text/html; charet=UTF-8');
  if($ecran_actuel eq 'Calendrier') {
    print $cgi->start_html({-Title => "etechnoserv.com v3.0", -script => \%script,
              -encoding => 'UTF-8', -style =>\%style, -xbase => "$url", onLoad => 'return gestion_affichage_rdv();'});
  }
  else {
    print $cgi->start_html({-Title => "etechnoserv.com v3.0", -script => \%script,
              -encoding => 'UTF-8', -style =>\%style, -xbase => "$url"});
  }
#  print "url = $url", $cgi->br(), "self_url = ", $cgi->self_url, $cgi->br();
}

