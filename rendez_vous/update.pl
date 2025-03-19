#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Time::Local;

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
use Connexion;
use Etechnoserv;
use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use RendezVous qw(entete_standard db_update_rdv);

# D�claration du r�pertoire de base
#our $rep = '../../../test/jude/V3.0';
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
	print $cgi->header(), $cgi->start_html(title=>'Mis � jour rendez-vous'); 
	print "Le parametre $parametres{ident_id} n'est pas d�fini dans la base dans la base de donn�e", $cgi->end_html();
#	die "Le parametre $id n'est pas d�fini dans la base dans la base de donn�es";
	exit;
  }
  if(verif_tps_connexion() == 0) { #D�lai d'attente d�pass�
#  my $cmd = "location.href = ".../etechnoserv.pl?err=3.";
    print $cgi->header(),$cgi->start_html({-head =>@liens, -Title => 'Mis � jour rendez-vous',
    -script => \@script, -base => 'true', -onLoad => 'window.setTimeout("se_reconnecter()", 5000);'});
	print $cgi->h1('Le temps de connexion est d�pass�, vous devez vous reconnecter'), $cgi->br(), $cgi->em("(Vous allez �tre redirig� dans 5 secondes vers la page principale)"), $cgi->end_html();	
#	print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
	exit;
  }
}
else {
	print $cgi->header(), $cgi->start_html(title=>'Mis � jour rendez-vous'); 
	print "Le parametre ident_id n'existe pas dans la ligne de commande", $cgi->end_html();
	exit;  
}
#$chaine_param = genere_chaine(\%parametres);
#if(exists($::parametres{s_action})) {
#  if($::parametres{s_action} eq 'P�riodicit�') {
#	print $cgi->redirect("periodicite/show.pl?$chaine_param");
#	exit;
#  }	
#}

db_update_rdv();
print $cgi->redirect("../calendrier/show.pl?ident_id=$parametres{ident_id}&annee=$parametres{annee}&mois=$parametres{mois}&jour=$parametres{jour}");
print $cgi->header(),$cgi->start_html({-head =>@liens, -Title => "Mis � jour d'un rendez-vous",
    -script => \@script, -base => 'true', -onLoad => ';'});

#print $cgi->header(),$cgi->start_html({-head =>@liens, -Title => "Enregistrement d'un rendez-vous",
#    -script => \@script, -base => 'true', -onLoad => 'recharge_calendrier(1);window.setTimeout("self.close()", 5000);'});


print $cgi->h1("Le rendez-vous a �t� enregistr� dans la base..."), $cgi->br(), $cgi->em("(Vous allez �tre redirig� dans 5 secondes vers la page principale)"), $cgi->end_html();	
print $cgi->end_html();



