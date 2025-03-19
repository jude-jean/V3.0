package Affichage;
use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(menu_social affiche_debut_corps_de_page affiche_bas_de_page affiche_fin_corps_de_page affiche_entete_login_connecte affiche_entete_login_non_connecte affiche_ecran_connexion affiche_menu_connecte affiche_menu_gauche);

use strict;
#our $rep = '/test/jude/V3.0';

sub affiche_debut_corps_de_page {
  print "\n", $::cgi->start_div({-id => "corps"});
}

sub affiche_bas_de_page  {
  print "\n", $::cgi->start_div({id=>"basdepage"});
  print "\n", $::cgi->img({-src=>"$::rep/images/basdepage.gif", -alt=> "Bas de page"});
  print $::cgi->span({-id => 'copy'}, "&copy; 2003-2024 Technologies et Services, etechnoserv.com. All Rights Reserved.");
  print "\n", $::cgi->end_div();
}

sub affiche_fin_corps_de_page {
  print "\n", $::cgi->end_div();
  print "\n", $::cgi->end_html();
}

sub affiche_entete_login_non_connecte {
  print "\n", $::cgi->start_div({-id => "entete"});
  print "\n", $::cgi->start_div({-id => "images"});
  print "\n", $::cgi->img({-id => "logo", src=>"$::rep/images/logo-h90.jpg", alt=> "Logo T&S"});
  print "\n", $::cgi->img({-id => "slogan", src=>"$::rep/images/slogan.jpg", alt=> "Slogan T&S"});
  print "\n", $::cgi->end_div();
  affiche_login_non_connecte();
  print "\n", $::cgi->end_div();
}

# Affichage de l'ent�te compos�e de la partie gauche (logo et image) et de la
# partie droite servant � la connexion au travers des fonctions d�finies
# dans %connexion
sub affiche_entete_login_connecte {
  print "\n", $::cgi->start_div({-id => "entete"});
  print "\n", $::cgi->start_div({-id => "images"});
  print "\n", $::cgi->img({-id => "logo", src=>"$::rep/images/logo-h90.jpg", alt=> "Logo T&S"});
  print "\n", $::cgi->img({-id => "slogan", src=>"$::rep/images/slogan.jpg", alt=> "Slogan T&S"});
  print "\n", $::cgi->end_div();
  affiche_login_connecte($::id, $::collaborateur[3]);
  print "\n", $::cgi->end_div();
}

#sub affiche_ecran_connexion {
#   if (defined($::id)) {
#      affiche_login_connecte($::id, $::collaborateur[3]);
#   }
#   else {
#     affiche_login_non_connecte(0);
#   } 
#}

sub affiche_login_connecte {
   my ($id, $login) = @_;
  $::cgi->autoEscape(undef);
   if(!defined($login)) {
     print "la valeur de login est égale &agrave; : $login ou $::collaborateur[3]", $::cgi->br(), "La valeur de id est $id", $::cgi->br();
   }
   if ($::cgi->self_url() =~ /optis/) {
		print $::cgi->start_div({id=>"connexion"}), $::cgi->start_form(-action => "$::rep_pl/connexion/connexion.pl"),
         $::cgi->start_div(),"$login connect&eacute;", $::cgi->br(), $::cgi->br(),
         vers_connexion("Déconnexion"), vers_doc("Compte"), $::cgi->start_div({-id => 'admin'}), "Administration",
		 $::cgi->a({-href => '#', -class => 'show'}, '[+]'), $::cgi->a({-href => '#', -class => 'hide'}, '[-]'),
		 $::cgi->start_ol({-id => 'list'}),
		 $::cgi->li($::cgi->a({-href => '#'}, 'Utilisateurs')),
		 $::cgi->li($::cgi->a({-href => '#'}, "Droits d'accès")),
		 $::cgi->li($::cgi->a({-href => '#'}, 'Menus')),
		 $::cgi->li($::cgi->a({-href => '#'}, 'Paramêtres')),
         $::cgi->end_ol, $::cgi->end_div(), $::cgi->hidden(-name=>'ident_id', -value=>"$id"),
		 $::cgi->hidden(-name=>'ident_user', value=>'$login'), $::cgi->end_div(),
         $::cgi->end_form(), $::cgi->end_div();
		}
	else {
		print $::cgi->start_div({id=>"connexion"}), $::cgi->start_form(-id=>"connexionForm", -action => "$::rep_pl/connexion/connexion.pl", -enctype => 'application/x-www-form-urlencoded'),
         $::cgi->start_div(),"$login connect&eacute;", $::cgi->br(), $::cgi->br(),
         #vers_connexion("D&eacute;connexion"),
         vers_connexion("D&eacute;connexion"), vers_doc("Compte"),
         $::cgi->hidden(-name=>'ident_id', -value=>"$id"),
		 $::cgi->hidden(-name=>'ident_user', value=>'$login'), $::cgi->end_div(),
         $::cgi->end_form(), $::cgi->end_div();
	}

}

sub affiche_login_non_connecte {
      my ($err) = @_;
	  print "\n", $::cgi->start_div({-id=> "connexion"});
#      print "\n", $::cgi->start_form(-onsubmit => "return valide_form_connexion(this);");
      print "\n", $::cgi->start_form(-action => "$::rep_pl/connexion/connexion.pl", -onsubmit => "return valide_form_connexion(this);");
      print "\n", $::cgi->start_div(), "Login &nbsp;: ", $::cgi->textfield(-id => 'log', -name=>"login",
                      -default=> "Identifiant", -size=> 20, -onfocus => "select();", -tabindex => '1',
                      -onchange=> "return valide_login(this)"), $::cgi->end_div();
      print "\n", $::cgi->start_div(), "Mot de passe &nbsp;: ",
                   $::cgi->password_field(-name=>"pswd", -size=>20), $::cgi->end_div();
      if(!defined($::erreur)) {
        print "\n", $::cgi->div(vers_connexion("Envoi"));
      }
      else {
        print "\n", $::cgi->start_div(),vers_connexion("Envoi"),
        $::cgi->em("$::erreur{$::erreur}"),
        $::cgi->end_div();
      }
      print $::cgi->end_form(), $::cgi->end_div();
}

#### Dans le menu droit, les boutons du bas
my @boutons_bas =	( ["Accueil", 0x1],
                    ["Rapports d'activit&eacute;s", 0x2],
                    ["Calendrier", 0x4],
                    ["Compte", 0x8],
					["Vie sociale", 0x10],
					["Optis", 0x20],
					);
					

sub menu_social {
  my $droits = shift;
  my $exp;
  my $s_exp;
  my $global= 0x0;
  my $i;
  print $::cgi->start_div({-class => 'menu_droit_bas'});
  for($i = 0; $i < @boutons_bas; $i++) {
    if($boutons_bas[$i]->[1] == ($droits & $boutons_bas[$i]->[1])) {
      print vers_doc("$boutons_bas[$i]->[0]");
    }
  }
  print $::cgi->end_div();
}

sub vers_doc { $::cgi->submit(-NAME =>".Etat", -VALUE => shift);}

sub vers_connexion { $::cgi->submit(-NAME =>".Connexion", -VALUE => shift)}

############################"
### G�n�ration du menu gauche
# D�claration des menus, les sous menus doivent �tre d�clar�s avant le menu
# global
###### D�claration des menus gauche pour un utilisateur connect� #######
my @menug1 = (
   [0, "Les adresses", "/collaborateur/adresse.php"],
   [0, "Les taux", "/collaborteur/taux.php"],
   [0, "La documentation", "/collaborteur/documentation.php"],
   [0, "Les liens", "/collaborteur/liens.php"],
);

my @menug5 = (
   [0, "Collaborateurs", "/collaborateur/collaborateurs.php"],
   [0, "Clients", "/collaborateur/clients.php"],
   [0, "taux de cotisation", "/collaborateur/admin_taux.php"],
   [0, "Rapports d'activit&eacute;s", "/collaborateur/admin_cra.php"],
);


my @menug = (
   [1, "Vie sociale","#", "menug1", \@menug1],
   [2, "Les rapports d'activit&eacute;s","/rapports_activites/show.pl?ident_id="],
   [0, "Les collaborateurs","/collaborateur/liste.php"],
   [0, "Le webmail","/collaborateur/webmail.php"],
   [2, "Mon compte","/compte/identification/show.pl?ident_id="],
   [1, "L'administration","#", "menug5", \@menug5],
);


##### D�claration des menus gauche pour un utilisateur non connect� ######
my @menu_realisation = (
   [0, "2006", "/etechnoserv.pl?menu=gauche&type=0&page=4&anne=2006"],
   [0, "2005", "/etechnoserv.pl?menu=gauche&type=0&page=4&anne=2005"],
);


my @menug_nconnecte = (
   [0, "Qui sommes nous?", "/etechnoserv.pl?menu=gauche&type=0&page=1"],
   [0, "Qui &ecirc;tes vous?", "/etechnoserv.pl?menu=gauche&type=0&page=2"],
   [0, "Notre m&eacute;tier", "/etechnoserv.pl?menu=gauche&type=0&page=3"],
   [1, "Nos r&eacute;alisations", "#", "menu_realisation", \@menu_realisation],
   [0, "Nos r&eacute;f&eacute;rences", "/etechnoserv.pl?menu=gauche&type=0&page=5"],
   [0, "Recrutement", "/etechnoserv.pl?menu=gauche&type=0&page=6"],
   [0, "Documentation", "/etechnoserv.pl?menu=gauche&type=0&page=7"],
);

############ Les fonctions d'affichage du menu gauche
sub affiche_menu_gauche {
  print "\n", $::cgi->start_div({-id=>"gauche"});
  print "\n", $::cgi->start_div({-id=>"menu"});
  print "\n", $::cgi->p('Navigation sur le site');
  if(defined($::id)) {
    genere_menu_gauche(\@menug, \@menug, "menu");
  }
  else {
    print "\n", $::cgi->start_object({-id=>"menu_object"});
    genere_menu_gauche(\@menug_nconnecte, \@menug_nconnecte, "menu");
    print "\n", $::cgi->end_object();
  }
  print "\n", $::cgi->end_div();
  print "\n", $::cgi->end_div(); # fin di div "gauche"

}

sub genere_menu_gauche {
  my ($ref_menu_base, $menu, $id_menu) = @_;
  my $i;
  if($menu == $ref_menu_base) {
     print "\n", $::cgi->start_ul();
  }
  else {
    print "\n", $::cgi->start_ul({-id=> "$id_menu"});
  }
 my $href;

  for($i = 0; $i < @$menu; $i++) {
	 $href = $::rep_pl."$menu->[$i][2]"; 
     if ($menu->[$i][0] == 0) {
          
		  print "\n", $::cgi->li($::cgi->a({-href=>"$href"}, $menu->[$i][1]));
     }
     elsif($menu->[$i][0] == 1) {
        print "\n", $::cgi->start_li({-onmouseover=> "return bascule('"."$menu->[$i][3]"."');",
                    -onmouseout=>"return bascule('"."$menu->[$i][3]"."');"}),
                    $::cgi->a({-href=>"$menu->[$i][2]"}, $menu->[$i][1]);

        genere_menu_gauche($ref_menu_base, $menu->[$i][4], "$menu->[$i][3]");
        print "\n", $::cgi->end_li();
     }
     else {# Cas = 2, la commande est calcul�e
#       $href = "$menu->[$i][2]".$::id;
	   $href .= $::id;
       print "\n", $::cgi->li($::cgi->a({-href=>"$href"},$menu->[$i][1]));
     }
  }
  print "\n", $::cgi->end_ul();

}
# Fin de l'affichage du menu gauche






1;