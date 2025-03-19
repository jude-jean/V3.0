package Calendrier;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(calendrier);

use Date::Calc qw(:all);
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Time::Local;
use Etechnoserv qw(lecture_parametres visu_parametres);


my (@heures_rdv, @jours_cal, @mini_cal);
my ($date_deb, $date_fin);
my ($tps, $pas);
my $annee_debut = 2003;
my @mois = (['Janvier', 1], ['Février', 2], ['Mars',3], ['Avril',4], ['Mai', 5], ['Juin', 6], ['Juillet', 7], ['Août', 8], ['Septembre', 9], ['Octobre', 10], ['Novembre', 11], ['Décembre', 12]);
my @jours = (['Lundi', 1], ['Mardi', 2], ['Mercredi',3], ['Jeudi',4], ['Vendredi', 5], ['Samedi', 6], ['Dimanche', 7]);
my @aujourdhui = Today();
my @liste_jours;
my %liste_jours = ();
my ($annee_active, $mois_actif, $annee_in, $mois_in, $jour_in);
my (@date);
my $periode_visu = 5;  # doit être supérieur à 2
my (@ra, @ra_astreinte, @ra_comment, @ra_global, @ra_hsup, @ra_presence);
my @clients;
my $flag_ra_global;
my ($action, $client_id, $ra_id);

#my %action = (
# 'creation'              => \&creer_ra,
# 'edition'               => \&editer_ra,
# 'suppression'           => \&supprimer_ra,
# 'sauvegarde'            => \&sauvegarder_ra,
# 'validation'            => \&valider_ra,
#);

#Document de gestion des rapports d'activités pour un utilisateur
sub calendrier {
#  my $actif = shift;
#  return unless $actif;
#  return unless $::id;
#  my $fonction;
#  $action = $::cgi->param('action');
#  if(defined($action)) {
#    if(defined($fonction = $action{$action})) {
#      $fonction->();
#    }
#    else {
#      print $::cgi->h3("Pas d'action définie pour $action");
#    }
#  }
#  else {
    lecture_parametres(\%::parametres);
#    visu_parametres(\%parametres);
    gestion_parametres();
    calcul_tab_rdv();
    calcul_mini_calendrier();
    print $::cgi->h1("Calendrier du compte $::collaborateur[3]");
    print $::cgi->start_div({-id=>'cal_bm'}), 'Barre de menu';
    print $::cgi->end_div(); # Fin de barre de menu du calendrier
    print $::cgi->start_div({-id=>'cal_visu'});
    print $::cgi->hidden(-name => 'annee', -value => $::parametres{annee});
    print $::cgi->hidden(-name => 'mois', -value => $::parametres{mois});
    print $::cgi->hidden(-name => 'jour', -value => $::parametres{jour});
    gestion_rdv_existants();
    affichage_tab_rdv();
    print $::cgi->end_div(); # Fin du div de gestion du calendrier
    print $::cgi->start_div({-id=>'cal_droite'});
    print $::cgi->start_div({-id=>'cal_mini'});
    affiche_mini_calendrier();
    print $::cgi->end_div(); # Fin du div cal_mini
    print $::cgi->start_div({-id=>'cal_taches'});
    print $::cgi->end_div(), $::cgi->end_div(); # Fin du div de gestion des taches et du div cal_droite

    &main::menu_social(0xFB);
#  }
}

sub gestion_parametres {
  my ($dernier_jour, $nb1_jours, $nb2_jours);
  if(!exists $::parametres{affichage_rdv}) {
# On devrait rechercher les préférences des parametres d'affichage pour le
# calendrier. Dans un premier temps, on fixe arbitrairement les valeurs
    $::parametres{affichage_rdv} = 0;# Affichage par jour
  }
  if(!exists($::parametres{jour})) {
    ($::parametres{annee}, $::parametres{mois}, $::parametres{jour})= Today();
    $tps = Mktime($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 0, 0, 0);
  }
  if(!exists($::parametres{affichage_heure})) {
# On devrait rechercher les préférences des parametres d'affichage pour le
# calendrier. Dans un premier temps, on fixe arbitrairement les valeurs
    $::parametres{affichage_heure} = 5; # Affichage par heure
  }
#  print "Affichage des parametres après la fonction gestion_parametres()", $::cgi->br();
#  visu_parametres(\%::parametres);
}
#***************** Affichage des données ************************************
sub affichage_tab_rdv {
  AFFICHAGE : {
    if($::parametres{affichage_rdv} eq '0') {
      affiche_tab_rdv_jour();
      last AFFICHAGE;
    }
    if($::parametres{affichage_rdv} eq '1') {
      affiche_tab_rdv_5jours();
      last AFFICHAGE;
    }
    if($::parametres{affichage_rdv} eq '2') {
      affiche_tab_rdv_semaine();
      last AFFICHAGE;
    }
    if($::parametres{affichage_rdv} eq '3') {
      affiche_tab_rdv_mois();
      last AFFICHAGE;
    }


  }
}

sub affiche_tab_rdv_jour {
  $tps = Mktime($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 0, 0, 0);
  affiche_titre_rdv_jour();
  HEURE : {
    if($::parametres{affichage_heure} eq '1') {
      affiche_rdv_5();
      last HEURE;
    }
    if($::parametres{affichage_heure} eq '2') {
      affiche_rdv_10();
      last HEURE;
    }
    if($::parametres{affichage_heure} eq '3') {
      affiche_rdv_15();
      last HEURE;
    }
    if($::parametres{affichage_heure} eq '4') {
      affiche_rdv_30();
      last HEURE;
    }
    if($::parametres{affichage_heure} eq '5') {
      affiche_rdv_heure();
      last HEURE;
    }

  }
}

sub affiche_titre_rdv_jour {
  my $titre_jour = "$jours[Day_of_Week($::parametres{annee}, $::parametres{mois}, $::parametres{jour}) - 1]->[0] $::parametres{jour} $mois[$::parametres{mois} -1 ]->[0] $::parametres{annee}";
  my $titre_semaine = ", Semaine ".Week_of_Year($::parametres{annee}, $::parametres{mois}, $::parametres{jour});
#  $tps = Mktime($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 0, 0, 0);
#  print "parametres{annee} = $::parametres{annee}, parametres{mois} = $::parametres{mois}, parametres{jour} = $::parametres{jour}", $::cgi->br();
  my ($an, $mois, $jj) = Add_Delta_Days($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, -1);
#  print "j-1 = $an/$mois/$jj - ";
  print $::cgi->start_div({-id=>'titre_rdv_jour'}), $::cgi->div({-id=>'t11_rdv_jour'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$an&mois=$mois&jour=$jj&ident_id=$::parametres{ident_id}"}, $::cgi->img({-id=>'img_prev', -src=>"$::rep/images/arrow_blue_left.png", -alt=>'jour précédent'}))), $::cgi->div({-id=>'t12_rdv_jour'}, $::cgi->span({-id=>'jour'}, $titre_jour), $::cgi->span({-id=>'semaine'}, $titre_semaine));
  ($an, $mois, $jj) = Add_Delta_Days($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 1);
#  print "j+1 = $an/$mois/$jj", $::cgi->br();
  print $::cgi->div({-id=>'t13_rdv_jour'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$an&mois=$mois&jour=$jj&ident_id=$::parametres{ident_id}"}, $::cgi->img({-id=>'img_next', -src=>"$::rep/images/arrow_blue_right.png", -alt=>'jour suivant'})));
  print $::cgi->end_div();# fin du div titre_rdv_jour
}
my (%echelle_tps, @cles_rangees);
sub cree_echelle_tps {
# echelle_tps est un hachage ayant comme cle $tps. Chaque valeur de clé est
# constitué d'un tableau anonyme composé de l'Id du rdv et de sa position sur
#l'axe des abscisses sachant que l'on décale par rapport au bord le plus à
#droite. Cette position est trouvée quand on insère la date de début du
#rendez-vous dans le hachage.
  my ($tps_debut, $tps_fin) = @_;
  my ($rdv, $tps, @temps, $rg, $maj, $decalage, $i);
  $decalage = -1;
  $maj = 0;
  $pas = 3600;
  for(my $j = 0; $j < 1+$#heures_rdv; $j++) {
    $rdv = $heures_rdv[$j];
#Initialise tps
    $tps = $rdv->[13];
#    while(($tps < $rdv->[14]) && ($tps < $tps_fin)) {
    while($tps < $rdv->[14]) {
# Si la clé n'existe pas dans le hachage
      if(!exists $echelle_tps{$tps}) {
#Si c'est la date de début du rendez-vous, on cré la clé et on met le rdv en
# position 0, et on affecte au decalage la position 0
        if($tps == $rdv->[13]) {
# Pos n° 1 : Flag permettant d'identifier la date de début du rdv
# Pos n° 2 : taille en % du bloc
# Pos n° 3 : N° de la zone d'affichage
#          $echelle_tps{$tps} = [ $rdv->[0], 1, 0, 1 ];
          $echelle_tps{$tps} = [ \@$rdv, 1, 0, -1 ];
          $decalage = 0;
          $rdv->[20] = $decalage;
        }
# On cré la clé en positionant directement le rdv avec le décalage existant
        else {
          $echelle_tps{$tps} = [  ];# Tableau anonyme vide
#          $echelle_tps{$tps}->[4*$decalage] = $rdv->[0];
          $echelle_tps{$tps}->[4*$decalage] = \@$rdv;
# Flag permettant d'identifier que ce n'est pas la date de début
          $echelle_tps{$tps}->[4*$decalage + 1] = 0;
          $echelle_tps{$tps}->[4*$decalage + 2] = 0;
          $echelle_tps{$tps}->[4*$decalage + 3] = -1;
        }
      }
      else {
# L'entrée existe dans le hachage pour $tps, 2 cas possibles : $tps == debut du
#rdv ou non.
# Si c'est la date début de rdv on cherche la 1ère position libre, sinon on met
# ajoute le rdv à la fin du tableau anonyme.
        if($tps == $rdv->[13]) {
          $rg = $echelle_tps{$tps};
          for($i = 0; 4*$i < $#{$rg}; $i++) {
            if(!exists $rg->[4*$i]) {
              $rg->[4*$i] = \@$rdv;
              $rg->[4*$i + 1] = 1;
              $rg->[4*$i + 2] = 0;
              $rg->[4*$i + 3] = -1;
              $decalage = $i;
              $rdv->[20] = $decalage;
              $maj = 1;
              last;
            }
          }
# Si aucune position n'est vide, alors on ajoute le rdv en dernière position et
# on fixe le décalge
          if($maj == 0) {
            my $sup = scalar(@$rg);
            $rg->[$sup] = \@$rdv;
            $rg->[$sup + 1] = 1;
            $rg->[$sup + 2] = 0;
            $rg->[$sup + 3] = -1;
            $decalage = $sup/4;
            $rdv->[20] = $decalage;
          }
        }
        else {
          $echelle_tps{$tps}->[4*$decalage] = \@$rdv;
          $echelle_tps{$tps}->[4*$decalage + 1] = 0;
          $echelle_tps{$tps}->[4*$decalage + 2] = 0;
          $echelle_tps{$tps}->[4*$decalage + 3] = -1;
        }
      }
      $tps+= 3600;
      $maj = 0;
    }
    $decalage = -1;
  }
  @cles_rangees = sort keys %echelle_tps;
  genere_liens_rdv();

}

my $cpt_rdv_avec_taille = 0;


sub genere_liens_rdv {
# Pour  un rdv donné, généré les rdv avant et après afin de calculer l'espace
# occupé pour définir la taille du rdv
  my ($rdv, $pos, $cle, $lig, $k);
  for(my $j = 0; $j < 1+$#heures_rdv; $j++) {
    $rdv = $heures_rdv[$j];
    $pos = $rdv->[20];
    $k = 1;
    foreach $cle (@cles_rangees) {
      next if($cle < $rdv->[13]);
      last if($cle >= $rdv->[14]);
      $lig = $echelle_tps{$cle};
      if($pos > 0) {
# Ajoute le précédent dans la liste des rdv_avant

AVANT : while(($pos -$k) >= 0) {
          if(exists($lig->[4*($pos - $k)]) && ($rdv->[16]->[$#{$rdv->[16]}] != $lig->[4*($pos - $k)])) {
            push @{$rdv->[16]}, $lig->[4*($pos - $k)];
            last AVANT;
          }
          $k++;
        }
      }
# Ajoute le suivant dans la liste des rdv_suivants
      $k = 1;
APRES : while(4*($pos + $k) < $#{$lig}) {
          if(exists($lig->[4*($pos + $k)])&& ($rdv->[19]->[$#{$rdv->[19]}] != $lig->[4*($pos + $k)])) {
            push @{$rdv->[19]}, $lig->[4*($pos + $k)];
#            push $rdv->[19], $lig->[4*($pos + $k)]->[0];
            if($rdv->[22] == 0) {
# Position du rdv le plus proche
              $rdv->[22] = $pos + $k;
            }
            else {
              $rdv->[22] = ($rdv->[22] < ($pos + $k)) ? $rdv->[22] : ($pos + $k);
            }
            last APRES;
          }
          $k++;
        }

    }
#    print "Pour le RDV $rdv->[0], les rendez suivants sont : @{$rdv->[19]}", $::cgi->br();
  }

}


sub lecture_echelle_tps {
#%nbre_rdv_adj est un hachage contenant pour chaque rdv un tableau comprenant
#[le nbre de rdv adjacent, la position du rdv dans $lig]
  my ($lig, @heures, %nbre_rdv_adj, $rdv_adj, $rdv);

  foreach (@cles_rangees) {
    $lig = $echelle_tps{$_};
    for(my $i = 0; 4*$i < $#{$lig}; $i++) {
      if(exists $lig->[4*$i]) {
        if(! exists $nbre_rdv_adj{$lig->[4*$i]->[0]}) {
          $nbre_rdv_adj{$lig->[4*$i]->[0]} = [(1+$#{$lig})/4, $i ];
        }
        else {
          $nbre_rdv_adj{$lig->[4*$i]->[0]}->[0] = ($nbre_rdv_adj{$lig->[4*$i]->[0]}->[0]>(1+$#{$lig})/4) ? $nbre_rdv_adj{$lig->[4*$i]->[0]}->[0]:(1+$#{$lig})/4;
        }
      }
    }
  }
  for(my $j = 0; $j < 1+$#heures_rdv; $j++) {
    $rdv = $heures_rdv[$j];
    foreach  (sort keys %nbre_rdv_adj) {
      if($rdv->[0] == $_) {
        $rdv->[15] = $nbre_rdv_adj{$_}->[0];
        $rdv->[21] = $nbre_rdv_adj{$_}->[0];
        last;
      }
    }
  }
# Recherche de liens dans l'ordre
  for(my $j = 0; $j < 1+$#heures_rdv; $j++) {
    my $rdv1 = $heures_rdv[$j];
    for(my $k = 0; $k < 1+$#heures_rdv; $k++) {
      recherche_liens_entre_rdv($rdv1, $heures_rdv[$k]);
    }
  }
#Puis recherhe de liens dans l'ordre inverse
  for(my $j = $#heures_rdv; $j >= 0; $j--) {
    my $rdv1 = $heures_rdv[$j];
    for(my $k = 0; $k < 1+$#heures_rdv; $k++) {
      recherche_liens_entre_rdv($rdv1, $heures_rdv[$k]);
    }
  }
  
  
  
#  print "Nombre max de rdv adjacents :", $::cgi->br();
#  foreach  (sort keys %nbre_rdv_adj) {
#    print "RDV = $_, Total rdv_adj = $nbre_rdv_adj{$_}->[0], Position = $nbre_rdv_adj{$_}->[1]", $::cgi->br();
#  }
#  print $::cgi->br();

#  for(my $j = 0; $j < 1+$#heures_rdv; $j++) {
#    my $rdv1 = $heures_rdv[$j];
#    print "RDV = $rdv1->[0], Total rdv_adj = $rdv1->[21]", $::cgi->br();
#  }

#  foreach (@cles_rangees) {
#    $lig = $echelle_tps{$_};
#    @heures = (Localtime($_))[3, 4];
#    print "@heures : ";
#    for(my $i = 0; 4*$i < $#{$lig}; $i++) {
#      if(exists $lig->[4*$i]) {
#        print "$lig->[4*$i]->[0] $lig->[4*$i + 1] ";
#        print sprintf " >%4.2f< ", (1/(1+$#{$lig})/4);
#        print "$lig->[4*$i + 3] ";
#      }
#    }
#    print ",(",(1+$#{$lig})/4,")", $::cgi->br();
#  }
}

sub recherche_liens_entre_rdv {
  my ($rdv1, $rdv2) = @_;
  my $max;
  if($rdv1->[0]!= $rdv2->[0]) {
    if($rdv1->[13]>= $rdv2->[13]) {
#      if($rdv2->[14] >= $rdv1->[13]) {
	  if($rdv1->[13] <= $rdv2->[14]) {
        $max = ($rdv1->[21] >= $rdv2->[21]) ? $rdv1->[21] : $rdv2->[21];
        $rdv1->[21] = $max;
        $rdv2->[21] = $max;
      }
    }
    if($rdv1->[13] < $rdv2->[13]) {
      if($rdv2->[13] <= $rdv1->[14]) {
        $max = ($rdv1->[21] >= $rdv2->[21]) ? $rdv1->[21] : $rdv2->[21];
        $rdv1->[21] = $max;
        $rdv2->[21] = $max;
      }
    }
  }
}

sub gestion_rdv_existants {
  my $nb_rdv;
  my $decalage_droite = 0;
  my (@deb, @fin, @rdv_apres, @rdv_avant);
  my ($rdv, $id_rdv, $tps, $tps_debut, $tps_fin, $texte, $heure_debut, $int_deb, $int_fin);
  my ($lig, $rg);
  $pas = 3600;
  $tps_debut = Mktime($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 0, 0, 0);
  $tps_fin = Mktime($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 23, 59, 59);

  cree_echelle_tps($tps_debut, $tps_fin);
  lecture_echelle_tps();
  my $j = 1;;
  print $::cgi->hidden(-name => "nb_rdv", -value => $#heures_rdv +1);
  foreach $rdv (@heures_rdv) {


    $nb_rdv = 0;
    @rdv_apres = ();
    @deb = split /(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/, $rdv->[2];
    @fin = split /(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/, $rdv->[3];
#    print "tps_debut = $tps_debut, rdv heure debut = $rdv->[13], tps_fin = $tps_fin, rdv heure fin = $rdv->[14]", $::cgi->br();
#    print "$deb[3]/$deb[2]/$deb[1] $deb[4]:$deb[5]", $::cgi->br();;
    if($rdv->[13] != Mktime($deb[1], $deb[2], $deb[3], $deb[4], $deb[5], 0)) { # < $tps_debut
      $texte = "$deb[3]/$deb[2]/$deb[1] $deb[4]:$deb[5]";
      $heure_debut = 0;
      $int_deb = $tps_debut;
    }
    else {
      $texte = "$deb[4]:$deb[5]";
      $heure_debut = $deb[4]*1;
      $int_deb = $rdv->[13];
    }
    $rdv->[17] = ($rdv->[13] - $tps_debut <= 0 )? 0 : ($rdv->[13] -$tps_debut)/$pas;
    if($rdv->[14] == Mktime($fin[1], $fin[2], $fin[3], $fin[4], $fin[5], 0)) { # <= $tps_fin
      $texte .=" - $fin[4]:$fin[5]";
      $int_fin = $rdv->[14];
    }
    else {
      $texte .=" - $fin[3]/$fin[2]/$fin[1] $fin[4]:$fin[5]";
      $int_fin = $tps_fin;
      $rdv->[18]++;
    }
    $rdv->[18] += ($int_fin - $int_deb)/$pas;

    $id_rdv = "rdv$j";

    print $::cgi->start_div({-id =>"$id_rdv", -class => 'rdv_existe', -onmousedown=>"return anime_rdv(this, event);", -onmouseover => "return curseur_rdv(this, event);"});
	if($rdv->[5] > 0) {
      print $::cgi->a({-class => 'rdv_a_partage', -title=>"$rdv->[9]", -target=>'rdv', -href=>"$::rep_pl/rendez_vous/open.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&rdv=$rdv->[0]&ident_id=$::id"},"$texte ". $::cgi->img({-id=>'img_mini_cal_hdebut', -src=>"$::rep/images/periodicite.png", -alt=>'rdv periodique'})." $rdv->[9]");	
	}
	else {
      print $::cgi->a({-class => 'rdv_a_partage', -title=>"$rdv->[9]", -target=>'rdv', -href=>"$::rep_pl/rendez_vous/open.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&rdv=$rdv->[0]&ident_id=$::id"},"$texte $rdv->[9]");
	}
    print $::cgi->hidden(-name => "id_$id_rdv", -value => $rdv->[0]);
#    print $::cgi->hidden(-name => "$id_rdv".'_debut', -value => $rdv->[2]);
#    print $::cgi->hidden(-name => "$id_rdv".'_fin', -value => $rdv->[3]);
    print $::cgi->hidden(-name => "pos_$id_rdv", -value => $rdv->[17]);
    print $::cgi->hidden(-name => "haut_$id_rdv", -value => $rdv->[18]);
	print $::cgi->hidden(-name => "debut_$id_rdv", -value => $rdv->[2]);
	print $::cgi->hidden(-name => "fin_$id_rdv", -value => $rdv->[3]);
	print $::cgi->hidden(-name => "ref_$id_rdv", -value => $rdv->[5]) if($rdv->[5]);
    $decalage_droite = 0;
    print $::cgi->hidden(-name => "nb_$id_rdv", -value => $nb_rdv);
    my $taille;
    if($rdv->[22] > 0) {
      $taille = sprintf "%6.4f", (($rdv->[22] - $rdv->[20])/$rdv->[21]);
    }
    else {
      $taille = sprintf "%6.4f", (($rdv->[21] - $rdv->[20])/$rdv->[21]);
    }
    print $::cgi->hidden(-name => "taille_$id_rdv", -value => $taille);
    my $droite = sprintf "%6.4f", $rdv->[20]/$rdv->[21];
    print $::cgi->hidden(-name => "droite_$id_rdv", -value => $droite);
    print $::cgi->end_div();
    $j++;
  }
}

sub affiche_rdv_heure {
# Affiche les rendez-vous toutes les heures
  my ($rdv, $nb_rdv, $deb_rdv);
  my ($heure, $mn, $msg);
  $nb_rdv = 0;
  my $id_rdv;
  print $::cgi->start_div({-id=>'cal_jour'});
  foreach (0 .. 23) {
    $heure = ($_ >= 10) ? "$_" : "0$_";
	$mn = "00";
    if($_ == 0) {
#      print $::cgi->start_div({-class=>'rdv_heure'}), $::cgi->div({-class=>'rdv_heure_col1 decalage_negatif'}, $::cgi->a({-title=>'Nouveau', -target=>'rdv', -href=>"$::rep_pl/rendez_vous/new.pl?ident_user=$::collaborateur[3]&&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&heure=$heure&ident_id=$::id"},"$_"));
      print $::cgi->div({-class=>'rdv_heure_col1'}, $::cgi->a({-title=>'Nouveau', -target=>'rdv', -href=>"$::rep_pl/rendez_vous/new.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&heure=$heure&ident_id=$::id"}, $::cgi->span({-id=>'heure'}, $heure), $::cgi->span({-id=>'mn'}, $mn)));
#      print $::cgi->start_div({-class=>'rdv_heure_col2 premiere_heure'}), $::cgi->div({-class=>'decalage'}, ' ');
      print $::cgi->start_div({-class=>'rdv_heure_col2'});
    }
    elsif($_ == 23) {
#      print $::cgi->start_div({-class=>'rdv_heure'}), $::cgi->div({-class=>'rdv_heure_col1 derniere_heure'},$::cgi->a({-title=>'Nouveau', -target=>'rdv', -href=>"$::rep_pl/rendez_vous/new.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&heure=$heure&ident_id=$::id"},"$_"));
      print $::cgi->div({-class=>'rdv_heure_col1 derniere_heure'},$::cgi->a({-title=>'Nouveau', -target=>'rdv', -href=>"$::rep_pl/rendez_vous/new.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&heure=$heure&ident_id=$::id"}, $::cgi->span({-id=>'heure'}, $heure), $::cgi->span({-id=>'mn'}, $mn)));
      print $::cgi->start_div({-class=>'rdv_heure_col2 derniere_heure'});
    }
    else {
#      print $::cgi->start_div({-class=>'rdv_heure'}), $::cgi->div({-class=>'rdv_heure_col1'},$::cgi->a({-title=>'Nouveau', -target=>'rdv', -href=>"$::rep_pl/rendez_vous/new.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&heure=$heure&ident_id=$::id"},"$_"));
      print $::cgi->div({-class=>'rdv_heure_col1'},$::cgi->a({-title=>'Nouveau', -target=>'rdv', -href=>"$::rep_pl/rendez_vous/new.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&heure=$heure&ident_id=$::id"},$::cgi->span({-id=>'heure'}, $heure), $::cgi->span({-id=>'mn'}, $mn)));
      print $::cgi->start_div({-class=>'rdv_heure_col2'});
    }
    print $::cgi->a({-class=>'rdv_a_vide', -target=>'rdv', -href=>"$::rep_pl/rendez_vous/new.pl?ident_user=$::collaborateur[3]&affichage_rdv=$::parametres{affichage_rdv}&affichage_heure=$::parametres{affichage_heure}&annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&heure=$heure&ident_id=$::id"}," ");
#    print $::cgi->end_div(), $::cgi->end_div(); #Fin du div rdv_heure_col2 et du div rdv_heure
    print $::cgi->end_div(); #Fin du div rdv_heure_col2
  }
  print $::cgi->end_div(); # Fin du div cal_jour
}

sub affiche_rdv_30 {
#Affiche les rendez-vous toutes les 30mn
;
}

sub affiche_rdv_15 {
#Affiche les rendez-vous toutes les 15 mn
;
}

sub affiche_rdv_10 {
#Affiche les rendez-vous toutes les 10mn
;
}

sub affiche_rdv_5 {
#Affiche les rendez-vous toutes les 5 mn
;
}

sub affiche_tab_rdv_5jours {
# Affiche les rendez-vous sur une semaine de travail (5 jours)
}

sub affiche_tab_rdv_semaine {
# Affiche les rendez-vous sur une semaine
;
}

sub affiche_tab_rdv_mois {
# Affiche les rendez-vous sur 1 mois
}

sub affiche_mini_calendrier {
  my $cle;
  print $::cgi->div({-id=>'titre_mini_annee'}, $::cgi->div($::parametres{annee}));
  my @mois_calcule = Add_Delta_YM($::parametres{annee}, $::parametres{mois}, $::parametres{jour} , 0, -1);
#  print $::cgi->start_div({-id=>'titre_mini_mois'}), $::cgi->div({-id=>'t11_mini_mois'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$::parametres{annee}&mois=$::parametres{mois}&jour=$::parametres{jour}&prev=m&ident_id=$::parametres{ident_id}"}, $::cgi->img({-id=>'img_mois_prev', -src=>"$::rep/images/nav_left_blue.png", -alt=>'mois précédent'}))), $::cgi->div({-id=>'t12_mini_mois'}, $mois[$::parametres{mois} -1]->[0]);
  print $::cgi->start_div({-id=>'titre_mini_mois'}), $::cgi->div({-id=>'t11_mini_mois'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$mois_calcule[0]&mois=$mois_calcule[1]&jour=$mois_calcule[2]&ident_id=$::parametres{ident_id}"}, $::cgi->img({-id=>'img_mois_prev', -src=>"$::rep/images/nav_left_blue.png", -alt=>'mois précédent'}))), $::cgi->div({-id=>'t12_mini_mois'}, $mois[$::parametres{mois} -1]->[0]);
  @mois_calcule = Add_Delta_YM($::parametres{annee}, $::parametres{mois}, $::parametres{jour} , 0, 1);
  print $::cgi->div({-id=>'t13_mini_mois'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$mois_calcule[0]&mois=$mois_calcule[1]&jour=$mois_calcule[2]&ident_id=$::parametres{ident_id}"}, $::cgi->img({-id=>'img_mois_next', -src=>"$::rep/images/nav_right_blue.png", -alt=>'mois suivant'}))), $::cgi->end_div();
  print $::cgi->start_div({-id=>'titre_lig_semaine'}), $::cgi->div({-class=>'cel_jour'}, 'L'), $::cgi->div({-class=>'cel_jour'}, 'M'), $::cgi->div({-class=>'cel_jour'}, 'M'),  $::cgi->div({-class=>'cel_jour'}, 'J'),  $::cgi->div({-class=>'cel_jour'}, 'V'),  $::cgi->div({-class=>'cel_jour'}, 'S'),  $::cgi->div({-class=>'cel_jour'}, 'D');
  print $::cgi->end_div();
  print $::cgi->start_div({-class=>'lig_semaine'});
  for(my $i = 0; $i <= $#jours_cal; $i++) {
    $cle = calcul_cle($jours_cal[$i]->[1], $jours_cal[$i]->[2], $jours_cal[$i]->[3]);
    print $::cgi->end_div(), $::cgi->start_div({-class=>'lig_semaine'}) if((($i%7) == 0) && ($i >0));
    if(($::parametres{jour} == $jours_cal[$i]->[3]) && ($::parametres{mois} == $jours_cal[$i]->[2])) {
      print $::cgi->div({-id=>'cel_jour_actif'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
    }
    elsif(($jours_cal[$i]->[1] == $aujourdhui[0]) && ($jours_cal[$i]->[2] == $aujourdhui[1]) && ($jours_cal[$i]->[3] == $aujourdhui[2])) {
      if(exists $liste_jours{$cle}) {
        if($::parametres{mois} != $jours_cal[$i]->[2]) {
          print $::cgi->div({-id=>'cel_aujourdhui', -class=>'cel_jour_inactif'}, $::cgi->a({-title=>"$liste_jours{$cle} rdv", -href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
        }else {
          print $::cgi->div({-id=>'cel_aujourdhui'}, $::cgi->a({-title=>"$liste_jours{$cle} rdv", -href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
        }
      }
      else {
        if($::parametres{mois} != $jours_cal[$i]->[2]) {
          print $::cgi->div({-id=>'cel_aujourdhui', -class=>'cel_jour_inactif'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
        }
        else {
          print $::cgi->div({-id=>'cel_aujourdhui'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
        }
      }
    }
    elsif($::parametres{mois} != $jours_cal[$i]->[2]) {
      if(exists $liste_jours{$cle}) {
        print $::cgi->div({-class =>'cel_jour_inactif rdv'}, $::cgi->a({-title=>"$liste_jours{$cle} rdv", -href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
      }
      else {
       print $::cgi->div({-class =>'cel_jour_inactif'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
      }
    }
    else {
      if(exists $liste_jours{$cle}) {
        print $::cgi->div({-class =>'cel_jour rdv'}, $::cgi->a({-title=>"$liste_jours{$cle} rdv", -href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
      }
      else {
        print $::cgi->div({-class =>'cel_jour'}, $::cgi->a({-href=>"$::rep_pl/calendrier/show.pl?annee=$jours_cal[$i]->[1]&mois=$jours_cal[$i]->[2]&jour=$jours_cal[$i]->[3]&ident_id=$::parametres{ident_id}"},"$jours_cal[$i]->[3]"));
      }
    }
  }
  print $::cgi->end_div();
}

sub calcul_cle {
  my($annee, $mois, $jour) = @_;
  my ($cle, $s_mois, $s_jour);
  $s_mois = ($mois <= 9)? "0$mois" : $mois;
  $s_jour = ($jour <= 9)? "0$jour" : $jour;
  $cle = "$annee $s_mois $s_jour";
  return $cle;
}

#***************** Génération des differentes strucutes de données *************
sub calcul_tab_rdv() {
  $date_deb = "$::parametres{annee}-$::parametres{mois}-$::parametres{jour} 00:00:00";
  $date_fin = "$::parametres{annee}-$::parametres{mois}-$::parametres{jour} 23:59:59";
  
#  print "Date début = $date_deb, Date fin = $date_fin", $::cgi->br();
  SWITCH: {
    if($::parametres{affichage_rdv} eq '0') {
      cree_tab_rdv_jour();
      last SWITCH;
    }
    if($::parametres{affichage_rdv} eq '1') {
      cree_tab_rdv_5jours();
      last SWITCH;
    }
    if($::parametres{affichage_rdv} eq '2') {
      cree_tab_rdv_semaine();
      last SWITCH;
    }
    if($::parametres{affichage_rdv} eq '3') {
      cree_tab_rdv_mois();
      last SWITCH;
    }
  }
}

sub calcul_mini_calendrier {
# @jours_cal = [ tps_jour, annee, mois, jour, heure, mn, sec, day_of_year, day_of_week, hiver/été]
# On récupère les informations sur le 1er jour du mois
  my $nb_jours_mois = Days_in_Month($::parametres{annee}, $::parametres{mois});
  my $tps_jour = Mktime($::parametres{annee}, $::parametres{mois}, 1, 0, 0, 0);

  my @jour = Localtime($tps_jour);
  my $debut_semaine = 0;
# On  remonte au 1er lundi du mois précédent
  my $var_jour;
  do {
    $var_jour = [ $tps_jour, @jour ];
    if(defined ($jours_cal[0])) {
      unshift (@jours_cal, $var_jour) if($jours_cal[$#jours_cal]->[7] != $var_jour->[7]);
    }
    else {
      unshift (@jours_cal, $var_jour);
    }
#    print "Jour de la semaine : $jour[7] a tester avec $jours[0]->[1]", $::cgi->br();
#Attention au 's' de $jours[0]->, on appelle la variable globale @jours
    if(($jour[7]) > $jours[0]->[1]) {
      $tps_jour -= 86400;
      @jour = Localtime($tps_jour);
    }
    else {
      $debut_semaine = 1;
    }
  }
  while($debut_semaine == 0);
# On ajoute tous les jours du mois, on se positionne sur le 1er jour du mois
  $var_jour = $jours_cal[$#jours_cal];
  while($var_jour->[3] < $nb_jours_mois) {
    $tps_jour = $var_jour->[0] + 86400;
    $var_jour = [ $tps_jour, Localtime($tps_jour) ];
    push (@jours_cal, $var_jour) if($jours_cal[$#jours_cal]->[7] != $var_jour->[7]);
  }
# On compléte maintenant avec le 1er dimanche du mois suivant
#  print "On complète pour arriver au 1er dimanche du mois suivant", $::cgi->br();
#  print "Dernier élément de jours_cal = @$var_jour, le test est entre var_jour[8] = $var_jour->[8] et $jours[6]->[1]", $::cgi->br();
  while($var_jour->[8] < $jours[6]->[1]) {
    $tps_jour = $var_jour->[0] + 86400;
    $var_jour = [ $tps_jour, Localtime($tps_jour) ];
#Le if permet de gérer le passage de l'heure d'hiver à l'heure d'été
    push (@jours_cal, $var_jour) if($jours_cal[$#jours_cal]->[7] != $var_jour->[7]);
  }
  db_recherche_liste_jours_rdv($nb_jours_mois);
#  print "Liste des jours du mois ayant un rendez-vous :  @liste_jours", $::cgi->br();
#  print "Nombre de rdv pour chaque jour pour le mois en cours : ", $::cgi->br();
#  foreach (keys %liste_jours) {
#    print "$_ : $liste_jours{$_} rdv", $::cgi->br();
#  }
}

sub visu_jours_cal {
  print "Jours du mini calendrier", $::cgi->br();
  foreach (@jours_cal) {
    print "$jours[$_->[8]-1]->[0] $_->[3]/$_->[2]/$_->[1]", $::cgi->br();
  }
  print $::cgi->br();
}

sub cree_tab_rdv_jour {
  db_recherche_rdv_jour();
#  print "Visualisation de heures_rdv", $::cgi->br();
#  foreach (@heures_rdv) {
#    print "$_->[0], $_->[1], $_->[2], $_->[3], $_->[4], $_->[5]", $::cgi->br();
#  }
}
#******************************************************************************

sub creer_ra {
  print $::cgi->start_form(-target=> "Création d'un rapport d'activité");
  print $::cgi->h1("Creation");
  print $::cgi->end_form();
}
#
#sub editer_ra {
#  print $::cgi->h1("Edition d'un rapport d'activité");
#}

sub supprimer_ra {
  print $::cgi->h1("Suppression d'un rapport d'activité");
}

sub sauvegarder_ra {
  print $::cgi->h1("Sauvegarde d'un rapport d'activité");
}

sub valider_ra {
  print $::cgi->h1("Validation d'un rapport d'activité");
}

#*********** Accès bases de données ***************************************
sub db_recherche_rdv_jour {
  my $ref_ligne;
#  my $rdv = "SELECT * FROM rdv WHERE id_user = ".$::dbh->quote($::collaborateur[0])." AND debut >= ".$::dbh->quote($date_deb)." AND fin <= ".$::dbh->quote($date_fin)." ORDER BY debut ASC, fin - debut DESC";
  my $tps_debut = Mktime($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 0, 0, 0);
  my $tps_fin = Mktime($::parametres{annee}, $::parametres{mois}, $::parametres{jour}, 23, 59, 59);


  my $rdv = "SELECT * FROM rdv WHERE id_user = ".$::dbh->quote($::collaborateur[0])." AND ((debut <= ".$::dbh->quote($date_deb)." AND fin > ".$::dbh->quote($date_deb).") OR (debut >= ".$::dbh->quote($date_deb)." AND debut < ".$::dbh->quote($date_fin).")) ORDER BY debut ASC, fin - debut DESC";
#  print "sql = $rdv", $::cgi->br();
  my $sth = $::dbh->prepare($rdv);
  $sth->execute();
  while($ref_ligne = $sth->fetchrow_arrayref) {
    my ($vide, $annee, $mois, $jour, $heure, $mn, $sec) = split /(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/, $ref_ligne->[2];
    my ($deb, $fin);
    $deb = Mktime($annee, $mois, $jour, $heure, $mn, $sec);
    $deb = ($deb <= $tps_debut) ? $tps_debut : $deb;
    ($vide, $annee, $mois, $jour, $heure, $mn, $sec) = split /(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/, $ref_ligne->[3];
    $fin = Mktime($annee, $mois, $jour, $heure, $mn, $sec);
    $fin = ($fin > $tps_fin) ? $tps_fin : $fin;
	#@$ref_ligne contient 12 élements
    #Le 1er 1 (indice 15)pour stocker la taille de la ligne la plus grande dont fait partie le rdv,
    #Le tableau anonyme (indice 16) permet de stocker l'indice des rdv précédents
    #3ième zéro (indice 17) pour la position par rapport au div cal_visu
    #4ième zéro (indice 18) pour la taille du div rdv
    #Le tableau anonyme (indice 19) permet de stocker l'indice des rdv suivants
    # 5ième zéro (indice 20) stocke la position du rdv dans $echelle_tps{$tps}
    # 1er -1 (indice 21) stocke le N° de la zone d'appartenance du rdv
    push @heures_rdv, [ @$ref_ligne, $deb, $fin, 1, [ ], 0, 0, [ ], 0, -1, 0 ];
#    print "RDV : @$ref_ligne -- sa taille est de ", scalar(@$ref_ligne), $::cgi->br();
  }
}

sub db_recherche_liste_jours_rdv {
  my ($nb_jours) = @_;
  my ($ref_ligne, $jour, $mois, $annee);
  $date_deb = "$jours_cal[0]->[1]-$jours_cal[0]->[2]-$jours_cal[0]->[3] 00:00:00";
  $date_fin = "$jours_cal[$#jours_cal]->[1]-$jours_cal[$#jours_cal]->[2]-$jours_cal[$#jours_cal]->[3] 23:59:59";
  my $liste_jours = "SELECT debut FROM rdv WHERE id_user = ".$::dbh->quote($::collaborateur[0])." AND debut >= ".$::dbh->quote($date_deb)." AND debut <= ".$::dbh->quote($date_fin)." ORDER BY debut ASC";
#  my $liste_jours = "SELECT * FROM rdv WHERE id_user = ".$::dbh->quote($::collaborateur[0])." AND debut >= ".$::dbh->quote($date_deb);
#  print "sql = $liste_jours", $::cgi->br();
  my $sth = $::dbh->prepare($liste_jours);
  $sth->execute();
  while(($ref_ligne) = $sth->fetchrow_array()) {
#    print "ref_ligne = $ref_ligne", $::cgi->br();
    ($annee, $mois, $jour) = (split /(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/, $ref_ligne)[1..3];
    push @liste_jours, $ref_ligne;
    if(exists $liste_jours{"$annee $mois $jour"}) {
      $liste_jours{"$annee $mois $jour"}++;
    }
    else {
      $liste_jours{"$annee $mois $jour"} = 1;
    }
  }
}

1;