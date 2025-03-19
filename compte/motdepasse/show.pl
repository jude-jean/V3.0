#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Date::Calc qw(:all);
use Time::Local;
#use RapportActivite qw(gestion_ra);


# Déclaration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our $dbh;
my $ecran_actuel;

my %etats = (
	'Defaut'		=> \&donnees_sociales,
	'Données sociales'			=> \&donnees_sociales,
	'Donnees sociales'			=> \&donnees_sociales,
);


my %connexion = (
#        'connexion'     => \&affiche_ecran_connexion, # saisie du login
#        'Envoi'         => \&connexion, # Accès à la base et valide connexion
        'Compte'        => \&gestion_compte,# Gère le compte dans la base
        'compte'        => \&gestion_compte,# Gère le compte dans la base
#        'Déconnexion'   => \&deconnexion, # déconnecte le compte.
);

our $cgi = new CGI;

#Connexion à la base de donnée.
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
#Connexion à la base de donnée.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "problème de connexion à la base de données db447674934 : $!";
	# Déclaration du répertoire de base
	$rep = '../jude/V3.0';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib/";
}
else {
#Connexion à la base de donnée.
	$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "problème de connexion à la base de données collaborateur : $!";
	$rep = '../../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}
use Etechnoserv qw(info_id);
#use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use Affichage;
use Connexion;
use Showgestioncompte;
# Déclaration du répertoire de base
#our $rep = '../../../../test/jude/V3.0';
# Déclaration pour javascript
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# Déclaration des feuilles de styles
my %style = (
       'src'               => "$rep/styles/etechnoserv.css",
);

my @liens = [
       Link({
         'rel'             => 'shortcut icon',
         'href'            => "$rep/images/favicon.ico",
       }),
];

#####################################################################################"
#Récupération du paramêtre .Connexion  partie droite de l'entête
my $connexion = $cgi->param(".Connexion");

my $bouton;
#Récupération du paramêtre .Etat nécessaire pour gérer le menu droit
$ecran_actuel = $cgi->param(".Etat") || "Defaut";

if(($ecran_actuel eq 'OK') || ($ecran_actuel eq 'Appliquer')) {
  $bouton = $ecran_actuel;
}

our @msg_maj;
our $no_msg;
my $vide = $cgi->param(".defaults");
$id = $cgi->param('ident_id');
unless ($id) {
  entete_standard();
  die "Le parametre ident_id n'est pas définie"
}
  
@collaborateur = info_id($id);
unless (@collaborateur) {
	print $cgi->header(), $cgi->start_html(title=>'etechnoserv.com'); 
	print "Le parametre $id n'est pas défini dans la base dans la base de donnée", $cgi->end_html();
#	die "Le parametre $id n'est pas défini dans la base dans la base de données";
	exit;
}

if(verif_tps_connexion() == 0) { #Délai d'attente dépassé
	print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
	exit;
}
if($ecran_actuel eq 'Appliquer') {
	if(compte_motdepasse_enregistre_data() != 2) {
		print $cgi->redirect($cgi->script_name."?smenu=motdepasse&no_msg=$no_msg&ident_id=$id&ident_user=".$cgi->param('login'));
		exit;
	}
	else {
		entete_standard();
		print "Erreur sur la base de donnée : ".$dbh->errstr;
		print $cgi->end_html();
		exit;	
	}
}	
if($ecran_actuel eq 'OK') {
	print $cgi->redirect("../../donnees_sociales/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
}  

entete_standard();

affiche_4_zones();

exit;

sub entete_standard {
  my $url = $cgi->url;
  print $cgi->header();
  if($ecran_actuel eq 'Calendrier') {
    print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0", -script => \%script,
              -style =>\%style, -xbase => "$url", onLoad => 'return gestion_affichage_rdv();'});
  }
  else {
    print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0", -script => \%script,
              -style =>\%style, -xbase => "$url"});
  }
#  print "url = $url", $cgi->br(), "self_url = ", $cgi->self_url, $cgi->br();
}

sub affiche_4_zones {
    affiche_debut_corps_de_page();
    affiche_entete_login_connecte();
    affiche_menu_gauche();
    affiche_menu_droit();
    affiche_bas_de_page();
    affiche_fin_corps_de_page();
#    print "\n", $cgi->end_div(); # la fin du div de corps
}


# Debut d'affichage du menu droit
sub affiche_menu_droit {
	print "\n", $cgi->start_div({-id=> "droite"});
#  print "self_url = ",$cgi->self_url(), $cgi->br(), "url = ", $cgi->url, $cgi->br(), "ENV{QUERY_STRING} = $ENV{QUERY_STRING}", $cgi->br(),"query_string = ", $cgi->query_string(), $cgi->br();
	if(defined($id)) {
		print "\n", $cgi->start_form();  # Début du formulaire du menu droit
		print "\n", $cgi->hidden(-name=>'ident_id', -value=>"$id");
		gestion_compte(1);
		print "\n", $cgi->end_form();# Fin du formulaire du menu droit
	}
	print "\n", $cgi->end_div(); # fin du div de droite
}


sub compte_motdepasse_enregistre_data {
	my $smenu = $cgi->param('smenu');
	if($smenu eq 'motdepasse') {
		my ($pswd, $pswd1, $pswd2, $pswd_md5);
		$pswd= $cgi->param('pswd_actuel');
		$pswd1 = $cgi->param('pswd_new1');
		$pswd2 = $cgi->param('pswd_new2');

# Les contrôles sur les données avant l'enregistrement
		if(menu_compte_verif_donnees($smenu, $pswd, $pswd1, $pswd2) == 0) {
			my $md5 = Digest::MD5->new;
			$md5->add($pswd1);
			$pswd_md5 = $md5->hexdigest;
			my $sql = "UPDATE collaborateur SET pass = ".$dbh->quote($pswd_md5)." WHERE (id = ".$dbh->quote($collaborateur[0]).") AND (actif = '1')";
#			$dbh->do($sql) or die " Erreur : $dbh->errstr";
			if($dbh->do($sql)) {
				$collaborateur[4] = $pswd_md5;
				$msg_maj[0] = $smenu;
				$msg_maj[1] = 0; # Utile pour supprimer initialisation des champs
				$msg_maj[2] = "Mise à jour du mot de passe effectuée";
				$no_msg = 100;
				return 0;
			}
			else {
				return 2;
			}
		}
#		die "compte_motdepasse_enregistre_data : smenu = $smenu : msg erreur = $msg_maj[2]";
		else {
			return 1;
		}
	}
}

