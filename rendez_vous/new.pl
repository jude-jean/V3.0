#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Time::Local;



#our @boutons_bas = ( ["Donn�es sociales", 0x1],
#                    ["Rapports d'activit�s", 0x2],
#                    ["Calendrier", 0x4],
#                    ["Compte", 0x8]);

# D�claration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our %parametres = ();
our $dbh;
our $tps_connexion = 600; # D�lai de connexion sans inactivit�

our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
our $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);
$mois += 1;
$annee += 1900;

# Date de cr�ation de Technologies et Services
our @date_ts = (2003, 1, 1);
my @msg_maj;
my $ecran_actuel;

my %s_action = (
 'Sauvegarder'            => \&sauvegarder_rdv,
 'Enregistrer et fermer'  => \&sauve_et_ferme_rdv,
 'Visualiser'             => \&visualiser_rdv,
 'Valider'            => \&valider_rdv,
 'Imprimer'           => \&imprimer_rdv,
 'Editer'             => \&ouvrir_rdv,
 'Supprimer'          => \&delete_rdv,
 'P�riodicit�'        => \&periodicite_rdv,
);


my $chaine_param;

our $cgi = new CGI;
#Connexion � la base de donn�e.
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "probl�me de connexion � la base de donn�es db447674934 : $!";
	# D�claration du r�pertoire de base
	$rep = '..';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib";

}
else {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "probl�me de connexion � la base de donn�es collaborateur : $!";
	$rep = '../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}
# D�claration du r�pertoire de base
# D�claration du r�pertoire de base
#our $rep = '../../../test/jude/V3.0';
use Connexion;
use Etechnoserv;
use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use RendezVous qw(entete_standard calcul_data_rdv affiche_ecran_rdv);

our @script = (
        { 'language'           => "javascript",
          'src'                => "$rep/scripts/ets_cal.js"
        },
        {
          'language'           => "javascript",
          'src'                => "$rep/scripts/mini_cal.js"
        },
);

# D�claration des feuilles de styles
our @liens = [
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/ets_cal.css",
         'media'           => 'screen',
       }),
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/ets_cal_print.css",
         'media'           => 'print',
       }),
       Link({
         'rel'             => 'shortcut icon',
         'href'            => "$rep/images/favicon.ico",
       }),

];

lecture_parametres(\%parametres);
if(defined($parametres{ident_id})) {
  @collaborateur = info_id($parametres{ident_id});
  unless (@collaborateur) {
	print $cgi->header(), $cgi->start_html(title=>'Nouveau rendez-vous'); 
	print "Le parametre $parametres{ident_id} n'est pas d&eacute;fini dans la base dans la base de donn&eacute;e", $cgi->end_html();
#	die "Le parametre $id n'est pas d�fini dans la base dans la base de donn�es";
	exit;
  }
  if(verif_tps_connexion() == 0) { #D�lai d'attente d�pass�
    print $cgi->header(),$cgi->start_html({-head =>@liens, -Title => 'Nouveau rendez-vous',
    -script => \@script, -base => 'true', -onLoad => 'recharge_calendrier(1);window.setTimeout("self.close()", 5000);'});
	print $cgi->h1('Le temps de connexion est d&eacute;pass&eacute;, vous devez vous reconnecter'), $cgi->br(), $cgi->em("(Vous allez &ecirc;tre redirig&eacute; dans 5 secondes vers la page principale)"), $cgi->end_html();	
#	print $cgi->redirect("/cgi-bin/V3.0/etechnoserv.pl?err=3");
	exit;
  }
}
else {
	print $cgi->header('text/html'), $cgi->start_html(title=>'Nouveau rendez-vous'); 
	print "Le parametre ident_id n'existe pas dans la ligne de commande", $cgi->end_html();
	exit;  
}

$chaine_param = genere_chaine(\%parametres);
if(exists($::parametres{s_action})) {
  if($::parametres{s_action} eq 'Enregistrer et fermer') {
	print $cgi->redirect("save_and_close.pl?$chaine_param");
	exit;
  }elsif($::parametres{s_action} eq 'P�riodicit�') {
	print $cgi->redirect("periodicite/show.pl?$chaine_param");
	exit;
  }elsif($::parametres{s_action} eq 'Imprimer') {
	print $cgi->redirect("print.pl?$chaine_param");
	exit;	
  }elsif($::parametres{s_action} eq "Inviter les participants") {
    print $cgi->redirect("invite.pl?$chaine_param");
	exit;
  }elsif($::parametres{s_action} eq "Ajoute un fichier") {
    print $cgi->redirect("add_fichier.pl?$chaine_param");
	exit;
  }	

}
entete_standard();
calcul_data_rdv();
visu_parametres(\%parametres);
affiche_ecran_rdv();
print $cgi->end_html();

############################### D�but des fonctions #######################################################
