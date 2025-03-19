#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Date::Calc qw(:all);
use Time::Local;

# D�claration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our $dbh;
our $type;

our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
my $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);
$mois += 1;
$annee += 1900;

# Date de cr�ation de Technologies et Services
our @date_ts = (2003, 1, 1);

our ($erreur, $msg_erreur);
our %erreur = (
		'1'	=> "*Erreur : le login n'est pas correct. Sa taille est comprise entre [4, 20]. Il ne doit pas contenir des caract�res interdits.",
		'2'	=> "*Erreur sur le login ou le mot de passe.",
		'3'	=> "D&eacute;lai d'inactivit&eacute; d&eacute;pass&eacute;, Veuillez vous reconnecter",
	);	


#### Dans le menu droit, les boutons du bas
my @boutons_bas = ( ["Donn�es sociales", 0x1],
                    ["Rapports d'activit&eacute;s", 0x2],
                    ["Calendrier", 0x4],
                    ["Compte", 0x8]);


#Table des etats associants � chaque document son sous-programmes
#my %etats;

my $ecran_actuel;

my %etats = (
	'Defaut'		=> \&donnees_sociales,
	'Calendrier'		=> \&calendrier,
	"Rapports d'activit�s"		=> \&gestion_ra,
	"Rapports d'activites"  => \&gestion_ra,
	'Compte'        	=> \&gestion_compte,
	'Donn�es sociales'			=> \&donnees_sociales,
	'Donnees sociales'			=> \&donnees_sociales,
);

my %compte = (
  'identification'            => \&menu_compte_identification,
  'communication'     => \&menu_compte_communication,
  'missions'          => \&menu_compte_missions,
  'mot_de_passe'          => \&menu_compte_mot_de_passe,
  'OK'                => \&menu_compte_ok,
  'Appliquer'         => \&menu_compte_appliquer,
#  'Annuler'           => \&gestion_compte,
);

#my %connexion = (
#        'connexion'     => \&affiche_ecran_connexion, # saisie du login
#        'Envoi'         => \&connexion, # Acc�s � la base et valide connexion
#        'Compte'        => \&gestion_compte,# G�re le compte dans la base
#        'compte'        => \&gestion_compte,# G�re le compte dans la base
#        'D�connexion'   => \&deconnexion, # d�connecte le compte.
#);

our $cgi = new CGI;
#$cgi = new CGI;
#R�cup�ration du param�tre .Etat n�cessaire pour g�rer le menu droit
$ecran_actuel = $cgi->param(".Etat") || "Defaut";
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
	$rep = '../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib/";
}
use Etechnoserv qw(info_id);
#use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);
use Affichage;
use Connexion;

# D�claration pour javascript
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
         'rel'             => 'shotcut icon',
#         'type'            => 'image/png',
         'href'            => "$rep/images/favicon.ico",		 
       }),
	   #meta({
		#   'http-equiv' => '"Content-Type" content="text/html; charset=utf-8"',
	   #}),   
];

#R�cup�ration du param�tre .Connexion  partie droite de l'ent�te
my $connexion = $cgi->param(".Connexion") || "connexion";

$type = $cgi->param("type");
if(defined($type) && $type == 'json') {
  print $cgi->header('application/json; charset=utf8');
  print '{"Title":"Etude NodeJs/Express Perl, OAuth2.0, etc.","User":{"Status":0},"Menu":{"Header":[{"Label":"Home","Body":"Ceci est le texte du menu Home"},{"Label":"Qui sommes-nous?","Body":"Ceci est le texte du menu \"Qui sommes-nous?\""},{"Label":"Nos réalisations","Body":"Ceci est le texte du menu \"Nos réalisations\""}]},"Titre":"Home Page","MenuHautPage":"Utilisateur non connecté","MenuDroit":"Menu droit","MenuGauche":"Menu gauche","MenuBasDePage":"Technologies et Services : 2023 - 2024","Msg":"Bienvenue pour cette étude"}';
  exit(0);
}
#unless ($connexion{$connexion}){
#  entete_standard();
#  die "Pas de fonction pour $connexion" ;
#}

my $bouton;

if(($ecran_actuel eq 'OK') || ($ecran_actuel eq 'Appliquer')) {
  $bouton = $ecran_actuel;
}
else {
  unless ($etats{$ecran_actuel}){
   entete_standard();
   die "Pas d'ecran ni de bouton pour $ecran_actuel";
  }
}
# 0 = smenu, 1 = identification du champ, 2 = msg. Maj dans la fonction
# menu_compte_verif_donnes et utilis�e dans les fonctions d'affichage du menu
# Compte
my @msg_maj;
my $vide = $cgi->param(".defaults");
$id = $cgi->param('ident_id');
$erreur = $cgi->param('err');
if(defined($id)) {
  @collaborateur = info_id($id);
  if(($connexion ne 'D�connexion') && (verif_tps_connexion() == 0)) {# d�lai d�pass�

    @collaborateur = undef;
    $id = undef;
  }
  if($connexion eq 'D�connexion') {
    print $cgi->redirect($cgi->script_name);
    exit;
  }

  if($ecran_actuel eq 'Appliquer') {
#    print "id avant mise � jour : $id", $cgi->br();
    entete_standard();
    menu_compte_maj_collaborateur();
  }
}
else {
	if($connexion eq 'Envoi') {
		my $login = $cgi->param("login");
		my $pswd = $cgi->param("pswd");
# Faire les v�rifications de login et pswd comme dans le javascript (� faire
		if((verif_login($login) == 1) && (connexion_db($login, $pswd) == 1)) {
#			print $cgi->redirect("../V3.0/donnees_sociales/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
			print $cgi->redirect("$rep_pl/donnees_sociales/show.pl?ident_id=$id&ident_user=$collaborateur[3]");
			exit;
#			affiche_menu_connexion(2);
		}
# Verif_login() ou connexion_db() ont renvoy� une erreur
		else{
			print $cgi->redirect($cgi->script_name."?err=$erreur");
			exit;
		}
	}

}
entete_standard();
affiche_4_zones();

exit;

sub entete_standard {
  my $url = $cgi->url;
  print $cgi->header();
  if($ecran_actuel eq 'Calendrier') {
    print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0", -script => \%script,
			-encoding => "utf-8",
              -style =>\%style, -xbase => "$url", onLoad => 'return gestion_affichage_rdv();'});
  }
  else {
    print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0", -script => \%script,
			-encoding => "UTF-8",
              -style =>\%style, -xbase => "$url", onLoad => 'return select_login();'});
  }
#  print "url = $url", $cgi->br(), "self_url = ", $cgi->self_url, $cgi->br();
}

sub affiche_4_zones {
    affiche_debut_corps_de_page();
    affiche_entete_login_non_connecte();
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
    while (my ($nom_ecran, $fonction) = each %etats) {
  	$fonction->($nom_ecran eq $ecran_actuel);
    }

    if(defined($bouton)) {
      if($bouton eq 'Appliquer') {
        menu_compte_appliquer();
      }
      if($bouton eq 'OK') {
        menu_compte_ok();
      }
    }
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
    print "\n", $cgi->p($cgi->start_object({-data=>"$rep/html/nous.htm",
           -type=>'text/html'}), $cgi->end_object());
  }
  else {
    print "\n", $cgi->p($cgi->start_object({-data=>"$rep/html/$page",
           -type=>'text/html'}), $cgi->end_object());
  }
}

#Sous programme pour le document par defaut
sub donnees_sociales {
  my $actif = shift;
  return unless $actif;
  return unless $id;
  my @date = split /-/, $collaborateur[5];
  print $cgi->h2("$collaborateur[2], bienvenue dans l'espace collaborateur.");
  my ($Da, $Dm, $Dj) = Delta_Dates_AMJ($date[0], $date[1], $date[2],
                       $annee, $mois, $jour);
  my $date_sortie;
  if($collaborateur[6]) {
     my @date_sortie = split /-/, $collaborateur[6];
     $date_sortie = "$date_sortie[2]\/$date_sortie[1]\/$date_sortie[0]";
  }
  else {
     $date_sortie = '';
  }
# Affichage dans un div gauche et dans un div droite => 2 colonnes
  print "\n", $cgi->start_div({-id => 'affiche_donnees_sociales'}), "\n";
  print $cgi->start_div({-id=> 'infos_generales'}), "\n",
        $cgi->span("Informations g�n�rales >> Date d'arriv�e : $date[2]\/$date[1]\/$date[0],",
        "Temps de pr�sence :",($Da >0)?"$Da an(s) ":'',($Dm >0)?"$Dm mois ":'',($Dj>0)?"$Dj jour(s)":'', $cgi->br, "Planning pr�visionnel :");

  print $cgi->start_div({-id=>'col_gauche'}), "Edition Rapport d'Activit�s :",
     $cgi->br, "Prochaine formation :",
     $cgi->br, "Convocation visite m�dicale :",
     $cgi->br, "Convocation entretien d'�valuation :",
     $cgi->br, "N�gociation salariale :",
     $cgi->end_div(), "\n";
  print $cgi->start_div({-id => 'col_droite'}), date_edition_ra(),
     $cgi->br, "",
     $cgi->br, date_visite_medicale(@date, $Da, $Dm, $Dj),
     $cgi->br, date_entretien(@date),
     $cgi->br, date_negociation(@date, $Da, $Dm, $Dj),
     $cgi->br, "",
     $cgi->end_div(), "\n";
  print $cgi->end_div(); # Fin du Div info_g�n�rales
  affiche_conges_payes(@date, $Da, $Dm, $Dj);
  affiche_rtt(@date, $Da,$Dm, $Dj);
   print $cgi->end_div();    # fin du div affiche_donn�es_sociales
   menu_social(0xe);
}

sub date_negociation {
  date_visite_medicale(@_);
}
sub date_entretien {
 ;
}

sub date_visite_medicale {
# La visite m�dicale est annuelle et intervient normalement dans le mois
#anniversaire de son entr�e dans la soci�t�.
  my ($a_in, $m_in, $j_in, $Da, $Dm, $Dj) = @_;
  my (@date_vm )= Add_Delta_YM($a_in, $m_in, $j_in, $Da + 1, 0);
# On retire 15 jours � la date anniversaire d'entr�e dans la soci�t�.
  @date_vm = Add_Delta_Days($date_vm[0], $date_vm[1], $date_vm[2], -15);
  return (($date_vm[1] < 10?"0$date_vm[1]":"$date_vm[1]")."\/$date_vm[0]");
#  return (($date_vm[1] < 10?"0$date_vm[1]":"$date_vm[1]")."\/$Da");
}

sub date_edition_ra {
  my $mois_ra = $mois;
  my $annee_ra = $annee;
  my $jour_ra;
  my @ra;
# Recherche du mois et de l'ann�e d'�dition du prochain RA en fonction des RA
#existants dans la base.
  do {
    my $sql= "SELECT * FROM ra WHERE idcollaborateur = ".$dbh->quote($id)." AND mois = ".$dbh->quote($mois_ra)." AND annee = ".$dbh->quote($annee_ra);
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    @ra = $sth->fetchrow_array();
    if (defined($ra[0])) {
      ($mois_ra < 12)? $mois_ra++ : ($mois_ra = 1, $annee_ra++);
    }
  }
#  while (@ra != undef);
  while (defined($ra[0]));
# Gestion du dernier jour ouvr� en prenant les jours f�ri�s et les cong�s, RTT
  $jour_ra = Days_in_Month($annee_ra, $mois_ra);
# Test pour le mois 12/05 pour le compte jean validation gestion f�ries/ouvr�s
#  my $test = 0;
#  if($test == 0) {
#    $jour_ra += -6;
#    $test = 1;
#  }
  my $est_ouvre;
  my $est_ferie;
  do {
    do { # Gestion des jours f�ri�s
      if($est_ferie = est_ferie($jour_ra, $mois_ra, $annee_ra)) {
        ($annee_ra, $mois_ra, $jour_ra) = Add_Delta_Days($annee_ra, $mois_ra,
         $jour_ra, -1);
      }
    }
    while($est_ferie);
    do { # Gestion des jours ouvr�s
      my $jour_semaine = Day_of_Week($annee_ra, $mois_ra, $jour_ra);
      if($jour_semaine > 5) {
        $est_ouvre = 0;
        ($annee_ra, $mois_ra, $jour_ra) = Add_Delta_Days($annee_ra, $mois_ra,
         $jour_ra, 5 - $jour_semaine);
      }
      else {
        $est_ouvre = 1;
      }
    }
    while (!$est_ouvre);
  }
  while($est_ferie && !$est_ouvre); # Sortie de boucle
  return ("$jour_ra\/".($mois_ra < 10?"0$mois_ra":"$mois_ra")."\/$annee_ra");
}


sub affiche_conges_payes {
  my $acquis_now;
  my ($arrondi, $res);
  my $acquis_avant;
  my $pris_now;
  my $pris_avant;
  my ($prendre_now, $prendre_avant);
  $res = 2.5*$jour/Days_in_Month($annee, $mois);
  $arrondi = $res <= 0.5 ? 0.5 :
             $res <= 1   ? 1   :
             $res <= 1.5 ? 1.5 :
             $res <= 2   ? 2   : 2.5;

  $acquis_now = ($mois == 1)? $arrondi:($mois -1)*2.5 + $arrondi;
  $acquis_avant = conges_payes_anterieurs(@_);
  ($pris_now, $pris_avant) = conges_pris(@_);
  $prendre_now = $acquis_now - $pris_now;
  $prendre_avant = $acquis_avant - $pris_avant;

  print $cgi->start_div({-id => 'affiche_conges_payes'});
  print $cgi->div({-class => 'Titre'}, 'D�compte des cong�s pay�s');
  print $cgi->start_div({-class => 'Libelle'});
  print $cgi->br, "Ann�e $annee ",
        $cgi->br, 'Ann�es ant�rieures ',
        $cgi->br, 'Total ' ;
  print "\n", $cgi->end_div(); # Fin du div libelle
  print $cgi->start_div({-class => 'Acquis'}), $cgi->span({-class => 'L1'},'Acquis');
  print $cgi->br, $acquis_now,
        $cgi->br, $acquis_avant,
        $cgi->br, $acquis_now + $acquis_avant;
  print "\n", $cgi->end_div(); # Fin du div Acquis

  print $cgi->start_div({-class => 'Pris'}), $cgi->span({-class => 'L1'}, 'Pris');
  print $cgi->br, $pris_now,
        $cgi->br, $pris_avant,
        $cgi->br, $pris_now + $pris_avant;
  print "\n", $cgi->end_div(); # Fin du div Pris

  print $cgi->start_div({-class => 'A_prendre'}), $cgi->span({-class => 'L1'}, 'A prendre');
  print $cgi->br, $prendre_now,
        $cgi->br, $prendre_avant,
        $cgi->br, $prendre_now + $prendre_avant;
  print "\n", $cgi->end_div(); # Fin du div A prendre
  print "\n", $cgi->end_div(); # Fin du div affiche_conges_payes
}

sub conges_payes_anterieurs {
  my ($a_in, $m_in, $j_in, $Da, $Dm, $Dj) = @_;
  my $acquis;
  my $arrondi;
  my $diff;
  my $res;
  if($annee == $a_in) { # 1�re ann�e dans la soci�t�
    $acquis = 0;
  }
  elsif($Da > 5) {
# On limite la recherche � 5 ans en arri�re.
       $acquis = 2.5*5*12;
  }
  else {#Delta entre le 31/12/ann�e -1 et la date d'entr�e chez T&S
      ($Da, $Dm, $Dj) = Delta_YMD( $a_in, $m_in, $j_in, ($annee -1), 12, 31);
      $res = 2.5*$Dj/Days_in_Month($a_in, $m_in);
      $arrondi = $res <= 0.5 ? 0.5 :
                 $res <= 1   ? 1   :
                 $res <= 1.5 ? 1.5 :
                 $res <= 2   ? 2   : 2.5;
      $acquis = 2.5*$Da*12 + 2.5*$Dm + $arrondi;
  }
  return $acquis;
}

sub conges_pris {
  my ($a_in, $m_in, $j_in, $Da, $Dm, $Dj) = @_;
  my ($cpt_now, $cpt_avant);
  my $sql= "SELECT SUM(congespayes) FROM ra WHERE idcollaborateur = ".$dbh->quote($id)." AND annee = ".$dbh->quote($annee)." AND mois <= ".$dbh->quote($mois)." AND valider = '1'";
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  ($cpt_now) = $sth->fetchrow_array();

  if($Da == 0) { # 1�re ann�e dans la soci�t�, pas de cong�s anterieurs
    $cpt_avant = 0;
  }
  elsif($Da > 5) {
# On limite la recherche � 5 ans en arri�re.
    my $sql= "SELECT SUM(congespayes) FROM ra WHERE idcollaborateur = ".$dbh->quote($id)." AND annee BETWEEN ".$dbh->quote($annee - 6)." AND ".$dbh->quote($annee - 1)." AND valider = '1'";
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    ($cpt_avant) = $sth->fetchrow_array();
  }
  else {#Delta entre le 31/12/ann�e -1 et la date d'entr�e chez T&S
    my $sql= "SELECT SUM(congespayes) FROM ra WHERE idcollaborateur = ".$dbh->quote($id)." AND annee BETWEEN ".$dbh->quote($a_in)." AND ".$dbh->quote($annee - 1)." AND valider = '1'";
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    ($cpt_avant) = $sth->fetchrow_array();
  }
  $cpt_now = defined($cpt_now) ? $cpt_now : 0;
  $cpt_avant = defined($cpt_avant) ? $cpt_avant : 0;

  return ($cpt_now, $cpt_avant);
}

sub affiche_rtt {
  my ($a_in, $m_in, $j_in, $Da, $Dm, $Dj) = @_;
  my $acquis_now;
  my ($arrondi, $res);
  my $acquis_avant;
  my $pris_now;
  my $pris_avant;
  my ($prendre_now, $prendre_avant);

  $acquis_now = ($mois -1)*0.5;
  $acquis_avant = rtt_anterieur(@_);
  $acquis_avant = (defined($acquis_avant)) ? $acquis_avant : 0;
  #$acquis_avant = ($mois < 4)? 6: 0;
  ($pris_now, $pris_avant) = rtt_pris(@_, $acquis_avant);
  $prendre_now = $acquis_now - $pris_now;
  $prendre_avant = $acquis_avant - $pris_avant;

  print $cgi->start_div({-id => 'affiche_rtt'});
  print $cgi->div({-class => 'Titre'}, 'D�compte des RTT');
  print $cgi->start_div({-class => 'Libelle'});
  print $cgi->br, "Ann�e $annee ",
        $cgi->br, "Ann�e ",$annee - 1,
        $cgi->br, 'Total ' ;
  print "\n", $cgi->end_div(); # Fin du div libelle
  print $cgi->start_div({-class => 'Acquis'}), $cgi->span({-class => 'L1'},'Acquis');
  print $cgi->br, "$acquis_now",
        $cgi->br, "$acquis_avant",
        $cgi->br, $acquis_now + $acquis_avant;
  print "\n", $cgi->end_div(); # Fin du div Acquis

  print $cgi->start_div({-class => 'Pris'}), $cgi->span({-class => 'L1'}, 'Pris');
  print $cgi->br, $pris_now,
        $cgi->br, $pris_avant,
        $cgi->br, $pris_now+$pris_avant;
  print "\n", $cgi->end_div(); # Fin du div Pris

  print $cgi->start_div({-class => 'A_prendre'}), $cgi->span({-class => 'L1'},'A prendre');
  print $cgi->br, $prendre_now,
        $cgi->br, $prendre_avant,
        $cgi->br, $prendre_now + $prendre_avant;
  print "\n", $cgi->end_div(); # Fin du div A prendre
  print "\n", $cgi->end_div(); # Fin du div affiche_rtt

}

sub rtt_anterieur {
  my ($a_in, $m_in, $j_in, $Da, $Dm, $Dj) = @_;
  my $acquis;
  my $arrondi;
  my $diff;
  my $res;
  if(($Da == 0)&&($a_in == $annee)) { # 1�re ann�e dans la soci�t�, donc pas de rtt anterieur
    $acquis = 0;
  }
  elsif (($Da == 0)&&($a_in == $annee + 1)){ # collaborateur entr� au cours de l'ann�e pr�c�dente
       $acquis = (12-$m_in)*0.5;
  }
  elsif(($Da == 1) && ($a_in == $annee + 1)){ #  Idem que pr�c�dement
      $acquis = (12-$m_in)*0.5;
  }
  else {
    $acquis = 12*0.5;
  }
  return $acquis;
  }

sub rtt_pris {
  my ($a_in, $m_in, $j_in, $Da, $Dm, $Dj, $rtt_avant) = @_;
  my ($cpt_now, $cpt_avant);
  my $sql= "SELECT SUM(rtt) FROM ra WHERE idcollaborateur = ".$dbh->quote($id)." AND annee = ".$dbh->quote($annee)." AND mois <= ".$dbh->quote($mois)." AND valider = '1'";
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  ($cpt_now) = $sth->fetchrow_array();
#  $mois = 3; # Pour tester
  if($mois < 4) {
    $sql= "SELECT SUM(rtt) FROM ra WHERE idcollaborateur = ".$dbh->quote($id)." AND annee = ".$dbh->quote($annee -1)." AND valider = '1'";
    $sth = $dbh->prepare($sql);
    $sth->execute;
      ($cpt_avant) = $sth->fetchrow_array();
  }
  else {
# On annule les rtt � prendre � partir de fin mars de l'ann�e suivante
# La mise � jour dans la base se fera par script, l'annulation se fait
# au niveau de l'affichage
    $cpt_avant = $rtt_avant;
  }
  $cpt_now = defined($cpt_now) ? $cpt_now : 0;
  $cpt_avant = defined($cpt_avant) ? $cpt_avant : 0;
  return ($cpt_now, $cpt_avant);
}

# Document qui affiche le menu de gestion du compte
sub gestion_compte {
  my $actif = shift;
  return unless $actif;
  return unless $id;
  my $smenu = $cgi->param('smenu')|| 'identification';
  print $cgi->h1("Gestion du compte $collaborateur[3]");
  print $cgi->start_div({-id => 'Menu_gestion_compte'});
  print $cgi->start_ul(),
        $cgi->li($cgi->a({-href => "etechnoserv.pl?.Etat=Defaut&ident_id=$id"}, 'Retour'));
  if($smenu eq 'identification') {
    print $cgi->li({-id => "active"}, $cgi->a({-id => "courant", -href => "etechnoserv.pl?.Etat=Compte&smenu=identification&ident_id=$id"}, 'Identification'));
#utile pour d�terminer le menu actif quand on utilise les boutons OK Appliquer
    print $cgi->hidden(-name=>'smenu', -value=>'identification');
  }
  else {
   print $cgi->li($cgi->a({-href => "etechnoserv.pl?.Etat=Compte&smenu=identification&ident_id=$id"}, 'Identification'));
  }
  if($smenu eq 'communication') {
    print $cgi->li({-id => "active"}, $cgi->a({-id => "courant", -href => "etechnoserv.pl?.Etat=Compte&smenu=communication&ident_id=$id"}, 'Communication'));
    print $cgi->hidden(-name=>'smenu', -value=>'communication');
  }
  else {
    print $cgi->li($cgi->a({-href => "etechnoserv.pl?.Etat=Compte&smenu=communication&ident_id=$id"}, 'Communication'));
  }
  if($smenu eq 'missions') {
    print $cgi->li({-id => "active"}, $cgi->a({-id=> "courant", -href => "etechnoserv.pl?.Etat=Compte&smenu=missions&ident_id=$id"}, 'Missions'));
    print $cgi->hidden(-name=>'smenu', -value=>'missions');
  }
  else {
      print $cgi->li($cgi->a({-href => "etechnoserv.pl?.Etat=Compte&smenu=missions&ident_id=$id"}, 'Missions'));
  }
  if($smenu eq 'mot_de_passe') {
    print $cgi->li({-id => "active"}, $cgi->a({-id =>"courant", -href => "etechnoserv.pl?.Etat=Compte&smenu=mot_de_passe&ident_id=$id"}, 'Mot de passe'));
    print $cgi->hidden(-name=>'smenu', -value=>'mot_de_passe');
  }
  else {
   print $cgi->li($cgi->a({-href => "etechnoserv.pl?.Etat=Compte&smenu=mot_de_passe&ident_id=$id"}, 'Mot de passe'));
  }
  print $cgi->end_ul();
  print $cgi->end_div(); # Fin du div de Menu_gestion_compte

  return unless $smenu;
  my $fonction = $compte{$smenu}; # Ex�cution de la fonction du sous menu de compte
  $fonction->();
}

sub menu_compte_identification {
  print $cgi->start_div({-id => 'Identification'}),
   $cgi->start_fieldset(), $cgi->legend('Etat Civil'), $cgi->start_div({-class => 'infos'}), $cgi->start_div({-class => 'Ligne2col'}), $cgi->div({-class => 'Ligne2col1'},"Nom") ,
   $cgi->textfield(-name=>"nom", -default=> "$collaborateur[1]", -size=> 20),
   $cgi->end_div(),
   $cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $cgi->div({-class => 'Ligne2col1'}, "Pr�nom"),
   $cgi->textfield(-name=>"prenom", -default=> "$collaborateur[2]", -size=> 20),
   $cgi->end_div(), $cgi->end_div();
   if((defined $msg_maj[0]) && ($msg_maj[0] eq 'identification') &&
      (($msg_maj[1] == 1) || ($msg_maj[1] == 2))) {
     print $cgi->start_div({-class => 'msg_erreur'}),
           $cgi->span("*$msg_maj[2]"), $cgi->end_div(), $cgi->end_fieldset();
   }
   else {
     print $cgi->end_fieldset();
   }
   print $cgi->start_fieldset(), $cgi->legend('Donn�es professionnelles'), $cgi->start_div({-class => 'infos'}), $cgi->start_div({-class => 'Ligne2col'}), $cgi->div({-class => 'Ligne2col1'}, "Login"),
   $cgi->textfield(-name=>"login", -default=> "$collaborateur[3]", -size=> 20),
   $cgi->end_div(),
   $cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $cgi->div({-class => 'Ligne2col1'}, "Fonction"),
   $cgi->textfield(-name=>'fonction', -default=> "$collaborateur[7]", -size=> 40, -disabled),
   $cgi->end_div(), $cgi->end_div();
   if((defined $msg_maj[0]) && ($msg_maj[0] eq 'identification') &&
      ($msg_maj[1] == 3)) {
     print $cgi->start_div({-class => 'msg_erreur'}),
           $cgi->span("*$msg_maj[2]"), $cgi->end_div(), $cgi->end_fieldset();
   }
   else {
     print $cgi->end_fieldset();
   }
  menu_compte_enregistrer('7');# Droits d'activer OK, enregistrer et annuler
  print $cgi->end_div(); # Fin du div Identification
# Afin de modifier les param�tres
  $cgi->delete('nom_old');
  $cgi->delete('prenom_old');
  $cgi->delete('login_old');

  print $cgi->hidden(-name =>'nom_old', -value => "$collaborateur[1]"), $cgi->hidden(-name => 'prenom_old', -value => "$collaborateur[2]"), $cgi->hidden(-name => 'login_old', -value => "$collaborateur[3]");
}

sub menu_compte_communication {
  print $cgi->start_div({-id => 'Communication'}),
   $cgi->start_fieldset(), $cgi->legend('Donn�es chez le client'), $cgi->start_div({-class => 'infos'}), $cgi->start_div({-class => 'Ligne2col'}), $cgi->div({-class => 'Ligne2col1'},"E-mail mission"),
   $cgi->textfield(-name=>'mail_mission', -default=> "$collaborateur[10]", -size=> 40),
   $cgi->end_div(),
   $cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $cgi->div({-class => 'Ligne2col1'}, "T�l. mission"),
   $cgi->textfield(-name=>"tel_mission", -default=> "$collaborateur[11]", -size=> 12),
   $cgi->end_div(), $cgi->end_div();
  if((defined $msg_maj[0]) && ($msg_maj[0] eq 'communication') &&
    (($msg_maj[1] == 1) || ($msg_maj[1] == 2))) {
        print $cgi->start_div({-class => 'msg_erreur'}),
         $cgi->span("*$msg_maj[2]"), $cgi->end_div(), $cgi->end_fieldset();
  }
  else {
       print $cgi->end_fieldset();
  }
  print $cgi->start_fieldset(), $cgi->legend('Donn�es personnelles'), $cgi->start_div({-class => 'infos'}), $cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $cgi->div({-class => 'Ligne2col1'}, "T�l. perso"),
   $cgi->textfield(-name=>"tel_perso", -default=> "$collaborateur[12]", -size=> 12),
   $cgi->end_div(), $cgi->end_div();
  if((defined $msg_maj[0]) && ($msg_maj[0] eq 'communication') &&
    ($msg_maj[1] == 3)) {
       print $cgi->start_div({-class => 'msg_erreur'}),
        $cgi->span("*$msg_maj[2]"), $cgi->end_div(), $cgi->end_fieldset();
  }
  else {
    print $cgi->end_fieldset();
  }
  menu_compte_enregistrer('7'); # Droits d'activer OK, enregistrer et annuler
  print $cgi->end_div(); # Fin du div Communication
  $cgi->delete('mail_mission_old');
  $cgi->delete('tel_mission_old');
  $cgi->delete('tel_perso_old');
  print $cgi->hidden(-name =>'mail_mission_old', -value => "$collaborateur[10]"),
        $cgi->hidden(-name =>'tel_mission_old', -value => "$collaborateur[11]"),
        $cgi->hidden(-name =>'tel_perso_old', -value => "$collaborateur[12]");
}

sub menu_compte_missions {
  my $sql = "SELECT idclient FROM  affectation WHERE idcollaborateur = ".$dbh->quote($collaborateur[0]);
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my ($client, @client);
  ($client) = $sth->fetchrow_array();
  if(defined($client)) {
    $sql = "SELECT * FROM client WHERE id = ".$dbh->quote($client);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    @client = $sth->fetchrow_array();
    print $cgi->start_div({-id => 'Missions'}),
     $cgi->start_fieldset(), $cgi->legend('Contact technique client'), $cgi->start_div({-class => 'infos'}),
     $cgi->start_div({-class => 'Ligne2col'}), $cgi->div({-class => 'Ligne2col1'}, "Nom du client"),
     $cgi->textfield(-name=>'nom_client', -default=> "$client[1]", -size=> 40, -disabled),
     $cgi->end_div(),
     $cgi->start_div({-class => 'Ligne2col'}), $cgi->div({-class => 'Ligne2col1'}, "Nom du contact"),
     $cgi->textfield(-name=>'nom_contact', -default=> "$client[12] $client[11]", -size=> 40, -disabled),
     $cgi->end_div(),
     $cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $cgi->div({-class => 'Ligne2col1'}, "T�l�phone"),
     $cgi->textfield(-name=>'tel_contact', -default=> "$client[18]", -size=> 40, -disabled),
     $cgi->end_div(), $cgi->end_div(), $cgi->end_fieldset();
  }
  else {
    print $cgi->p($cgi->em("Aucun client n'est affect�"), $cgi->br, "En cas d'erreur, contacter votre responsable de contact");
  }
  menu_compte_enregistrer('4'); # Droits d'activer OK
  print $cgi->end_div(); # Fin du div Missions
}

sub menu_compte_mot_de_passe {
#  my ($paquetage, $fichier, $ligne, $routine) = caller(2);
#  print " La pile d'execution du programme est : $paquetage, $fichier, $ligne, $routine";

  if((defined $msg_maj[0]) && ($msg_maj[1] == 0)) {
    $cgi->delete('pswd_actuel');
    $cgi->delete('pswd_new1');
    $cgi->delete('pswd_new2');
  }
  print $cgi->start_div({-id => 'Mot_de_passe'}),
        $cgi->start_fieldset(), $cgi->legend('Changement de mot de passe'), $cgi->start_div({-class => 'infos'}), $cgi->start_div({-class => 'Ligne2col'}), $cgi->div({-class => 'Ligne2col1'}, "Le mot de passe actuel"),
        $cgi->password_field(-name=>'pswd_actuel', -size=> 20, -value => undef),
        $cgi->end_div(),
        $cgi->start_div({-class => 'Ligne2col'}), $cgi->div({-class => 'Ligne2col1'}, "Le nouveau mot de passe"),
        $cgi->password_field(-name=>"pswd_new1", -size=> 20, -value => undef),
        $cgi->end_div(),
        $cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $cgi->div({-class => 'Ligne2col1'}, "Le nouveau mot de passe"),
        $cgi->password_field(-name=>"pswd_new2", -size=> 20, -value => undef),
        $cgi->end_div(), $cgi->end_div();
  if((defined $msg_maj[0]) && ($msg_maj[0] eq 'mot_de_passe') &&
     (($msg_maj[1] == 0) ||($msg_maj[1] == 1))) {
       print $cgi->start_div({-class => 'msg_erreur'}),
        $cgi->span("*$msg_maj[2]"), $cgi->end_div(), $cgi->end_fieldset();
  }
  else {
    print $cgi->end_fieldset();
  }
  menu_compte_enregistrer('7'); # Droits d'activer OK, enregistrer et annuler
  print $cgi->end_div(); # Fin du div Mot de passe
#  print $cgi->hidden(-name => 'pswd_actuel', -value => ' ');
#  print $cgi->hidden(-name => 'pswd_new1', -value => ' ');
#  print $cgi->hidden(-name => 'pwsd_new2', -value => ' ');
}

# La partie v�rification et maj du menu compte
sub menu_compte_maj_collaborateur {
  my $smenu;
  $smenu = $cgi->param('smenu');
# $bouton a la valeur de .Etat dans ce cas $etat = $cgi->param('.Etat');
  if($smenu eq 'identification') {
    my ($nom, $prenom, $user);
    $nom = $cgi->param('nom');
    $prenom = $cgi->param('prenom');
    $user = $cgi->param('login');
# Les contr�les sur les donn�es avant l'enregistrement

    if(menu_compte_verif_donnees($smenu, $nom, $prenom, $user) == 0) {
      my $sql = "UPDATE collaborateur SET nom = ".$dbh->quote($nom).", prenom = ".$dbh->quote($prenom).", user = ".$dbh->quote($user)." WHERE id = ".$dbh->quote($collaborateur[0]);
      $dbh->do($sql) or die " Erreur : $dbh->errstr";
    }
    @collaborateur[1..3] = ($nom, $prenom, $user);
    $msg_maj[0] = $smenu;
    $msg_maj[1] = 1;
    $msg_maj[2] = "Mise � jour effectu�e";
    return;
  }
  if($smenu eq 'communication') {
    my ($mail_mission, $tel_mission, $tel_perso);
    $mail_mission= $cgi->param('mail_mission');
    $tel_mission = $cgi->param('tel_mission');
    $tel_perso = $cgi->param('tel_perso');

# Les contr�les sur les donn�es avant l'enregistrement
    if(menu_compte_verif_donnees($smenu, $mail_mission, $tel_mission, $tel_perso) == 0) {
      my $sql = "UPDATE collaborateur SET email_pro = ".$dbh->quote($mail_mission).", tel_pro = ".$dbh->quote($tel_mission).", tel_perso = ".$dbh->quote($tel_perso)." WHERE id = ".$dbh->quote($collaborateur[0]);
      $dbh->do($sql) or die " Erreur : $dbh->errstr";
    }
    @collaborateur[10..12] = ($mail_mission, $tel_mission, $tel_perso);
    $msg_maj[0] = $smenu;
    $msg_maj[1] = 1;
    $msg_maj[2] = "Mise � jour effectu�e";
    return;
  }
  if($smenu eq 'mot_de_passe') {
    my ($pswd, $pswd1, $pswd2, $pswd_md5);
    $pswd= $cgi->param('pswd_actuel');
    $pswd1 = $cgi->param('pswd_new1');
    $pswd2 = $cgi->param('pswd_new2');

# Les contr�les sur les donn�es avant l'enregistrement
    if(menu_compte_verif_donnees($smenu, $pswd, $pswd1, $pswd2) == 0) {
      my $md5 = Digest::MD5->new;
      $md5->add($pswd1);
      $pswd_md5 = $md5->hexdigest;
      my $sql = "UPDATE collaborateur SET pass = ".$dbh->quote($pswd_md5)." WHERE (id = ".$dbh->quote($collaborateur[0]).") AND (actif = '1')";
      $dbh->do($sql) or die " Erreur : $dbh->errstr";
      $collaborateur[4] = $pswd_md5;
      $msg_maj[0] = $smenu;
      $msg_maj[1] = 0; # Utile pour supprimer initialisation des champs
      $msg_maj[2] = "Mise � jour du mot de passe effectu�e";
      return;
    }
  }

}

# V�rification des donn�es avant la mise � jour
sub menu_compte_verif_donnees {
  my $smenu = shift;
  if($smenu eq 'identification') {
    my($nom, $prenom, $login) = @_;
    unless($nom eq $collaborateur[1]) {
      if((length $nom <= 0) || (length $nom > 20) || ($nom =~/^[0-9\.\s]/) ||
         ($nom =~ /^[\d\s]*$/) ||
         ($nom =~ /[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/)) {
            $msg_maj[0] = $smenu;
            $msg_maj[1] = 1;
            $msg_maj[2] = "Le champ nom ne peut �tre vide, avoir une taille sup�rieure � 20, commencer par un chiffre, un espace ou par un point. Il ne peut �tre une combinaison de blancs et de chiffres et comprendre des caract�res tels que :".$cgi->br." &nbsp; &nbsp;$, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ";
            return 1;
      }
    }
    unless($prenom eq $collaborateur[2]) {
      if((length $prenom <= 0) || (length $prenom > 20) || ($prenom =~/^[0-9\.\s]/) ||
         ($prenom =~ /^[\d\s]*$/) ||
         ($prenom =~ /[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/)) {
            $msg_maj[0] = $smenu;
            $msg_maj[1] = 2;
            $msg_maj[2] = "Le champ prenom ne peut �tre vide, avoir une taille sup�rieure � 20, commencer par un chiffre, un espace ou par un point. Il ne peut �tre une combinaison de blancs et de chiffres et comprendre des caract�res tels que :".$cgi->br." &nbsp; &nbsp;$, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ";
            return 2;
      }
    }
    unless($login eq $collaborateur[3]) {
      if((length $login < 4) || (length $login > 20) || ($login =~/^[0-9\.\s]/) ||
         ($login =~ /^[\d\s]*$/) ||
         ($login =~ /[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/)) {
            $msg_maj[0] = $smenu;
            $msg_maj[1] = 3;
            $msg_maj[2] = "Le champ login ne peut �tre vide, avoir une taille inf�rieure � 4 et sup�rieure � 20, commencer par un chiffre, un espace ou par un point. Il ne peut une combinaison de blancs et de chiffres et comprendre des caract�res tels que :".$cgi->br." &nbsp; &nbsp;$, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ";
            return 3;
      }
    }
    return 0;
  }
  if($smenu eq 'communication') {
    my($mail_mission, $tel_mission, $tel_perso) = @_;
    unless($mail_mission eq $collaborateur[10]) {
      if(!(($mail_mission =~ /^[a-zA-Z]([\w\-\.]*[\w]+)*@[a-zA-Z]([\w\-\.]*[\w]+)*\.[a-zA-Z]+$/) &&
          (length $mail_mission > 0) && (length $mail_mission < 101))) {
            $msg_maj[0] = $smenu;
            $msg_maj[1] = 1;
            $msg_maj[2] = "L'adresse mail est incorrecte. Elle doit �tre de la forme nom\@domaine.ext avec :".$cgi->br()."&nbsp;&nbsp;-nom et domaine : mot.mot.---.mot,".$cgi->br()."&nbsp;&nbsp;-ext : mot";
            return 1;
      }
    }
    unless($tel_mission eq $collaborateur[11]) {
      if(!((length $tel_mission >0) && (length $tel_mission < 11) &&
          ($tel_mission =~ /^\d{10}$/))) {
            $msg_maj[0] = $smenu;
            $msg_maj[1] = 2;
            $msg_maj[2] = "Le champ T�l mission est incorrect. Il doit �tre un nombre de 10 chiffres";
            return 2;
      }
    }
    unless($tel_perso eq $collaborateur[12]) {
      if(!((length $tel_perso >0) && (length $tel_perso < 11) &&
          ($tel_perso =~ /^\d{10}$/))) {
            $msg_maj[0] = $smenu;
            $msg_maj[1] = 3;
            $msg_maj[2] = "Le champ T�l perso est incorrect. Il doit �tre un nombre de 10 chiffres";
            return 3;
      }
    }
    return 0;
  }
  if($smenu eq 'mot_de_passe') {
    my($pswd, $pswd1, $pswd2) = @_;
    my $md5 = Digest::MD5->new;
    my $pswd_md5;
    $md5->add($pswd);
    $pswd_md5 = $md5->hexdigest;
    unless($pswd_md5 eq $collaborateur[4]) {
      $msg_maj[0] = $smenu;
      $msg_maj[1] = 1;
      $msg_maj[2] = "Le mot de passe saisi n'est pas �gal au mot de passe actuel";
      return 1;
    }
    unless($pswd1 eq $pswd2) {
      $msg_maj[0] = $smenu;
      $msg_maj[1] = 1;
      $msg_maj[2] = "Erreur sur le nouveau mot de passe : Le deuxi�me mot de passe ne correspond pas au premier";
      return 1;
    }
    if((length $pswd1 <= 3) || (length $pswd2 <= 3)) {
      $msg_maj[0] = $smenu;
      $msg_maj[1] = 1;
      $msg_maj[2] = "Erreur sur le nouveau mot de passe : Sa taille doit �tre au moins �gale � 4";
      return 1;
    }
    return 0;
  }
}

# La partie Affichage du menu Compte
sub menu_compte_appliquer {
  my $smenu = $cgi->param('smenu');
  if($smenu eq 'identification') {
    gestion_compte(1);
    return;
#    print $cgi->end_form(), $cgi->end_div();# Fin du formulaire et du menu droit
  }
  if($smenu eq 'communication') {
    gestion_compte(1);
    return;
  }
  if($smenu eq 'mot_de_passe') {
    gestion_compte(1);
    return;
  }

  else {
    print "Les champs disponibles pour la fonction Appliquer sont :", $cgi->br;
    print $cgi->Dump;
  }

}

sub menu_compte_ok{
  donnees_sociales(1);
}


sub menu_compte_enregistrer {
  my $droits = shift;
 if($droits & '1') { # droits d'activation de Annuler
  print $cgi->div({-class => 'menu_enregistrer'}, vers_compte('OK', $droits & '4'),
                vers_compte('Appliquer', $droits & '2'),
                $cgi->reset());
 }
 else {
  print $cgi->div({-class => 'menu_enregistrer'}, vers_compte('OK', $droits & '4'),
                vers_compte('Appliquer', $droits & '2'),
                $cgi->reset({-disabled}));
 }
}


sub vers_compte {
  my $valeur = shift;
  my $droits = shift;
#  print $cgi->p("Les droits pour le bouton $valeur sont : $droits");
  if($droits) {
    $cgi->submit({-name => ".Etat", value => $valeur, -onclick => "return valide_modif_compte(this);"});
  }
  else {
    $cgi->submit({-name => ".Etat", value => $valeur, -onclick => "return valide_modif_compte(this);", -disabled});
#  $cgi->submit({-name => ".Etat", value => $valeur, -onclick => $fonction});
  }
}

sub vers_doc { $cgi->submit(-NAME =>".Etat", -VALUE => shift, -onclick => "return appel_url(this);");}

#sub vers_doc { $cgi->submit(-NAME =>".Etat", -VALUE => shift);}

sub vers_connexion { submit(-NAME =>".Connexion", -VALUE => shift)}
