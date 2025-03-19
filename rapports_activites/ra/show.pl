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


# Déclaration du répertoire de base
#our $rep = '../../../../test/jude/V3.0';
# Déclaration pour javascript
# liste des fonctions à lancer en fonction du paramètre action
my %action = (
 'creation'              => \&creer_ra ,
 'edition'               => \&editer_ra,
 'impression'           => \&afficher_ra, #La modification importante se trouve dans entete_standard avec la fonction javascript
 'affichage'             => \&afficher_ra,
);
my $action;

our %parametres =();
# Déclaration des identifications de connexion
my ($id, $id_ra, $nom_client);
#my $login;
our (@collaborateur, $dbh);
#my $tps_connexion = 600; # Délai de connexion sans inactivité

# Tableau des RA
our (@ra, @ra_ast, @ra_comment, @ra_global, @ra_hsup, @ra_pres);

#Liste des clients pour le salarié
our (@clients, %clients);
our %tous_clients = (0, 'T&S'); # Hachage incluant T&S et les autres clients

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
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# Dï¿½claration des feuilles de styles
my @liens = [
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/ra.css",
         'media'           => 'screen',
       }),
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/ra_print.css",
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
visu_parametres();
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
$action = $cgi->param('action') || 'creation';
&{$action{$action}}();
#creer_ra();

exit;

sub creer_ra {
  entete_standard();
  recherche_liste_clients();
  recherche_ra();
  print $cgi->start_div({-id => 'ecran'});
#  print $cgi->h1("Rapport d'activité de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
  affiche_entete();
  genere_mois($parametres{action});
  #$parametres{mois} = 'Jude';
  my $decodeMois = decode('utf-8', $parametres{mois});

  print $cgi->start_form(-id =>'f_ra', -action => "$rep_pl/rapports_activites/ra/create.pl?action=creation&annee=$parametres{annee}&mois=$decodeMois&client_id=$parametres{client_id}&ident_user=$parametres{ident_user}&ident_id=$parametres{ident_id}");
  print $cgi->hidden(-name => 'nb_jours', -value =>"$nb_jours");
  print $cgi->hidden(-name => 'action', -value =>'$parametres{action}');
  print $cgi->hidden(-name => 'annee', -value =>'$parametres{annee}');
  print $cgi->hidden(-name => 'mois', -value =>'$parametres{mois}');
  #print "decodeMois = $decodeMois";
  print $cgi->hidden(-name => 'client_id', -value =>"$parametres{client_id}");
  print $cgi->hidden(-name => 'ident_user', -value =>'$parametres{ident_user}');
  print $cgi->hidden(-name => 'ident_id', -value =>'$parametres{ident_id}');
  gestion_champs_caches();
  affiche_mois($parametres{action});
  print $cgi->end_form(), $cgi->end_div(), $cgi->end_html();
}


sub entete_standard {
	print $cgi->header();
	if ($parametres{action} ne 'impression') { #  -encoding => 'UTF-8',
		print $cgi->start_html({-head => @liens, -Title => "Rapport d'activites v1.0", -script => \%script, -encoding => 'UTF-8', -base => 'true', -onLoad =>"return ra_charge();"});
	}
	else {
		print $cgi->start_html({-head => @liens, -Title => "Rapport d'activites v1.0", -script => \%script, -encoding => 'UTF-8', -base => 'true', -onLoad =>"return imprimer_ra();"});
	}
}

sub afficher_ra {
  entete_standard();
  recherche_liste_clients();
  recherche_ra();

  print $cgi->start_div({-id => 'ecran'});
  print $cgi->div({-id =>'logo'},$cgi->img({-alt =>'Logo', -name =>'logo', -src => "$rep/images/logo-w90.jpg"}));
#  print $cgi->h1("Rapport d'activitï¿½s de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
  affiche_entete();
  genere_mois($parametres{action});
  print $cgi->start_form(-id =>'f_ra');
  print $cgi->hidden(-name => 'nb_jours', -value =>"$nb_jours");
  gestion_champs_caches();
  affiche_mois($parametres{action});
  print $cgi->end_form();
  print $cgi->end_div();
}

sub editer_ra {
  entete_standard();
  recherche_liste_clients();
  recherche_ra();
  print $cgi->start_div({-id => 'ecran'});
#  print $cgi->h1("Rapport d'activitï¿½s de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
  affiche_entete();
  genere_mois($parametres{action});
  my $decodeMois = decode('utf-8', $parametres{mois});
  my $moisUnescape = uri_unescape($parametres{mois});
  #print $cgi->p("decodeMois = $decodeMois, mois = $parametres{mois}");
  print $cgi->start_form(-id =>'f_ra', -action => "$rep_pl/rapports_activites/ra/update.pl?action=edition&annee=$parametres{annee}&mois=$decodeMois&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&ident_user=$parametres{ident_user}&ident_id=$parametres{ident_id}");
  print $cgi->hidden(-name => 'nb_jours', -value =>"$nb_jours");
  print $cgi->hidden(-name => 'action', -value =>'$parametres{action}');
  print $cgi->hidden(-name => 'annee', -value =>'$parametres{annee}');
  print $cgi->hidden(-name => 'mois', -value =>'$decodeMois');
  #print $cgi->hidden(-name => 'moisBis', -value =>"$parametres{mois}");
  print $cgi->hidden(-name => 'client_id', -value =>"$parametres{client_id}");
  print $cgi->hidden(-name => 'ident_user', -value =>"$parametres{ident_user}");
  print $cgi->hidden(-name => 'ident_id', -value =>'$parametres{ident_id}');
  print $cgi->hidden(-name => 'ra_id', -value =>'$parametres{ra_id}');
  #print $cgi->hidden(-name => 'test', -value =>'Test');
  gestion_champs_caches();
  affiche_mois($parametres{action});
  print $cgi->end_form();
  print $cgi->end_div();
}

sub supprimer_ra {
#  entete_standard();
#  print $cgi->start_div({-id => 'ecran'});
#  print $cgi->h1("Suppression d'un rapport d'activitï¿½");
#    print $cgi->end_div();
  my $url;
  $url = "ra.pl?ident_user=$parametres{ident_user}&action=affichage&prev=supprimer&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&ident_id=$parametres{ident_id}";
  print $cgi->redirect("$url");
}

sub sauvegarder_ra {
#  entete_standard();
#  visu_parametres();
  my ($res, $url);
  if($parametres{action} eq 'creation') {
    if(($res = db_creation_ra()) != 0) {
      entete_standard();
      print $cgi->h1("Création du rapport d'activité");
      print $cgi->p("Une erreur est survenue lors de la crï¿½ation du rapport d'activité pour :");
      print $cgi->p("L'utilisateur : $parametres{ident_user}");
      print $cgi->p("Le client : $parametres{client_id}");
      print $cgi->p("L'annï¿½e : $parametres{annee}");
      print $cgi->p("Le mois : $parametres{mois}");
      print $cgi->p("Le code retour de la fonction db_create_ra() est : $res");
      print $cgi->p("Conseils : Recharger votre fenêtre de gestion des rapports d'activités afin de mettre à jour les éventuelles modifications intervenues à votre insu. Si le problème persiste, contacter l'administrateur en lui fournissant les informations ci-dessus.");
      print $cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(0);");
    }
    else {
      $url = "ra.pl?ident_user=$parametres{ident_user}&action=edition&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$id_ra&ident_id=$parametres{ident_id}&maj=".recherche_nom_client();
      print $cgi->redirect("$url");
    }
#    $url = "ra.pl?ident_user=$parametres{ident_user}&action=edition&annee=$parametres{annee}&mois=".uri_escape($parametres{mois})."&client_id=$parametres{client_id}&ra_id=$id_ra&ident_id=$parametres{ident_id}&maj=".uri_escape(recherche_nom_client());
  }
  elsif($parametres{action} eq 'edition') {
#    entete_standard();
#    visu_parametres();
    db_maj_ra();
#  $url = "ra.pl?ident_user=$parametres{ident_user}&action=edition&annee=$parametres{annee}&mois=".uri_escape($parametres{mois})."&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&ident_id=$parametres{ident_id}";
  $url = "ra.pl?ident_user=$parametres{ident_user}&action=edition&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&ident_id=$parametres{ident_id}";
  print $cgi->redirect("$url");
  }

}

sub visualiser_ra {
  my $url;
  if($parametres{action} eq 'edition') {
    $url = "ra.pl?ident_user=$parametres{ident_user}&action=affichage&prev=editer&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&ident_id=$parametres{ident_id}";
    print $cgi->redirect("$url");
  }
}

sub ouvrir_ra {
  my $url;
  if($parametres{action} eq 'affichage') {
    $url = "ra.pl?ident_user=$parametres{ident_user}&action=edition&annee=$parametres{annee}&mois=$parametres{mois}&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&ident_id=$parametres{ident_id}";
    print $cgi->redirect("$url");
  }
}

#sub delete_ra {
#  my $url;
#  my $nb_lignes = db_delete_ra();
#  $nom_client = recherche_nom_client();
#  if($nb_lignes == $nb_tables_delete) {
#    $url = "ra_delete.pl?ident_user=$parametres{ident_user}&annee=$parametres{annee}&mois=$parametres{mois}&client=$nom_client&ra_id=$parametres{ra_id}&client_id=$parametres{client_id}&ident_id=$parametres{ident_id}&status=ok&nb_lig=$nb_lignes";
#  }
#  else {
#    $url = "ra_delete.pl?ident_user=$parametres{ident_user}&annee=$parametres{annee}&mois=$parametres{mois}&client=$nom_client&ra_id=$parametres{ra_id}&status=nok&nb_lig=$nb_lignes";
#  }
#  print $cgi->redirect("$url");
#}

sub valider_ra {
  entete_standard();
  print $cgi->start_div({-id => 'ecran'});
  print $cgi->h1("Validation d'un rapport d'activité");
  print $cgi->end_div();
}

sub imprimer_ra {
  entete_standard();
  print $cgi->start_div({-id => 'ecran'});
  print $cgi->h1("Impression du rapport d'activité");
    print $cgi->end_div();
}

############## Requêtes SQL ###################################################


sub recherche_ra {
#Pour un collaborateur, une annï¿½e et un mois, on recherche les RA dans la table
# RA, puis pour chaque id_ra trouvï¿½ on cherche les diffï¿½rentes donnï¿½es dans les
# tables prï¿½vues ï¿½ cet effet (ra_presence, ra_hsup, ra_astreinte, etc.)
  my $ra;
#  unless($parametres{client_id} eq '-1') {
    my $sql = 'SELECT * FROM ra WHERE  idcollaborateur = '.$dbh->quote($collaborateur[0]).' AND mois = '.$dbh->quote($mois{$parametres{mois}}).' AND annee = '.$dbh->quote($parametres{annee});
#    print $sql;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while($ra = $sth->fetchrow_arrayref) {
      push @ra, [ @$ra ];
    }
    if(defined $ra[0]) {
#      print $cgi->br, "Rï¿½sultat de la recherche des RA, Voici la liste des id des RA ï¿½ chercher : ", $cgi->br();
      foreach (@ra) {
#        print " $_->[0]";
        $sql = 'SELECT * FROM ra_presence WHERE id = '.$dbh->quote($_->[0]);
#        print " $sql";
        $sth = $dbh->prepare($sql);
        $sth->execute();
        while($ra = $sth->fetchrow_arrayref) {
          push @ra_pres, [ @$ra ];
        }
#        print $cgi->br(), "Donnï¿½es contenues dans ra_presence", $cgi->br();
#        foreach (@ra_pres) {
#           print "@$_";
#        }
        $sql = 'SELECT * FROM ra_hsup WHERE id = '.$dbh->quote($_->[0]);
#        print " $sql";
        $sth = $dbh->prepare($sql);
        $sth->execute();
        while($ra = $sth->fetchrow_arrayref) {
          push @ra_hsup, [ @$ra ];
        }
        $sql = 'SELECT * FROM ra_astreinte WHERE id = '.$dbh->quote($_->[0]);
#        print " $sql";
        $sth = $dbh->prepare($sql);
        $sth->execute();
        while($ra = $sth->fetchrow_arrayref) {
          push @ra_ast, [ @$ra ];
        }
        $sql = 'SELECT * FROM ra_commentaire WHERE id = '.$dbh->quote($_->[0]);
#        print " $sql", $cgi->br();
        $sth = $dbh->prepare($sql);
        $sth->execute();
        while($ra = $sth->fetchrow_arrayref) {
          push @ra_comment, [ @$ra ];
        }


      }
    }
#  }
}

sub recherche_liste_clients {
# Quand on recherche les donnï¿½es du RA, on a besoin de connaitre la liste des
# clients afin me mettre le nom du client dans les tranches de prï¿½sence qui ont
# ï¿½tï¿½ rï¿½servï¿½es par le collaborateur dans le RA de ce client.
  my $client;
  my $sql = 'SELECT t1.id, t1.nom FROM client t1, affectation t2 WHERE (t2.idcollaborateur = '.$dbh->quote($collaborateur[0]).') AND (t2.idclient = t1.id)';
#  print $cgi->br(), "Liste des clients pour l'utilisateur $collaborateur[1]", $cgi->br();
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  while($client = $sth->fetchrow_arrayref) {
    if($client->[0] != $parametres{client_id}) {
      #(0,..0) pour les hsup et les astreintes
      push @clients, [ @$client, 0, 0, 0, 0, 0, 0, 0, 0 ];
      $clients{$client->[0]} = $client->[1];
    }
    $tous_clients{$client->[0]} = $client->[1];

  }
  push @clients, [ 0, 'Technologies et Services', 0, 0, 0, 0, 0, 0, 0, 0 ];
#  print "La taille de \@clients est de : ",1 + $#clients;
#  foreach (@clients) {
#    print " [$_->[1] : $_->[0]]";
#  }
}

sub recherche_data_ra {
}

