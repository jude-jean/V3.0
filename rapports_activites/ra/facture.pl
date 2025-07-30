#!/usr/bin/perl -w
# Magasin de chemises et chaussures
use strict;
#use utf8;                      # Source code is encoded using UTF-8.
use Encode qw(encode decode);
#use open ':encoding(UTF-8)';   # Set default encoding for file handles.
#BEGIN { binmode(STDOUT, ':encoding(UTF-8)'); }  # HTML
#BEGIN { binmode(STDERR, ':encoding(UTF-8)'); }  # Error log


use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use URI::Escape;
use DBI;
use Date::Calc qw(:all);


# Déclaration du répertoire de base
#our $rep = '../../../../test/jude/V3.0';
# Déclaration pour javascript
# liste des fonctions à lancer en fonction du paramètre action
my %action = (
 'creation'              => \&creer_facture ,
 'edition'               => \&editer_facture,
 'impression'           => \&afficher_facture, #La modification importante se trouve dans entete_standard avec la fonction javascript
 #'affichage'             => \&afficher_ra,
);
my ($action, $url);

my %s_action = (
 'Sauvegarder'            => \&sauvegarder_facture,
 'Visualiser'             => \&visualiser_facture,
 'Valider'            => \&valider_facture,
 'Imprimer'           => \&imprimer_facture,
 'Editer'             => \&editer_facture,
 'editer'             => \&editer_facture,
 'Supprimer'          => \&delete_facture,
);

our %parametres =();
# Déclaration des identifications de connexion
my ($id, $id_ra, $nom_client);
#my $login;
our (@collaborateur, $dbh);
#my $tps_connexion = 600; # Délai de connexion sans inactivité

# Tableau des RA
#our (@ra, @ra_ast, @ra_comment, @ra_global, @ra_hsup, @ra_pres);

# Les variables de la facturation
our ($facture, $client, $tauxPrestation, $typeTauxPrestation, %tauxPrestationByType, $tauxPrestationExiste, $user, $nbreAFacturer, $jourHeureAFacturer, $montantFacture, $mission, $estAJour, $raControle, @tauxTva);
our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];

#Liste des clients pour le salarié
#our (@clients, %clients);
#our %tous_clients = (0, 'T&S'); # Hachage incluant T&S et les autres clients

our $cgi = new CGI;
#Connexion à la base de données.
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
#Connexion à la base de données.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "problème de connexion à la base de données db447674934 : $!";
	# Déclaration du répertoire de base
	$rep = '../..';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib/";
}
else {
#Connexion à la base de donnï¿½e.
	$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "problème de connexion à la base de données collaborateur : $!";
	$rep = '../../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}
use RapportActivite qw(gestion_ra);
use JourDeFete qw(est_ferie est_jour_ferie Delta_Dates_AMJ);
use Etechnoserv;
use Connexion;
use Ra;
use Facture;

my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# Dï¿½claration des feuilles de styles
my @liens = [
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/facture.css",
         'media'           => 'screen',
       }),
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/facture_print.css",
         'media'           => 'print',
       }),
       Link({
         'rel'             => 'shortcut icon',
         'href'            => "$rep/images/favicon.ico",
       }),
];

lecture_parametres(\%parametres);
if($parametres{mois} =~ /vrier$/) {
  $parametres{mois} = 'Février';
  $parametres{mois_num} = '2';
}
if($parametres{mois} =~ /^Ao/) {
  $parametres{mois} = 'Août';
  $parametres{mois_num} = '8';
}
if($parametres{mois} =~ /cembre$/) {
  $parametres{mois} = 'Décembre';
  $parametres{mois_num} = '12';
}
if($parametres{mois} =~ /Janvier/) {
  $parametres{mois_num} = '1';
}
if($parametres{mois} =~ /Mars/) {
  $parametres{mois_num} = '3';
}
if($parametres{mois} =~ /Avril/) {
  $parametres{mois_num} = '4';
}
if($parametres{mois} =~ /Mai/) {
  $parametres{mois_num} = '5';
}
if($parametres{mois} =~ /Juin/) {
  $parametres{mois_num} = '6';
}
if($parametres{mois} =~ /Juillet/) {
  $parametres{mois_num} = '7';
}
if($parametres{mois} =~ /Septembre/) {
  $parametres{mois_num} = '9';
}
if($parametres{mois} =~ /Octobre/) {
  $parametres{mois_num} = '10';
}
if($parametres{mois} =~ /Novembre/) {
  $parametres{mois_num} = '11';
}
#visu_parametres();
$tauxPrestationExiste = 0;
@collaborateur = info_id($parametres{ident_id});
unless (@collaborateur) {
	entete_standard(); 
	print "Le parametre ident_id n'est pas défini dans la base de donnée", $cgi->br();
	visu_parametres(\%parametres);
	print $cgi->end_html();
#	die "Le parametre $parametres{ident_id} n'est pas défini dans la base dans la base de données";
	exit;
}
if(verif_tps_connexion() == 0) { #Délai d'attente dépassé
	print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
	exit;
}
if(exists($parametres{s_action})) {
  if(exists($s_action{$parametres{s_action}})) {
    $s_action{$parametres{s_action}}->();
  }
  else {
    entete_standard();
    print "Pas de fonction d&eacute;finie pour le param&egrave;tre $parametres{s_action}";
  }
}
else {
  $action = $cgi->param('action') || 'creation';
  &{$action{$action}}();
}

#creer_ra();

exit;

sub editer_facture {
  entete_standard();
  rechercheInfosClient();
  rechercheInfosCollaborateur();
  rechercheInfosFacture();
  #rechercheTauxPrestation($facture->[6]);
  my @tauxId = ();
  if(defined $facture->[6] && $facture->[6] != 0) {
    push @tauxId, $facture->[6];
  }
  if(defined $facture->[10] && $facture->[10] != 0) {
    push @tauxId, $facture->[10];
  }  
  rechercheTauxPrestation(@tauxId);
  rechercheIntituleMission();
  #($toDayJour, $toDayMois, $toDayAnnee) = (localtime)[3..5];
  #recherche_liste_clients();
  #recherche_ra();
  print $cgi->start_div({-id => 'ecran'});
#  print $cgi->h1("Rapport d'activité de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
  #affiche_entete();
  #genere_mois($parametres{action});
  #$parametres{mois} = 'Jude';
  #my $decodeMois = decode('utf-8', $parametres{mois});

  print $cgi->start_form(-id =>'f_facture', -action => "$rep_pl/rapports_activites/ra/facture.pl?action=edition&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ident_user=$parametres{ident_user}&ra_id=$parametres{ra_id}&ident_id=$parametres{ident_id}");
  #print $cgi->hidden(-name => 'nb_jours', -value =>"$nb_jours");
  print $cgi->hidden(-name => 'action', -value =>'$parametres{action}');
  print $cgi->hidden(-name => 'annee', -value =>'$parametres{annee}');
  print $cgi->hidden(-name => 'mois', -value =>'$parametres{mois}');
  #print "decodeMois = $decodeMois";
  print $cgi->hidden(-name => 'client_id', -value =>"$parametres{client_id}");
  print $cgi->hidden(-name => 'ident_user', -value =>'$parametres{ident_user}');
  print $cgi->hidden(-name => 'ident_id', -value =>'$parametres{ident_id}');
  print $cgi->hidden(-name => 'ra_id', -value =>'$parametres{ra_id}');
  if(defined $parametres{facture_id}) {
    print $cgi->hidden(-name => 'facture_id', -value =>'$parametres{facture_id}');
  }
  #if(defined $parametres{tauxPrestationIdj}) {
  #  print $cgi->hidden(-name => 'tauxPrestationIdj', -value =>'$parametres{tauxPrestationIdj}');
  #}
  #if(defined $parametres{nbreAFacturer}) {
  #  print $cgi->hidden(-name => 'nbreAFacturer', -value =>'$parametres{nbreAFacturer}');
  #}
  #if(defined $parametres{nbreAFacturer}) {
  #  print $cgi->hidden(-name => 'nbreAFacturer', -value =>'$parametres{nbreAFacturer}');
  #}
  #if(defined $parametres{typeTauxPrestation}) {
  #  print $cgi->hidden(-name => 'typeTauxPrestation', -value =>'$parametres{typeTauxPrestation}');
  #}
  if(defined $parametres{user_id}) {
    print $cgi->hidden(-name => 'user_id', -value =>'$parametres{user_id}');
  }          
  gestion_champs_caches();
  affiche_facture($parametres{action});
  print $cgi->end_form(), $cgi->end_div(), $cgi->end_html();

}


sub creer_facture {
  entete_standard();
  rechercheInfosClient();
  rechercheInfosCollaborateur();
  rechercheTauxPrestation();
  recherchePrestationAFacturerV2();
  rechercheTva();
  $montantFacture = $nbreAFacturer * $tauxPrestation->[0];
  #($toDayJour, $toDayMois, $toDayAnnee) = (localtime)[3..5];
  #recherche_liste_clients();
  #recherche_ra();
  print $cgi->start_div({-id => 'ecran'});
#  print $cgi->h1("Rapport d'activité de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
  #affiche_entete();
  #genere_mois($parametres{action});
  #$parametres{mois} = 'Jude';
  #my $decodeMois = decode('utf-8', $parametres{mois});

  print $cgi->start_form(-id =>'f_facture', -action => "$rep_pl/rapports_activites/ra/facture.pl?action=edition&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ident_user=$parametres{ident_user}&ra_id=$parametres{ra_id}&ident_id=$parametres{ident_id}");
  #print $cgi->hidden(-name => 'nb_jours', -value =>"$nb_jours");
  print $cgi->hidden(-name => 'action', -value =>'$parametres{action}');
  print $cgi->hidden(-name => 'annee', -value =>'$parametres{annee}');
  print $cgi->hidden(-name => 'mois', -value =>'$parametres{mois}');
  #print "decodeMois = $decodeMois";
  print $cgi->hidden(-name => 'client_id', -value =>"$parametres{client_id}");
  print $cgi->hidden(-name => 'ident_user', -value =>'$parametres{ident_user}');
  print $cgi->hidden(-name => 'ident_id', -value =>'$parametres{ident_id}');
  print $cgi->hidden(-name => 'ra_id', -value =>'$parametres{ra_id}');
  #print $cgi->hidden(-name => 'tauxPrestationIdj', -value => "$tauxPrestation->[2]");
  #print $cgi->hidden(-name => 'nbreAFacturer', -value => "$nbreAFacturer");
  #print $cgi->hidden(-name => 'typeTauxPrestation', -value => "$tauxPrestation->[1]");
  print $cgi->hidden(-name => 'user_id', -value => "$user->[2]");
  gestion_champs_caches();
  saisie_facture($parametres{action});
  print $cgi->end_form(), $cgi->end_div(), $cgi->end_html();
}

sub sauvegarder_facture() {
  my $res;
  #entete_standard();
  #visu_parametres(\%parametres);
  if(defined($parametres{facture_id})) {
    $res = db_maj_facture();
    if($res != 1) {
      entete_standard();
      visu_parametres(\%parametres);
      print $cgi->h1("Mise &agrave; jour d'une facture");
      print $cgi->p("Une erreur est survenue lors de la mise &agrave; jour de la facture pour :");
      print $cgi->p("L'utilisateur : $parametres{ident_user}");
      print $cgi->p("Le client : $parametres{client_id}");
      print $cgi->p("L'ann&eacute;e : $parametres{annee}");
      print $cgi->p("Le mois : $parametres{mois}");
      print $cgi->p("Le rapport d'activit&eacute : $parametres{ra_id}");
      print $cgi->p("Le taux de prestation : $parametres{tauxPrestationIdj}");
      print $cgi->p("La facture : $parametres{facture_id}");
      print $cgi->p("Le code retour de la fonction db_maj_facture() est : $res");
      print $cgi->p("Conseils : Recharger votre fen&egrave;tre de gestion des rapports d'activit&eacute;s. Si le probl&egrave;me persiste, contacter l'administrateur en lui fournissant les informations ci-dessus.");
      print $cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(0);");      
    }
    $url = "facture.pl?ident_user=$parametres{ident_user}&action=edition&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&facture_id=$parametres{facture_id}&ident_id=$parametres{ident_id}";
    print $cgi->redirect("$url");
    exit;  
  }
  else {
    $res = db_creer_facture();
    #entete_standard();
    #print $cgi->div("res db_creer_facture = $res");
    if($res == -1 || $res == -2) {
      entete_standard();
      visu_parametres(\%parametres);
      print $cgi->h1("Cr&eacute;ation d'une facture");
      print $cgi->p("Une erreur est survenue lors de la cr&eacute;ation de la facture pour :");
      print $cgi->p("L'utilisateur : $parametres{ident_user}");
      print $cgi->p("Le client : $parametres{client_id}");
      print $cgi->p("L'ann&eacute;e : $parametres{annee}");
      print $cgi->p("Le mois : $parametres{mois}");
      print $cgi->p("Le rapport d'activit&eacute;s : $parametres{ra_id}");
      print $cgi->p("Le taux de prestation : $parametres{tauxPrestationIdj}");
      print $cgi->p("Le code retour de la fonction db_creer_facture() est : $res");
      print $cgi->p("Conseils : Recharger votre fen&egrave;tre de gestion des rapports d'activit&eacute;s. Si le probl&egrave;me persiste, contacter l'administrateur en lui fournissant les informations ci-dessus.");
      print $cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(0);");
    }
    else {
      #&tauxPrestationIdj=$parametres{tauxPrestationIdj}
      $url = "facture.pl?ident_user=$parametres{ident_user}&action=edition&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&facture_id=$res&ident_id=$parametres{ident_id}";
      if(defined $parametres{tauxPrestationIdj} && $parametres{tauxPrestationIdj} ne '') {
        $url .= "&tauxPrestationIdj=$parametres{tauxPrestationIdj}";
      }
      if(defined $parametres{tauxPrestationIdh} && $parametres{tauxPrestationIdh} ne '') {
        $url .= "&tauxPrestationIdh=$parametres{tauxPrestationIdh}";
      }
      print $cgi->redirect("$url");
      exit;      
    }
  }
}

sub delete_facture {
  my $res;
  if(defined($parametres{facture_id})) {
    $res = db_delete_facture();
    if($res == 1) {
      $url = "$rep_pl/facture/facture_delete.pl?ident_user=$parametres{ident_user}&annee=$parametres{annee}&mois=$parametres{mois}&client=$nom_client&facture_id=$parametres{facture_id}&client_id=$parametres{client_id}&ident_id=$parametres{ident_id}&status=ok&nb_lig=$res";
    }
    else {
      $url = "$rep_pl/facturefacture_delete.pl?ident_user=$parametres{ident_user}&annee=$parametres{annee}&mois=$parametres{mois}&client=$nom_client&facture_id=$parametres{facture_id}&status=nok&nb_lig=$res";      
    }
  }
  print $cgi->redirect("$url");  
}

sub imprimer_facture {
  #editer_facture();
  $url = "facture.pl?ident_user=$parametres{ident_user}&action=impression&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&facture_id=$parametres{facture_id}&tauxPrestationIdj=$parametres{tauxPrestationIdj}&ident_id=$parametres{ident_id}";
  print $cgi->redirect("$url");
  exit;    
}

sub afficher_facture {
  editer_facture();
}


sub entete_standard {
	print $cgi->header();
	if ($parametres{action} ne 'impression') { #  -encoding => 'UTF-8',
		print $cgi->start_html({-head => @liens, -Title => "Factures v1.0", -script => \%script, -encoding => 'UTF-8', -base => 'true', -onLoad =>"return imprimer_charge();"});
	}
	else {
		print $cgi->start_html({-head => @liens, -Title => "Factures v1.0", -script => \%script, -encoding => 'UTF-8', -base => 'true', -onLoad =>"return imprimer_facture();"});
	}
}

############## Requêtes SQL ###################################################
# Quand on recherche les donnï¿½es du RA, on a besoin de connaitre la liste des
# clients afin me mettre le nom du client dans les tranches de prï¿½sence qui ont
# ï¿½tï¿½ rï¿½servï¿½es par le collaborateur dans le RA de ce client.
#  my $client;
#  my $sql = 'SELECT t1.id, t1.nom FROM client t1, affectation t2 WHERE (t2.idcollaborateur = '.$dbh->quote($collaborateur[0]).') AND (t2.idclient = t1.id)';
##  print $cgi->br(), "Liste des clients pour l'utilisateur $collaborateur[1]", $cgi->br();
#  my $sth = $dbh->prepare($sql);
#  $sth->execute();
#  while($client = $sth->fetchrow_arrayref) {
#    if($client->[0] != $parametres{client_id}) {
#      #(0,..0) pour les hsup et les astreintes
#      push @clients, [ @$client, 0, 0, 0, 0, 0, 0, 0, 0 ];
#      $clients{$client->[0]} = $client->[1];
#    }
#    $tous_clients{$client->[0]} = $client->[1];
#
#  }
#  push @clients, [ 0, 'Technologies et Services', 0, 0, 0, 0, 0, 0, 0, 0 ];
#  print "La taille de \@clients est de : ",1 + $#clients;
#  foreach (@clients) {
#    print " [$_->[1] : $_->[0]]";
#  }

sub rechercheInfosClient() {
  my $sql = 'Select nom, adresse, adresse2, codepostal, ville, pays From client where id = '.$dbh->quote($parametres{client_id});
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $client = $sth->fetchrow_arrayref;
  #print $cgi->span($client);
}

sub rechercheInfosCollaborateur() {
#  my $sql = 'SELECT t1.id, t1.nom FROM client t1, affectation t2 WHERE (t2.idcollaborateur = '.$dbh->quote($collaborateur[0]).') AND (t2.idclient = t1.id)';
  my $sql = 'Select t1.nom, t1.prenom, t1.id From collaborateur t1, connexion t2 Where (t2.id_connexion = '.$dbh->quote($parametres{ident_id}).') and (t2.id_user = t1.id)';
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $user = $sth->fetchrow_arrayref;
  #print $cgi->span($user);
}

sub rechercheInfosFacture() {
  my $sql = 'Select * From facture Where id = '.$dbh->quote($parametres{facture_id});
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $facture = $sth->fetchrow_arrayref;
  #print $cgi->div("facture = @$facture");
  # Vérification des données
  $sql = 'Select * From ra Where id = '.$dbh->quote($facture->[3]);
  $sth = $dbh->prepare($sql);
  $sth->execute();
  $raControle = $sth->fetchrow_arrayref;
  #print $cgi->div("raControle = @$raControle");
  # Nbre de jours travaillés
  #print $cgi->div();
  $estAJour = ($facture->[9] == $raControle->[5] && $facture->[12] == $raControle->[14]) ? 1 : 0;
}

sub rechercheTauxPrestation() {
  my $sql; 
  my $sth;
  #print $cgi->div("\@_ =@_");
  #print $cgi->div("Taille de \@_ = ".scalar(@_));
  #my($tauxPrestation_id) = @_;
  #foreach(@_) {
  #  #print $cgi->div("$_ = ".$_); 
  #  if($_ != 0) {
  #    $sql .= $_.' and id = ';
  #  }
  #}   
  #$sql =~ s/ and id = $//;
  #print $cgi->div("sql = $sql");
  if(scalar(@_) > 0) {
    $sql = 'Select montant, type, id From tauxPrestation where id = ';
    foreach(@_) {
      #print $cgi->div("$_ = ".$_); 
      if($_ != 0) {
        $sql .= $dbh->quote($_).' or id = ';
      }
    }   
    $sql =~ s/ or id = $//;
    #print $cgi->div("sql = $sql");
  }
  else {
    my $dateTaux = $parametres{annee}.'-'.($parametres{mois_num} < 10 ? '0'.$parametres{mois_num} : $parametres{mois_num}).'-01';
    $sql = 'Select montant, type, id From tauxPrestation where client_id = '.$dbh->quote($parametres{client_id}).' And collaborateur_id = '.$dbh->quote($user->[2]).' and dateDebut <= '.$dbh->quote($dateTaux).' and dateFin > '.$dbh->quote($dateTaux);
  }
  #print $cgi->div("sql = $sql");
  #print 'sql = '.$sql, $cgi->br();
  $sth = $dbh->prepare($sql);
  $sth->execute;
  while ($tauxPrestation = $sth->fetchrow_arrayref) {
    #print @$tauxPrestation, $cgi->br();
    $tauxPrestationByType{$tauxPrestation->[1]} = [ ($tauxPrestation->[0], $tauxPrestation->[2]) ];
    $tauxPrestationExiste = 1;
    #print $cgi->div("key = $tauxPrestation->[1], value = $tauxPrestation->[0], $tauxPrestation->[2]");  
  }
  #foreach(keys %tauxPrestationByType) {
  #  print 'Type = '.$_.': montant = '.$tauxPrestationByType{$_}->[0].', id = '.$tauxPrestationByType{$_}->[1], $cgi->br();
  #}
  #print $cgi->div("Taille de \%tauxPrestationByType = ".scalar(keys %tauxPrestationByType));

}

sub rechercheTva() {
  my $tauxTVA;
  my $debutMois = $parametres{annee}.'-'.($parametres{mois_num} < 10 ? '0'.$parametres{mois_num} : $parametres{mois_num}).'-01';
  my $finMois = $parametres{annee}.'-'.($parametres{mois_num} < 10 ? '0'.$parametres{mois_num} : $parametres{mois_num}).'-'.Days_in_Month($parametres{annee}, $parametres{mois_num});
  my $sql = 'Select * From tva Where dateFin >= '.$dbh->quote($debutMois).' And dateDebut <= '.$dbh->quote($finMois).' order By dateDebut';
  print $cgi->div("sql = $sql");
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  while($tauxTVA = $sth->fetchrow_arrayref) {
    print $cgi->div("Taux de TVA = @$tauxTVA");
    push @tauxTva, [ @$tauxTVA ];
  }
  #print $cgi->div($tauxTVA);
}


sub rechercheIntituleMission() {
  my $dateMission = $parametres{annee}.'-'.($parametres{mois_num} < 10 ? '0'.$parametres{mois_num} : $parametres{mois_num}).'-01';
  my $sql = 'Select intitule, delaiPaiementInt, delaiPaiementStr, id From mission where clientId = '.$dbh->quote($parametres{client_id}).' And collaborateurId = '.$dbh->quote($user->[2]).' and dateDebut <= '.$dbh->quote($dateMission).' and dateFin > '.$dbh->quote($dateMission);
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  ($mission) = $sth->fetchrow_arrayref;
  #print $cgi->span($mission), $cgi->br();
  $mission->[0] =~ s/é/&eacute;/g;
  #print $cgi->span($mission->[0]);
}


sub recherchePrestationAFacturerV2() {
  my ($sql, $sth);
  $sql = 'Select jfacture, hsupp0 From ra where id = '.$dbh->quote($parametres{ra_id});
  $sth = $dbh->prepare($sql);
  $sth->execute;
  $jourHeureAFacturer = $sth->fetchrow_arrayref;
}

sub recherchePrestationAFacturer() {
  my $sql = 'Select * From ra_presence Where id = '.$parametres{ra_id};
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  (my $ra_pres) = $sth->fetchrow_arrayref;
  #print $cgi->span($ra_pres);
  my $i = 0;
  print $cgi->br();
  foreach(@$ra_pres) {
    print "<$i, $_> ";
    if($i != 0) {
      $nbreAFacturer += $_;

    }
    $i++;
  }
  $nbreAFacturer = $nbreAFacturer / 2;
}

sub db_maj_facture() {
  my $sql = 'Update facture SET dateCreation = '.$dbh->quote($parametres{dateCreation}).' Where id ='.$dbh->quote($parametres{facture_id});
  my $nb_lignes = $dbh->do($sql);
  return $nb_lignes;
}

sub db_creer_facture() {
  #entete_standard();
  my $id_facture;
  my $sql = 'SELECT id From facture where collaborateurId = '.$dbh->quote($parametres{user_id}).' And clientId = '.$dbh->quote($parametres{client_id}).' And raId = '.$dbh->quote($parametres{ra_id}).' And annee = '.$dbh->quote($parametres{annee}).' And mois = '.$dbh->quote($parametres{mois_num}).' And tauxIdj = '.$dbh->quote($parametres{tauxPrestationIdj});
  #print $cgi->div("sql = $sql");
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  ($id_facture) = $sth->fetchrow_array();
  if(defined $id_facture) {
    return -1;
  }
  #, tauxIdj = '.$dbh->quote($parametres{tauxPrestationIdj}).', montantj = '.$dbh->quote($parametres{montantFacturej}).', nbreAFacturer = '.$dbh->quote($parametres{nbreAFacturer})'
  $sql = 'INSERT facture SET collaborateurId = '.$dbh->quote($parametres{user_id}).', clientId = '.$dbh->quote($parametres{client_id}).', raId = '.$dbh->quote($parametres{ra_id}).', annee = '.$dbh->quote($parametres{annee}).', mois = '.$dbh->quote($parametres{mois_num}).', dateCreation = '.$dbh->quote($parametres{dateCreation});
  if(defined $parametres{tauxPrestationIdj} && $parametres{tauxPrestationIdj} ne '') {
    $sql .= ', tauxIdj = '.$dbh->quote($parametres{tauxPrestationIdj}).', montantj = '.$dbh->quote($parametres{montantFacturej}).', nbreJoursAFacturer = '.$dbh->quote($parametres{nbrej});
  }
  if(defined $parametres{tauxPrestationIdh} && $parametres{tauxPrestationIdh} ne '') {
    $sql .= ', tauxIdh = '.$dbh->quote($parametres{tauxPrestationIdh}).', montanth = '.$dbh->quote($parametres{montantFactureh}).', nbreHeuresAFacturer = '.$dbh->quote($parametres{nbreh});
  }  
  #print $cgi->div("sql = $sql");
  my $nb_lignes = $dbh->do($sql);
  #.' And tauxIdj = '.$dbh->quote($parametres{tauxPrestationIdj})
  $sql = 'SELECT id From facture where collaborateurId = '.$dbh->quote($parametres{user_id}).' And clientId = '.$dbh->quote($parametres{client_id}).' And raId = '.$dbh->quote($parametres{ra_id}).' And annee = '.$dbh->quote($parametres{annee}).' And mois = '.$dbh->quote($parametres{mois_num});
  if(defined $parametres{tauxPrestationIdj} && $parametres{tauxPrestationIdj} ne '') {
    $sql .= ' And tauxIdj = '.$dbh->quote($parametres{tauxPrestationIdj});
  }
  if(defined $parametres{tauxPrestationIdh} && $parametres{tauxPrestationIdh} ne '') {
    $sql .= ' And tauxIdh = '.$dbh->quote($parametres{tauxPrestationIdh});
  }
  #print $cgi->div("sql = $sql");
  $sth = $dbh->prepare($sql);
  $sth->execute();
  ($id_facture) = $sth->fetchrow_array();
  if(defined $id_facture) {
    return $id_facture;
  }
  else {
    return -2;
  }

sub db_delete_facture() {
  my $del = "DELETE FROM facture WHERE id = ".$dbh->quote($parametres{facture_id});
  my $nb_lignes = 0;
  $nb_lignes = $dbh->do($del);
  return $nb_lignes;  
}  
  

}
