#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
#use Digest::MD5  qw(md5_hex);
#use Digest::SHA qw(sha1_hex);
#use Date::Calc qw(:all);
#use Time::Local;
#use Calendrier qw(calendrier);


# Déclaration du répertoire de base
#our $rep = '../../../test/jude/V3.0';
# Déclaration pour javascript
# Déclaration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our $dbh;
our ($mois, $annee) = (localtime)[4, 5];
$mois += 1;
$annee += 1900;


#### Dans le menu droit, les boutons du bas
#my @boutons_bas = ( ["Données sociales", 0x1],
#                    ["Rapports d'activités", 0x2],
#                    ["Calendrier", 0x4],
#                    ["Compte", 0x8]);


#Table des etats associants à chaque document son sous-programmes
#my %etats;

my $ecran_actuel;

my %etats = (
	'Defaut'		=> \&donnees_sociales,
#	'Calendrier'		=> \&calendrier,
#	'Rapports d'activités"		=> \&gestion_ra,
#	"Rapports d'activites"  => \&gestion_ra,
#	'Compte'        	=> \&gestion_compte,
	'Données sociales'			=> \&donnees_sociales,
	'Donnees sociales'			=> \&donnees_sociales,
);

our $cgi = new CGI;

#Récupération du paramêtre .Etat nécessaire pour gérer le menu droit
$ecran_actuel = $cgi->param(".Etat") || "Defaut";
#Début du fichier HTML
#entete_standard();

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
	$rep = '../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}
use RapportActivite qw(gestion_ra);
use Affichage;
use Etechnoserv qw(info_id);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use Connexion;

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

#Récupération du paramêtre .Connexion  partie droite de l'entête
#my $connexion = $cgi->param(".Connexion") || "connexion";
#unless ($connexion{$connexion}){
#  entete_standard();
#  die "Pas de fonction pour $connexion" ;
#}

my $bouton;
my @msg_maj;
my $vide = $cgi->param(".defaults");
$id = $cgi->param('ident_id');

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

if(($ecran_actuel eq 'OK') || ($ecran_actuel eq 'Appliquer')) {
  $bouton = $ecran_actuel;
}
if($ecran_actuel eq "Accueil") {
	print $cgi->redirect("$rep_pl/donnees_sociales/show.pl?ident_id=$id&ident_user=$cgi->param('ident_user')");
	exit;
}
if($ecran_actuel eq 'Compte') {
	print $cgi->redirect("$rep_pl/compte/identification/show.pl?ident_id=$id&ident_user=$cgi->param('ident_user')");
	exit;
}
if($ecran_actuel eq 'Calendrier') {
	print $cgi->redirect("$rep_pl/calendrier/show.pl?ident_id=$id&ident_user=$cgi->param('ident_user')");
	exit;
}
if($ecran_actuel eq 'Vie sociale') {
	print $cgi->redirect("$rep_pl/vie_sociale/show.pl?ident_id=$id&ident_user=$cgi->param('ident_user')");
	exit;
}
if($ecran_actuel eq 'Optis') {
	print $cgi->redirect("$rep_pl/optis/menug/show.pl?ident_id=$id&ident_user=$cgi->param('ident_user')");
	exit;
}

entete_standard();

affiche_4_zones();

exit;

sub entete_standard {
  my $url = $cgi->url;
  print $cgi->header();
#  if($ecran_actuel eq 'Calendrier') {
#    print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0", -script => \%script,
#              -style =>\%style, -xbase => "$url", onLoad => 'return gestion_affichage_rdv();'});
#  }
#  else {
    print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0", -script => \%script,
              -style =>\%style, -xbase => "$url"});
#  }
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
	print "\n", $cgi->start_form();  # Début du formulaire du menu droit
#    print "\n", $cgi->hidden(-name=>'ident_nom', -value=>"$login");
	print "\n", $cgi->hidden(-name=>'ident_id', -value=>"$id");
# Voici la boucle principale
	gestion_ra();
	print "\n", $cgi->end_form();# Fin du formulaire du menu droit

	print "\n", $cgi->end_div(); # fin du div de droite
}



