#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Time::Local;
# D�claration du r�pertoire de base
our $rep = '../jude/V3.0';
# D�claration pour javascript
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# D�claration des feuilles de styles
my %style = (
       'src'               => "$rep/styles/etechnoserv.css",
);

# D�claration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
our $dbh;
my $tps_connexion = 600; # D�lai de connexion sans inactivit�

our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
my $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);
$mois += 1;
$annee += 1900;

# Date de cr�ation de Technologies et Services
our @date_ts = (2003, 1, 1);



# D�claration des menus, les sous menus doivent �tre d�clar�s avant le menu
# global
###### D�claration des menus gauche pour un utilisateur connect� #######
my @menug1 = (
   [0, "Les adresses", "collaborteur/adresse.php"],
   [0, "Les taux", "collaborteur/taux.php"],
   [0, "La documentation", "collaborteur/documentation.php"],
   [0, "Les liens", "collaborteur/liens.php"],
);

my @menug5;

my @menug = (
   [1, "Vie sociale","#", "menug1", \@menug1],
#   [0, "Les rapports d'activit�s","collaborateur/cra.php"],
   [2, "Les rapports d'activit�s","etechnoserv.pl?.Etat=Rapports d'activit�s&annee=$annee&ident_id="],
   [0, "Les collaborateurs","collaborateur/liste.php"],
   [0, "Le webmail","collaborateur/webmail.php"],
   [2, "Mon compte","etechnoserv.pl?.Etat=Compte&smenu=identification&ident_id=$id"],
   [1, "L'administration","#", "menug5", \@menug5]
);


@menug5 = (
   [0, "Collaborateurs", "collaborateur/collaborateurs.php"],
   [0, "Clients", "collaborateur/clients.php"],
   [0, "taux de cotisation", "collaborateur/admin_taux.php"],
   [0, "Rapports d'activit�s", "collaborateur/admin_cra.php"],
);

##### D�claration des menus gauche pour un utilisateur non connect� ######
my @menu_realisation = (
   [0, "2006", "etechnoserv.pl?menu=gauche&type=0&page=4&anne=2006"],
   [0, "2005", "etechnoserv.pl?menu=gauche&type=0&page=4&anne=2005"],
);

my @menug_nconnecte = (
   [0, "Qui sommes nous?", "etechnoserv.pl?menu=gauche&type=0&page=1"],
   [0, "Qui êtes vous?", "etechnoserv.pl?menu=gauche&type=0&page=2"],
   [0, "Notre métier", "etechnoserv.pl?menu=gauche&type=0&page=3"],
   [1, "Nos réalisations", "#", "menu_realisation", \@menu_realisation],
   [0, "Nos références", "etechnoserv.pl?menu=gauche&type=0&page=5"],
   [0, "Recrutement", "etechnoserv.pl?menu=gauche&type=0&page=6"],
   #[0, "Documentation", "etechnoserv.pl?menu=gauche&type=0&page=7"],
);


our $cgi = new CGI;
debut_page_html();
affiche_menu_gauche();
fin_page_html();
exit;

sub debut_page_html {
  my $url = $cgi->url;
  print $cgi->header('text/html;charset=UTF-8');
  print $cgi->start_html();
}
  
#  if($ecran_actuel eq 'Calendrier') {
#    print $cgi->start_html({-Title => "etechnoserv.com v3.0", -script => \%script,
#              -style =>\%style, -xbase => "$url", onLoad => 'return gestion_affichage_rdv();'});
#  }
#  else {
#    print $cgi->start_html({-Title => "etechnoserv.com v3.0", -script => \%script,
#              -style =>\%style, -xbase => "$url"});
#  }
#  print "url = $url", $cgi->br(), "self_url = ", $cgi->self_url, $cgi->br();
#}



sub affiche_menu_gauche {
  print "\n", $cgi->start_div({-id=>"gauche"});
  print "\n", $cgi->start_div({-id=>"menu"});
  print "\n", $cgi->p('Navigation sur le site');
  if(defined($id)) {
    genere_menu_gauche(\@menug, \@menug, "menu");
  }
  else {
#    print "\n", $cgi->start_object({-id=>"menu_object"});
    print "\n", "<object -id=menu_object>";	
    genere_menu_gauche(\@menug_nconnecte, \@menug_nconnecte, "menu");
    print "\n", "</object>";
  }
  print "\n", $cgi->end_div();
  print "\n", $cgi->end_div(); # fin di div "gauche"

}

sub genere_menu_gauche {
  my ($ref_menu_base, $menu, $id_menu) = @_;
  my $i;
  if($menu == $ref_menu_base) {
     print "\n", $cgi->start_ul();
  }
  else {
    print "\n", $cgi->start_ul({-id=> "$id_menu"});
  }
 my $href;

  for($i = 0; $i < @$menu; $i++) {
     if ($menu->[$i][0] == 0) {
          print "\n", $cgi->li($cgi->a({-href=>"$menu->[$i][2]"}, $menu->[$i][1]));
     }
     elsif($menu->[$i][0] == 1) {
        print "\n", $cgi->start_li({-onmouseover=> "return bascule('"."$menu->[$i][3]"."');",
                    -onmouseout=>"return bascule('"."$menu->[$i][3]"."');"}),
                    $cgi->a({-href=>"$menu->[$i][2]"}, $menu->[$i][1]);

        genere_menu_gauche($ref_menu_base, $menu->[$i][4], "$menu->[$i][3]");
        print "\n", $cgi->end_li();
     }
     else {# Cas = 2, la commande est calcul�e
       $href = "$menu->[$i][2]".$id;
       print "\n", $cgi->li($cgi->a({-href=>"$href"},$menu->[$i][1]));
     }
  }
  print "\n", $cgi->end_ul();

}


sub fin_page_html {
  print "\n", $cgi->end_div();
  print "\n", $cgi->end_html();
}

