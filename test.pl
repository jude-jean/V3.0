#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);

# Déclaration du répertoire de base
our $rep = '../../test/jude/V3.0';
# Déclaration pour javascript
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# Déclaration des feuilles de styles
my %style = (
       'src'               => "$rep/styles/test.css",
);
my %s_action = (
 'Sauvegarder'            => \&sauvegarder_ra,
 'Valider'            => \&valider_ra,
 'Imprimer'           => \&imprimer_ra,
);


my %parametres =();
my %mois = ('Janvier', 1, 'Février', 2, 'Mars', 3, 'Avril', 4, 'Mai', 5, 'Juin', 6, 'Juillet', 7, 'Août', 8, 'Septembre', 9, 'Octobre', 10, 'Novembre', 11, 'Décembre', 12);
my %semaine = (1, 'Lundi', 2, 'Mardi', 3, 'Mercredi', 4, 'Jeudi', 5, 'Vendredi', 6, 'Samedi', 7, 'Dimanche');
my @calendrier;# Tableau de tableau [N°du jour, jour, ouvré|samedi|dimanche, 0=non férie | Nom de la fête, Hsup 0%, Hsup 25%, Hsup 50%, Hsup 100%, j_astreinte; n_astreinte, 24_astreinte, commentaire]

my @heures = (' ', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24);

my @activites = ( # [Libellé, Code activité, 0=client| 1 = T&S et Global]
 ['Présent', 1, 0],
 ['Absent', 0, 0],
 ['Travail interne', 2, 1],
 ['Congés payés', 3, 1],
 ['RTT',4, 1],
 ['Maladie', 5, 1],
 ['Récupération', 6, 1],
 ['Formation', 7, 1],
 ['Abs. except.', 8, 1],
 ['Sans solde', 9, 1],
);
my (%activites_vues_client, %activites_vues_TS, %r_activites_vues_client, %r_activites_vues_TS);
my (@activites_valeurs_client, @activites_valeurs_TS, @r_activites_valeurs_client, @r_activites_valeurs_TS);
my @astreinte = (0, 1, 2); #(0 = jour, 1 = nuit, 2 = 24H)
my %astreinte = (
  0 => ' ',
  1 => ' ',
  2 => ' ',
);

my %selection_presence_client = (
  1 => 'Tout',
  2 => 'Vide',
  3 => 'Présent',
  4 => 'Absent',
);
my @selection_presence_client = (1, 2, 3, 4);



init_popup_activites();
my $cgi = new CGI;
entete_standard();
print "\n", $cgi->start_div({-id => 'ecran'});
print "\n", $cgi->h1('Titre H1 du test');
print "\n", $cgi->start_div({-id => 'tableau'});
for(my $i = 0; $i <5; $i++) {
  print "\n", $cgi->start_div({-class => 'ouvre'});
  print "\n", $cgi->start_div({-class => 'Lig11col'});
  remplit_tableau();
  print "\n", $cgi->end_div(), $cgi->end_div();
}
print "\n", $cgi->start_div({-class => 'samedi'});
print "\n", $cgi->start_div({-class => 'Lig11col'});
remplit_tableau();
print "\n", $cgi->end_div(), $cgi->end_div();
print "\n", $cgi->start_div({-class => 'dimanche'});
print "\n", $cgi->start_div({-class => 'Lig11col'});
remplit_tableau();
print "\n", $cgi->end_div(), $cgi->end_div();



print "\n", $cgi->end_div();
affiche_barre_outils();
affiche_menu_s_actions();
print $cgi->end_div();




exit();

sub entete_standard {
	print $cgi->header();
	print $cgi->start_html({-Title => "Test", -script => \%script,
              -style =>\%style, -base => 'true'});
}

sub remplit_tableau {
  for(my $i = 2; $i <= 11; $i++) {
    print "\n", $cgi->div({-class => "Lig11col$i"}, "Col$i");
  }
}


sub vers_sous_menu {
  print $cgi->submit(-name=>'s_action', -value=>shift);
}


sub affiche_barre_outils {
  print "\n", $cgi->start_div({-id => 'barre_outils'});
#  if($parametres{client_id} > 0) {
#    $r_activites_vues_client{-1}='Vide';
#    print $cgi->label({-for => 'remplir'}, 'Remplir avec');
#    print $cgi->radio_group(-onclick => "return remplissage_presence(this)", -id => 'remplir', -name => 'presence', -values => \@r_activites_valeurs_client, -labels => \%r_activites_vues_client);
#    print $cgi->label({-for => 'selectionner'}, 'Sélectionner :');
#    print $cgi->radio_group(-id => 'selectionner', -name => 'selection', -values => \@selection_presence_client, -labels => \%selection_presence_client);
    $r_activites_vues_client{-1}='Vide';
    print $cgi->start_fieldset({-id => 'remplir'}), $cgi->legend('Remplir avec');
    print $cgi->radio_group(-onclick => "return remplissage_presence(this)", -name => 'presence', -values => \@r_activites_valeurs_client, -labels => \%r_activites_vues_client);
    print $cgi->end_fieldset();
    print $cgi->start_fieldset({-id => 'selectionner'}), $cgi->legend('Les champs sélectionnés');
    print $cgi->radio_group(-name => 'selection', -values => \@selection_presence_client, -labels => \%selection_presence_client);
    print $cgi->end_fieldset();
#  }
  print "\n", $cgi->end_div();
}


sub affiche_menu_s_actions {
  print $cgi->start_div({-id=>'menu_actions'});
  vers_sous_menu('Sauvegarder');
  vers_sous_menu('Imprimer');
  print $cgi->reset, $cgi->end_div();
}

sub init_popup_activites {
  push @activites_valeurs_client, ' ';
  push @activites_valeurs_TS, ' ';
  push @r_activites_valeurs_client, -1;
  push @r_activites_valeurs_TS, -1;

  foreach (@activites) {
    if ($_->[2] == 0) {
      push @activites_valeurs_client, $_->[1];
      $activites_vues_client{$_->[1]} = "$_->[1].$_->[0]";
      push @r_activites_valeurs_client, $_->[1];
      $r_activites_vues_client{$_->[1]} = "$_->[0]";

    }
    else {
      push @activites_valeurs_TS, $_->[1];
      $activites_vues_TS{$_->[1]} = "$_->[1].$_->[0]";
      push @r_activites_valeurs_TS, $_->[1];
      $r_activites_vues_TS{$_->[1]} = "$_->[1].$_->[0]";

    }
  }
}
