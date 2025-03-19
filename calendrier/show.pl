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
our %parametres =();
our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
my $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);
$mois += 1;
$annee += 1900;

# Date de cr�ation de Technologies et Services
our @date_ts = (2003, 1, 1);



my %connexion = (
        'connexion'     => \&affiche_ecran_connexion, # saisie du login
        'Envoi'         => \&connexion, # Acc�s � la base et valide connexion
        'Compte'        => \&gestion_compte,# G�re le compte dans la base
        'compte'        => \&gestion_compte,# G�re le compte dans la base
#       'D�connexion'   => \&deconnexion, # d�connecte le compte.
);
					
#Table des etats associants � chaque document son sous-programmes

our $cgi = new CGI;
#R�cup�ration du param�tre .Etat n�cessaire pour g�rer le menu droit
my $ecran_actuel = $cgi->param(".Etat") || "Defaut";

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
	$rep = '../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib/";
}
# D�claration du r�pertoire de base
#our $rep = '../../../test/jude/V3.0';
# D�claration pour javascript
use Etechnoserv qw(info_id);
use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use Affichage;
use Connexion;

my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# D�claration des feuilles de styles
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
#R�cup�ration du param�tre .Connexion  partie droite de l'ent�te
my $connexion = $cgi->param(".Connexion") || "connexion";
unless ($connexion{$connexion}){
  entete_standard();
  die "Pas de fonction pour $connexion" ;
}

my $bouton;

if(($ecran_actuel eq 'OK') || ($ecran_actuel eq 'Appliquer')) {
  $bouton = $ecran_actuel;
}

my @msg_maj;
my $vide = $cgi->param(".defaults");
$id = $cgi->param('ident_id');
if(defined($id)) {
  @collaborateur = info_id($id);
  if(verif_tps_connexion() == 0) { #D�lai d'attente d�pass�
	print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
	exit;
  }
}
else {
	print $cgi->header(), $cgi->start_html(title=>'Calendrier v1.0'); 
	print "Le parametre ident_id n'existe pas dans la ligne de commande", $cgi->end_html();
	exit;  
}

  #  if(($connexion ne 'D�connexion') && (verif_tps_connexion() == 0)) {# d�lai d�pass�

#    @collaborateur = undef;
#    $id = undef;
# }
  if($connexion eq 'D�connexion') {
    deconnexion();
    print $cgi->redirect("$rep_pl/etechnoserv.pl");
    exit;
  }
  if($ecran_actuel eq 'Compte') {
    print $cgi->redirect("$rep_pl/compte/identification/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
  }	
  if($ecran_actuel eq "Rapports d'activit�s") {
    print $cgi->redirect("$rep_pl/rapports_activites/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
  }	
  if($ecran_actuel eq "Accueil") {
    print $cgi->redirect("$rep_pl/donnees_sociales/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
  }	
  if($ecran_actuel eq "Vie sociale") {
    print $cgi->redirect("$rep_pl/vie_sociale/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
  }	
  if($ecran_actuel eq "Optis") {
    print $cgi->redirect("$rep_pl/optis/menug/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
	exit;
  }	


$ecran_actuel = 'Calendrier';
entete_standard();

affiche_4_zones();

exit;

sub entete_standard {
  my $url = $cgi->url;
  print $cgi->header();
  if($ecran_actuel eq 'Calendrier') {
    print $cgi->start_html({-head => @liens, -Title => "Calendrier v1.0", -script => \%script,
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
    print "\n", $cgi->start_form();  # D�but du formulaire du menu droit
#    print "\n", $cgi->hidden(-name=>'ident_nom', -value=>"$login");
    print "\n", $cgi->hidden(-name=>'ident_id', -value=>"$id");
# Voici la boucle principale
    calendrier();
    print "\n", $cgi->end_form();# Fin du formulaire du menu droit
  }
  else {
    my $page = $cgi->param('page')|| 'defaut';
    if($page eq '1') {
      affiche_page_html('nous.htm');
    }
    elsif ($page eq '2') {
      affiche_page_html('vous.htm');
    }
    elsif ($page eq '3') {
      affiche_page_html('metier.htm');
    }
    elsif ($page eq '4') {  # g�rer les ann�es
      affiche_page_html('realisations.htm');
    }
    elsif ($page eq '5') {
      affiche_page_html('references.htm');
    }
    elsif ($page eq '6') {
      affiche_page_html('recrutement.htm');      
    }
    elsif($page eq '7') {
      affiche_page_html('documentation.htm');
    }    
    else {
      affiche_page_html('defaut');
    }

  }
  print "\n", $cgi->end_div(); # fin du div de droite
}

sub affiche_page_html {
  my ($page) = @_;
  if($page eq 'defaut') {
    print "\n", $cgi->p($cgi->start_object({-data=>"$rep/nous.htm",
           -type=>'text/html'}), $cgi->end_object());
  }
  else {
    print "\n", $cgi->p($cgi->start_object({-data=>"$rep/$page",
           -type=>'text/html'}), $cgi->end_object());
  }
}

