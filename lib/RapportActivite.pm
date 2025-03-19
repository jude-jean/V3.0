package RapportActivite;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(gestion_ra);

use Date::Calc qw(:all);
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Time::Local;
use Encode qw(encode decode);

my $annee_debut = 2003;
my @mois = (['Janvier', 1], ['Février', 2], ['Mars',3], ['Avril',4], ['Mai', 5], ['Juin', 6], ['Juillet', 7], ['Août', 8], ['Septembre', 9], ['Octobre', 10], ['Novembre', 11], ['Décembre', 12]);
my ($annee_active, $mois_actif, $annee_in, $mois_in, $jour_in);
my (@date);
my $periode_visu = 5;  # doit �tre sup�rieur � 2
my (@ra, @ra_astreinte, @ra_comment, @ra_global, @ra_hsup, @ra_presence);
my @clients;
my $flag_ra_global;
my ($action, $client_id, $ra_id);
my $decodeMoisActif;
my ($nb_jours, $mois_actif_num);

#my %action = (
# 'creation'              => \&creer_ra,
# 'edition'               => \&editer_ra,
# 'suppression'           => \&supprimer_ra,
# 'sauvegarde'            => \&sauvegarder_ra,
# 'validation'            => \&valider_ra,
#);

#Document de gestion des rapports d'activit�s pour un utilisateur
sub gestion_ra {
#  my $actif = shift;
#  return unless $actif;
#  return unless $main::id;
#  my $fonction;
#  $action = $main::cgi->param('action');
#  if(defined($action)) {
#    if(defined($fonction = $action{$action})) {
#      $fonction->();
#    }
#    else {
#      print $main::cgi->h3("Pas d'action d�finie pour $action");
#    }
#  }
#  else {
#  my $smenu = $cgi->param('smenu')|| 'identification';
    print $main::cgi->h1("Gestion des rapports d'activit&eacute;s du compte $main::collaborateur[3]");
    gestion_date_entree();
    affiche_menu_annuel();
#  print $main::cgi->div(); # Pourcontrer l'effet du float left.
    print $main::cgi->br;
    info_menu_mensuel();
    affiche_ecran_mensuel();

    &main::menu_social(0xFD);
#  }
}

sub gestion_date_entree {
  my ($multiple, $annee_ra);
  ($annee_in, $mois_in, $jour_in) = split /-/, $main::collaborateur[5];
#  print "La date d'entr�e dans la soci�t� est $jour_in, $mois_in, $annee_in", $main::cgi->br;
  $annee_ra = ($main::annee - 2 > $annee_in) ? $main::annee -2 :$annee_in;
#  print "tableau des dates : ";
  if($annee_ra == $annee_in) {
    $date[0] = [$annee_ra, $mois_in, 0];#permet de d�sactiver les mois pr�c�dents l'entr�e dans la soci�t�
  }
  else {
    $date[0] = [$annee_ra, 0, 0];
  }

  for(my $i = 1; $i < $periode_visu; $i++) {
      $date[$i] = [$annee_ra + $i, 0, 0];
#    print "$date[$i]->[0], $date[$i]->[1], $date[$i]->[2]", $main::cgi->br;
  }
}

sub recherche_ra {
  my ($ra, $mois_actif_num);
  if (defined $mois_actif) {
    foreach (@mois) {
#      print "$_->[0] $_->[1]";
      if($_->[0] eq $mois_actif) {
        $mois_actif_num = $_->[1];
        last;
      }
    }
  }
  elsif($annee_active == $main::annee) { # L'utilisateur a s�lectionn� une ann�e
    $mois_actif_num = $main::mois;
  }
  else {
      $mois_actif_num = 1; # C'est le mois de janvier
  }
  my $sql = "SELECT * FROM ra WHERE (idcollaborateur = ".$main::dbh->quote($main::collaborateur[0]).") AND (annee = ".$main::dbh->quote($annee_active).") AND (mois = ".$main::dbh->quote($mois_actif_num).")";
  print "sql = $sql", $main::cgi->br;
  my $sth = $main::dbh->prepare($sql);
  $sth->execute;
  while($ra = $sth->fetchrow_arrayref) {
    push @ra, [ @$ra ];
  }
  if(defined $ra[0]) {
    for(my $i = 0; $i < @ra; $i++) {
      $sql = "SELECT * FROM ra_presence, ra_hsup, ra_astreinte, ra_commentaire WHERE (ra_presence.id = ".$main::dbh->quote($ra[$i]->[0]).") AND (ra_hsup.id = ".$main::dbh->quote($ra[$i]->[0]).") AND (ra_astreinte.id = ".$main::dbh->quote($ra[$i]->[0]).") AND (ra_commentaire.id = ".$main::dbh->quote($ra[$i]->[0]).")";
      print "sql = $sql";
    }
  }
  else {
    print "Pas de rapport d'activités pour $mois_actif $annee_active", $main::cgi->br;
  }
  #print $::cgi->p("mois_actif = $mois_actif");
  #$::nb_jours = Days_in_Month($annee_active, $mois_actif_num);
}

sub info_menu_mensuel {
  my ($client, $ra_id, $ra_etat);
  if (defined $mois_actif) {
    foreach (@mois) {
#      print "$_->[0] $_->[1]";
      if($_->[0] eq $mois_actif) {
        $mois_actif_num = $_->[1];
        last;
      }
    }
  }
  elsif($annee_active == $main::annee) { # L'utilisateur a s�lectionn� une ann�e
    $mois_actif_num = $main::mois;
    $mois_actif = $mois[$mois_actif_num -1]->[0];
  }
  else {
      $mois_actif_num = 1; # C'est le mois de janvier
      $mois_actif = 'Janvier';
  }
  my $sql = "SELECT t1.nom, t1.id FROM client t1, affectation t2 WHERE (t1.id = t2.idclient) AND (t2.idcollaborateur = ".$main::dbh->quote($main::collaborateur[0]).") AND t1.actif = '1'";
#  print "sql = $sql", $main::cgi->br;
  my $sth = $main::dbh->prepare($sql);
  $sth->execute;
  while($client = $sth->fetchrow_arrayref) {
    push @clients, [ @$client, 0, 0 ];# [nom_du_client, client_id, ra_id, ra_etat]
  }
  push @clients, ["Technologies et Services", 0, 0, 0];
  foreach (@clients) {
    $sth = $main::dbh->prepare("SELECT id, valider FROM ra WHERE idclient = ? AND idcollaborateur = ? AND annee = ? AND mois = ? GROUP BY id");
    $sth->execute($_->[1], $main::collaborateur[0], $annee_active, $mois_actif_num);
    while(($ra_id, $ra_etat) = $sth->fetchrow_array) {
      $_->[2] = $ra_id;
      $_->[3] = $ra_etat;
    }
#    print "$_->[0] << $_->[1] $_->[2] $_->[3]>>" , $main::cgi->br;
  }
  $sth = $main::dbh->prepare("SELECT valider FROM ra_global WHERE idcollaborateur = ".$main::dbh->quote($main::collaborateur)." AND annee = ".$main::dbh->quote($annee_active)." AND mois = ".$main::dbh->quote($mois_actif));
  $sth->execute();
  ($flag_ra_global) = $sth->fetchrow_array;
  print $::cgi->p("annee_active = $annee_active, mois_actif = $mois_actif_num, decodeMoisActif = $decodeMoisActif");
  $nb_jours = Days_in_Month($annee_active, $mois_actif_num);
  print $::cgi->p("nb_jours = $nb_jours");
}


sub affiche_menu_annuel {
  my $debut;
  $annee_active = param('annee') || $main::annee; #Valeur par d�faut
  $mois_actif = param('mois'); #|| $mois[$main::mois]; #Valeur par d�faut
  $decodeMoisActif = decode('utf-8', $mois_actif);
#  info_menu_mensuel();
  print "\n", $main::cgi->start_div({-id => 'menu_gestion_ra'}),
    $main::cgi->start_ul();
  if($date[0]->[0] == $annee_in) {
    if($date[0]->[0] == $annee_active) {
      print "\n", $main::cgi->start_li({-id =>'active'}), $main::cgi->a({-class => 'active', -href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&ident_id=$main::id"}, "$date[0]->[0]");
      print "\n", $main::cgi->start_div({-class => 'menu_gestion_ra_mois'}), $main::cgi->start_ul();

      unless(defined($mois_actif)) {
        if($date[0]->[0] == $main::annee) {
          $mois_actif = $mois[$main::mois - 1]->[0];
        }
        else {
          $mois_actif = $mois[$mois_in - 1]->[0];
        }
      }
      for(my $j = 0; $j < @mois; $j++) {
        $decodeMoisActif = decode('utf-8', $mois[$j]->[0]);
        if($mois[$j]->[1] < $mois_in) {
          if($j == 0) {
            print "\n", $main::cgi->li({-id=>'debut_mois', -class => 'inactif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&ident_id=$main::id", -onclick => 'return false'}, decode('utf-8', $mois[$j]->[0])));
          }
          elsif($j == $#mois) {
            print "\n", $main::cgi->li({-id=>'fin_mois', -class => 'inactif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&ident_id=$main::id", -onclick => 'return false'}, decode('utf-8', $mois[$j]->[0])));
          }
          else {
            print "\n", $main::cgi->li({-class => 'inactif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&ident_id=$main::id", -onclick => 'return false'}, decode('utf-8', $mois[$j]->[0])));
          }
        }
        elsif($mois[$j]->[0] eq $mois_actif) {
          #print "\n", $main::cgi->li({-id=>'actif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
          print "\n", $main::cgi->li({-id=>'actif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&mois=$decodeMoisActif&ident_id=$main::id"}, $decodeMoisActif));
        }
        else {
          if($j==0) {
            #print "\n", $main::cgi->li({-id=>'debut_mois'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            print "\n", $main::cgi->li({-id=>'debut_mois'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&mois=$decodeMoisActif&ident_id=$main::id"}, $decodeMoisActif));
          }
          elsif($j == $#mois) {
            print "\n", $main::cgi->li({-id=>'fin_mois'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&mois=$decodeMoisActif&ident_id=$main::id"}, $decodeMoisActif));
          }
          else {
            print "\n", $main::cgi->li($main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?&annee=$annee_in&mois=$decodeMoisActif&ident_id=$main::id"}, $decodeMoisActif));
          }
        }
      }
    }
    else {# L'ann�e n'est pas active
      print "\n", $main::cgi->start_li({-id =>'debut_annee'}), $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&ident_id=$main::id"}, "$date[0]->[0]");
      print "\n", $main::cgi->start_div({-class => 'menu_gestion_ra_mois'}), $main::cgi->start_ul();
      for(my $j = 0; $j < @mois; $j++) {
        if($mois[$j]->[1] < $mois_in)  {
          print "\n", $main::cgi->li({-class => 'inactif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&ident_id=$main::id", -onclick => 'return false'}, decode('utf-8', $mois[$j]->[0])));
        }
        else {
          print "\n", $main::cgi->li($main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$annee_in&mois=$>decodeMoisActif&ident_id=$main::id"}, $decodeMoisActif));
        }
      }
    }
    print "\n", $main::cgi->end_ul(), $main::cgi->end_div(), $main::cgi->end_li();
    $debut = 1;
  }
  else {
    $debut = 0;
  }
  for(my $i = $debut; $i < $periode_visu; $i++) {
    if(($date[$i]->[0] == $annee_active) && ($date[$i]->[0] == $main::annee)) {
      print "\n", $main::cgi->start_li({-id =>'active'}), $main::cgi->a({-class => 'active', -href => "$::rep_pl/rapports_activites/show.pl?annee=$main::annee&ident_id=$main::id"}, "$date[$i]->[0]");
      print "\n", $main::cgi->start_div({-class => 'menu_gestion_ra_mois'}), $main::cgi->start_ul();
      if(defined ($mois_actif)) {
        for(my $j = 0; $j < @mois; $j++) {
          if($mois[$j]->[0] eq $mois_actif) {
            print "\n", $main::cgi->li({-id =>'actif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
          }
          else {
            if($j == 0) {
              print "\n", $main::cgi->li({-id=>'debut_mois'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
            elsif($j == $#mois) {
              print "\n", $main::cgi->li({-id=>'fin_mois'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
            else {
              print "\n", $main::cgi->li($main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
          }
        }
      }
      else {
        for(my $j = 0; $j < @mois; $j++) {
          if(($j + 1) == $main::mois) { # On traite le N� de mois
            print "\n", $main::cgi->li({-id =>'actif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
          }
          else {
            if($j == 0) {
              print "\n", $main::cgi->li({-id=>'debut_mois'},$main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
            elsif($j == $#mois) {
              print "\n", $main::cgi->li({-id=>'fin_mois'},$main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
            else {
              print "\n", $main::cgi->li($main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
          }
        }
        $mois_actif = $mois[$main::mois - 1]->[0];
      }
      print "\n", $main::cgi->end_ul(), $main::cgi->end_div(), $main::cgi->end_li();
    }
    elsif(($date[$i]->[0] == $annee_active) && ($date[$i]->[0] != $main::annee)) {
      print "\n", $main::cgi->start_li({-id =>'active'}), $main::cgi->a({-class => 'active', -href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&ident_id=$main::id"}, "$date[$i]->[0]");
      print "\n", $main::cgi->start_div({-class => 'menu_gestion_ra_mois'}), $main::cgi->start_ul();
      if(defined ($mois_actif)) {
        for(my $j = 0; $j < @mois; $j++) {
          if($mois[$j]->[0] eq $mois_actif) {
            print "\n", $main::cgi->li({-id =>'actif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
          }
          else {
            if($j == 0) {
              print "\n", $main::cgi->li({-id=>'debut_mois'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
            elsif($j == $#mois) {
              print "\n", $main::cgi->li({-id=>'fin_mois'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
            else {
              print "\n", $main::cgi->li($main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
            }
          }
        }
      }
      else {
        for(my $j = 0; $j < @mois; $j++) {
          if($j == 0) { # Mois de janvier
            print "\n", $main::cgi->li({-id =>'actif'}, $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
          }
          elsif($j == $#mois) {
            print "\n", $main::cgi->li({-id=>'fin_mois'},$main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
          }
          else {
            print "\n", $main::cgi->li($main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
          }
        }
        $mois_actif = 'Janvier';
      }
      print "\n", $main::cgi->end_ul(), $main::cgi->end_div(), $main::cgi->end_li();
    }
    else {
      if($i == 0) {
        print "\n", $main::cgi->start_li({-id =>'debut_annee'}), $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&ident_id=$main::id"}, "$date[$i]->[0]");
      }
      elsif($i == ($periode_visu - 1)) {
        print "\n", $main::cgi->start_li({-id =>'fin_annee'}), $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&ident_id=$main::id"}, "$date[$i]->[0]");
      }
      else {
        print "\n", $main::cgi->start_li(), $main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&ident_id=$main::id"}, "$date[$i]->[0]");
      }
      print "\n", $main::cgi->start_div({-class => 'menu_gestion_ra_mois'}), $main::cgi->start_ul();
      for(my $j = 0; $j < @mois; $j++) {
          print "\n", $main::cgi->li($main::cgi->a({-href => "$::rep_pl/rapports_activites/show.pl?annee=$date[$i]->[0]&mois=$mois[$j]->[0]&ident_id=$main::id"}, decode('utf-8', $mois[$j]->[0])));
      }
      print "\n", $main::cgi->end_ul(), $main::cgi->end_div(), $main::cgi->end_li();
    }
  }
  print "\n", $main::cgi->end_ul(), $main::cgi->end_div();
}


sub affiche_ecran_mensuel {
  $decodeMoisActif = decode('utf-8', $mois_actif);
  #
  print $main::cgi->start_div({-id => 'ra_ecran_mensuel'}),
    $main::cgi->start_div({-class => 'ra_titre_ecran_mensuel'}), $main::cgi->span(decode('utf-8',"Relevé mensuel pour $mois_actif $annee_active")), $main::cgi->end_div();
  #print "decodeMoisActif = $decodeMoisActif";  
  print $main::cgi->start_div({-class => 'ra_ligne3col', -id => 'ligne1'}),
    $main::cgi->div({-class => 'ra_ligne3col1'}, "Rapports d'activit&eacute;s"),
    $main::cgi->div({-class => 'ra_ligne3col2'}, 'Actions'),
    $main::cgi->div({-class => 'ra_ligne3col3'}, 'Etat'),
    $main::cgi->end_div(); #fin du div ra_ligne3col id=ligne1
  foreach (@clients) {
    print $main::cgi->div({-class =>'ra_ligne3col'});
    if(($_->[2] > 0) && (($_->[3] == 0) || ($_->[3] == 2))) {
    print $main::cgi->div({-class => 'ra_ligne3col1'}, $main::cgi->a({-target =>'Edition', -title => 'Editer', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=edition&annee=$annee_active&mois=$mois_actif&client_id=$_->[1]&ra_id=$_->[2]&ident_id=$main::id"},"$_->[0]"));
    print $main::cgi->start_div({-class => 'ra_ligne3col2'}), $main::cgi->a({-target =>'Edition', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=edition&annee=$annee_active&mois=$mois_actif&nb_jours=$nb_jours&mois_num=$mois_actif_num&client_id=$_->[1]&ra_id=$_->[2]&ident_id=$main::id"}, $main::cgi->img({-src =>"$main::rep/images/page_edit.png", -alt => "Editer-$_->[0]", -title => 'Editer'})),
           "&nbsp", $main::cgi->a({-target =>'Suppression', -title => 'Supprimer', -href => "$::rep_pl/rapports_activites/ra/delete.pl?ident_user=$::collaborateur[3]&action=suppression&annee=$annee_active&mois=$mois_actif&client_id=$_->[1]&ra_id=$_->[2]&ident_id=$::id"}, $main::cgi->img({-src =>"$main::rep/images/page_delete.png", -alt => "Supprimer-$_->[0]", -title => 'Supprimer'})),
           "&nbsp", $main::cgi->a({-target =>'Facturation', -title => 'Facturer', -href => "$::rep_pl/rapports_activites/ra/facture.pl?ident_user=$::collaborateur[3]&action=facture&annee=$annee_active&mois=$mois_actif&client_id=$_->[1]&ra_id=$_->[2]&ident_id=$::id"}, $main::cgi->img({-src =>"$main::rep/images/euro-16.png", -alt => "Facturer-$_->[0]", -title => 'Facturer'})),
           $main::cgi->end_div();
    print $main::cgi->div({-class => 'ra_ligne3col3'},'A valider');
    }
    elsif(($_->[2] == 0) && (($_->[3] == 0) || ($_->[3] == 2))) {
      #print "decodeMoisActif = $decodeMoisActif"; 
      print $main::cgi->div({-class => 'ra_ligne3col1'}, $main::cgi->a({-target => 'Creation', -title => 'Créer', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=creation&annee=$annee_active&mois=$mois_actif&client_id=$_->[1]&ident_id=$main::id"},"$_->[0]"));
      print $main::cgi->start_div({-class => 'ra_ligne3col2'}), $main::cgi->a({-target => 'Creation', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=creation&annee=$annee_active&mois=$mois_actif&client_id=$_->[1]&ident_id=$main::id"}, $main::cgi->img({-src =>"$main::rep/images/page_blank.png", -alt => decode('utf-8', "Créer-$_->[0]"), -title => decode('utf-8', 'Créer')})), $main::cgi->end_div();
      print $main::cgi->div({-class => 'ra_ligne3col3'},'&nbsp');
    }
    elsif(($_->[2] > 0) && ($_->[3] == 1)) {
      print $main::cgi->div({-class => 'ra_ligne3col1'}, $main::cgi->a({-target =>'Affichage', -title => 'Afficher', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&nb_jours=$nb_jours&mois_num=$mois_actif_num&client_id=$_->[1]&ra_id=$_->[2]&ident_id=$main::id"},"$_->[0]"));
      print $main::cgi->start_div({-class => 'ra_ligne3col2'}), $main::cgi->a({-target =>'Affichage', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&nb_jours=$nb_jours&mois_num=$mois_actif_num&client_id=$_->[1]&ra_id=$_->[2]&ident_id=$main::id"}, $main::cgi->img({-src =>"$main::rep/images/page.png", -alt => "Afficher-$_->[0]", -title => 'Afficher'})), $main::cgi->end_div();
      print $main::cgi->div({-class => 'ra_ligne3col3'},'Validé');

    }
    print $main::cgi->end_div(); #fin du div ligne3col
  }
  print $main::cgi->div({-class =>'ra_ligne3col'});
  if(defined($flag_ra_global)) {
    if(($flag_ra_global == 0) || ($flag_ra_global == 2)) {# Cas pas valid� ou invalid� temporairement
      print  $main::cgi->div({-id => 'ra_ligne3col1_fin'}, $main::cgi->a({-target => 'Affichage', -title =>'Afficher', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&client_id=-1&ra_id=-1&ident_id=$main::id"},'Global'));
      print  $main::cgi->start_div({-id => 'ra_ligne3col2_fin'}), $main::cgi->a({-target => 'Affichage', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&nb_jours=$nb_jours&mois_num=$mois_actif_num&client_id=-1&ra_id=-1&ident_id=$main::id"}, $main::cgi->img({-src =>"$main::rep/images/page.png", -alt => "Affichage du rapport d'activités", -title => 'Afficher'})),
              "&nbsp", $main::cgi->a({-href => "$::rep_pl/rapports_activites/ra/delete.pl?ident_user=$::collaborateur[3]&action=suppression&annee=$annee_active&mois=$mois_actif&client_id=-1&ra_id=-1&ident_id=$::id"}, $::cgi->img({-src =>"$main::rep/images/page_delete.png", -alt => "Suppression du rapport d'activit�", -title => 'Supprimer'})), $main::cgi->end_div();
      if($flag_ra_global == 0) {
        print  $main::cgi->div({-id => 'ra_ligne3col3_fin'},'Pas valid�');
      }
      else {
       print  $main::cgi->div({-id => 'ra_ligne3col3_fin'},'Invalid� temporairement');
      }
    }
    else { # Cas ra global valid�
      print  $main::cgi->div({-id => 'ra_ligne3col1_fin'}, $main::cgi->a({-target => 'Affichage', -title =>'Afficher', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&client_id=-1&ra_id=-1&ident_id=$main::id"},'Global'));
      print  $main::cgi->start_div({-id => 'ra_ligne3col2_fin'}), $main::cgi->a({-target => 'Affichage', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&nb_jours=$nb_jours&mois_num=$mois_actif_num&client_id=-1&ra_id=-1&ident_id=$main::id"}, $main::cgi->img({-src =>"$main::rep/images/page.png", -alt => "Affichage du rapport d'activités", -title => 'Afficher'})), $main::cgi->end_div();
      print  $main::cgi->div({-id => 'ra_ligne3col3_fin'},'Valid�');
    }
  }
  else { # Cas ou il n'y a pas de ra global
      print  $main::cgi->div({-id => 'ra_ligne3col1_fin'}, $main::cgi->a({target => 'Affichage', -title =>'Afficher', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&client_id=-1&ra_id=-1&ident_id=$main::id"},'Global'));
      print  $main::cgi->start_div({-id => 'ra_ligne3col2_fin'}), $main::cgi->a({target => 'Affichage', -href => "$::rep_pl/rapports_activites/ra/show.pl?ident_user=$main::collaborateur[3]&action=affichage&annee=$annee_active&mois=$mois_actif&nb_jours=$nb_jours&mois_num=$mois_actif_num&client_id=-1&ra_id=-1&ident_id=$main::id"}, $main::cgi->img({-src =>"$main::rep/images/page.png", -alt => "Affichage du rapport d'activités", -title => 'Afficher'})), $main::cgi->end_div();
      print  $main::cgi->div({-id => 'ra_ligne3col3_fin'},'&nbsp');
  }
  print  $main::cgi->end_div(); #fin du div ligne3col
  print $main::cgi->end_div(); #Fin du div ecran_mensuel
}

#sub creer_ra {
#  print $main::cgi->start_form(-target=> "Cr�ation d'un rapport d'activit�");
#  print $main::cgi->h1("Creation");
#  print $main::cgi->end_form();
#}
#
#sub editer_ra {
#  print $main::cgi->h1("Edition d'un rapport d'activit�");
#}

#sub supprimer_ra {
#  print $main::cgi->h1("Suppression d'un rapport d'activit�");
#}

#sub sauvegarder_ra {
#  print $main::cgi->h1("Sauvegarde d'un rapport d'activit�");
#}

#sub valider_ra {
#  print $main::cgi->h1("Validation d'un rapport d'activit�");
#}

1;