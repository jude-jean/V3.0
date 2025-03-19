package Ra;
use Exporter;
use Encode qw(encode decode);
use URI::Escape;
@ISA = ('Exporter');
@EXPORT = qw(recherche_nom_client affiche_entete genere_mois gestion_champs_caches affiche_mois $nb_jours $nb_tables_delete %mois);

use Date::Calc qw(:all);
use Time::Local;
use JourDeFete qw(est_ferie est_jour_ferie Delta_Dates_AMJ);

our %mois = ('Janvier', 1, 'Février', 2, 'Mars', 3, 'Avril', 4, 'Mai', 5, 'Juin', 6, 'Juillet', 7, 'Août', 8, 'Septembre', 9, 'Octobre', 10, 'Novembre', 11, 'Décembre', 12, , 'D%E9cembre', 12);
my %semaine = (1, 'Lundi', 2, 'Mardi', 3, 'Mercredi', 4, 'Jeudi', 5, 'Vendredi', 6, 'Samedi', 7, 'Dimanche');
my @calendrier;# Tableau de tableau [N�du jour, jour, ouvr�|samedi|dimanche, 0=non f�rie | Nom de la f�te, Si (date_in < date) ? 1 : 0]

my %numVsMois = ('1' => 'Janvier', '2' => 'Février', '3' => 'Mars', '4' => 'Avril', '5' => 'Mai', '6' => 'Juin', '7' => 'Juillet', '8' => 'Août', '9' => 'Septembre', '10' => 'Octobre', '11' => 'Novembre', '12' => 'Décembre');

my $ferie = 0;
#my @heures = (' ', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, '+');
my @heures = (' ', 1, 2, 3, 4, 5, 6, 7, 8, '+');

my @activites = ( # [Libell�, Code activit�, 0=client| 1 = T&S et Global, Compteur >=0 ]
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
my (%activites_vues_client, %activites_vues_TS, %r_activites_vues_client, %r_activites_vues_TS, %calcul_nb_activites);
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

my @selection_presence_client_vues;

my %action = (
 'creation'              => 'Cr&eacute;ation' ,
 'edition'               => 'Edition' ,
 'suppression'           => 'Suppression',
 'affichage'             => 'Affichage',
);
my %s_action = (
 'Sauvegarder'            => \&sauvegarder_ra,
 'Visualiser'             => \&visualiser_ra,
 'Valider'            => \&valider_ra,
 'Imprimer'           => \&imprimer_ra,
 'Editer'             => \&ouvrir_ra,
 'Supprimer'          => \&delete_ra,
);



my @selection_presence_client = (1, 2, 3, 4);
# Tableau des RA
#my (@::ra, @::ra_ast, @::ra_comment, @::ra_global, @::ra_hsup, @::ra_pres);
my $nb_tables_delete = 5;
#Liste des clients pour le salari�
#my (@clients, %clients);
my %tous_clients = (0, 'T&S'); # Hachage incluant T&S et les autres clients
our ($nb_jours, $list_arg);
my ($nb_ouvres, $nb_pres, $nb_dispo, $nb_samedi, $nb_dimanche, $nb_ferie);
my ($nb_resa, $nb_hsup0, $nb_hsup25, $nb_hsup50, $nb_hsup100);
my ($nb_ast_j, $nb_ast_n, $nb_ast_24);
my $nom_client;

my ($mois_in, $annee_in, $jour_in);



sub genere_mois {
  my ($fonction) = @_;
  ($annee_in, $mois_in, $jour_in) = split /-/, $::collaborateur[5];
  my $tps_in = Mktime($annee_in, $mois_in, $jour_in, 2, 0, 0);
  my $tps;
  my ($num_jour, $type);
  $nb_ouvres = 0;
  if(exists($::parametres{nb_jours})) {
    $nb_jours = $::parametres{nb_jours};
    #print $::cgi->p("nb_jours = $nb_jours, mois_num = $::parametres{mois_num}, numVsMois = $numVsMois{$::parametres{mois_num}}");
  }
  else {
    $moisDecode = decode('utf-8', $::parametres{mois});
    $moisEncode = encode('utf-8', $::parametres{mois});
    $moisUnescape = uri_unescape($::parametres{mois});
    #print decode('utf-8',"Février : ");
    #print decode('utf-8', "F\%E9vrier");
    #print $::cgi->p(%mois);
    #print $::cgi->p("paramètres = $::parametres");
    #print $::cgi->p("parametres{mois} = $::parametres{mois}, moisDecode = $moisDecode, mois{parametres{mois} = $mois{$::parametres{mois}}, encode(encode(parametre{mois})) = $moisEncode");
    #print $::cgi->p("moisUnescape = $moisUnescape, mois{'$moisUnescape'} = $mois{$moisUnescape}");
    if(defined $mois{$::parametres{mois}}) {
      $nb_jours = Days_in_Month($::parametres{annee}, $mois{$::parametres{mois}});
    }
    else {
      if(defined $mois{$moisUnescape}) {
        $nb_jours = Days_in_Month($::parametres{annee}, $mois{$moisUnescape});
      }  
      else {
        if(defined $mois{$moisDecode}) {
          $nb_jours = Days_in_Month($::parametres{annee}, $mois{$moisDecode});
        }
        else {
          if($::parametres{mois} =~ m/vrier$/) {
            $nb_jours = Days_in_Month($::parametres{annee}, '2');
          }
          if($::parametres{mois} =~ m/^Ao/) {
            $nb_jours = Days_in_Month($::parametres{annee}, '8');
          }
          if($::parametres{mois} =~ m/cembre$/) {
            $nb_jours = Days_in_Month($::parametres{annee}, '12');
          }
        }
        
      }  
    }
    

  }
  foreach (1..$nb_jours) {
    if(defined $::parametres{mois_num}) {
      $num_jour = Day_of_Week($::parametres{annee}, $::parametres{mois_num}, $_);
      $tps = Mktime($::parametres{annee}, $::parametres{mois_num}, $_, 2, 0, 0);
      est_jour_ferie($_, $::parametres{mois_num}, $::parametres{annee}, \$ferie);
    }
    #else {
    #  if($::parametres{mois} =~ /vrier$/) {
    #    #$num_jour = Day_of_Week($::parametres{annee}, $mois{$::parametres{mois}}, $_);
    #    #$tps = Mktime($::parametres{annee}, $mois{$::parametres{mois}}, $_, 2, 0, 0);
    #    #est_jour_ferie($_, $mois{$::parametres{mois}}, $::parametres{annee}, \$calendrier[$_]->[3]);
    #    $num_jour = Day_of_Week($::parametres{annee}, 2, $_);
    #    $tps = Mktime($::parametres{annee}, 2, $_, 2, 0, 0);
    #    est_jour_ferie($_, 2, $::parametres{annee}, \$calendrier[$_]->[3]);        
    #  }
    #}
     
    $type = (($num_jour != 7) && ($num_jour != 6)) ? 0 : $num_jour;
# Gestion des jours pr�c�dents l'arriv�e dans la soci�t�
    #$tps = Mktime($::parametres{annee}, $mois{$::parametres{mois}}, $_, 2, 0, 0);
    if($tps_in <= $tps) {
      $calendrier[$_] = [$_, $semaine{$num_jour}, $type, $ferie, 1];
    }
    else {
      $calendrier[$_] = [$_, $semaine{$num_jour}, $type, $ferie, 0];
    }
#     if($annee_in >= $::parametres{annee}) {
#       if($mois_in >= $::parametres{mois}) {
#         if($jour_in > $_) {
#           $calendrier[$_] = [$_, $semaine{$num_jour}, $type, 0, 0];
#         }
#         else {
#           $calendrier[$_] = [$_, $semaine{$num_jour}, $type, 0, 1];
#         }
#       }
#       else {
#         $calendrier[$_] = [$_, $semaine{$num_jour}, $type, 0, 1];
#       }
#     }
#     else {
#       $calendrier[$_] = [$_, $semaine{$num_jour}, $type, 0, 1];
#     }
    
    if(($type == 0) && ($calendrier[$_]->[3] eq '0') && ($calendrier[$_]->[4] == 1)) {
      $nb_ouvres++;
    }
  }
}
sub affiche_lig1_tab {
# Affiche la ligne de titre du tableau
  print $::cgi->start_div({-class => 'Lig11_debut'});
  print $::cgi->div({-class => 'Lig11_debut_col2'}, '&nbsp', $::cgi->span('Jour'));
  #print $::cgi->div({-class => 'Lig11_debut_col3'}, '&nbsp', $::cgi->span('Date'));
  print $::cgi->div({-class => 'Lig11_debut_col3'}, $::cgi->span('Date'));
  print $::cgi->div({-class => 'Lig11_debut_col4'}, '&nbsp', $::cgi->span('Matin'));
  print $::cgi->div({-class => 'Lig11_debut_col5'}, '&nbsp', $::cgi->span('Apr&egrave;s-Midi'));
  print $::cgi->start_div({-class => 'Lig11_debut_hs'});
  print $::cgi->div({-class=> 'Lig11_debut_hs_t1'}, 'Heures suppl&eacute;mentaires');
  print $::cgi->start_div({-class =>'Lig11_debut_hs_t2'});
  print $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '0%'), $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '25%'), $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '50%'), $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '100%');
  print $::cgi->end_div(), $::cgi->end_div(); # Fin du div Lig11_debut_hs_t2 et du div Lig11_debut_hs
  print $::cgi->start_div({-class => 'Lig11_debut_ast'});
  print $::cgi->div({-class => 'Lig11_debut_ast_t1'}, 'Astreintes');
  print $::cgi->start_div({-class => 'Lig11_debut_ast_t2'});
  print $::cgi->div({-class =>'Lig11_debut_ast_t21'}, 'Jour'), $::cgi->div({-class =>'Lig11_debut_ast_t22'}, 'Nuit'), $::cgi->div({-class =>'Lig11_debut_ast_t23'}, '24H');
  print $::cgi->end_div(), $::cgi->end_div();# fin du div Lig11_debut_ast_t2 et du div Lig11_debut_ast_t1
  print $::cgi->div({-class => 'Lig11_debut_col11'}, '&nbsp', $::cgi->span('Commentaires'));
  print $::cgi->end_div();# Fin du div Lig11_debut
}

sub affiche_comment_creation {
    print $::cgi->div({-class => 'Lig11col11'}, $::cgi->textfield(-tabindex => '4', -name =>"c$_", -size => 40, -maxlength=>200));
}

sub affiche_astreinte_creation {
  print $::cgi->start_div({-class => 'Lig11col10'});
  print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
  print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'2', -label => ' '), $::cgi->end_div();
  print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'3', -label => ' '), $::cgi->end_div();
  print $::cgi->end_div();
}

sub affiche_hsup_creation {
  print $::cgi->div({-class => 'Lig11col6'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup0_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
  print $::cgi->div({-class => 'Lig11col7'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup25_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
  print $::cgi->div({-class => 'Lig11col8'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup50_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
  print $::cgi->div({-class => 'Lig11col9'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup100_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
}

sub affiche_presence_creation {
# On cherche si la cellule est d�j� r�serv�e. Si elle l'est dans un autre ra,
# il faut l'afficher comme tel en pr�cisant le nom du client pour lequel
# l'intervention a eu lieu
  MATIN: {
    for(my $i = 0; $i < scalar(@::ra_pres); $i++) {
#      if($::ra_pres[$i]->[(2*$_) - 1] != undef) {# D�ja utilis� dans un autre RA
      if(defined $::ra_pres[$i]->[(2*$_) - 1]) {# D�ja utilis� dans un autre RA
        for(my $j = 0; $j < scalar(@::ra); $j++) {# on cherche � d�terminer dans quel RA la r�servation a �t� faite en bouclant sur le tableau des tableaux ra
          if($::ra[$j]->[0] == $::ra_pres[$i]->[0]) {# on teste le N� du RA
            if(($::ra[$j]->[2] > 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {# Si le idclient est positif et que on n'a pas une erreur, on �crit le nom du client et on sort de la boucle MATIN
               print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($::clients{$::ra[$j]->[2]}));
               $nb_resa += 0.5;
               last MATIN;
            }
            elsif(($::ra[$j]->[2] == 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {
#La r�servation a �t� faite sur le RA de T&S, on affiche dans ce cas l'activit� r�alis�e.
              print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[(2*$_) - 1]}));
              $calcul_nb_activites{$::ra_pres[$i]->[(2*$_) - 1]}+=0.5;
              last MATIN;
            }
            else {# Erreur car en cr�ation ce cas est impossible
              print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span({-class => 'erreur'}, '*Erreur'));
              last MATIN;
            }
          }
        }
      }
    }
# La cellule n'est pas encore affect�e. On teste alors le type du client
    $nb_dispo +=0.5;
    if($::parametres{client_id} > 0) {
      print $::cgi->div({-class => 'Lig11col4'}, $::cgi->popup_menu(-tabindex => '1', -name =>"pmatin_$_", -values =>\@activites_valeurs_client, -labels => \%activites_vues_client, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
    }
    elsif($::parametres{client_id} == 0) {
      print $::cgi->div({-class => 'Lig11col4'}, $::cgi->popup_menu(-tabindex => '1', -name =>"pmatin_$_", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
    }
    else {# Cas de figure impossible car pas de creation manuelle de RA global
      print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span('NA'));
    }
  }

# On cherche si la cellule est d�j� r�serv�e. Si elle l'est dans un autre ra,
# il faut l'afficher comme tel en pr�cisant le nom du client pour lequel
# l'intervention a eu lieu
  APREM: {
    for(my $i = 0; $i < scalar(@::ra_pres); $i++) {
#      if($::ra_pres[$i]->[2*$_] != undef) {# D�ja utilis� dans un autre RA
      if(defined $::ra_pres[$i]->[2*$_]) {# D�ja utilis� dans un autre RA
        for(my $j = 0; $j < scalar(@::ra); $j++) {# on cherche � d�terminer dans quel RA la r�servation a �t� faite en bouclant sur le tableau des tableaux ra
          if($::ra[$j]->[0] == $::ra_pres[$i]->[0]) {# on teste le N� du RA
            if(($::ra[$j]->[2] > 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {# Si le idclient est positif et que on n'a pas une erreur, on �crit le nom du client et on sort de la boucle MATIN
               print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($::clients{$::ra[$j]->[2]}));
               $nb_resa += 0.5;
               last APREM;
            }
            elsif(($::ra[$j]->[2] == 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {
#La r�servation a �t� faite sur le RA de T&S, on affiche dans ce cas l'activit� r�alis�e.
              print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[2*$_]}));
              $calcul_nb_activites{$::ra_pres[$i]->[2*$_]}+=0.5;
              last APREM;
            }
            else {# Erreur car en cr�ation ce cas est impossible
              print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span({-class => 'erreur'}, '*Erreur'));
              last APREM;
            }
          }
        }
      }
    }
# La cellule n'est pas encore affect�e. On teste alors le type du client
    $nb_dispo +=0.5;
    if($::parametres{client_id} > 0) {
      print $::cgi->div({-class => 'Lig11col5'}, $::cgi->popup_menu(-tabindex => '1', -name =>"paprem_$_", -values =>\@activites_valeurs_client, -labels => \%activites_vues_client, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
    }
    elsif($::parametres{client_id} == 0) {
      print $::cgi->div({-class => 'Lig11col5'}, $::cgi->popup_menu(-tabindex => '1', -name =>"paprem_$_", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS, -onChange => "return calcul_nb_presence(this);", -onFocus =>"return valeur_courante(this);"));
    }
    else {# Cas de figure impossible car pas de creation manuelle de RA global
      print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span('NA'));
    }
  }
}

sub affiche_presence_affichage {
  MATIN: {
# On cherche si la cellule est d�j� r�serv�e. Si elle l'est dans un autre ra,
# il faut l'afficher comme tel en pr�cisant le nom du client pour lequel
# l'intervention a eu lieu
    for(my $i = 0; $i < scalar(@::ra_pres); $i++) {
      if(defined $::ra_pres[$i]->[(2*$_) - 1]) {# D�ja utilis� dans un autre RA
        for(my $j = 0; $j < scalar(@::ra); $j++) {# on cherche � d�terminer dans quel RA la r�servation a �t� faite en bouclant sur le tableau des tableaux ra
          if($::ra[$j]->[0] == $::ra_pres[$i]->[0]) {# on teste le N� du RA
            if(($::ra[$j]->[2] > 0) && ($::ra[$j]->[2] ne $::parametres{client_id})) {# Si le idclient est positif et que on n'a pas une erreur, on �crit le nom du client et on sort de la boucle MATIN
              if($::parametres{ra_id} <= 0) {
                print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($::clients{$::ra[$j]->[2]}));
#                $calcul_nb_activites{"$::clients{$::ra[$j]->[2]}_$::ra_pres[$i]->[(2*$_) - 1]"}+=0.5;
                incremente_somme_clients($::ra_pres[$i]->[(2*$_) - 1], $j, 0.5);
              }
              else {
                #Changement de background_color
                print $::cgi->div({-class => 'Lig11col4_resa'}, '&nbsp');
                $nb_resa += 0.5;
              }
              last MATIN;
            }
            elsif(($::ra[$j]->[2] == 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {
#La r�servation a �t� faite sur le RA de T&S, on affiche dans ce cas l'activit� r�alis�e.
              if($::parametres{ra_id} <= 0) {
                print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[(2*$_) - 1]}));
                if($::ra_pres[$i]->[(2*$_) - 1] eq '2') {
                  incremente_somme_clients($::ra_pres[$i]->[(2*$_) - 1], $j, 0.5);
                }
              }
              else {
                print $::cgi->div({-class => 'Lig11col4_resa'}, '&nbsp');
              }
              $calcul_nb_activites{$::ra_pres[$i]->[(2*$_) - 1]}+=0.5;

              last MATIN;
            }
            else {
# On pr�s�lectionne la valeur en testant au pr�alable le type du client
              if($::parametres{client_id} > 0) {
                print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($r_activites_vues_client{$::ra_pres[$i]->[(2*$_) - 1]}));
                if($::ra_pres[$i]->[(2*$_) - 1] == 1)  {
                  $nb_pres+=0.5;
                  incremente_somme_clients($::ra_pres[$i]->[(2*$_) - 1], $j, 0.5);
                }
                last MATIN;
              }
              else {
                print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[(2*$_) - 1]}));
                $calcul_nb_activites{$::ra_pres[$i]->[(2*$_) - 1]}+=0.5;
                if($::ra_pres[$i]->[(2*$_) -1] eq '2') {
                  incremente_somme_clients($::ra_pres[$i]->[(2*$_) - 1], $j, 0.5);
                }
                last MATIN;
              }
            }
          }
        }
      }
    }
# La cellule n'est pas encore affect�e. On teste alors le type du client
    if($calendrier[$_]->[4] == 1) {
      print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span('NA'));
      $nb_dispo +=0.5;
    }
    else {
      print $::cgi->div({-class => 'Lig11col4'}, '&nbsp');
    }
  }
#  APREM: {
# On cherche si la cellule est d�j� r�serv�e. Si elle l'est dans un autre ra,
# il faut l'afficher comme tel en pr�cisant le nom du client pour lequel
# l'intervention a eu lieu
    for(my $i = 0; $i < scalar(@::ra_pres); $i++) {
#      if($::ra_pres[$i]->[2*$_] != undef) {# D�ja utilis� dans un autre RA
      if(defined $::ra_pres[$i]->[2*$_]) {# D�ja utilis� dans un autre RA
        for(my $j = 0; $j < scalar(@::ra); $j++) {# on cherche � d�terminer dans quel RA la r�servation a �t� faite en bouclant sur le tableau des tableaux ra
          if($::ra[$j]->[0] == $::ra_pres[$i]->[0]) {# on teste le N� du RA
            if(($::ra[$j]->[2] > 0) && ($::ra[$j]->[2] ne $::parametres{client_id})) {# Si le idclient est positif et que on n'a pas une erreur, on �crit le nom du client et on sort de la boucle MATIN
              if($::parametres{ra_id} <= 0) {
                print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($::clients{$::ra[$j]->[2]}));
#                $calcul_nb_activites{"$::clients{$::ra[$j]->[2]}_$::ra_pres[$i]->[2*$_]"}+=0.5;
                incremente_somme_clients($::ra_pres[$i]->[2*$_], $j, 0.5);
              }
              else {
                #Changement de background_color
                print $::cgi->div({-class => 'Lig11col5_resa'}, '&nbsp');
                $nb_resa += 0.5;
              }
              return;
            }
            elsif(($::ra[$j]->[2] == 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {
#La r�servation a �t� faite sur le RA de T&S, on affiche dans ce cas l'activit� r�alis�e.
              if($::parametres{ra_id} <= 0) {
                print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[2*$_]}));
                if($::ra_pres[$i]->[2*$_] eq '2') {
                  incremente_somme_clients($::ra_pres[$i]->[2*$_], $j, 0.5);
                }
              }
              else {
                print $::cgi->div({-class => 'Lig11col5_resa'}, '&nbsp');
              }
              $calcul_nb_activites{$::ra_pres[$i]->[2*$_]}+=0.5;

              return;
            }
            else {
# On pr�s�lectionne la valeur en testant au pr�alable le type du client
              if($::parametres{client_id} > 0) {
                print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($r_activites_vues_client{$::ra_pres[$i]->[2*$_]}));
                if($::ra_pres[$i]->[2*$_] eq '1')  {
                  $nb_pres+=0.5;
                  incremente_somme_clients($::ra_pres[$i]->[2*$_], $j, 0.5);
                }

                return;
              }
              else {
                print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[2*$_]}));
                $calcul_nb_activites{$::ra_pres[$i]->[2*$_]}+=0.5;
                if($::ra_pres[$i]->[2*$_] eq '2') {
                  incremente_somme_clients($::ra_pres[$i]->[2*$_], $j, 0.5);
                }
                return;
              }
            }
          }
        }
      }
    }
# La cellule n'est pas encore affect�e. On teste alors le type du client
    if($calendrier[$_]->[4] == 1) {
      print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span('NA'));
      $nb_dispo += 0.5;
    }
    else {
      print $::cgi->div({-class => 'Lig11col5'}, '&nbsp');
    }
    return;
#  }
}

sub affiche_hsup_affichage {
  my ($som0, $som25, $som50, $som100);
  $som0 = $som25 = $som50 =$som100 = 0;
  if($::parametres{client_id} == -1) {
    for(my $i = 0; $i < scalar(@::ra_hsup); $i++) {
      if(defined $::ra_hsup[$i]->[(4*$_) - 3]) {
        $som0 += $::ra_hsup[$i]->[(4*$_) - 3];
        incremente_somme_clients(3, $i, $::ra_hsup[$i]->[(4*$_) - 3]);
      }
      if(defined $::ra_hsup[$i]->[(4*$_) - 2]) {
        $som25 += $::ra_hsup[$i]->[(4*$_) - 2];
        incremente_somme_clients(4, $i, $::ra_hsup[$i]->[(4*$_) - 2]);
      }
      if(defined $::ra_hsup[$i]->[(4*$_) - 1]) {
        $som50 += $::ra_hsup[$i]->[(4*$_) - 1];
        incremente_somme_clients(5, $i, $::ra_hsup[$i]->[(4*$_) - 1]);
      }
      if(defined $::ra_hsup[$i]->[4*$_]) {
        $som100 += $::ra_hsup[$i]->[4*$_];
        incremente_somme_clients(6, $i, $::ra_hsup[$i]->[4*$_]);
      }
#      print $::cgi->div({-class => 'Lig11col6'}, '&nbsp', $::cgi->span("$som0")), $::cgi->div({-class => 'Lig11col7'}, '&nbsp', $::cgi->span("$som25")), $::cgi->div({-class => 'Lig11col8'}, '&nbsp', $::cgi->span("$som50")), $::cgi->div({-class => 'Lig11col9'}, '&nbsp', $::cgi->span("$som100"));
    }
  }
  else {
    for(my $j = 0; $j < scalar(@::ra); $j++) {
      if($::ra[$j]->[2] == $::parametres{client_id}) {
        for(my $i = 0; $i < scalar(@::ra_hsup); $i++) {
          if($::ra_hsup[$i]->[0] == $::ra[$j]->[0]) {
            if(defined $::ra_hsup[$i]->[(4*$_) - 3]) {
              $som0 += $::ra_hsup[$i]->[(4*$_) - 3];
            }
            if(defined $::ra_hsup[$i]->[(4*$_) - 2]) {
              $som25 += $::ra_hsup[$i]->[(4*$_) - 2];
            }
            if(defined $::ra_hsup[$i]->[(4*$_) - 1]) {
              $som50 += $::ra_hsup[$i]->[(4*$_) - 1];
            }
            if(defined $::ra_hsup[$i]->[4*$_]) {
              $som100 += $::ra_hsup[$i]->[4*$_];
            }
          }
        }
        last;
      }
    }
  }
  $calcul_nb_activites{hsup0}+=$som0;
  $calcul_nb_activites{hsup25}+=$som25;
  $calcul_nb_activites{hsup50}+=$som50;
  $calcul_nb_activites{hsup100}+=$som100;
  $som0 = ($som0 > 0)? $som0 : ' ';
  $som25 = ($som25 > 0)? $som25 : ' ';
  $som50 = ($som50 > 0)? $som50 : ' ';
  $som100 = ($som100 > 0)? $som100 : ' ';
  print $::cgi->div({-class => 'Lig11col6'}, '&nbsp', $::cgi->span("$som0")), $::cgi->div({-class => 'Lig11col7'}, '&nbsp', $::cgi->span("$som25")), $::cgi->div({-class => 'Lig11col8'}, '&nbsp', $::cgi->span("$som50")), $::cgi->div({-class => 'Lig11col9'}, '&nbsp', $::cgi->span("$som100"));
}

sub affiche_astreinte_affichage {
  my ($ast_j, $ast_n, $ast_24);
  ($ast_j, $ast_n, $ast_24) = (0, 0, 0);
  if($::parametres{client_id} == -1) {
# Dans l'�tat actuel des choses, plusieurs astreintes peuvent apparaitre au m�me moment pour plusieurs clients
    for(my $i = 0; $i < scalar(@::ra_ast); $i++) {
      if(defined $::ra_ast[$i]->[(3*$_) - 2]) {
        $ast_j = 1;
        $nb_ast_j++;
        $calcul_nb_activites{ast1}++;
        incremente_somme_clients(7, $i, 1);
      }
      if(defined $::ra_ast[$i]->[(3*$_) - 1]) {
        $ast_n = 1;
        $nb_ast_n++;
        $calcul_nb_activites{ast2}++;
        incremente_somme_clients(8, $i, 1);
      }
      if(defined $::ra_ast[$i]->[3*$_]) {
        $ast_24 = 1;
        $nb_ast_24++;
        $calcul_nb_activites{ast3}++;
        incremente_somme_clients(9, $i, 1);
      }
    }
    print $::cgi->start_div({-class => 'Lig11col10'});
    if($ast_j == 1) {
#      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-checked =>'checked', -disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -name =>"ast_$_", -value =>'1', -label => ' ', -disabled), $::cgi->end_div();

    }
    else {
#      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-class => 'ast', -name =>"ast_$_", -value =>'1', -label => ' ', -disabled), $::cgi->end_div();
    }
    if($ast_n == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -name =>"ast_$_", -value =>'2', -label => ' ', -disabled), $::cgi->end_div();
#      $calcul_nb_activites{ast2}+=1;
    }
    else {
#      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'2', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-class => 'ast', -name =>"ast_$_", -value =>'2', -label => ' ', -disabled), $::cgi->end_div();
    }
    if($ast_24 == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -name =>"ast_$_", -value =>'3', -label => ' ', -disabled), $::cgi->end_div();
#      $calcul_nb_activites{ast3}+=1;
    }
    else {
#      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'3', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-class => 'ast', -name =>"ast_$_", -value =>'3', -label => ' ', -disabled), $::cgi->end_div();
    }
    print $::cgi->end_div();

  }
  else {
    for(my $j = 0; $j < scalar(@::ra); $j++) {
      if($::ra[$j]->[2] == $::parametres{client_id}) {
        for(my $i = 0; $i < scalar(@::ra_ast); $i++) {
          if($::ra_ast[$i]->[0] == $::ra[$j]->[0]) {
            if(defined $::ra_ast[$i]->[(3*$_) - 2]) {
              $ast_j = 1;
            }
            if(defined $::ra_ast[$i]->[(3*$_) - 1]) {
              $ast_n = 1;
            }
            if(defined $::ra_ast[$i]->[3*$_]) {
              $ast_24 = 1;
            }
          }
        }
        last;
      }
    }
    print $::cgi->start_div({-class => 'Lig11col10'});
    if($ast_j == 1) {
#      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-checked =>'checked', -disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -name =>"ast_$_", -value =>'1', -label => ' ', -disabled), $::cgi->end_div();
      $calcul_nb_activites{ast1}+=1;
    }
    else {
#      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-class => 'ast', -name =>"ast_$_", -value =>'1', -label => ' ', -disabled), $::cgi->end_div();
    }
    if($ast_n == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -name =>"ast_$_", -value =>'2', -label => ' ', -disabled), $::cgi->end_div();
      $calcul_nb_activites{ast2}+=1;
    }
    else {
#      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'2', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-class => 'ast', -name =>"ast_$_", -value =>'2', -label => ' ', -disabled), $::cgi->end_div();
    }
    if($ast_24 == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -name =>"ast_$_", -value =>'3', -label => ' ', -disabled), $::cgi->end_div();
      $calcul_nb_activites{ast3}+=1;
    }
    else {
#      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'3', -label => ' '), $::cgi->end_div();
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-class => 'ast', -name =>"ast_$_", -value =>'3', -label => ' ', -disabled), $::cgi->end_div();
    }
    print $::cgi->end_div();
  }

}

sub affiche_comment_affichage {
  my $msg_comment;
  if($::parametres{client_id} == -1) {
    for(my $i = 0; $i < scalar(@::ra_comment); $i++) {
      if(defined $::ra_comment[$i]->[$_]) {
        if(defined $msg_comment) {
          $msg_comment .= '|' . $::ra_comment[$i]->[$_];
        }
        else {
          $msg_comment = $::ra_comment[$i]->[$_];
        }
      }
    }
  }
  else {
    for(my $j = 0; $j < scalar(@::ra); $j++) {
      if($::ra[$j]->[2] == $::parametres{client_id}) {
        for(my $i = 0; $i < scalar(@::ra_comment); $i++) {
          if($::ra_comment[$i]->[0] == $::ra[$j]->[0]) {
            if(defined $::ra_comment[$i]->[$_]) {
              $msg_comment = $::ra_comment[$i]->[$_];
            }
            last;
          }
        }
      }
    }
  }
  if (defined $msg_comment) {
#    print $::cgi->div({-class => 'Lig11col11'}, "$msg_comment");
    print $::cgi->div({-class => 'Lig11col11'}, $::cgi->textfield(-tabindex => '4', -name =>"c$_", -default => "$msg_comment", -size => 40, -maxlength=>200, -disabled));
  }
  else {
#    print $::cgi->div({-class => 'Lig11col11'}, '&nbsp');
    print $::cgi->div({-class => 'Lig11col11'}, $::cgi->textfield(-tabindex => '4', -name =>"c$_", -size => 40, -maxlength=>200, -disabled));
  }

}

sub affiche_comment_edition {
  my $msg_comment;
  if($::parametres{client_id} == -1) {
    for(my $i = 0; $i < scalar(@::ra_comment); $i++) {
      if(defined $::ra_comment[$i]->[$_]) {
        if(defined $msg_comment) {
          $msg_comment .= $::ra_comment[$i]->[$_];
        }
        else {
          $msg_comment = $::ra_comment[$i]->[$_];
        }
      }
    }
  }
  else {
    for(my $j = 0; $j < scalar(@::ra); $j++) {
      if($::ra[$j]->[2] == $::parametres{client_id}) {
        for(my $i = 0; $i < scalar(@::ra_comment); $i++) {
          if($::ra_comment[$i]->[0] == $::ra[$j]->[0]) {
            if(defined $::ra_comment[$i]->[$_]) {
              $msg_comment = $::ra_comment[$i]->[$_];
            }
            last;
          }
        }
      }
    }
  }
  if (defined $msg_comment) {
    print $::cgi->div({-class => 'Lig11col11'}, $::cgi->textfield(-tabindex => '4', -name =>"c$_", -default => "$msg_comment", -size => 40, -maxlength=>200));
  }
  else {
    print $::cgi->div({-class => 'Lig11col11'}, $::cgi->textfield(-tabindex => '4', -name =>"c$_", -size => 40, -maxlength=>200));
  }
}


sub affiche_astreinte_edition {
  my ($ast_j, $ast_n, $ast_24);
  ($ast_j, $ast_n, $ast_24) = (0, 0, 0);
  if($::parametres{client_id} == -1) {
    for(my $i = 0; $i < scalar(@::ra_ast); $i++) {
      if(defined $::ra_ast[$i]->[(3*$_) - 2]) {
        $ast_j = 1;
#        print "$ast_j";
      }
      if(defined $::ra_ast[$i]->[(3*$_) - 1]) {
        $ast_n = 1;
#        print "$ast_n";
      }
      if(defined $::ra_ast[$i]->[3*$_]) {
        $ast_24 = 1;
#        print "$ast_24";
      }
    }
    print $::cgi->start_div({-class => 'Lig11col10'});
    if($ast_j == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-checked =>'checked', -disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
      $calcul_nb_activites{ast1}+=1;
    }
    else {
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
    }
    if($ast_n == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-checked =>'checked', -disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'2', -label => ' '), $::cgi->end_div();
      $calcul_nb_activites{ast2}+=1;
    }
    else {
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'2', -label => ' '), $::cgi->end_div();
    }
    if($ast_24 == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-checked =>'checked', -disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'3', -label => ' '), $::cgi->end_div();
      $calcul_nb_activites{ast3}+=1;
    }
    else {
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-disabled, -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'3', -label => ' '), $::cgi->end_div();
    }
    print $::cgi->end_div();

  }
  else {
    for(my $j = 0; $j < scalar(@::ra); $j++) {
      if($::ra[$j]->[2] == $::parametres{client_id}) {
        for(my $i = 0; $i < scalar(@::ra_ast); $i++) {
          if($::ra_ast[$i]->[0] == $::ra[$j]->[0]) {
            if(defined $::ra_ast[$i]->[(3*$_) - 2]) {
              $ast_j = 1;
            }
            if(defined $::ra_ast[$i]->[(3*$_) - 1]) {
              $ast_n = 1;
            }
            if(defined $::ra_ast[$i]->[3*$_]) {
              $ast_24 = 1;
            }
          }
        }
        last;
      }
    }
    print $::cgi->start_div({-class => 'Lig11col10'});
    if($ast_j == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
      $calcul_nb_activites{ast1}+=1;
    }
    else {
      print $::cgi->start_div({-class => 'Lig11col10_1'}), $::cgi->checkbox(-class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'1', -label => ' '), $::cgi->end_div();
    }
    if($ast_n == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'2', -label => ' '), $::cgi->end_div();
      $calcul_nb_activites{ast2}+=1;
    }
    else {
      print $::cgi->start_div({-class => 'Lig11col10_2'}), $::cgi->checkbox(-class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'2', -label => ' '), $::cgi->end_div();
    }
    if($ast_24 == 1) {
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-checked =>'checked', -class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'3', -label => ' '), $::cgi->end_div();
      $calcul_nb_activites{ast3}+=1;
    }
    else {
      print $::cgi->start_div({-class => 'Lig11col10_3'}), $::cgi->checkbox(-class => 'ast', -tabindex => '3', -onclick => "return bascule_astreinte(this);", -name =>"ast_$_", -value =>'3', -label => ' '), $::cgi->end_div();
    }
    print $::cgi->end_div();
  }
}

sub affiche_hsup_edition {
  my ($som0, $som25, $som50, $som100);
  $som0 = $som25 = $som50 =$som100 = 0;
  for(my $j = 0; $j < scalar(@::ra); $j++) {# On cherche le ra affect� au client
    if($::ra[$j]->[2] == $::parametres{client_id}) {
      for(my $i = 0; $i < scalar(@::ra_hsup); $i++) {
        if($::ra_hsup[$i]->[0] == $::ra[$j]->[0]) {# On valide avec l'Id du ra
          if(defined $::ra_hsup[$i]->[(4*$_) - 3]) {# on traite hsup 0%
            $som0 += $::ra_hsup[$i]->[(4*$_) - 3];
            $calcul_nb_activites{hsup0}+=$som0;
            my @heures_maj;
            if(maj_tab_heures($::ra_hsup[$i]->[(4*$_) - 3], \@heures_maj) == 0) {
              print $::cgi->div({-class => 'Lig11col6'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup0_$_", -values =>\@heures, -default => "$::ra_hsup[$i]->[(4*$_) - 3]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
            else {
              print $::cgi->div({-class => 'Lig11col6'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup0_$_", -values =>\@heures_maj, -default => "$::ra_hsup[$i]->[(4*$_) - 3]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
          }
          else {
            print $::cgi->div({-class => 'Lig11col6'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup0_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
          }
          if(defined $::ra_hsup[$i]->[(4*$_) - 2]) { #On traite hsup 25%
            $som25 += $::ra_hsup[$i]->[(4*$_) - 2];
            $calcul_nb_activites{hsup25}+=$som25;
            my @heures_maj;
            if(maj_tab_heures($::ra_hsup[$i]->[(4*$_) - 2], \@heures_maj) == 0) {
              print $::cgi->div({-class => 'Lig11col7'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup25_$_", -values =>\@heures, -default => "$::ra_hsup[$i]->[(4*$_) - 2]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
            else {
              print $::cgi->div({-class => 'Lig11col7'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup25_$_", -values =>\@heures_maj, -default => "$::ra_hsup[$i]->[(4*$_) - 2]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
          }
          else {
            print $::cgi->div({-class => 'Lig11col7'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup25_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
          }
          if(defined $::ra_hsup[$i]->[(4*$_) - 1]) {#On traite hsup 50%
            $som50 += $::ra_hsup[$i]->[(4*$_) - 1];
            $calcul_nb_activites{hsup50}+=$som50;
            my @heures_maj;
            if(maj_tab_heures($::ra_hsup[$i]->[(4*$_) - 1], \@heures_maj) == 0) {
              print $::cgi->div({-class => 'Lig11col8'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup50_$_", -values =>\@heures, -default => "$::ra_hsup[$i]->[(4*$_) - 1]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
            else {
              print $::cgi->div({-class => 'Lig11col8'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup50_$_", -values =>\@heures_maj, -default => "$::ra_hsup[$i]->[(4*$_) - 1]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
          }
          else {
            print $::cgi->div({-class => 'Lig11col8'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup50_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
          }
          if(defined $::ra_hsup[$i]->[4*$_]) {#On traite hsup100%
            $som100 += $::ra_hsup[$i]->[4*$_];
            $calcul_nb_activites{hsup100}+=$som100;
            my @heures_maj;
            if(maj_tab_heures($::ra_hsup[$i]->[4*$_], \@heures_maj) == 0) {
              print $::cgi->div({-class => 'Lig11col9'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup100_$_", -values =>\@heures, -default => "$::ra_hsup[$i]->[4*$_]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
            else {
              print $::cgi->div({-class => 'Lig11col9'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup100_$_", -values =>\@heures_maj, -default => "$::ra_hsup[$i]->[4*$_]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
            }
          }
          else {
            print $::cgi->div({-class => 'Lig11col9'}, $::cgi->popup_menu(-tabindex => '2', -name =>"hsup100_$_", -values =>\@heures, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
          }
          last;
        }
      }
      last;
    }
  }
}

sub affiche_presence_edition {
  MATIN: {
# On cherche si la cellule est d�j� r�serv�e. Si elle l'est dans un autre ra,
# il faut l'afficher comme tel en pr�cisant le nom du client pour lequel
# l'intervention a eu lieu
    for(my $i = 0; $i < scalar(@::ra_pres); $i++) {
      if(defined $::ra_pres[$i]->[(2*$_) - 1]) {# D�ja utilis� dans un autre RA
        for(my $j = 0; $j < scalar(@::ra); $j++) {# on cherche � d�terminer dans quel RA la r�servation a �t� faite en bouclant sur le tableau des tableaux ra
          if($::ra[$j]->[0] == $::ra_pres[$i]->[0]) {# on teste le N� du RA
            if(($::ra[$j]->[2] > 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {# Si le idclient est positif et que on n'a pas une erreur, on �crit le nom du client et on sort de la boucle MATIN
               print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($::clients{$::ra[$j]->[2]}));
               $nb_resa += 0.5;
               last MATIN;
            }
            elsif(($::ra[$j]->[2] == 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {
#La r�servation a �t� faite sur le RA de T&S, on affiche dans ce cas l'activit� r�alis�e.
              print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[(2*$_) - 1]}));
              $calcul_nb_activites{$::ra_pres[$i]->[(2*$_) - 1]}+=0.5;
              last MATIN;
            }
            else {
# On pr�s�lectionne la valeur en testant au pr�alable le type du client
              if($::parametres{client_id} > 0) {
                print $::cgi->div({-class => 'Lig11col4'}, $::cgi->popup_menu(-tabindex => '1', -name =>"pmatin_$_", -values =>\@activites_valeurs_client, -labels => \%activites_vues_client, -default => "$::ra_pres[$i]->[(2*$_) - 1]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
                if($::ra_pres[$i]->[(2*$_) - 1] == 1)  {
                  $nb_pres+=0.5;
                }
                last MATIN;
              }
              else {
                print $::cgi->div({-class => 'Lig11col4'}, $::cgi->popup_menu(-tabindex => '1', -name =>"pmatin_$_", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS, -default => "$::ra_pres[$i]->[(2*$_) - 1]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
                $calcul_nb_activites{$::ra_pres[$i]->[(2*$_) - 1]}+=0.5;
                last MATIN;
              }
            }
          }
        }
      }
    }
# La cellule n'est pas encore affect�e. On teste alors le type du client
    $nb_dispo +=0.5;
    if($::parametres{client_id} > 0) {
      print $::cgi->div({-class => 'Lig11col4'}, $::cgi->popup_menu(-tabindex => '1', -name =>"pmatin_$_", -values =>\@activites_valeurs_client, -labels => \%activites_vues_client, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
      last MATIN;
    }
    elsif($::parametres{client_id} == 0) {
      print $::cgi->div({-class => 'Lig11col4'}, $::cgi->popup_menu(-tabindex => '1', -name =>"pmatin_$_", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
      last MATIN;
    }
    else {# Cas de figure impossible car pas de creation manuelle de RA global
      print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span('NA'));
      last MATIN;
    }

  }
#  APREM: {
# On cherche si la cellule est d�j� r�serv�e. Si elle l'est dans un autre ra,
# il faut l'afficher comme tel en pr�cisant le nom du client pour lequel
# l'intervention a eu lieu
    for(my $i = 0; $i < scalar(@::ra_pres); $i++) {
      if(defined $::ra_pres[$i]->[2*$_]) {# D�ja utilis� dans un autre RA
        for(my $j = 0; $j < scalar(@::ra); $j++) {# on cherche � d�terminer dans quel RA la r�servation a �t� faite en bouclant sur le tableau des tableaux ra
          if($::ra[$j]->[0] == $::ra_pres[$i]->[0]) {# on teste le N� du RA
            if(($::ra[$j]->[2] > 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {# Si le idclient est positif et que on n'a pas une erreur, on �crit le nom du client et on sort de la boucle MATIN
               print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($::clients{$::ra[$j]->[2]}));
               $nb_resa +=0.5;
               return;
            }
            elsif(($::ra[$j]->[2] == 0) && ($::ra[$j]->[2] != $::parametres{client_id})) {
#La r�servation a �t� faite sur le RA de T&S, on affiche dans ce cas l'activit� r�alis�e.
              print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span($r_activites_vues_TS{$::ra_pres[$i]->[2*$_]}));
              $calcul_nb_activites{$::ra_pres[$i]->[2*$_]}+=0.5;
              return;
            }
            else {
# On pr�s�lectionne la valeur en testant au pr�alable le type du client
              if($::parametres{client_id} > 0) {
                print $::cgi->div({-class => 'Lig11col5'}, $::cgi->popup_menu(-tabindex => '1', -name =>"paprem_$_", -values =>\@activites_valeurs_client, -labels => \%activites_vues_client, -default => "$::ra_pres[$i]->[2*$_]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
                if($::ra_pres[$i]->[2*$_] == 1)  {
                  $nb_pres+=0.5;
                }

                return;
              }
              else {
                print $::cgi->div({-class => 'Lig11col5'}, $::cgi->popup_menu(-tabindex => '1', -name =>"paprem_$_", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS, -default => "$::ra_pres[$i]->[2*$_]", -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
                $calcul_nb_activites{$::ra_pres[$i]->[2*$_]}+=0.5;
                return;
              }
            }
          }
        }
      }
    }
# La cellule n'est pas encore affect�e. On teste alors le type du client
    $nb_dispo +=0.5;
    if($::parametres{client_id} > 0) {
      print $::cgi->div({-class => 'Lig11col5'}, $::cgi->popup_menu(-tabindex => '1', -name =>"paprem_$_", -values =>\@activites_valeurs_client, -labels => \%activites_vues_client, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
      return;
    }
    elsif($::parametres{client_id} == 0) {
      print $::cgi->div({-class => 'Lig11col5'}, $::cgi->popup_menu(-tabindex => '1', -name =>"paprem_$_", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS, -onChange => "return calcul_nb_presence(this);", -onfocus =>"return valeur_courante(this);"));
      return;
    }
    else {# Cas de figure impossible car pas de creation manuelle de RA global
      print $::cgi->div({-class => 'Lig11col5'}, '&nbsp', $::cgi->span('NA'));
      return;
    }

#  }
}

sub maj_tab_heures {
  my ($i, $heures_maj) = @_;
  foreach (@heures) {
    if($i eq $_) {
      return 0;
    }
    else {
      push @$heures_maj, $_;
    }
  }
  $heures_maj->[$#{@$heures_maj}] = $i;
  push @$heures_maj, '+';
  return 1;
}

sub incremente_somme_clients {
  my ($i, $j, $k) = @_;
  if($i eq '2') {
    $::clients[$#::clients]->[2] += $k;
    if($::parametres{client_id} == -1) {
      $nb_pres += $k;
    }
  }
  elsif($i eq '0'){
  }
  else {
    foreach (@::clients) {
      if($_->[0] == $::ra[$j]->[2]) {
        if($i eq '1') {
          $_->[2]+= $k;
          if($::parametres{client_id} == -1) {
            $nb_pres += $k;
          }
        }
        else {
          $_->[$i]+= $k;
        }
        last;
      }
    }
  }
  return;

}

sub affiche_jour_ouvre {
  print $::cgi->start_div({-class => 'ouvre'}), $::cgi->start_div({-class => 'Lig11col'});
  #print $::cgi->div({-class => 'Lig11col2'}, '&nbsp', $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col2'}, $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col3'}, '&nbsp', $::cgi->span("$_"));
#  if($::parametres{client_id} >0 ) {
  if($calendrier[$_]->[4] == 1) {
    if($::parametres{action} eq 'creation') {
      affiche_presence_creation();
      affiche_hsup_creation();
      affiche_astreinte_creation();
      affiche_comment_creation();
    }
    elsif($::parametres{action} eq 'affichage') {
      affiche_presence_affichage();
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
    elsif($::parametres{action} eq 'edition') {
      affiche_presence_edition();
      affiche_hsup_edition();
      affiche_astreinte_edition();
      affiche_comment_edition();
    }
    else {
      affiche_presence_affichage();
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
  }
  else {
      affiche_presence_affichage();
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
  }
  print $::cgi->end_div(), $::cgi->end_div(); # Fin du div Lig11col et du div ouvre
}

sub affiche_jour_ferie {
  print $::cgi->start_div({-class => 'ferie'}), $::cgi->start_div({-class => 'Lig11col'});
  #print $::cgi->div({-class => 'Lig11col2'}, '&nbsp', $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col2'}, $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col3'}, '&nbsp', $::cgi->span("$_"));
  print $::cgi->div({-class => 'Lig11col4'}, '&nbsp', $::cgi->span("$calendrier[$_]->[3]"));
#  print $::cgi->div({-class => 'Lig11col5'}, "&nbsp");
  if($calendrier[$_]->[4] == 1) {
    if($::parametres{action} eq 'creation') {
      affiche_hsup_creation();
      affiche_astreinte_creation();
      affiche_comment_creation();
    }
    elsif($::parametres{action} eq 'affichage') {
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
    elsif($::parametres{action} eq 'edition') {
      affiche_hsup_edition();
      affiche_astreinte_edition();
      affiche_comment_edition();
    }
    else {
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
  }
  else {
    affiche_hsup_affichage();
    affiche_astreinte_affichage();
    affiche_comment_affichage();
  }
  print $::cgi->end_div(), $::cgi->end_div(); # Fin du div Lig11col et du div samedi

}

sub affiche_samedi {
  print $::cgi->start_div({-class => 'samedi'}), $::cgi->start_div({-class => 'Lig11col'});
  #print $::cgi->div({-class => 'Lig11col2'}, '&nbsp', $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col2'}, $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col3'}, '&nbsp', $::cgi->span("$_"));
  print $::cgi->div({-class => 'Lig11col4'}, "&nbsp");
  print $::cgi->div({-class => 'Lig11col5'}, "&nbsp");
  if($calendrier[$_]->[4] == 1) {
    if($::parametres{action} eq 'creation') {
      affiche_hsup_creation();
      affiche_astreinte_creation();
      affiche_comment_creation();
    }
    elsif($::parametres{action} eq 'affichage') {
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
    elsif($::parametres{action} eq 'edition') {
      affiche_hsup_edition();
      affiche_astreinte_edition();
      affiche_comment_edition();
    }
    else {
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
  }
  else {
    affiche_hsup_affichage();
    affiche_astreinte_affichage();
    affiche_comment_affichage();
  }
  print $::cgi->end_div(), $::cgi->end_div(); # Fin du div Lig11col et du div samedi
}

sub affiche_dimanche {
  print $::cgi->start_div({-class => 'dimanche'}), $::cgi->start_div({-class => 'Lig11col'});
  #print $::cgi->div({-class => 'Lig11col2'}, '&nbsp', $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col2'}, $::cgi->span("$calendrier[$_]->[1]"));
  print $::cgi->div({-class => 'Lig11col3'}, '&nbsp', $::cgi->span("$_"));
  print $::cgi->div({-class => 'Lig11col4'}, "&nbsp");
  print $::cgi->div({-class => 'Lig11col5'}, "&nbsp");
  if($calendrier[$_]->[4] == 1) {
    if($::parametres{action} eq 'creation') {
      affiche_hsup_creation();
      affiche_astreinte_creation();
      affiche_comment_creation();
    }
    elsif($::parametres{action} eq 'affichage') {
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
    elsif($::parametres{action} eq 'edition') {
      affiche_hsup_edition();
      affiche_astreinte_edition();
      affiche_comment_edition();
    }
    else {
      affiche_hsup_affichage();
      affiche_astreinte_affichage();
      affiche_comment_affichage();
    }
  }
  else {
    affiche_hsup_affichage();
    affiche_astreinte_affichage();
    affiche_comment_affichage();
  }
  print $::cgi->end_div(), $::cgi->end_div(); # Fin du div Lig11col et du div dimanche

}


# Calendrier = Tableau de tableaux [N�du jour, jour, 0=ouvr�|6=samedi|7=dimanche, 0=non f�rie | Nom de la f�te, Hsup 0%, Hsup 25%, Hsup 50%, Hsup 100%, j_astreinte; n_astreinte, 24_astreinte, commentaire]
sub affiche_mois {
# Initialisation des compteurs
 ($nb_pres, $nb_dispo, $nb_dimanche, $nb_ferie) = (0, 0, 0, 0);
 ($nb_resa, $nb_hsup0, $nb_hsup25, $nb_hsup50, $nb_hsup100) = (0, 0, 0, 0, 0);
 ($nb_ast_j, $nb_ast_n, $nb_ast_24) = (0, 0, 0);

  init_popup_activites();
  print $::cgi->start_div({-id => 'tableau'});
  affiche_lig1_tab();
# Affichage des donn�es du mois, on boucle sur les jours du tableau calendrier
  foreach (1..$nb_jours) {
    if($calendrier[$_]->[3] ne '0') {
      affiche_jour_ferie();
    }
    else { # Ce n'est pas un jour f�ri�
      if($calendrier[$_]->[2] == 0) {
        affiche_jour_ouvre();
      }
      elsif($calendrier[$_]->[2] == 6) {
        affiche_samedi();
      }
      else { # C'est un dimanche
        affiche_dimanche();
      }
    }
  }
  print $::cgi->end_div(); # Fin du div tableau
  affiche_decompte_jours();
  if(($::parametres{action} eq 'affichage') || ($::parametres{action} eq 'impression')) {
    if($::parametres{ra_id}>= 0) {
      affiche_signature();
    }
  }
  else {
    affiche_barre_outils();
  }
  affiche_menu_s_actions();
#  print "Infos sur le hachage calcul_nb_activites", $::cgi->br();
#  foreach (keys %calcul_nb_activites) {
#    print "$_ : $calcul_nb_activites{$_}", $::cgi->br();
#  }
}

sub init_popup_activites {
  push @activites_valeurs_client, ' ';
  push @activites_valeurs_TS, ' ';
  push @r_activites_valeurs_client, -1;
  push @r_activites_valeurs_TS, -1;

  foreach (@activites) {
    if ($_->[2] == 0) {
      push @activites_valeurs_client, $_->[1];
      $activites_vues_client{$_->[1]} = decode('utf-8', "$_->[1].$_->[0]");
      push @r_activites_valeurs_client, $_->[1];
      $r_activites_vues_client{$_->[1]} = decode('utf-8', "$_->[0]");

    }
    else {
      push @activites_valeurs_TS, $_->[1];
      $activites_vues_TS{$_->[1]} = decode('utf-8', "$_->[1].$_->[0]");
      push @r_activites_valeurs_TS, $_->[1];
      $r_activites_vues_TS{$_->[1]} = decode('utf-8', "$_->[0]");
#      $r_activites_vues_TS{$_->[1]} = "$_->[1].$_->[0]";
    }
  $calcul_nb_activites{$_->[1]} = 0;
  }
  $calcul_nb_activites{hsup0} = 0;
  $calcul_nb_activites{hsup25} = 0;
  $calcul_nb_activites{hsup50} = 0;
  $calcul_nb_activites{hsup100} = 0;
  $calcul_nb_activites{ast1} = 0;
  $calcul_nb_activites{ast2} = 0;
  $calcul_nb_activites{ast3} = 0;
#  $calcul_nb_activites{hsup0} = 0;
  keys %selection_presence_client;
  while(my ($k, $v) = each %selection_presence_client) {
    $selection_presence_client{$k} = decode('utf-8', $v);
  }
}

sub gestion_champs_caches {
  if(exists($::parametres{list_arg})) {
    $list_arg = $::parametres{list_arg};
  }
  else {
    foreach (keys %::parametres) {
      #print $::cgi->p("$_");
      if("$_" eq "mois") {
        my $decodeMois = decode('utf-8', "$::parametres{mois}");
        $list_arg .= "$_=$decodeMois/";
        #print $::cgi->p("$list_arg");
      }
      else {
        $list_arg .= "$_=$::parametres{$_}/";
        #print $::cgi->p("$list_arg");
      }
      
    }
    $list_arg =~s/\/$//;
  }
#  print "list_arg : $list_arg", $::cgi->br;
  print $::cgi->hidden(-name => 'list_arg', -value =>"$list_arg");
}


sub affiche_entete {
  $nom_client = recherche_nom_client();
  $ucFirstName = ucfirst $::collaborateur[1];
  if($::parametres{action} eq 'affichage') {
    print $::cgi->start_div({-id => 'entete_affichage'});
    print $::cgi->div({-id => 'ent_lig1'}, $::cgi->span("$action{$::parametres{action}} du Rapport d'activit&eacute;s"));
    print $::cgi->div({-id => 'ent_lig1_print'}, $::cgi->span("RAPPORT D'ACTVITES"));
    #print $::cgi->div('')
    print $::cgi->start_div({-id => 'ent_lig2col1'});
    print $::cgi->div({-class => 'cel1'}, $::cgi->label('Nom :'), $::cgi->span("$ucFirstName"));
    print $::cgi->div({-class => 'cel2'}, $::cgi->label('Pr&eacute;nom :'), $::cgi->span("$::collaborateur[2]"));
    print $::cgi->end_div; #fin du div ent_lig2col1
    print $::cgi->start_div({-id => 'ent_lig2col2'});
    print $::cgi->div({-class => 'cel1'}, $::cgi->label('Mois :'), $::cgi->span(decode('utf-8',"$numVsMois{$::parametres{mois_num}} $::parametres{annee}")));
    #print $::cgi->div('parametres{mois} = '+$::parametres{mois});
    #print $::cgi->div({-class => 'cel1'}, $::cgi->label('Mois :'), $::cgi->span("$::parametres{mois} $::parametres{annee}"));
    if($::parametres{client_id} >=0) {
      print $::cgi->div({-class => 'cel2'}, $::cgi->label('Soci&eacute;t&eacute; :'), $::cgi->span("$nom_client"));
    }
    else {
      print $::cgi->div({-id => 'cel2_glob'}, $::cgi->span("$nom_client"));
    }
    print $::cgi->end_div; #fin du div ent_lig2col2
    print $::cgi->start_div({-id=>'ent_fin'}), $::cgi->hr();
    print $::cgi->start_div({-id=>'ent_msg'}), $::cgi->span('A remplir '), $::cgi->span({-class=>'gras'}, 'le dernier jour du mois '), $::cgi->span('et &agrave; envoyer '), $::cgi->span({-class=>'gras'}, 'par mail &agrave; l\'adresse jude.jean@etechnoserv.com');
    print $::cgi->end_div(), $::cgi->end_div(); # fin des div ent_msg et ent_fin
    print $::cgi->end_div; #fin du div entete
  }
  else {
    print $::cgi->start_div({-id => 'entete'});
    print $::cgi->div({-id => 'ent_lig1'}, $::cgi->span("$action{$::parametres{action}} du Rapport d'activit&eacute;s"));
#    print $::cgi->div({-id => 'ent_lig1_print'}, $::cgi->span("RAPPORT D'ACTVITES"));
    print $::cgi->start_div({-id => 'ent_lig2col1'});
    print $::cgi->div({-class => 'cel1'}, $::cgi->label('Nom :'), $::cgi->span("$ucFirstName"));
    print $::cgi->div({-class => 'cel2'}, $::cgi->label('Pr&eacute;nom :'), $::cgi->span("$::collaborateur[2]"));
    print $::cgi->end_div; #fin du div ent_lig2col1
    print $::cgi->start_div({-id => 'ent_lig2col2'});
    print $::cgi->div({-class => 'cel1'}, $::cgi->label('Mois :'), $::cgi->span(decode('utf-8',"$::parametres{mois} $::parametres{annee}")));
    #print $::cgi->div({-class => 'cel1'}, $::cgi->label('Mois :'), $::cgi->span("$::parametres{mois} $::parametres{annee}"));
    if($::parametres{client_id} >=0) {
      print $::cgi->div({-class => 'cel2'}, $::cgi->label('Soci&eacute;t&eacute; :'), $::cgi->span("$nom_client"));
    }
    else {
      print $::cgi->div({-id => 'cel2_glob'}, $::cgi->span("$nom_client"));
    }
    print $::cgi->end_div; #fin du div ent_lig2col2
#    print $::cgi->start_div({-id=>'ent_fin'}), $::cgi->hr();
#    print $::cgi->start_div({-id=>'ent_msg'}), $::cgi->span('A remplir '), $::cgi->span({-class=>'gras'}, 'le dernier jour du mois '), $::cgi->span('et � envoyer par '), $::cgi->span({-class=>'gras'}, 'fax au 01 46 26 36 02');
#    print $::cgi->end_div(), $::cgi->end_div(); # fin des div ent_msg et ent_fin
    print $::cgi->end_div; #fin du div entete
  }
}



sub affiche_decompte_jours {
    print $::cgi->start_fieldset({-id => 'decompte_jours_client'}), $::cgi->legend("D&eacute;compte des jours, de la pr&eacute;sence et des activit&eacute;s");
    print $::cgi->start_div({-id => 'titre_decompte'});
    if($::parametres{client_id} == -1) {
#      $nb_pres +=$calcul_nb_activites{2};
      print $::cgi->div({-id =>'titre_ra_global'}, '&nbsp');
    }
    print $::cgi->div({-id =>'titre_ouvres'}, '&nbsp', $::cgi->span('Ouvr&eacute;s')), $::cgi->div({-id=>'titre_presence'}, '&nbsp', $::cgi->span('Pr&eacute;sence')), $::cgi->div({-id => 'titre_dispo'}, '&nbsp', $::cgi->span('Disponible'));
    print $::cgi->start_div({-class => 'Lig11_debut_hs'});
    print $::cgi->div({-class=> 'Lig11_debut_hs_t1'}, 'Heures suppl&eacute;mentaires');
    print $::cgi->start_div({-class =>'Lig11_debut_hs_t2'});
    print $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '0%'), $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '25%'), $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '50%'), $::cgi->div({-class => 'Lig11_debut_hs_t21'}, '100%');
    print $::cgi->end_div(), $::cgi->end_div(); # Fin du div Lig11_debut_hs_t2 et du div Lig11_debut_hs
    print $::cgi->start_div({-class => 'Lig11_debut_ast'});
    print $::cgi->div({-class => 'Lig11_debut_ast_t1'}, 'Astreintes');
    print $::cgi->start_div({-class => 'Lig11_debut_ast_t2'});
    print $::cgi->div({-class =>'Lig11_debut_ast_t21'}, 'Jour'), $::cgi->div({-class =>'Lig11_debut_ast_t22'}, 'Nuit'), $::cgi->div({-class =>'Lig11_debut_ast_t23'}, '24H');
    print $::cgi->end_div(), $::cgi->end_div();# fin du div Lig11_debut_ast_t2 et du div Lig11_debut_ast_t1
    print $::cgi->end_div(); #Fin du div titre_decompte
    print $::cgi->start_div({-id =>'data_decompte'});
    if($::parametres{action} eq 'affichage') {
      if($::parametres{client_id} == -1) {
          print $::cgi->div({-id =>'data_ra_global'}, $::cgi->span('Total'));
      }
      print $::cgi->div({-id => 'data_ouvres'}, $::cgi->span({-name =>"nb_ouvres"}, "$nb_ouvres"));
      if($::parametres{client_id} == 0) {
        print $::cgi->div({-id => 'data_presence'}, $::cgi->span({-name =>"nb_presence"}, "$calcul_nb_activites{2}"));
      }
      else {
        print $::cgi->div({-id => 'data_presence'}, $::cgi->span({-name =>"nb_presence"}, "$nb_pres"));
      }
      print $::cgi->div({-id => 'data_dispo'}, $::cgi->span({-name =>'nb_dispo'},"$nb_dispo"));
      print $::cgi->div({-id => 'data_hsup0'}, $::cgi->span({-name =>'nb_hsup0'}, "$calcul_nb_activites{hsup0}"));
      print $::cgi->div({-id => 'data_hsup25'}, $::cgi->span({-name =>'nb_hsup25'}, "$calcul_nb_activites{hsup25}"));
      print $::cgi->div({-id => 'data_hsup50'}, $::cgi->span({-name =>'nb_hsup50'},"$calcul_nb_activites{hsup50}"));
      print $::cgi->div({-id => 'data_hsup100'}, $::cgi->span({-name =>'nb_hsup100'},"$calcul_nb_activites{hsup100}"));
      print $::cgi->div({-id => 'data_ast1'}, $::cgi->span({-name =>'nb_ast1'},"$calcul_nb_activites{ast1}"));
      print $::cgi->div({-id => 'data_ast2'}, $::cgi->span({-name =>'nb_ast2'}, "$calcul_nb_activites{ast2}"));
      print $::cgi->div({-id => 'data_ast3'}, $::cgi->span({-name =>'nb_ast3'},"$calcul_nb_activites{ast3}"));
      if($::parametres{client_id} == -1) {
        print $::cgi->start_div({-class => 'data_client'});
        print $::cgi->div({-class => 'data_client_nom'}, $::cgi->span($::clients[$#::clients]->[1]));
        print $::cgi->div({-class => 'data_client_ouvres'}, '&nbsp');
#        print $::cgi->div({-class => 'data_client_presence'}, $calcul_nb_activites{2});
        print $::cgi->div({-class => 'data_client_presence'}, $::clients[$#::clients]->[2]);
        print $::cgi->div({-class => 'data_client_dispo'}, '&nbsp');
        print $::cgi->div({-class => 'data_client_hsup0'}, $::clients[$#::clients]->[3]);
        print $::cgi->div({-class => 'data_client_hsup25'}, $::clients[$#::clients]->[4]);
        print $::cgi->div({-class => 'data_client_hsup50'}, $::clients[$#::clients]->[5]);
        print $::cgi->div({-class => 'data_client_hsup100'}, $::clients[$#::clients]->[6]);
        print $::cgi->div({-class => 'data_client_ast1'}, $::clients[$#::clients]->[7]);
        print $::cgi->div({-class => 'data_client_ast2'}, $::clients[$#::clients]->[8]);
        print $::cgi->div({-class => 'data_client_ast3'}, $::clients[$#::clients]->[9]);
        print $::cgi->end_div();
       pop @::clients; #Supprime le dernier �l�ment qui correspond � T&S
        foreach(@::clients) {
          print $::cgi->start_div({-class => 'data_client'});
          print $::cgi->div({-class => 'data_client_nom'}, $::cgi->span($_->[1]));
          print $::cgi->div({-class => 'data_client_ouvres'}, '&nbsp');
          print $::cgi->div({-class => 'data_client_presence'}, $_->[2]);
          print $::cgi->div({-class => 'data_client_dispo'}, '&nbsp');
          print $::cgi->div({-class => 'data_client_hsup0'}, $_->[3]);
          print $::cgi->div({-class => 'data_client_hsup25'}, $_->[4]);
          print $::cgi->div({-class => 'data_client_hsup50'}, $_->[5]);
          print $::cgi->div({-class => 'data_client_hsup100'}, $_->[6]);
          print $::cgi->div({-class => 'data_client_ast1'}, $_->[7]);
          print $::cgi->div({-class => 'data_client_ast2'}, $_->[8]);
          print $::cgi->div({-class => 'data_client_ast3'}, $_->[9]);
          print $::cgi->end_div();
        }
      }
    }
    else {
      print $::cgi->div({-id => 'data_ouvres'}, $::cgi->textfield(-name =>"nb_ouvres", -size =>3, -default =>"$nb_ouvres",  -readonly));
      if($::parametres{client_id} == 0) {
        print $::cgi->div({-id => 'data_presence'}, $::cgi->textfield(-name =>"nb_presence", -size =>3, -default => "$calcul_nb_activites{2}", -readonly));
      }
      else {
        print $::cgi->div({-id => 'data_presence'}, $::cgi->textfield(-name =>"nb_presence", -size =>3, -default => "$nb_pres", -readonly));
      }
      print $::cgi->div({-id => 'data_dispo'}, $::cgi->textfield(-name =>'nb_dispo', -size =>3, -default => "$nb_dispo", -readonly));
      print $::cgi->div({-id => 'data_hsup0'}, $::cgi->textfield(-name =>'nb_hsup0', -size =>3, -default => "$calcul_nb_activites{hsup0}", -readonly));
      print $::cgi->div({-id => 'data_hsup25'}, $::cgi->textfield(-name =>'nb_hsup25', -size =>3, -default => "$calcul_nb_activites{hsup25}", -readonly));
      print $::cgi->div({-id => 'data_hsup50'}, $::cgi->textfield(-name =>'nb_hsup50', -size =>3, -default => "$calcul_nb_activites{hsup50}", -readonly));
      print $::cgi->div({-id => 'data_hsup100'}, $::cgi->textfield(-name =>'nb_hsup100', -size =>3, -default => "$calcul_nb_activites{hsup100}", -readonly));
      print $::cgi->div({-id => 'data_ast1'}, $::cgi->textfield(-name =>'nb_ast1', -size =>2, -default => "$calcul_nb_activites{ast1}", -readonly));
      print $::cgi->div({-id => 'data_ast2'}, $::cgi->textfield(-name =>'nb_ast2', -size =>2, -default => "$calcul_nb_activites{ast2}", -readonly));
      print $::cgi->div({-id => 'data_ast3'}, $::cgi->textfield(-name =>'nb_ast3', -size =>2, -default => "$calcul_nb_activites{ast3}", -readonly));
    }
  print $::cgi->end_div(); # Fin du div data_decompte
  if($::parametres{client_id} > 0) { # Pour un client
    print $::cgi->end_fieldset(); #fin de 'decompte_jours_client'
  }
  else { # Pour T&S ou un RA global
    print $::cgi->start_div({-id => 'titre_absence'}), $::cgi->p('D&eacute;tail des absences');
#    print $::cgi->div({-id=>'titre_total_absence'},$::cgi->span('Total')), $::cgi->div({-id => 'titre_cp'}, 'Cong�s pay�s'), $::cgi->div({-id =>'titre_rtt'}, 'RTT'), $::cgi->div({-id=>'titre_maladie'}, 'Maladie');
    print $::cgi->div({-id=>'titre_total_absence'},'Total'), $::cgi->div({-id => 'titre_cp'}, 'Cong�s pay�s'), $::cgi->div({-id =>'titre_rtt'}, 'RTT'), $::cgi->div({-id=>'titre_maladie'}, 'Maladie');
    print $::cgi->div({-id => 'titre_recup'}, 'R&eacute;cup&eacute;ration'), $::cgi->div({-id =>'titre_formation'}, 'Formation'), $::cgi->div({-id=>'titre_excep'}, 'Abs. except.'), $::cgi->div({-id=>'titre_sssolde'}, 'Sans solde');
    print $::cgi->end_div(); #Fin du div titre_absence
    if($::parametres{action} eq 'affichage') {
      print $::cgi->start_div({-id => 'data_absence'});
      print $::cgi->div({-id=>'data_total_absence'},eval("$calcul_nb_activites{3}+$calcul_nb_activites{4}+$calcul_nb_activites{5}+$calcul_nb_activites{6}+$calcul_nb_activites{7}+$calcul_nb_activites{8}+$calcul_nb_activites{9}")),$::cgi->div({-id => 'data_cp'}, $::cgi->span({-name =>"nb_cp"}, "$calcul_nb_activites{3}")), $::cgi->div({-id =>'data_rtt'}, $::cgi->span({-name =>"nb_rtt"}, "$calcul_nb_activites{4}")),  $::cgi->div({-id=>'data_maladie'}, $::cgi->span({-name =>"nb_maladie"}, "$calcul_nb_activites{5}"));
      print $::cgi->div({-id => 'data_recup'}, $::cgi->span({-name =>"nb_recup"}, "$calcul_nb_activites{6}")), $::cgi->div({-id =>'data_formation'}, $::cgi->span({-name =>"nb_formation"}, "$calcul_nb_activites{7}")), $::cgi->div({-id=>'data_excep'}, $::cgi->span({-name =>"nb_excep"}, "$calcul_nb_activites{8}")), $::cgi->div({-id=>'data_sssolde'}, $::cgi->span({-name =>"nb_sssolde"}, "$calcul_nb_activites{9}"));
      print $::cgi->end_div(); #Fin du div data_absence
    }
    else {
      print $::cgi->start_div({-id => 'data_absence'});
      print $::cgi->div({-id=>'data_total_absence'},$::cgi->textfield(-name =>"nb_absence", -size =>3, -default =>eval("$calcul_nb_activites{3}+$calcul_nb_activites{4}+$calcul_nb_activites{5}+$calcul_nb_activites{6}+$calcul_nb_activites{7}+$calcul_nb_activites{8}+$calcul_nb_activites{9}"),  -readonly));
      print $::cgi->div({-id => 'data_cp'}, $::cgi->textfield(-name =>"nb_cp", -size =>3, -default =>"$calcul_nb_activites{3}",  -readonly)), $::cgi->div({-id =>'data_rtt'}, $::cgi->textfield(-name =>"nb_rtt", -size =>3, -default => "$calcul_nb_activites{4}", -readonly)), $::cgi->div({-id=>'data_maladie'}, $::cgi->textfield(-name =>"nb_maladie", -size =>3, -default => "$calcul_nb_activites{5}", -readonly));
      print $::cgi->div({-id => 'data_recup'}, $::cgi->textfield(-name =>"nb_recup", -size =>3, -default => "$calcul_nb_activites{6}", -readonly)), $::cgi->div({-id =>'data_formation'}, $::cgi->textfield(-name =>"nb_formation", -size =>3, -default => "$calcul_nb_activites{7}", -readonly)), $::cgi->div({-id=>'data_excep'}, $::cgi->textfield(-name =>"nb_excep", -size =>3, -default => "$calcul_nb_activites{8}", -readonly)), $::cgi->div({-id=>'data_sssolde'}, $::cgi->textfield(-name =>"nb_sssolde", -size =>3, -default => "$calcul_nb_activites{9}", -readonly));
      print $::cgi->end_div(); #Fin du div data_absence
    }
    print $::cgi->end_fieldset();
  }
}

sub affiche_barre_outils {
  print $::cgi->start_div({-id => 'barre_outils'});
  if($::parametres{client_id} > 0) {
    $r_activites_vues_client{-1}='Vide';
    print $::cgi->start_fieldset({-id => 'remplir'}), $::cgi->legend('Remplir avec');
#    print $::cgi->label({-for => 'remplir'}, 'Remplir avec');
#    print $::cgi->radio_group(-onclick => "return remplissage_presence(this)", -id => 'remplir', -name => 'presence', -values => \@r_activites_valeurs_client, -labels => \%r_activites_vues_client);
    print $::cgi->radio_group(-onclick => "return remplissage_presence(this)", -name => 'presence', -values => \@r_activites_valeurs_client, -labels => \%r_activites_vues_client);
    print $::cgi->end_fieldset();
    print $::cgi->start_fieldset({-id => 'selectionner'}), $::cgi->legend('Les champs s&eacute;lectionn&eacute;s');
#    print $::cgi->label({-for => 'selectionner'}, 'S�lectionner :');
    #print $::cgi->radio_group(-name => 'selection', -values => \@selection_presence_client, -labels => \@selection_presence_client_vues);
    print $::cgi->radio_group(-name => 'selection', -values => \@selection_presence_client, -labels => \%selection_presence_client);
    print $::cgi->end_fieldset();
  }
  else {

    print $::cgi->start_fieldset({-id => 'remplir'}), $::cgi->legend('Remplir avec');
#    print $::cgi->radio_group(-onclick => "return remplissage_presence(this)", -name => 'presence', -values => \@r_activites_valeurs_TS, -labels => \%r_activites_vues_TS);
    print $::cgi->popup_menu(-tabindex => '10', -name =>"bo_remplir", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS);
    print $::cgi->end_fieldset();
    print $::cgi->start_fieldset({-id => 'selectionner'}), $::cgi->legend('S&eacute;lectionner les champs');
#    print $::cgi->radio_group(-onclick => "return remplissage_presence(this)", -name => 'presence', -values => \@r_activites_valeurs_TS, -labels => \%r_activites_vues_TS);
    print $::cgi->popup_menu(-tabindex => '10', -name =>"bo_selectionner", -values =>\@activites_valeurs_TS, -labels => \%activites_vues_TS);
    print $::cgi->end_fieldset();
    print $::cgi->start_fieldset({-id => 'appliquer_selection'}), $::cgi->legend('Appliquer');
    print $::cgi->submit(-name =>"OK", -onclick => "return remplissage_presence_ts(this);");
    print $::cgi->end_fieldset();
  }
  print $::cgi->end_div();
}

sub affiche_signature {
#  print $::cgi->start_div({-id =>'bloc_signature'});
  print $::cgi->start_div({-id=>'signature_collaborateur'});
  print $::cgi->span("Signature de $::collaborateur[2] $::collaborateur[1]");
  print $::cgi->div({-class=>'signature'}, $::cgi->span('Date :'));
  print $::cgi->end_div();
  print $::cgi->start_div({-id=>'signature_societe'});
  print $::cgi->span("Signature pour $nom_client / Cachet de la soci&eacute;t&eacute;");
  print $::cgi->div({-class=>'signature'}, $::cgi->span('Date :'));
  print $::cgi->end_div();
#  print $::cgi->end_div(); # Fin du div bloc_signature
}

sub affiche_menu_s_actions {
	print $::cgi->start_div({-id=>'menu_actions'});
	if($::parametres{action} eq 'impression') {
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(0);");
	}
	elsif($::parametres{action} eq 'affichage') {
		print $::cgi->submit(-name =>'s_action', -value =>'Imprimer', -onclick => "return imprimer_ra(0)");		
		print $::cgi->submit(-name =>'s_action', -value =>'Version PDF');
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(0);");
	}
	elsif($::parametres{action} eq 'creation') {
		vers_sous_menu('Sauvegarder');
		print $::cgi->reset;
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(1);");
	}
	else {
		vers_sous_menu('Sauvegarder');
		print $::cgi->submit(-name =>'s_action', -value =>'Visualiser', -onclick => "return visualiser_ra()");
		print $::cgi->submit(-name =>'s_action', -value =>'Imprimer', -onclick => "return imprimer_ra(1)");
		print $::cgi->reset;
		print $::cgi->submit(-name =>'s_action', -value =>'Version PDF');
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(1);");
	}
    print $::cgi->end_div();
}

sub vers_sous_menu {
  print $::cgi->submit(-name=>'s_action', -value=>shift);
}


####################### Requetes SQL #########################################"""
sub recherche_nom_client {
  my $res;
  if($::parametres{client_id} eq '0') {
    return 'Technologies et Services';
  }
  elsif($::parametres{client_id} eq '-1') {
    return 'Rapport global';
  }
  else {
    my $sql =  'SELECT nom FROM client WHERE id = '.$::dbh->quote($::parametres{client_id});
    my $sth = $main::dbh->prepare($sql);
    $sth->execute;
    ($res) = $sth->fetchrow_array();
    if(defined $res){
      return $res;
    }
    else {
      return ' ';
    }
  }
}


1;