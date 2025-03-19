# Affichage dans un div gauche et dans un div droite => 2 colonnes
  print "\n", $cgi->start_div({-id => 'affiche_donnees_sociales'}), "\n";
  print $cgi->start_div({-id=> 'infos_generales'}), "\n",
        $cgi->span("Informations générales >> Date d'arrivée : $date[2]\/$date[1]\/$date[0],",
        "Temps de présence :",($Da >0)?"$Da an(s) ":'',($Dm >0)?"$Dm mois ":'',($Dj>0)?"$Dj jour(s)":'', $cgi->br, "Planning prévisionnel :");

  print $cgi->start_div({-id=>'col_gauche'}), "Edition Rapport d'Activités :",
     $cgi->br, "Prochaine formation :",
     $cgi->br, "Convocation visite médicale :",
     $cgi->br, "Convocation entretien d'évaluation :",
     $cgi->br, "Négociation salariale :",
     $cgi->end_div(), "\n";
  print $cgi->start_div({-id => 'col_droite'}), date_edition_ra(),
     $cgi->br, "",
     $cgi->br, date_visite_medicale(@date, $Da, $Dm, $Dj),
     $cgi->br, date_entretien(@date),
     $cgi->br, date_negociation(@date, $Da, $Dm, $Dj),
     $cgi->br, "",
     $cgi->end_div(), "\n";
  print $cgi->end_div(); # Fin du Div info_générales
  affiche_conges_payes(@date, $Da, $Dm, $Dj);
  affiche_rtt(@date, $Da,$Dm, $Dj);
   print $cgi->end_div();    # fin du div affiche_données_sociales
   menu_social(0xe);
}

sub affiche_conges_payes {
  my $acquis_now;
  my ($arrondi, $res);
  my $acquis_avant;
  my $pris_now;
  my $pris_avant;
  my ($prendre_now, $prendre_avant);
  $res = 2.5*$jour/Days_in_Month($annee, $mois);
  $arrondi = $res <= 0.5 ? 0.5 :
             $res <= 1   ? 1   :
             $res <= 1.5 ? 1.5 :
             $res <= 2   ? 2   : 2.5;

  $acquis_now = ($mois == 1)? $arrondi:($mois -1)*2.5 + $arrondi;
  $acquis_avant = conges_payes_anterieurs(@_);
  ($pris_now, $pris_avant) = conges_pris(@_);
  $prendre_now = $acquis_now - $pris_now;
  $prendre_avant = $acquis_avant - $pris_avant;

  print $cgi->start_div({-id => 'affiche_conges_payes'});
  print $cgi->div({-class => 'Titre'}, 'Décompte des congés payés');
  print $cgi->start_div({-class => 'Libelle'});
  print $cgi->br, "Année $annee ",
        $cgi->br, 'Années antérieures ',
        $cgi->br, 'Total ' ;
  print "\n", $cgi->end_div(); # Fin du div libelle
  print $cgi->start_div({-class => 'Acquis'}), $cgi->span({-class => 'L1'},'Acquis');
  print $cgi->br, $acquis_now,
        $cgi->br, $acquis_avant,
        $cgi->br, $acquis_now + $acquis_avant;
  print "\n", $cgi->end_div(); # Fin du div Acquis

  print $cgi->start_div({-class => 'Pris'}), $cgi->span({-class => 'L1'}, 'Pris');
  print $cgi->br, $pris_now,
        $cgi->br, $pris_avant,
        $cgi->br, $pris_now + $pris_avant;
  print "\n", $cgi->end_div(); # Fin du div Pris

  print $cgi->start_div({-class => 'A_prendre'}), $cgi->span({-class => 'L1'}, 'A prendre');
  print $cgi->br, $prendre_now,
        $cgi->br, $prendre_avant,
        $cgi->br, $prendre_now + $prendre_avant;
  print "\n", $cgi->end_div(); # Fin du div A prendre
  print "\n", $cgi->end_div(); # Fin du div affiche_conges_payes
}


sub affiche_rtt {
  my ($a_in, $m_in, $j_in, $Da, $Dm, $Dj) = @_;
  my $acquis_now;
  my ($arrondi, $res);
  my $acquis_avant;
  my $pris_now;
  my $pris_avant;
  my ($prendre_now, $prendre_avant);

  $acquis_now = ($mois -1)*0.5;
  $acquis_avant = rtt_anterieur(@_);
  $acquis_avant = (defined($acquis_avant)) ? $acquis_avant : 0;
  #$acquis_avant = ($mois < 4)? 6: 0;
  ($pris_now, $pris_avant) = rtt_pris(@_, $acquis_avant);
  $prendre_now = $acquis_now - $pris_now;
  $prendre_avant = $acquis_avant - $pris_avant;

  print $cgi->start_div({-id => 'affiche_rtt'});
  print $cgi->div({-class => 'Titre'}, 'Décompte des RTT');
  print $cgi->start_div({-class => 'Libelle'});
  print $cgi->br, "Année $annee ",
        $cgi->br, "Année ",$annee - 1,
        $cgi->br, 'Total ' ;
  print "\n", $cgi->end_div(); # Fin du div libelle
  print $cgi->start_div({-class => 'Acquis'}), $cgi->span({-class => 'L1'},'Acquis');
  print $cgi->br, "$acquis_now",
        $cgi->br, "$acquis_avant",
        $cgi->br, $acquis_now + $acquis_avant;
  print "\n", $cgi->end_div(); # Fin du div Acquis

  print $cgi->start_div({-class => 'Pris'}), $cgi->span({-class => 'L1'}, 'Pris');
  print $cgi->br, $pris_now,
        $cgi->br, $pris_avant,
        $cgi->br, $pris_now+$pris_avant;
  print "\n", $cgi->end_div(); # Fin du div Pris

  print $cgi->start_div({-class => 'A_prendre'}), $cgi->span({-class => 'L1'},'A prendre');
  print $cgi->br, $prendre_now,
        $cgi->br, $prendre_avant,
        $cgi->br, $prendre_now + $prendre_avant;
  print "\n", $cgi->end_div(); # Fin du div A prendre
  print "\n", $cgi->end_div(); # Fin du div affiche_rtt

}
