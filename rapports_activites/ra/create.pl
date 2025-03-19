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
my ($id, $ra_id, $nom_client, $ret);
#my $login;
our (@collaborateur, $dbh);
#my $tps_connexion = 600; # D�lai de connexion sans inactivité

# Tableau des RA
my (@ra, @ra_ast, @ra_comment, @ra_global, @ra_hsup, @ra_pres);

my %mois = ('Janvier', 1, 'Février', 2, 'Mars', 3, 'Avril', 4, 'Mai', 5, 'Juin', 6, 'Juillet', 7, 'Août', 8, 'Septembre', 9, 'Octobre', 10, 'Novembre', 11, 'Décembre', 12, 'D%E9cembre', 12);

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
	or die "problème de connexion à la base de donnèes collaborateur : $!";
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
if($parametres{mois} =~ /vrier$/) {
  $parametres{mois} = 'Février';
}
if($parametres{mois} =~ /^Ao/) {
  $parametres{mois} = 'Août';
}
if($parametres{mois} =~ /cembre$/) {
  $parametres{mois} = 'Décembre';
}
#visu_parametres();
@collaborateur = info_id($parametres{ident_id});
unless (@collaborateur) {
	entete_standard(); 
	print "Le parametre ident_id n'est pas défini dans la base de donnée", $cgi->br();
	visu_parametres(\%parametres);
	print $cgi->end_html();
#	die "Le parametre $parametres{ident_id} n'est pas défini dans la base dans la base de données";
	exit;
}

if(verif_tps_connexion == 0) { #D�lai d'attente d�pass�
	print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
	exit;
}

my $decodeMois = $parametres{mois};
if(($ret = db_creation_ra()) == 0) {
	$nom_client = recherche_nom_client();
	print $cgi->redirect("$rep_pl/rapports_activites/ra/show.pl?maj=$nom_client&action=edition&client_id=$parametres{client_id}&ra_id=$ra_id&annee=$parametres{annee}&mois=$decodeMois&ident_id=$parametres{ident_id}&ident_user=$parametres{ident_user}");
}	
else {
	my $script = "url=".$cgi->script_name."?";
	foreach (keys %parametres) {
			$script .= "$_=$parametres{$_}&";
	}
	print $cgi->redirect("$rep_pl/erreur.pl?$script&mois_num=$mois{$decodeMois}&Mois=$parametres{mois}&decodeMois=$decodeMois&err=$ret");
#	die "Le parametre parametres{ident_id} n'est pas d�fini dans la base dans la base de donn�es";
}
exit;
##################Requetes SQL ##############################################"
sub db_creation_ra {
  my ($cle, $som_pres, $som_travail_interne, $som_conges_payes, $som_conges_pris, $som_rtt);
  my ($som_maladie, $som_recup, $som_formation, $som_abs_excep, $som_sans_solde);
  my ($som_hsup_0, $som_hsup_25, $som_hsup_50, $som_hsup_100);
  my ($som_ast_jour, $som_ast_nuit, $som_ast_24);
  my ($str_id_pres, $str_value_pres, $str_id_comment, $str_value_comment);
  my ($str_id_hsup, $str_value_hsup, $str_id_ast, $str_value_ast, $taux);
  my ($ra, $ra_pres, $ra_hsup, $ra_ast, $ra_comment);
  $som_pres = $som_maladie = 0.0;
  $som_travail_interne = $som_recup = $som_formation = $som_abs_excep = 0.0;
  $som_conges_payes = $som_conges_pris = $som_rtt = $som_sans_solde = 0.0;
  $som_hsup_0 = $som_hsup_25= $som_hsup_50 = $som_hsup_100 = 0;
  $som_ast_jour = $som_ast_nuit = $som_ast_24 = 0;

  foreach (keys %parametres) {
    /^pmatin|^paprem/ && do {
      if($parametres{client_id} > 0) {
        if($parametres{$_} eq '1') {
          $som_pres += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
      }
      else { # RA pour T&S
        if($parametres{$_} eq '2') {
          $som_travail_interne+=0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '3') {
          $som_conges_payes += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '4'){
          $som_rtt += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '5'){
          $som_maladie += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '6'){
          $som_recup += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '7'){
          $som_formation += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '8'){
          $som_abs_excep += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
        if($parametres{$_} eq '9'){
          $som_sans_solde += 0.5;
          $str_id_pres .= "$_,";
          $str_value_pres .= $dbh->quote($parametres{$_}).",";
          next;
        }
      }
    };# fin du bloc do
    /^hsup(\d+)_/ && do {
      $taux = $1;
      if((defined $parametres{$_})&& ($parametres{$_}=~ /^\d+$/)){
        ($taux eq '0')? ($som_hsup_0 += $parametres{$_}):
        ($taux eq '25') ? ($som_hsup_25 += $parametres{$_}) :
        ($taux eq '50')? ($som_hsup_50 += $parametres{$_}): ($som_hsup_100 +=$parametres{$_});
        $str_id_hsup .= "$_,";
        $str_value_hsup .= $dbh->quote($parametres{$_}).",";
        next;
      }
    };# fin du bloc do
    /^ast_(\d+)$/ && do {
      if(exists $parametres{$_}) {
        if($parametres{$_} == 1){
          $str_id_ast .= "ajour_$1,";
          $str_value_ast .= "'1',";
          $som_ast_jour++;
          next;
        }
        if($parametres{$_} == 2){
          $str_id_ast .= "anuit_$1,";
          $str_value_ast .= "'1',";
          $som_ast_nuit++;
          next;
        }
        if($parametres{$_} == 3){
          $str_id_ast .= "a24h_$1,";
          $str_value_ast .= "'1',";
          $som_ast_24++;
          next;
        }
      }
    }; # fin du bloc do
    /^c(\d+)$/ && do {
      if(length $parametres{$_} != 0){
        $str_id_comment .= "com_$1,";
        $str_value_comment .= $dbh->quote(decode('utf-8', $parametres{$_})).",";
        next;
      }
    }; # fin du bloc do
  }
# Ici on fait l'ins�re complet de la ligne dans la table ra
# et on r�cup�re ainsi le nouveau ra_id.
# On peut tester les valeurs des sommes calcul�es avec celles re�ues du client
  $som_conges_pris = $som_conges_payes + $som_rtt + $som_abs_excep + $som_sans_solde + $som_recup;
# Poser un verrou WRITE sur les tables ra, ra_presence, ra_hsup, ra_astreinte, ra_commentaire
  my $res;
  $res = $dbh->do('LOCK TABLES ra WRITE, ra_astreinte WRITE, ra_hsup WRITE, ra_commentaire WRITE, ra_presence WRITE');
# V�rifie que le ra n'existe pas
  $ra = "SELECT id FROM ra WHERE idcollaborateur = ".$dbh->quote($collaborateur[0])." AND idclient = ".$dbh->quote($parametres{client_id})." AND mois = ".$dbh->quote($mois{$parametres{mois}})." AND annee = ".$dbh->quote($parametres{annee})." AND valider = '0'";
  my $sth = $dbh->prepare($ra);
  $sth->execute();
  ($ra_id) = $sth->fetchrow_array();
  if(defined $ra_id) {
    return (-1*$ra_id);
  }
  #$ra = "INSERT INTO ra (idcollaborateur, idclient, mois, annee, valider, jfacture, projetint, formation, congespayes, congespris, rtt, congesexcept, jmaladie, sans_solde, hsupp0, hsupp25, hsupp50, hsupp100, ajour, anuit, a24hVALUES (".$dbh->quote($collaborateur[0]).", ".$dbh->quote($parametres{client_id}).", ".$dbh->quote($mois{$parametres{mois}}).", ".$dbh->quote($parametres{annee}).", '0',".$dbh->quote($som_pres).", ".$dbh->quote($som_travail_interne).", ".$dbh->quote($som_formation).", ".$dbh->quote($som_conges_payes).", ".$dbh->quote($som_conges_pris).", ".$dbh->quote($som_rtt).", ".$dbh->quote($som_abs_excep).", ".$dbh->quote($som_maladie).", ".$dbh->quote($som_sans_solde).", ".$dbh->quote($som_hsup_0).", ".$dbh->quote($som_hsup_25).", ".$dbh->quote($som_hsup_50).", ".$dbh->quote($som_hsup_100).", ".$dbh->quote($som_ast_jour).", ".$dbh->quote($som_ast_nuit).", ".$dbh->quote($som_ast_24).")";
  #if($parametres{mois} =~ m/vrier$/) {
  #  #$ra = "INSERT INTO ra (idcollaborateur, idclient, mois, annee, valider, jfacture, projetint, formation, congespayes, congespris, rtt, congesexcept, jmaladie, sans_solde, hsupp0, hsupp25, hsupp50, hsupp100, ajour, anuit, a24h) VALUES (".$dbh->quote($collaborateur[0]).", ".$dbh->quote($parametres{client_id}).", '2', ".$dbh->quote($parametres{annee}).", '0',".$dbh->quote($som_pres).", ".$dbh->quote($som_travail_interne).", ".$dbh->quote($som_formation).", ".$dbh->quote($som_conges_payes).", ".$dbh->quote($som_conges_pris).", ".$dbh->quote($som_rtt).", ".$dbh->quote($som_abs_excep).", ".$dbh->quote($som_maladie).", ".$dbh->quote($som_sans_solde).", ".$dbh->quote($som_hsup_0).", ".$dbh->quote($som_hsup_25).", ".$dbh->quote($som_hsup_50).", ".$dbh->quote($som_hsup_100).", ".$dbh->quote($som_ast_jour).", ".$dbh->quote($som_ast_nuit).", ".$dbh->quote($som_ast_24).")";
  #  $parametres{mois} = 'Février';
  #}
  #else {
  #  if($parametres{mois} =~ m/^Ao/) {
  #    #$ra = "INSERT INTO ra (idcollaborateur, idclient, mois, annee, valider, jfacture, projetint, formation, congespayes, congespris, rtt, congesexcept, jmaladie, sans_solde, hsupp0, hsupp25, hsupp50, hsupp100, ajour, anuit, a24h) VALUES (".$dbh->quote($collaborateur[0]).", ".$dbh->quote($parametres{client_id}).", '8', ".$dbh->quote($parametres{annee}).", '0',".$dbh->quote($som_pres).", ".$dbh->quote($som_travail_interne).", ".$dbh->quote($som_formation).", ".$dbh->quote($som_conges_payes).", ".$dbh->quote($som_conges_pris).", ".$dbh->quote($som_rtt).", ".$dbh->quote($som_abs_excep).", ".$dbh->quote($som_maladie).", ".$dbh->quote($som_sans_solde).", ".$dbh->quote($som_hsup_0).", ".$dbh->quote($som_hsup_25).", ".$dbh->quote($som_hsup_50).", ".$dbh->quote($som_hsup_100).", ".$dbh->quote($som_ast_jour).", ".$dbh->quote($som_ast_nuit).", ".$dbh->quote($som_ast_24).")"; 
  #    $parametres{mois} = 'Août';    
  #  }
  #  else {
  #    if($parametres{mois} =~ m/cembre$/) {
  #      #$ra = "INSERT INTO ra (idcollaborateur, idclient, mois, annee, valider, jfacture, projetint, formation, congespayes, congespris, rtt, congesexcept, jmaladie, sans_solde, hsupp0, hsupp25, hsupp50, hsupp100, ajour, anuit, a24h) VALUES (".$dbh->quote($collaborateur[0]).", ".$dbh->quote($parametres{client_id}).", '12', ".$dbh->quote($parametres{annee}).", '0',".$dbh->quote($som_pres).", ".$dbh->quote($som_travail_interne).", ".$dbh->quote($som_formation).", ".$dbh->quote($som_conges_payes).", ".$dbh->quote($som_conges_pris).", ".$dbh->quote($som_rtt).", ".$dbh->quote($som_abs_excep).", ".$dbh->quote($som_maladie).", ".$dbh->quote($som_sans_solde).", ".$dbh->quote($som_hsup_0).", ".$dbh->quote($som_hsup_25).", ".$dbh->quote($som_hsup_50).", ".$dbh->quote($som_hsup_100).", ".$dbh->quote($som_ast_jour).", ".$dbh->quote($som_ast_nuit).", ".$dbh->quote($som_ast_24).")";
  #      $parametres{mois} = 'Décembre';
  #    }
  #    else {
  #      #$ra = "INSERT INTO ra (idcollaborateur, idclient, mois, annee, valider, jfacture, projetint, formation, congespayes, congespris, rtt, congesexcept, jmaladie, sans_solde, hsupp0, hsupp25, hsupp50, hsupp100, ajour, anuit, a24h) VALUES (".$dbh->quote($collaborateur[0]).", ".$dbh->quote($parametres{client_id}).", ".$dbh->quote($mois{$parametres{mois}}).", ".$dbh->quote($parametres{annee}).", '0',".$dbh->quote($som_pres).", ".$dbh->quote($som_travail_interne).", ".$dbh->quote($som_formation).", ".$dbh->quote($som_conges_payes).", ".$dbh->quote($som_conges_pris).", ".$dbh->quote($som_rtt).", ".$dbh->quote($som_abs_excep).", ".$dbh->quote($som_maladie).", ".$dbh->quote($som_sans_solde).", ".$dbh->quote($som_hsup_0).", ".$dbh->quote($som_hsup_25).", ".$dbh->quote($som_hsup_50).", ".$dbh->quote($som_hsup_100).", ".$dbh->quote($som_ast_jour).", ".$dbh->quote($som_ast_nuit).", ".$dbh->quote($som_ast_24).")";
  #    }
  #  }
  #}
  $ra = "INSERT INTO ra (idcollaborateur, idclient, mois, annee, valider, jfacture, projetint, formation, congespayes, congespris, rtt, congesexcept, jmaladie, sans_solde, hsupp0, hsupp25, hsupp50, hsupp100, ajour, anuit, a24h) VALUES (".$dbh->quote($collaborateur[0]).", ".$dbh->quote($parametres{client_id}).", ".$dbh->quote($mois{$parametres{mois}}).", ".$dbh->quote($parametres{annee}).", '0',".$dbh->quote($som_pres).", ".$dbh->quote($som_travail_interne).", ".$dbh->quote($som_formation).", ".$dbh->quote($som_conges_payes).", ".$dbh->quote($som_conges_pris).", ".$dbh->quote($som_rtt).", ".$dbh->quote($som_abs_excep).", ".$dbh->quote($som_maladie).", ".$dbh->quote($som_sans_solde).", ".$dbh->quote($som_hsup_0).", ".$dbh->quote($som_hsup_25).", ".$dbh->quote($som_hsup_50).", ".$dbh->quote($som_hsup_100).", ".$dbh->quote($som_ast_jour).", ".$dbh->quote($som_ast_nuit).", ".$dbh->quote($som_ast_24).")";
  #print "requete sql : $ra", $cgi->br();
  my $nb_lignes = $dbh->do($ra);
  return -1 unless $nb_lignes;
#  my $sth = $dbh->prepare($ra);
#  $sth->execute();
  $ra = "SELECT id FROM ra WHERE idcollaborateur = ".$dbh->quote($collaborateur[0])." AND idclient = ".$dbh->quote($parametres{client_id})." AND mois = ".$dbh->quote($mois{$parametres{mois}})." AND annee = ".$dbh->quote($parametres{annee})." AND valider = '0'";
  $sth = $dbh->prepare($ra);
  $sth->execute();
  ($ra_id= $sth->fetchrow_array());
#  print "L'identification du RA : $ra_id", $cgi->br();
  if((defined $str_id_pres) && (length $str_id_pres != 0)){
    $str_id_pres =~ s/,$//;
    $str_value_pres =~ s/,$//;
    $ra_pres = "INSERT INTO ra_presence (id, $str_id_pres) VALUES (".$dbh->quote($ra_id).",$str_value_pres)";
  }
  else {
    $ra_pres = "INSERT INTO ra_presence (id) VALUES (".$dbh->quote($ra_id).")";
  }

  $nb_lignes = $dbh->do($ra_pres);
  if((defined $str_id_hsup) && (length $str_id_hsup != 0)) {
    $str_id_hsup =~ s/,$//;
    $str_value_hsup =~ s/,$//;
    $ra_hsup = "INSERT INTO ra_hsup (id, $str_id_hsup) VALUES (".$dbh->quote($ra_id).",$str_value_hsup)";
  }
  else {
    $ra_hsup = "INSERT INTO ra_hsup (id) VALUES (".$dbh->quote($ra_id).")";
  }

  $nb_lignes = $dbh->do($ra_hsup);
  if((defined $str_id_ast) &&(length $str_id_ast != 0)){
    $str_id_ast =~ s/,$//;
    $str_value_ast =~ s/,$//;
    $ra_ast = "INSERT INTO ra_astreinte (id, $str_id_ast) VALUES (".$dbh->quote($ra_id).",$str_value_ast)";
  }
  else {
    $ra_ast = "INSERT INTO ra_astreinte (id) VALUES (".$dbh->quote($ra_id).")";
  }
#  print "Sql astreinte : $ra_ast", $cgi->br, "Ast jour = $som_ast_jour, Ast nuit = $som_ast_nuit, Ast 24H = $som_ast_24", $cgi->br();
  $nb_lignes = $dbh->do($ra_ast);
  if((defined $str_id_comment) && (length $str_id_comment != 0)){
    $str_id_comment =~ s/,$//;
    $str_value_comment =~ s/,$//;
    $ra_comment = "INSERT INTO ra_commentaire (id, $str_id_comment) VALUES (".$dbh->quote($ra_id).",$str_value_comment)";
  }
  else {
    $ra_comment = "INSERT INTO ra_commentaire (id) VALUES (".$dbh->quote($ra_id).")";
  }
#  print "Sql commentaire : $ra_comment", $cgi->br;
  $nb_lignes = $dbh->do($ra_comment);
  $res = $dbh->do('UNLOCK TABLES');
  return 0;
}

