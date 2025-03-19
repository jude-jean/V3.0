#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Time::Local;

# Déclaration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our %parametres = ();
our $dbh;
our $tps_connexion = 600; # Délai de connexion sans inactivité

our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
our $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);
$mois += 1;
$annee += 1900;

# Date de création de Technologies et Services
our @date_ts = (2003, 1, 1);
my @msg_maj;
my $ecran_actuel;

my $chaine_param;
our $cgi = new CGI;



#Connexion à la base de donnée.
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
#Connexion à la base de donnée.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "problème de connexion à la base de données db447674934 : $!";
	# Déclaration du répertoire de base
	$rep = '../..';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib/";

}
else {
#Connexion à la base de donnée.
	$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "problème de connexion à la base de données collaborateur : $!";
	$rep = '../../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib/";
}
use Connexion;
use Etechnoserv;
use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use RendezVous qw(entete_standard affiche_ecran_periodicite);
# Déclaration du répertoire de base
#our $rep = '../../../../test/jude/V3.0';
our @script = (
        { 'language'           => "javascript",
          'src'                => "$rep/scripts/ets_cal.js"
        },
        {
          'language'           => "javascript",
          'src'                => "$rep/scripts/mini_cal.js"
        },
);

# Déclaration des feuilles de styles
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
	print $cgi->header(), $cgi->start_html(title=>'Périodicité rendez-vous'); 
	print "Le parametre $parametres{ident_id} n'est pas défini dans la base dans la base de donnée", $cgi->end_html();
#	die "Le parametre $id n'est pas défini dans la base dans la base de données";
	exit;
  }
  if(verif_tps_connexion() == 0) { #Délai d'attente dépassé
    print $cgi->header(),$cgi->start_html({-head =>@liens, -Title => 'Périodicité rendez-vous',
    -script => \@script, -base => 'true', -onLoad => 'recharge_calendrier(1);window.setTimeout("self.close()", 5000);'});
	print $cgi->h1('Le temps de connexion est dépassé, vous devez vous reconnecter'), $cgi->end_html();	
#	print $cgi->redirect("/cgi-bin/V3.0/etechnoserv.pl?err=3");
	exit;
  }
}
else {
	print $cgi->header(), $cgi->start_html(title=>'Périodicité rendez-vous'); 
	print "Le parametre ident_id n'existe pas dans la ligne de commande", $cgi->br();
	visu_parametres(\%parametres);
	print $cgi->end_html();
	exit;  
}

#if(exists($parametres{s_action})) {
#  if($parametres{s_action} eq 'Retour au rendez-vous') {
#	print $cgi->redirect($cgi->referer);
#	exit;
#  }	
#}
if(exists($parametres{bouton}) && ($parametres{bouton} eq 'OK')) {
	delete $parametres{s_action};
	$chaine_param = genere_chaine(\%parametres);	
#    print $cgi->header(-expires =>'0');
#    print $cgi->start_html({-head =>@liens, -Title => "Périodicité rendez-vous - V1.0",
#       -script => \@script, -base => 'true', -onLoad=> 'return affiche_periodicite_choisie();'});
#    print "La chaine de parametres est : $chaine_param", $cgi->br();
#	print $cgi->end_html();
    print $cgi->redirect("../open.pl?$chaine_param");
}
print $cgi->header(-expires =>'0');
print $cgi->start_html({-head =>@liens, -Title => "Périodicité rendez-vous - V1.0",
       -script => \@script, -base => 'true', -onLoad=> 'return affiche_periodicite_choisie();'});
affiche_ecran_periodicite();
print $cgi->end_html();
