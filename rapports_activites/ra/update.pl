#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use URI::Escape;
use Encode qw(encode decode);
use DBI;
use Date::Calc qw(:all);
use Time::Local;

our %parametres =();
# D�claration des identifications de connexion
my ($id, $id_ra, $nom_client, $rep);
#my $login;
our @collaborateur;
our $dbh;
#my $tps_connexion = 600; # D�lai de connexion sans inactivit�

# Tableau des RA
my (@ra, @ra_ast, @ra_comment, @ra_global, @ra_hsup, @ra_pres);
my ($decodeMois, $moisUnescape);
my %numVsMois = {'1' => 'Janvier', '2' => 'Février', '3' => 'Mars', '4' => 'Avril', '5' => 'Mai', '6' => 'Juin', '7' => 'Juillet', '8' => 'Août', '9' => 'Septembre', '10' => 'Octobre', '11' => 'Novembre', '12' => 'Décembre'};

our $cgi = new CGI;
#Connexion � la base de donn�e.
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "probl�me de connexion � la base de donn�es db447674934 : $!";
	# D�claration du r�pertoire de base
	$rep = '../..';
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
use RapportActivite qw(gestion_ra);
use JourDeFete qw(est_ferie est_jour_ferie Delta_Dates_AMJ);
use Connexion;
use Etechnoserv;
use Ra;
lecture_parametres(\%parametres);
$decodeMois = decode('utf-8', $parametres{mois});
$moisUnescape = uri_escape($parametres{mois});
#visu_parametres();
@collaborateur = info_id($parametres{ident_id});
unless (@collaborateur) {
	my $script = "url=".$cgi->script_name."?";
	foreach (keys %parametres) {
		$script .= "$_=$parametres{$_}&";
	}
	print $cgi->redirect("$rep_pl/erreur.pl?$script&err=10");
#	die "Le parametre parametres{ident_id} n'est pas d�fini dans la base dans la base de donn�es";
	exit;
}
if(verif_tps_connexion() == 0) { #D�lai d'attente d�pass�
	print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
	exit;
}
if ($parametres{s_action} eq 'Imprimer') {
	print $cgi->redirect("$rep_pl/rapports_activites/ra/show.pl?action=impression&client_id=$parametres{client_id}&annee=$parametres{annee}&nb_jours=$parametres{nb_jours}&mois_num=$parametres{mois_num}&mois=$parametres{mois}&ident_id=$parametres{ident_id}&ra_id=$parametres{ra_id}&ident_user=$parametres{ident_user}");
	exit;
}
if($parametres{s_action} eq 'Visualiser') {
	print $cgi->redirect("$rep_pl/rapports_activites/ra/show.pl?action=affichage&client_id=$parametres{client_id}&annee=$parametres{annee}&nb_jours=$parametres{nb_jours}&mois_num=$parametres{mois_num}&mois=$parametres{mois}&ident_id=$parametres{ident_id}&ra_id=$parametres{ra_id}&ident_user=$parametres{ident_user}");
	exit;
}
if($parametres{s_action} eq 'Version PDF') {
	print $cgi->redirect("$rep_pl/rapports_activites/ra/show_pdf.pl?action=Version PDF&client_id=$parametres{client_id}&annee=$parametres{annee}&nb_jours=$parametres{nb_jours}&mois_num=$parametres{mois_num}&mois=$parametres{mois}&ident_id=$parametres{ident_id}&ra_id=$parametres{ra_id}&ident_user=$parametres{ident_user}");
	exit;
}
if(($rep = db_maj_ra()) == 0) {
	print $cgi->redirect("$rep_pl/rapports_activites/ra/show.pl?action=edition&client_id=$parametres{client_id}&annee=$parametres{annee}&nb_jours=$parametres{nb_jours}&mois_num=$parametres{mois_num}&mois=$parametres{mois}&ident_id=$parametres{ident_id}&ra_id=$parametres{ra_id}&ident_user=$parametres{ident_user}");
}	
else {
	my $script = "url=".$cgi->script_name."?";
	foreach (keys %parametres) {
		$script .= "$_=$parametres{$_}&";
	}
	print $cgi->redirect("$rep_pl/erreur.pl?$script&err=$rep");
#	die "Le parametre parametres{ident_id} n'est pas d�fini dans la base dans la base de donn�es";

}
exit;
##################Requetes SQL ##############################################"
sub db_maj_ra {
  my ($cle, $som_pres, $som_travail_interne, $som_conges_payes, $som_conges_pris, $som_rtt);
  my ($som_maladie, $som_recup, $som_formation, $som_abs_excep, $som_sans_solde);
  my ($som_hsup_0, $som_hsup_25, $som_hsup_50, $som_hsup_100);
  my ($som_ast_jour, $som_ast_nuit, $som_ast_24);
  my ($str_pres, $str_hsup, $str_ast, $str_comment);
  my ($ra, $ra_pres, $ra_hsup, $ra_ast, $ra_comment, $taux);
  $som_pres = $som_maladie = 0;
  $som_travail_interne = $som_recup = $som_formation = $som_abs_excep = 0;
  $som_conges_payes = $som_conges_pris = $som_rtt = $som_sans_solde = 0;
  $som_hsup_0 = $som_hsup_25= $som_hsup_50 = $som_hsup_100 = 0;
  $som_ast_jour = $som_ast_nuit = $som_ast_24 = 0;
#  $ra_pres = "INSERT INTO ra_presence ( ";
  foreach (keys %parametres) {
    /^pmatin|^paprem/ && do {
      if($parametres{client_id} > 0) {
        if($parametres{$_} eq '1') {
          $som_pres += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
          next;
        }
        if(($parametres{$_} eq ' ') || ($parametres{$_} eq '0')) {
          $str_pres .= "$_=NULL,";
        }
      }
      else { # RA pour T&S
        if(($parametres{$_} eq ' ') || ($parametres{$_} eq '0')) {
          $str_pres .= "$_=NULL,";
          next;
        }
        if($parametres{$_} eq '2') {
          $som_travail_interne+=0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '3') {
          $som_conges_payes += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '4') {
          $som_rtt += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '5') {
          $som_maladie += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '6') {
          $som_recup += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '7') {
          $som_formation += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '8') {
          $som_abs_excep += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '9') {
          $som_sans_solde += 0.5;
          $str_pres .= "$_=".$dbh->quote($parametres{$_}).",";
#          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
      }
    };# fin du bloc do
    /^hsup(\d+)_/ && do {
      $taux = $1;
#      if($parametres{$_}=~ /^\d+$/) {
      if((!defined $parametres{$_}) || ($parametres{$_} eq ' ')) {
        $str_hsup .="$_=NULL,";
      }
      else {
        ($taux eq '0')? ($som_hsup_0 += $parametres{$_}) :
        ($taux eq '25') ? ($som_hsup_25 += $parametres{$_}) :
        ($taux eq '50') ? ($som_hsup_50 += $parametres{$_}) : ($som_hsup_100 +=$parametres{$_});
        $str_hsup .= "$_=".$dbh->quote($parametres{$_}).",";
        print "Heures sup pour : $_, valeur de \$1 : $1, valeur de parametres{\$_} : $parametres{$_}, som 0% : $som_hsup_0, som 25% : $som_hsup_25, som 50% : $som_hsup_50, som 100% : $som_hsup_100", $cgi->br();
      }
#        $str_value_hsup .= $dbh->quote($parametres{$_}).",";
      next;
    };# fin du bloc do
    /^ast_(\d+)$/ && do {
      if(exists $parametres{$_} ) {
        if($parametres{$_} == 1) {
          $str_ast .= "ajour_$1='1',anuit_$1=NULL,a24h_$1=NULL,";
#          $str_value_ast .= "'1',";
          $som_ast_jour++;
          next;
        }
        if($parametres{$_} == 2) {
          $str_ast .= "ajour_$1=NULL,anuit_$1='1',a24h_$1=NULL,";
#          $str_value_ast .= "'1',";
          $som_ast_nuit++;
          next;
        }
        if($parametres{$_} == 3) {
          $str_ast .= "ajour_$1=NULL,anuit_$1=NULL,a24h_$1='1',";
#          $str_value_ast .= "'1',";
          $som_ast_24++;
          next;
        }
      }
    }; # fin du bloc do
    /^c(\d+)$/ && do {
      if(length $parametres{$_} != 0) {
        $str_comment .= "com_$1 =".$dbh->quote(decode('utf-8', $parametres{$_})).",";
        next;
      }
    }; # fin du bloc do
  }
# Ici on fait l'update complet de la ligne dans la table ra
# On peut tester les valeurs des sommes calcul�es avec celles re�ues du client
  $som_conges_pris = $som_conges_payes + $som_rtt + $som_abs_excep + $som_sans_solde + $som_recup;
#  $ra = "INSERT INTO ra (idcollaborateur, idclient, mois, annee, valider, jfacture, projetint, formation, congespayes, congespris, rtt, congesexcept, jmaladie, sans_solde, hsupp0, hsupp25, hsupp50, hsupp100, ajour, anuit, a24h) VALUES (".$dbh->quote($collaborateur[0]).", ".$dbh->quote($parametres{client_id}).", ".$dbh->quote($mois{$parametres{mois}}).", ".$dbh->quote($parametres{annee}).", '0',".$dbh->quote($som_pres).", ".$dbh->quote($som_travail_interne).", ".$dbh->quote($som_formation).", ".$dbh->quote($som_conges_payes).", ".$dbh->quote($som_conges_pris).", ".$dbh->quote($som_rtt).", ".$dbh->quote($som_abs_excep).", ".$dbh->quote($som_maladie).", ".$dbh->quote($som_sans_solde).", ".$dbh->quote($som_hsup_0).", ".$dbh->quote($som_hsup_25).", ".$dbh->quote($som_hsup_50).", ".$dbh->quote($som_hsup_100).", ".$dbh->quote($som_ast_jour).", ".$dbh->quote($som_ast_nuit).", ".$dbh->quote($som_ast_24).")";
  $ra = "UPDATE ra SET jfacture = ".$dbh->quote($som_pres).", projetint = ".$dbh->quote($som_travail_interne).", formation = ".$dbh->quote($som_formation).", congespayes = ".$dbh->quote($som_conges_payes).", congespris = ".$dbh->quote($som_conges_pris).", rtt = ".$dbh->quote($som_rtt).", congesexcept = ".$dbh->quote($som_abs_excep).", jmaladie = ".$dbh->quote($som_maladie).", sans_solde = ".$dbh->quote($som_sans_solde).", hsupp0 = ".$dbh->quote($som_hsup_0).", hsupp25 = ".$dbh->quote($som_hsup_25).", hsupp50 = ".$dbh->quote($som_hsup_50).", hsupp100 = ".$dbh->quote($som_hsup_100).", ajour = ".$dbh->quote($som_ast_jour).", anuit = ".$dbh->quote($som_ast_nuit).", a24h = ".$dbh->quote($som_ast_24)." WHERE id = ".$dbh->quote($parametres{ra_id});
  #print "requete sql : $ra", $cgi->br();
  my $nb_lignes = $dbh->do($ra);
  return -10 unless $nb_lignes;
  if((defined $str_pres) && (length $str_pres != 0)){
    $str_pres =~ s/,$//;
    $ra_pres = "UPDATE ra_presence SET ".$str_pres." WHERE id = ".$dbh->quote($parametres{ra_id});
    #print "Sql pres : $ra_pres", $cgi->br, "Nbre de jours de pr�sence = $som_pres", $cgi->br();
    return -20 unless ($nb_lignes = $dbh->do($ra_pres));
  }
  if((defined $str_hsup) && (length $str_hsup != 0)) {
    $str_hsup =~ s/,$//;
    $ra_hsup = "UPDATE ra_hsup SET ".$str_hsup." WHERE id = ".$dbh->quote($parametres{ra_id});
    #print "Sql hsup : $ra_hsup", $cgi->br, "hsup 0% = $som_hsup_0, hsup 25% = $som_hsup_25, hsup 50% = $som_hsup_50, hsup 100% = $som_hsup_100", $cgi->br();
    return -30 unless ($nb_lignes = $dbh->do($ra_hsup));
  }
  if((defined $str_ast) &&(length $str_ast != 0)) {
    $str_ast =~ s/,$//;
    $ra_ast = "UPDATE ra_astreinte SET ".$str_ast." WHERE id = ".$dbh->quote($parametres{ra_id});
    #print "Sql astreinte : $ra_ast", $cgi->br, "Ast jour = $som_ast_jour, Ast nuit = $som_ast_nuit, Ast 24H = $som_ast_24", $cgi->br();
    return -40 unless ($nb_lignes = $dbh->do($ra_ast));
  }
  if((defined $str_comment) && (length $str_comment != 0)) {
    $str_comment =~ s/,$//;
    $ra_comment = "UPDATE ra_commentaire SET ".$str_comment. " WHERE id = ".$dbh->quote($parametres{ra_id});
    #print "Sql commentaire : $ra_comment", $cgi->br;
    return -50 unless ($nb_lignes = $dbh->do($ra_comment));
  }
  return 0;
}

