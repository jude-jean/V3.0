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


# D�claration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our $dbh;
my $ecran_actuel;

my %etats = (
	'Defaut'		=> \&donnees_sociales,
	'Donn�es sociales'			=> \&donnees_sociales,
	'Donnees sociales'			=> \&donnees_sociales,
);


my %connexion = (
#        'connexion'     => \&affiche_ecran_connexion, # saisie du login
#        'Envoi'         => \&connexion, # Acc�s � la base et valide connexion
        'Compte'        => \&gestion_compte,# G�re le compte dans la base
        'compte'        => \&gestion_compte,# G�re le compte dans la base
#        'D�connexion'   => \&deconnexion, # d�connecte le compte.
);

our $cgi = new CGI;

#Connexion � la base de donn�e.
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
	$rep = '../../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}
use Etechnoserv qw(info_id);
#use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use Affichage;
use Connexion;
#use Showgestioncompte;
# D�claration du r�pertoire de base
#our $rep = '../../../../test/jude/V3.0';
# D�claration pour javascript
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# D�claration des feuilles de styles
my %style = (
       'src'               => "$rep/styles/vie_sociale.css",
);

my @liens = [
       Link({
         'rel'             => 'shortcut icon',
         'href'            => "$rep/images/favicon.ico",
       }),
];

#####################################################################################"
#R�cup�ration du param�tre .Connexion  partie droite de l'ent�te
my $connexion = $cgi->param(".Connexion");

my $bouton;
#R�cup�ration du param�tre .Etat n�cessaire pour g�rer le menu droit
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
  die "Le parametre ident_id n'est pas d�finie"
}
  
@collaborateur = info_id($id);
unless (@collaborateur) {
	print $cgi->header(), $cgi->start_html(title=>'etechnoserv.com'); 
	print "Le parametre $id n'est pas d�fini dans la base dans la base de donn�e", $cgi->end_html();
#	die "Le parametre $id n'est pas d�fini dans la base dans la base de donn�es";
	exit;
}

if(verif_tps_connexion() == 0) { #D�lai d'attente d�pass�
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
		print "Erreur sur la base de donn�e : ".$dbh->errstr;
		print $cgi->end_html();
		exit;	
	}
}	
if($connexion eq 'Déconnexion') {
    deconnexion();
    print $cgi->redirect("$rep_pl/etechnoserv.pl");
    exit;
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
  if($ecran_actuel eq "Rapports d'activit�s") {
    print $cgi->redirect("$rep_pl/rapports_activites/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
  }	
  if($ecran_actuel eq "Optis") {
    print $cgi->redirect("$rep_pl/optis/menug/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
  }	

entete_standard();

affiche_4_zones();

exit;

sub entete_standard {
  my $url = $cgi->url;
  print $cgi->header();
  print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0", -script => \%script,
              -style =>\%style, -xbase => "$url"});
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
	if(defined($id)) {
		print "\n", $cgi->start_form();  # D�but du formulaire du menu droit
		print "\n", $cgi->hidden(-name=>'ident_id', -value=>"$id");
		menu_droit();
		menu_social(0xEF);
		print "\n", $cgi->end_form();# Fin du formulaire du menu droit
	}
	print "\n", $cgi->end_div(); # fin du div de droite
}

sub menu_droit {
	print $cgi->h2("L'espace vie sociale de $collaborateur[2].");
	menu_infos();
	menu_docs();
	menu_liens_adresses();
}

sub menu_infos {
	print $cgi->start_div({-id=> 'infos'});
	print "Cong�s de $collaborateur[2]", $cgi->br();
	print $cgi->start_div({-id => 'conges'});
	
	print $cgi->end_div(); # fin du div conges
	print $cgi->start_div({-id => 'rtt'});
	
	print $cgi->end_div(); # fin du div rtt

	print $cgi->end_div(); # fin du div infos

}

sub menu_docs {
	print $cgi->start_div({-id => 'docs'});
	
	print $cgi->end_div(); # fin du div docs

}

sub menu_liens_adresses {
	print $cgi->start_div({-id => 'liens_adresses'});
	print $cgi->start_div({-id => 'liens'});
	
	print $cgi->end_div(); # fin du div liens
	print $cgi->start_div({-id => 'adresses'});
	
	print $cgi->end_div(); # fin du div adresses
	
	print $cgi->end_div(); # fin du div liens_adresses

}