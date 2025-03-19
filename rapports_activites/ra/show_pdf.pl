#!/usr/bin/perl -w
# Magasin de chemises et chaussures
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use URI::Escape;
use DBI;
use PDF::API2;


# D�claration du r�pertoire de base
#our $rep = '../../../../test/jude/V3.0';
# liste des fonctions � lancer en fonction du param�tre action
my %action = (
 'creation'              => \&creer_ra ,
 'edition'               => \&editer_ra,
 'impression'           => \&afficher_ra, #La modification importante se trouve dans entete_standard avec la fonction javascript
 'affichage'             => \&afficher_ra,
 'Version PDF'			=> \&creer_pdf,
);
my $action;
my ($page, $gfx, $text, $font, $img);
my ($width, $height) = (612, 792);
my ($row, $column) = (31, 12);
my ($hspace, $vspace) = (6, 0);
my ($tmargin, $bmargin, $lmargin, $rmargin) = (30, 30, 30, 30);
my %font;

my $rowheight = ($height-$tmargin-$bmargin-($row-1)*$vspace)/$row;
#my @colwidth = (60, 20, 90, 90, 30, 30, 30, 30, 20, 20, 20, 150);
my @colwidth = (60, 20, 100, 100, 30, 30, 30, 30, 20, 20, 20); # Le reste est pour le chanmp commentaire
our %parametres =();
# D�claration des identifications de connexion
my ($id, $id_ra, $nom_client);
#my $login;
our (@collaborateur, $dbh);


# Tableau des RA
our (@ra, @ra_ast, @ra_comment, @ra_global, @ra_hsup, @ra_pres);

#Liste des clients pour le salari�
our (@clients, %clients);
our %tous_clients = (0, 'T&S'); # Hachage incluant T&S et les autres clients

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
use Etechnoserv;
use Connexion;
use Ra;
# D�claration pour javascript
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# D�claration des feuilles de styles
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

our $pdf = PDF::API2->new();
lecture_parametres(\%parametres);
#visu_parametres();
@collaborateur = info_id($parametres{ident_id});
unless (@collaborateur) {
	entete_standard(); 
	print "Le parametre ident_id n'est pas d�fini dans la base de donn�e", $cgi->br();
	visu_parametres(\%parametres);
	print $cgi->end_html();
#	die "Le parametre $parametres{ident_id} n'est pas d�fini dans la base dans la base de donn�es";
	exit;
}
if(verif_tps_connexion() == 0) { #D�lai d'attente d�pass�
	print $cgi->redirect("$rep_pl/etechnoserv.pl?err=3");
	exit;
}
$action = $cgi->param('action') || 'creation';
&{$action{$action}}();


exit;

sub creer_pdf {
#	print $cgi->header(-type => "application/pdf", -expires => "now", -content_disposition =>"inline; filename=test.pdf");
	$nom_client = recherche_nom_client();
	print $cgi->header(-type => "application/pdf", -expires => "now");
	$pdf->info(
			'Author'	=>	"$collaborateur[2] $collaborateur[1]",
			'Creator'	=>	"show_pdf.pl",
			'Title'		=>	"CRA de $collaborateur[2] $collaborateur[1] pour $parametres{mois} $parametres{annee} pour le client $nom_client",
			'Subject'	=>	"Rapports d'activit�s",
			'Keywords'	=>	"$collaborateur[2] $collaborateur[1] $nom_client Rapports d'activit�s $parametres{mois} $parametres{annee}",
		);
	$page = $pdf->page();
	$font{'plain'} = $pdf->corefont('Helvetica', 1); # R�cupere une font
	$font{'bold'} = $pdf->corefont('Helvetica-Bold', 1); # R�cupere une font
#	foreach (keys (%font)) {
#		$font{$_}->encode('latin1');
#	}
	$page->mediabox($width, $height);
	$gfx = $page->gfx();
	$img = $pdf->image_jpeg('logo-w90.jpg');
	$gfx->image($img, 256, 720);
	
	$text = $page->text();
	$text->translate(306, 700); #396

	$text->font($font{'bold'}, 12); # Assigne la fonte font au texte

#	$text->text_center("Rapport d'activit�s de $collaborateur[3] pour le mois de $parametres{mois} $parametres{annee}");
	$text->text_center("RAPPORT D'ACTIVITES");
	$text->cr(-16);
	$text->text_center("   NOM: $collaborateur[1]                                Mois: $parametres{mois} $parametres{annee}");
	$text->cr(-16);
	$text->text_center("PRENOM: $collaborateur[2]                           	Soci�t�: $nom_client");

	$height = 720 - 90; # 720 = position de l'image, 90 = la place pour le titre de la page.
	$gfx->strokecolor("#151111");
	$gfx->rect($lmargin, $bmargin, $width-$lmargin-$rmargin, $height-$tmargin-$bmargin);
	$gfx->stroke;
	$gfx->endpath();
	$text->font($font{'plain'}, 8);
	my $x = $lmargin;
	foreach my $c (0..$#colwidth) {
# Dessine les lignes verticales	
		$x += $colwidth[$c];
		$gfx->move($x, $bmargin);
		$gfx->line($x, $height-$tmargin);
		$gfx->move($x, $bmargin);
		$gfx->line($x, $height-$tmargin);
		$gfx->stroke;
		$gfx->endpath();
		foreach my $r (0..$row-1) {
#Dessine les 2 lignes horizontales		
			my $y = $height -$tmargin -$r*($rowheight+$vspace);
			$gfx->move($lmargin, $y);
			$gfx->line($width-$rmargin, $y);
#			$gfx->move($lmargin, $y+$vspace);
#			$gfx->line($width-$rmargin, $y+$vspace);
			$gfx->stroke;
			$gfx->endpath();
			$text->translate($lmargin, $y-16);
			$text->text("y = ". sprintf("%6.2f", $y). ", r = $r");
		}
	}
	print $pdf->stringify();
	$pdf->end;
	exit;
	
}


sub creer_ra {
  entete_standard();
  recherche_liste_clients();
  recherche_ra();
  print $cgi->start_div({-id => 'ecran'});
#  print $cgi->h1("Rapport d'activit�s de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
  affiche_entete();
  my $decodeMois = decode('utf-8', $parametres{mois});
  genere_mois($parametres{action});
  print $cgi->start_form(-id =>'f_ra', -action => "/cgi-bin/V3.0/rapports_activites/ra/create.pl?action=creation&annee=$parametres{annee}&mois=$decodeMois&client_id=$parametres{client_id}&ident_user=$parametres{ident_user}&ident_id=$parametres{ident_id}");
  print $cgi->hidden(-name => 'nb_jours', -value =>"$nb_jours");
  print $cgi->hidden(-name => 'action', -value =>'$parametres{action}');
  print $cgi->hidden(-name => 'annee', -value =>'$parametres{annee}');
  print $cgi->hidden(-name => 'mois', -value =>"$decodeMois");
  print $cgi->hidden(-name => 'client_id', -value =>"$parametres{client_id}");
  print $cgi->hidden(-name => 'ident_user', -value =>'$parametres{ident_user}');
  print $cgi->hidden(-name => 'ident_id', -value =>'$parametres{ident_id}');
  gestion_champs_caches();
  affiche_mois($parametres{action});
  print $cgi->end_form(), $cgi->end_div(), $cgi->end_html();
}


sub entete_standard {
	print $cgi->header(-type => "application/pdf", -expires => "now", );
}

sub afficher_ra {
  entete_standard();
  recherche_liste_clients();
  recherche_ra();

  print $cgi->start_div({-id => 'ecran'});
  print $cgi->div({-id =>'logo'},$cgi->img({-alt =>'Logo', -name =>'logo', -src => "$rep/images/logo-w90.jpg"}));
#  print $cgi->h1("Rapport d'activit�s de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
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
#  print $cgi->h1("Rapport d'activit�s de $parametres{mois} $parametres{annee} pour le login $parametres{ident_user}");
  affiche_entete();
  my $decodeMois = decode('utf-8', $parametres{mois});
  genere_mois($parametres{action});
  print $cgi->start_form(-id =>'f_ra', -action => "/cgi-bin/V3.0/rapports_activites/ra/update.pl?action=ecdition&annee=$parametres{annee}&mois=$decodeMois&client_id=$parametres{client_id}&ra_id=$parametres{ra_id}&ident_user=$parametres{ident_user}&ident_id=$parametres{ident_id}");
  print $cgi->hidden(-name => 'nb_jours', -value =>"$nb_jours");
  print $cgi->hidden(-name => 'action', -value =>'$parametres{action}');
  print $cgi->hidden(-name => 'annee', -value =>'$parametres{annee}');
  print $cgi->hidden(-name => 'mois', -value =>"$decodeMois");
  print $cgi->hidden(-name => 'client_id', -value =>"$parametres{client_id}");
  print $cgi->hidden(-name => 'ident_user', -value =>"$parametres{ident_user}");
  print $cgi->hidden(-name => 'ident_id', -value =>'$parametres{ident_id}');
  print $cgi->hidden(-name => 'ra_id', -value =>'$parametres{ra_id}');
  print $cgi->hidden(-name => 'test', value => 'Test');
  gestion_champs_caches();
  affiche_mois($parametres{action});
  print $cgi->end_form();
  print $cgi->end_div();
}

sub supprimer_ra {
#  entete_standard();
#  print $cgi->start_div({-id => 'ecran'});
#  print $cgi->h1("Suppression d'un rapport d'activit�");
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
      print $cgi->h1("Cr�ation du rapport d'activit�");
      print $cgi->p("Une erreur est survenue lors de la cr�ation du rapport d'activit� pour :");
      print $cgi->p("L'utilisateur : $parametres{ident_user}");
      print $cgi->p("Le client : $parametres{client_id}");
      print $cgi->p("L'ann�e : $parametres{annee}");
      print $cgi->p("Le mois : $parametres{mois}");
      print $cgi->p("Le code retour de la fonction db_create_ra() est : $res");
      print $cgi->p("Conseils : Recharger votre fen�tre de gestion des rapports d'activit�s afin de mettre � jour les �ventuelles modifications intervenues � votre insu. Si le probl�me persiste, contacter l'administrateur en lui fournissant les informations ci-dessus.");
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
  print $cgi->h1("Validation d'un rapport d'activit�");
  print $cgi->end_div();
}

sub imprimer_ra {
  entete_standard();
  print $cgi->start_div({-id => 'ecran'});
  print $cgi->h1("Impression du rapport d'activit�");
    print $cgi->end_div();
}

############## Requ�tes SQL ###################################################


sub recherche_ra {
#Pour un collaborateur, une ann�e et un mois, on recherche les RA dans la table
# RA, puis pour chaque id_ra trouv� on cherche les diff�rentes donn�es dans les
# tables pr�vues � cet effet (ra_presence, ra_hsup, ra_astreinte, etc.)
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
#      print $cgi->br, "R�sultat de la recherche des RA, Voici la liste des id des RA � chercher : ", $cgi->br();
      foreach (@ra) {
#        print " $_->[0]";
        $sql = 'SELECT * FROM ra_presence WHERE id = '.$dbh->quote($_->[0]);
#        print " $sql";
        $sth = $dbh->prepare($sql);
        $sth->execute();
        while($ra = $sth->fetchrow_arrayref) {
          push @ra_pres, [ @$ra ];
        }
#        print $cgi->br(), "Donn�es contenues dans ra_presence", $cgi->br();
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
# Quand on recherche les donn�es du RA, on a besoin de connaitre la liste des
# clients afin me mettre le nom du client dans les tranches de pr�sence qui ont
# �t� r�serv�es par le collaborateur dans le RA de ce client.
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

