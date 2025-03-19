package Optis;
use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(show_table_geos cree_menug);

use strict;

my $racine;

my ($ligne, $menu_encours, @menu_encours);
sub cree_menug {
  my $ecran = recup_nom_ecran();
  my ($ind, $info);
  my $sql = "SELECT id, nom, gauche, droite, idparent, fonction FROM menuoptis WHERE ecran = (SELECT id FROM listecrans WHERE nom = ".$::dbh->quote($ecran).") AND gauche >= (SELECT gauche FROM menuoptis WHERE id = '1') AND droite <= (SELECT droite FROM menuoptis WHERE id = '1') ORDER BY gauche;";
#  print "Ecran : ", $ecran, $::cgi->br(), "sql = ", $sql, $::cgi->br();
  my $sth = $::dbh->prepare($sql);
  $sth->execute();
  my @menu;
  while(my @m = $sth->fetchrow_array()) {
	push @menu, [ @m ];
  }
  $racine = shift @menu;
  unshift @menu_encours, [ $racine->[2], $racine->[3] ];
  my $new_url;
#  for $ligne (@menu) {
#    print "@$ligne", $::cgi->br();
#  }
#  print "Generation du menu", $::cgi->br();
  print $::cgi->start_ul({-id => "$ecran"});
  $info = "<menu> id=$ecran>\n", 
  my $dim = scalar(@menu_encours);
  my ($i, $j, $k);
  $k = 0;
  for $ligne (@menu) {
	for ($i = 0; $i < $dim; $i++) {
#		print "k = $k"; 
#		print " i = $i, [ $menu_encours[$i][0], $ligne->[2], $ligne->[3], $menu_encours[$i][1] }";
		if(($menu_encours[$i][0] < $ligne->[2]) && ($ligne->[3] < $menu_encours[$i][1])) {
			last;
		}
		else {
			if($menu[$k-1][4] > 1) {# Idparent n'est pas le père
				print $::cgi->end_ul(), $::cgi->end_li();
				$info .= "</menu> </feuille> $ligne->[1]\n";
			}	
		}
#		print "Menu : $ligne->[1], Predecesseur : $menu[$k - 1][1], Droite : $menu[$k - 1][3], Gauche : $menu[$k - 1][2]", $::cgi->br();
	}
	$i--;
	for($j = 0; $j < $i; $j++) {
#		print "Dim(menu_encours) = ", scalar(@menu_encours), " Depiler $i fois pour $ligne->[1]";
		shift @menu_encours;
	}
	if ($ligne->[3] - $ligne->[2]== 1) { # C'est une feuille
		$new_url = genere_new_url($ecran, lcfirst $ligne->[1]);
		print $::cgi->li($::cgi->a({-href=>"$new_url"}, $ligne->[1]));
		$info .= "<feuille> <ancre -- $new_url $ligne->[1]></feuille>\n";
	}	
	else { # C'est un sous-menu
#		print " Dim(menu_encours) = ", scalar(@menu_encours), " Empiler 1 fois  pour $ligne->[1]";
		unshift @menu_encours, [ $ligne->[2], $ligne->[3] ];
		print $::cgi->start_li(), $::cgi->a("$ligne->[1]"), $::cgi->start_ul();
		$info .= "<feuille> <ancre $ligne->[1]> <menu>\n";
	}
	$k++;
  }
  print $::cgi->end_ul();
  $info .= "</menu> $ligne->[1]\n";
#  print "Html debug : \n$info";
}

sub find_menu_encours {
# retourne -1 si @menu_encours est vide ou si l'idparent n'existe pas
# dans @menu_encours ou $i dans le cas contraire
	my ($gauche, $droite, $nomparent) = @_;
	my $i = 0;
#	print "find_menu_encours : droite = $$droite, nom parent = $$nomparent ** "; 
	if(!defined(@menu_encours)) {
		print "find_menu_encours : menu_encours pas defini pour $$nomparent ";
		return -1;
	}	
#	print "droite = $$droite"; 
	while ($i < scalar(@menu_encours)) {
#		print "find_menu_encours : i = $i, dim(menu_encours) = ", scalar(@menu_encours), " droite = $$droite";
		if($menu_encours[$i] == $$gauche
		) {
			print "find_menu_encours : Parent trouve pour $$nomparent au rg $i";
			return $i;
		}
		$i++;
	}
	return -1;
	
}

#sub add_menu_encours {
#	if (not defined(@menu_encours)) {
#		push @menu_encours, $ligne->[4];
#		return;
#	}
#}

sub menu_trie_par_rg {
  $a->[4] <=> $b->[4];
#  ||
#  $a->[2] <=> $b->[2];
}
sub show_table_geos {
#  print "L'URL de lancement : ", $::cgi->url(), "<->", $::cgi->script_name(), "<->", '?', "<->", $::cgi->query_string(),$::cgi->br();
  my $legeos = 'Affichage de la table G&eacute;os';
  print $::cgi->start_div({-id => 'tbgeos'}), $::cgi->div({-id => 'legeos'}, $legeos), $::cgi->div({-id => 'footgeos'}, "Fin du tableau");

  my $sql= "SELECT * FROM geos" ;
  my $sth = $::dbh->prepare($sql);
  $sth->execute;
  my @geos;
  while(@geos = $sth->fetchrow_array()) {
	print $::cgi->start_div({-class => 'ligeos'}), $::cgi->span("$geos[1]"), $::cgi->span("$geos[2]"), $::cgi->span("&#$geos[3];"), $::cgi->end_div();
  }
  print $::cgi->start_div({-id => 'l1geos'}), $::cgi->span('Nom de la zone'), $::cgi->span('Nom de la devise'), $::cgi->span('Symbole'), $::cgi->end_div();
  print $::cgi->end_div(); # Fin du div tbgeos
}

sub recup_nom_ecran {
  $::cgi->script_name() =~ /menu(.*)\//;
  return "menu".$1;
}

sub genere_new_url {
  my ($ch1, $ch2) = @_;
  my ($new_script_name, $new_query_string);
  ($new_script_name = $::cgi->script_name()) =~ s/$ch1/$ch2/;
  ($new_query_string = $::cgi->query_string()) =~ s/;/&/;
  return $::cgi->url()."$new_script_name".'?'."$new_query_string";
}

1;