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
if(($rep = db_delete_ra()) > 0) {
#	print $cgi->redirect("$rep_pl/rapports_activites/show.pl?action=edition&annee=$parametres{annee}&mois=$parametres{mois}&ident_id=$parametres{id}");
	$nom_client = recherche_nom_client();
	#my $decodeMois = decode('utf-8', $parametres{mois});
	print $cgi->redirect("$rep_pl/ra_delete.pl?nb_lig=$rep&status=ok&client=$nom_client&annee=$parametres{annee}&mois=$parametres{mois}&ident_id=$parametres{ident_id}&ident_user=$parametres{ident_user}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}");	
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
sub db_delete_ra {
  my $del = "DELETE ra, ra_presence, ra_hsup, ra_astreinte, ra_commentaire FROM ra, ra_presence, ra_hsup, ra_astreinte, ra_commentaire WHERE ra_presence.id = ra_hsup.id AND ra_hsup.id = ra_astreinte.id AND ra_astreinte.id = ra_commentaire.id AND ra_commentaire.id = ra.id AND ra.id = ".$dbh->quote($parametres{ra_id});
  my $nb_lignes = 0;
  $nb_lignes = $dbh->do($del);
  return $nb_lignes;
}


