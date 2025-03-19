#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Date::Calc qw(:all);
use Time::Local;
use RapportActivite qw(gestion_ra);
use Etechnoserv;
use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);


# Déclaration du répertoire de base
our $rep;

my @script = (
        { 'language'           => "javascript",
          'src'                => "$rep/scripts/ets_cal.js"
        },
        {
          'language'           => "javascript",
          'src'                => "$rep/scripts/mini_cal.js"
        },
);

# Déclaration des feuilles de styles
my @liens = [
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/ets_cal.css",
         'media'           => 'screen',
       }),
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/ets_cal_print.css",
         'media'           => 'print',
       }),
];

my @boutons_bas = ( ["Données sociales", 0x1],
                    ["Rapports d'activités", 0x2],
                    ["Calendrier", 0x4],
                    ["Compte", 0x8]);

# Déclaration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
my %parametres = ();
our $dbh;
our $tps_connexion = 600; # Délai de connexion sans inactivité

our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
our $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);
$mois += 1;
$annee += 1900;

# Date de création de Technologies et Services
our @date_ts = (2003, 1, 1);
my @msg_maj;
my $ecran_actuel;

my %action = (
 'creation'              => [ \&creer_rdv, 'Création' ],
 'edition'               => [ \&editer_rdv,'Edition' ],
 'suppression'           => [ \&supprimer_rdv, 'Suppression' ],
 'affichage'             => [ \&afficher_rdv, 'Affichage' ],
);
my %s_action = (
 'Sauvegarder'            => \&sauvegarder_rdv,
 'Enregistrer et fermer'  => \&sauve_et_ferme_rdv,
 'Visualiser'             => \&visualiser_rdv,
 'Valider'            => \&valider_rdv,
 'Imprimer'           => \&imprimer_rdv,
 'Editer'             => \&ouvrir_rdv,
 'Supprimer'          => \&delete_rdv,
 'Périodicité'        => \&periodicite_rdv,
);

my (%rdv, @list_rdv, %list_rdv);
my @emplt = ("4 rue de la boëtie", "121, Bl du général de Gaulle", "45, avenue Matignon");

my (@list_jours_mois, @list_mois, @list_annee, @list_heures_debut, @duree, $ind_annee_debut, $ind_annee_fin, $ind_heure_debut, $ind_heure_fin, @list_heures_fin);
my ($heure_debut, $heure_fin, $tps_debut, $tps_fin, $tps, $pas, @date_debut, @date_fin, $idx_duree);
my $nb_jours_mois = 31;
my ($msg_maj, $msg_plage_periodicite);

my @mois = (['Janvier', 1, 'Jan'], ['Février', 2, 'Fév'], ['Mars',3, 'Mars'], ['Avril',4, 'Avr'], ['Mai', 5, 'Mai'], ['Juin', 6, 'Juin'], ['Juillet', 7, 'Juil'], ['Août', 8, 'Août'], ['Septembre', 9, 'Sep'], ['Octobre', 10, 'Oct'], ['Novembre', 11, 'Nov'], ['Décembre', 12, 'Déc']);
my @jours = (['Lundi', 1, 'Lun'], ['Mardi', 2, 'Mar'], ['Mercredi',3, 'Mer'], ['Jeudi',4, 'Jeu'], ['Vendredi', 5, 'Ven'], ['Samedi', 6, 'Sam'], ['Dimanche', 7, 'Dim']);
my @list_rappels = ("5 minutes", "10 minutes", "15 minutes", "30 minutes", "1 heure", "2 heures", "3 heures", "4 heures", "5 heures", "6 heures", "7 heures", "8 heures", "9 heures", "10 heures", "11 heures", "0.5 jours", "1 jour", "2 jours", "3 jours", "4 jours", "1 semaine", "2 semaines");
my @list_dispo = ('Libre', 'Provisoire', 'Occupé(e)', 'Absent(e) du bureau');
my @list_categories = ('Aucune', 'Bureau', 'Important', 'Personnel', 'Congé', 'Participation obligatoire', 'Déplacement requis', 'Nécessite préparation', 'Anniversaire', 'Appel téléphonique');
my @list_periodicite = ('Quotidienne', 'Hebdomadaire', 'Mensuelle', 'Annuelle');
my @choix = ('1', '2');
my %qlabel = ( 1 => '', 2 => '');
my @hchoix = (1, 2, 3, 4, 5, 6, 7);
my %hlabel =(1=> 'lundi', 2 => 'mardi', 3 => 'mercredi', 4 => 'jeudi', 5 => 'vendredi', 6 => 'samedi', 7 => 'dimanche');
my @mchoix = (1, 2, 3, 4, 5);
my %mlabel = (1 => 'premier', 2 => 'deuxième', 3 => 'troisième', 4 => 'quatrième', 5 => 'dernier');
my @mchoix2 = (8, 9, 1, 2, 3, 4, 5, 6, 7);
my %mlabel2 = (1=> 'lundi', 2 => 'mardi', 3 => 'mercredi', 4 => 'jeudi', 5 => 'vendredi', 6 => 'samedi', 7 => 'dimanche', 8 => 'jour', 9 => 'jour ouvré');
my @achoix = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
my %alabel = (1=>'janvier', 2=>'février', 3=>'mars', 4=>'avril', 5=>'mai', 6=>'juin', 7=>'juillet', 8=>'août', 9=>'septembre', 10=>'octobre', 11=>'novembre', 12=>'décembre');

our $cgi = new CGI;

#Connexion à la base de donnée.
$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "problème de connexion à la base de données collaborateur : $!";

lecture_parametres(\%parametres);
if(defined($parametres{ident_id})) {
  @collaborateur = info_id($parametres{ident_id});
# Il faudra décommenter cette partie pour faire une demande de connexion en cas
# de délai dépassé.
#  if(verif_tps_connexion() == 0) {# délai dépassé
#    @collaborateur = undef;
#    $id = undef;
#  }
}
if(exists($parametres{s_action})) {
  if(exists($s_action{$parametres{s_action}})) {
    $s_action{$parametres{s_action}}->();
  }
  else {
    entete_standard();
    print "Pas de fonction définie pour le paramètre $parametres{s_action}";
  }
}
elsif(exists($parametres{action})) {
  if(exists($action{$parametres{action}})) {
    $action{$parametres{action}}->[0]->();
  }
  else {
    entete_standard();
    print "Pas de fonction définie pour le paramètre $parametres{action}";
  }
}
else {
  entete_standard();
  visu_parametres(\%parametres);
  print "Pas de paramètre 'action' ni 's_action' défini dans la requete. Fin du programme";
  exit;
}


exit;
##################### Début des fonctions #####################################
sub entete_standard {
	print $cgi->header(-expires =>'0');
	print $cgi->start_html({-head =>@liens, -Title => "Gestion de calendrier - V1.0", -script => \@script,
              -base => 'true', -onLoad=>'return ecran_charge();'});
}

sub creer_rdv {
  entete_standard();
  calcul_data_rdv();
  visu_parametres(\%parametres);
  affiche_ecran_rdv();
  print $cgi->end_html();
}

sub editer_rdv {
  entete_standard();
  calcul_data_rdv();
  visu_parametres(\%parametres);
  recherche_autres_rdv();
  recherche_emplacements();
  affiche_ecran_rdv();
  print $cgi->end_html();
}

sub sauve_et_ferme_rdv {
  print $cgi->header(-expires =>'0');
  print $cgi->start_html({-head =>@liens, -Title => "Gestion de calendrier - V1.0",
    -script => \@script, -base => 'true', -onLoad => 'return recharge_calendrier(1);'});

#  lecture_parametres(\%parametres);
  visu_parametres(\%parametres);
#  print "Info dans le tableau collaborateur : @collaborateur", $cgi->br();
  db_enregistre_rdv();
  print $cgi->hidden(-name => "s_action", value => "Enregistrer et fermer");
  print $cgi->end_html();
}

sub delete_rdv {
  print $cgi->header(-expires =>'0');
  print $cgi->start_html({-head =>@liens, -Title => "Gestion de calendrier - V1.0",
    -script => \@script, -base => 'true', -onLoad => 'return recharge_calendrier(0);'});

#  lecture_parametres(\%parametres);
#  visu_parametres(\%parametres);
#  print "Info dans le tableau collaborateur : @collaborateur", $cgi->br();
  db_supprime_rdv();
  print $cgi->hidden(-name => "s_action", value => "Supprimer");
  print $cgi->end_html();
}

sub imprimer_rdv {
  print $cgi->header();
  print $cgi->start_html({-head =>@liens, -Title => "Gestion de calendrier - V1.0",
            -script => \@script, -base => 'true'});
  affiche_ecran_rdv_print();
  print $cgi->end_html();
}

sub periodicite_rdv {
  lecture_parametres(\%parametres);
  if(exists($parametres{bouton})) {
    if(($parametres{bouton} eq 'OK') || ($parametres{bouton} eq 'Supprimer')) {
# Pour l'instant, on edite le rdv sans prise en compte des données périodicité
     print $cgi->header(-expires =>'0');
     print $cgi->start_html({-head =>@liens, -Title => "Gestion de calendrier - V1.0",
            -script => \@script, -base => 'true', -onLoad => 'return ecran_charge();'});
     visu_parametres(\%parametres);
     calcul_data_rdv();
     recherche_autres_rdv();
     recherche_emplacements();
     affiche_ecran_rdv();
     print $cgi->end_html();
    }
    else {
      print $cgi->redirect("$ENV{SCRIPT_NAME}?$ENV{QUERY_STRING}");
    }
  }
  else {
    print $cgi->header(-expires =>'0');
    print $cgi->start_html({-head =>@liens, -Title => "Gestion de calendrier - V1.0",
            -script => \@script, -base => 'true', -onLoad=> 'return affiche_periodicite_choisie();'});
    affiche_ecran_periodicite();
    print $cgi->end_html();
  }
}



my $ind = 0;
sub calcul_data_rdv {
#my ($aa, $mm, $jj, $hh, $mn, $ss, @delta, @sp_heure, $st_hh, $st_mn, $st_delta);
## Calcul du pas
  FIN : {
    if($parametres{affichage_heure} eq '5') {
      $pas = 60*60;
      last FIN;
    }
    if($parametres{affichage_heure} eq '4') {
      $pas = 30*60;
      last FIN;
    }
    if($parametres{affichage_heure} eq '3') {
      $pas = 15*60;
      last FIN;
    }
    if($parametres{affichage_heure} eq '2') {
      $pas = 10*60;
      last FIN;
    }
  }
## Génération des listes de jours et de mois
    foreach (1..$nb_jours_mois) {
      push @list_jours_mois, $_;
    }
    foreach (0.. $#mois) {
      push @list_mois, $mois[$_]->[0];
    }
####### Calcul pour la fonction de création #################################
  if($parametres{action} eq 'creation') {
    if(exists $parametres{bouton}) {
# L'utilisateur a utilisé l'écran périodicité et cliqué sur OK avant de créer le rdv
      calcul_data_rdv_edition();
      return;
    }
    calcul_data_rdv_creation();
  }
####### Calcul pour la fonction d'Edition #################################
  elsif($parametres{action} eq 'edition') {
    calcul_data_rdv_edition();
  }
}


sub affiche_ecran_rdv {
#  print "La valeur de heure de fin est $list_heures_fin[$ind_heure_fin]", $cgi->br();
  affiche_entete_impression();
  print start_form();
  gestion_des_champs_caches();
  affiche_barre_outils();
  if(length $msg_maj >0) {
    print $cgi->div({-id=>'rdv_msg'}, "$msg_maj");
  }
  else {
    print $cgi->div({-id=>'rdv_msg'},  " ");
  }
  print $cgi->start_div({-id=>'rdv_objet'}), $cgi->label({-class=>'label1', -for=>'rdv_objet'}, 'Objet:');
  if(exists $rdv{objet}) {
    print $cgi->textfield(-name =>'rdv_objet', -size => 40, -default => "$rdv{objet}", -maxlength=>200), $cgi->end_div();
  }
  else {
    print $cgi->textfield(-name =>'rdv_objet', -size => 40, -maxlength=>200), $cgi->end_div();
  }
#  print $cgi->start_div({-id=>'rdv_emplt'}), $cgi->div({-class=>'label1'}, $cgi->label({-for=>'rdv_emplt'}, 'Emplacement:'));
  print $cgi->start_div({-id=>'rdv_emplt'}), $cgi->label({-class=>'label1', -for=>'rdv_emplt'}, 'Emplacement:');
  print $cgi->start_div({-id=>'emplt'});
  if(exists $rdv{lieu}) {
    print $cgi->textfield(-name =>'rdv_emplt', -size => 40, -default => "$rdv{lieu}", -maxlength=>200);
  }
  else {
    print $cgi->textfield(-name =>'rdv_emplt', -size => 40, -maxlength=>200);
  }
  print $cgi->popup_menu(-name =>'rdv_emplt_list', -values =>\@emplt, -onchange =>"return emplt_choisi(this);");
  print $cgi->end_div(), $cgi->end_div(); #Fin du div emplt et du div rdv_emplt
  print $cgi->start_div({-id=>'rdv_debut'}), $cgi->label({-class =>'label_date', -for=>'rdv_debut'}, 'Début:');
  if($parametres{action} eq 'creation') {
    if(exists $parametres{bouton}) {
# La modification des valeurs par défaut s'obtient en modifiant la valeur du parametre car il a déjà été initialisé au premier passage
     $cgi->param(rdv_debut_num_jour => "$rdv{jour_debut}");
     $cgi->param(rdv_debut_mois => "$list_mois[$rdv{mois_debut} -1]");
     $cgi->param(rdv_debut_annee => "$list_annee[$rdv{annee_debut} - $list_annee[0]]");
#      print $cgi->textfield(-name =>'rdv_debut_jour', -size => 4, -maxlength=>4, -default=>"$jours[Day_of_Week($rdv{annee_debut}, $rdv{mois_debut}, $rdv{jour_debut}) - 1]->[2]", -disabled), $cgi->popup_menu(-name=>'rdv_debut_num_jour', -values =>\@list_jours_mois, -default=>"$list_jours_mois[$rdv{jour_debut} -1]", -onchange=>"return debut_num_jour_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_mois', -values =>\@list_mois, -default=>"$list_mois[$rdv{mois_debut} -1]", -onchange=>"return debut_mois_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_annee', -values =>\@list_annee, -default=>"$list_annee[5]", -onchange=>"return debut_annee_choisie(this);");
      print $cgi->textfield(-name =>'rdv_debut_jour', -size => 4, -maxlength=>4, -default=>"$jours[Day_of_Week($rdv{annee_debut}, $rdv{mois_debut}, $rdv{jour_debut}) - 1]->[2]", -disabled), $cgi->popup_menu(-name=>'rdv_debut_num_jour', -values =>\@list_jours_mois, -onchange=>"return debut_num_jour_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_mois', -values =>\@list_mois, -onchange=>"return debut_mois_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_annee', -values =>\@list_annee, -onchange=>"return debut_annee_choisie(this);");
    }
    else {
      print $cgi->textfield(-name =>'rdv_debut_jour', -size => 4, -maxlength=>4, -default=>"$jours[Day_of_Week($parametres{annee}, $parametres{mois}, $parametres{jour}) - 1]->[2]", -disabled), $cgi->popup_menu(-name=>'rdv_debut_num_jour', -values =>\@list_jours_mois, -default=>"$list_jours_mois[$parametres{jour} -1]", -onchange=>"return debut_num_jour_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_mois', -values =>\@list_mois, -default=>"$list_mois[$parametres{mois} -1]", -onchange=>"return debut_mois_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_annee', -values =>\@list_annee, -default=>"$list_annee[5]", -onchange=>"return debut_annee_choisie(this);");
    }
  }
  else {
      print $cgi->textfield(-name =>'rdv_debut_jour', -size => 4, -maxlength=>4, -default=>"$jours[Day_of_Week($rdv{annee_debut}, $rdv{mois_debut}, $rdv{jour_debut}) - 1]->[2]", -disabled), $cgi->popup_menu(-name=>'rdv_debut_num_jour', -values =>\@list_jours_mois, -default=>"$list_jours_mois[$rdv{jour_debut} -1]", -onchange=>"return debut_num_jour_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_mois', -values =>\@list_mois, -default=>"$list_mois[$rdv{mois_debut} -1]", -onchange=>"return debut_mois_choisi(this);"), $cgi->popup_menu(-name=>'rdv_debut_annee', -values =>\@list_annee, -default=>"$list_annee[5]", -onchange=>"return debut_annee_choisie(this);");
  }
  print $cgi->a({-onclick=> "return mini_cal(this);"}, $cgi->img({-id=>'img_mini_cal_hdebut', -src=>"$::rep/images/application_view_detail.png", -alt=>'Mini calendrier'})), $cgi->div({-id=>'mini_cal_hdebut', -name=>'mini_cal_hdebut'}, ' ');
  print $cgi->label({-class =>'label_heure', -for=>'rdv_heure_debut'}, 'Heure:');
  print $cgi->popup_menu(-class=>'heure', -name=>'rdv_heure_debut', -values =>\@list_heures_debut, -default=>"$list_heures_debut[$ind_heure_debut]", -onchange =>"return debut_heure_choisie(this);");
  print $cgi->end_div(); #Fin du div rdv_debut
#  print "La valeur de heure de debut est $list_heures_debut[$ind_heure_debut]", $cgi->br();
  print $cgi->start_div({-id=>'rdv_fin'}), $cgi->label({-class =>'label_date', -for=>'rdv_fin'}, 'Fin:');
  if($parametres{action} eq 'creation') {
    if(exists $parametres{bouton}) {
     $cgi->param(rdv_fin_num_jour => "$rdv{jour_fin}");
     $cgi->param(rdv_fin_mois => "$list_mois[$rdv{mois_fin} -1]");
     $cgi->param(rdv_fin_annee => "$list_annee[$rdv{annee_fin} - $list_annee[0]]");
      print $cgi->textfield(-name =>'rdv_fin_jour', -size => 4, -maxlength=>4, -default=>"$jours[Day_of_Week($rdv{annee_fin}, $rdv{mois_fin}, $rdv{jour_fin}) - 1]->[2]", -disabled), $cgi->popup_menu(-name=>'rdv_fin_num_jour', -values =>\@list_jours_mois, -default=>"$list_jours_mois[$rdv{jour_fin} -1]", -onchange=>"return fin_num_jour_choisi(this);"), $cgi->popup_menu(-name=>'rdv_fin_mois', -values =>\@list_mois, -default=>"$list_mois[$rdv{mois_fin} -1]", -onchange=>"return fin_mois_choisi(this);"), $cgi->popup_menu(-name=>'rdv_fin_annee', -values =>\@list_annee, -default=>"$list_annee[$rdv{annee_fin} - $list_annee[0]]", -onchange=>"return fin_annee_choisie(this);");
    }
    else {
      print $cgi->textfield(-name =>'rdv_fin_jour', -size => 4, -maxlength=>4, -default=>"$jours[$date_fin[7] - 1]->[2]", -disabled), $cgi->popup_menu(-name=>'rdv_fin_num_jour', -values =>\@list_jours_mois, -default=>"$list_jours_mois[$date_fin[2] -1]", -onchange=>"return fin_num_jour_choisi(this);"), $cgi->popup_menu(-name=>'rdv_fin_mois', -values =>\@list_mois, -default=>"$list_mois[$date_fin[1] -1]", -onchange=>"return fin_mois_choisi(this);"), $cgi->popup_menu(-name=>'rdv_fin_annee', -values =>\@list_annee, -default=>"$list_annee[$date_fin[0] - $list_annee[0]]", -onchange=>"return fin_annee_choisie(this);");
    }
  }
  else {
    print $cgi->textfield(-name =>'rdv_fin_jour', -size => 4, -maxlength=>4, -default=>"$jours[Day_of_Week($rdv{annee_fin}, $rdv{mois_fin}, $rdv{jour_fin}) - 1]->[2]", -disabled), $cgi->popup_menu(-name=>'rdv_fin_num_jour', -values =>\@list_jours_mois, -default=>"$list_jours_mois[$rdv{jour_fin} -1]", -onchange=>"return fin_num_jour_choisi(this);"), $cgi->popup_menu(-name=>'rdv_fin_mois', -values =>\@list_mois, -default=>"$list_mois[$rdv{mois_fin} -1]", -onchange=>"return fin_mois_choisi(this);"), $cgi->popup_menu(-name=>'rdv_fin_annee', -values =>\@list_annee, -default=>"$list_annee[$rdv{annee_fin} - $list_annee[0]]", -onchange=>"return fin_annee_choisie(this);");
  }
  print $cgi->a({-onclick =>"return mini_cal(this);"}, $cgi->img({-id=>'img_mini_cal_hfin', -src=>"$::rep/images/application_view_detail.png", -alt=>'Mini calendrier'})), $cgi->div({-id=>'mini_cal_hfin', -name =>'mini_cal_hfin'}, ' ');
  print $cgi->label({-class =>'label_heure', -for=>'rdv_heure_fin'}, 'Heure:');
  print $cgi->popup_menu(-class=>'heure', -name=>'rdv_heure_fin', -values =>\@list_heures_fin, -default=>"$list_heures_fin[$ind_heure_fin]", -onchange =>"return fin_heure_choisie(this);");
  print $cgi->end_div(); #Fin du div rdv_fin
#  print "La valeur de heure de fin est $list_heures_fin[$ind_heure_fin]", $cgi->br();
#       @date_debut = (Localtime($tps_debut))[0 .. 5];
#       @date_fin = Localtime($tps_fin);
#       print "Heure de début : @date_debut, heure de fin @date_fin", $cgi->br();

  print $cgi->start_div({-id=>'rappel'});
  if(exists $rdv{rappel}) {
    print $cgi->checkbox(-name =>'rappel', -value =>'1', -label => ' ', -checked=>'checked', -onclick =>"return rappel_choisi(this);"), $cgi->label({-for=>'rdv_rappel'}, 'Rappel'), $cgi->popup_menu(-id =>'rdv_rappel', -name=>'rdv_rappel', -values =>\@list_rappels, -default=>"$list_rappels[$rdv{rappel}]");
  }
  else {
    print $cgi->checkbox(-name =>'rappel', -value =>'1', -label => ' ', -onclick =>"return rappel_choisi(this);"), $cgi->label({-for=>'rdv_rappel'}, 'Rappel'), $cgi->popup_menu(-id =>'rdv_rappel', -name=>'rdv_rappel', -values =>\@list_rappels, -default=>"$list_rappels[2]", -disabled);
  }
  print $cgi->end_div(); #Fin du div rappel
  print $cgi->div({-id=>'disponibilite'});
  print $cgi->label('Disponibilité:'), $cgi->popup_menu(-id =>'rdv_dispo', -name=>'rdv_dispo', -values =>\@list_dispo);
  print $cgi->end_div();
  print $cgi->div({-id=>'categorie'});
  print $cgi->label('Catégorie:'), $cgi->popup_menu(-id =>'rdv_categorie', -name=>'rdv_categorie', -values =>\@list_categories);
  print $cgi->end_div();
  affiche_msg_periodicite() if(exists $parametres{p_periodicite});
  print $cgi->textarea(-id=>'rdv_info', -name =>'rdv_info', -rows=>10, -column=>50, -default =>"$list_rappels[$rdv{rappel}]");
  print end_form();
}

sub affiche_ecran_rdv_print {

  affiche_entete_impression();
  affiche_info_impression();
  print start_form();
  print $cgi->start_div({-id=>'rdv_objet_print'}), $cgi->label({-class=>'label1_print', -for=>'rdv_objet_print'}, 'Objet:');
  if(exists $parametres{rdv_objet}) {
    print "$parametres{rdv_objet}", $cgi->end_div();
  }
  else {
    print ' ', $cgi->end_div();
  }
#  print $cgi->start_div({-id=>'rdv_emplt'}), $cgi->div({-class=>'label1'}, $cgi->label({-for=>'rdv_emplt'}, 'Emplacement:'));
  print $cgi->start_div({-id=>'rdv_emplt_print'}), $cgi->label({-class=>'label1_print', -for=>'rdv_emplt_print'}, 'Emplacement:');
#  print $cgi->start_div({-id=>'emplt'});
  if(exists $parametres{rdv_emplt}) {
    print "$parametres{rdv_emplt}";
  }
  else {
    print ' ';
  }
#  print $cgi->popup_menu(-name =>'rdv_emplt_list', -values =>\@emplt, -onchange =>"return emplt_choisi(this);");
  print $cgi->end_div(), $cgi->end_div(); #Fin du div emplt et du div rdv_emplt
  print $cgi->end_div(); #Fin du div rdv_emplt
  print $cgi->start_div({-id=>'rdv_heure_print'}), $cgi->span({-id=>'date_heure_debut'}, 'Début:');
  print $cgi->span("$parametres{rdv_debut_num_jour} $parametres{rdv_debut_mois} $parametres{rdv_debut_annee} à $parametres{rdv_heure_debut}");
#  print $cgi->end_div(); #Fin du div rdv_debut
  print $cgi->span({-id=>'date_heure_fin'}, 'Fin:');
  print $cgi->span("$parametres{rdv_fin_num_jour} $parametres{rdv_fin_mois} $parametres{rdv_fin_annee} à $parametres{rdv_heure_fin}");
  print $cgi->end_div(); #Fin du div rdv_heure_print
  print $cgi->start_div({-id=>'ligne_options'});
  if(exists $parametres{rdv_rappel}) {
#    print $cgi->start_div({-id=>'rappel_print'});
    print $cgi->span({-name =>'rappel'}, "Rappel : $parametres{rdv_rappel}");
#    print $cgi->end_div(); #Fin du div rappel
  }
#  print $cgi->div({-id=>'disponibilite_print'});
  print $cgi->span("Disponibilité: $parametres{rdv_dispo}");
#  print $cgi->end_div();
#  print $cgi->div({-id=>'categorie_print'});
  print $cgi->span("Catégorie: $parametres{rdv_categorie}");
#  print $cgi->end_div();
  print $cgi->end_div(); # Fin du div rdv_heure_options
  print $cgi->p({-id=>'rdv_info_print', -name =>'rdv_info'}, "$parametres{rdv_info}");

  print end_form();
}

sub calcul_data_rdv_creation {
## Génération de la liste list_annee
  my ($aa, $mm, $jj, $hh, $mn, $ss, @delta, @sp_heure, $st_hh, $st_mn, $st_delta);
#  $ind = 0;
  foreach (0..9) {
    push @list_annee, $parametres{annee}-5+$_;
  }
  $ind_annee_debut = 5;
  
   
# Génération de la liste list_heures_debut en fonction du type d'affichage de l'heure
  if($parametres{affichage_heure} eq '5') {
    foreach(0..23) {
      $heure_debut = ($_ >= 10) ? "$_:00" : "0$_:00";
      push @list_heures_debut, $heure_debut;
      if($heure_debut eq "$parametres{heure}:00") {
        $heure_fin = $heure_debut;
        $ind_heure_debut = $ind;
      }
      $ind++;
    }
  }
  elsif($parametres{affichage_heure} eq '4') {
    foreach(0..23) {
      foreach my $i ('00', '30') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($_ eq $parametres{heure}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  elsif($parametres{affichage_heure} eq '3') {
    foreach(0..23) {
      foreach my $i ('00', '15', '30', '45') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($_ eq $parametres{heure}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  elsif($parametres{affichage_heure} eq '2') {
    foreach(0..23) {
      foreach my $i ('00', '10', '20', '30', '40', '50') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($_ eq $parametres{heure}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  @sp_heure = split /:/, $list_heures_debut[$ind_heure_debut];
#  print "Décomposition de heure debut : $sp_heure[0], $sp_heure[1], >> ind_heure_debut = $ind_heure_debut", $cgi->br();
  $tps_debut = Mktime($parametres{annee}, $parametres{mois}, $parametres{jour}, $sp_heure[0], $sp_heure[1], 0);
#  $tps = Mktime($parametres{annee}, $parametres{mois}, $parametres{jour}, $sp_heure[0], $sp_heure[1], 0) + $pas;
  $tps = $tps_debut + $pas;
  $tps_fin = $tps;
  @date_fin = Localtime($tps_fin);
  print "Le pas est égal à $pas >> Valeur de date_fin : @date_fin", $cgi->br();
#Génération des options des heures
  $ind_heure_fin = 0;
# Ajout de la 1ère ligne des options des heures de fin
  while (($tps - $tps_debut) < 86400) {
    ($aa, $mm, $jj, $hh, $mn, $ss) =  (Localtime($tps))[0..5];
    @delta = Delta_DHMS($parametres{annee}, $parametres{mois}, $parametres{jour}, $sp_heure[0], $sp_heure[1], 0,$aa, $mm, $jj, $hh, $mn, $ss);
    $st_hh = ($hh >= 10) ? "$hh" : "0$hh";
    $st_mn = ($mn >= 10) ? "$mn" : "0$mn";
    if($delta[2] > 0) {
      $st_delta = ($delta[1] > 0) ? "($delta[1] h, $delta[2] mn)" : "($delta[2] mn)";
    }
    else {
      $st_delta = "($delta[1] h)";
    }
## Génération de la liste list_heures_fin
    push @list_heures_fin, "$st_hh:$st_mn $st_delta";
      $tps = Mktime($aa, $mm, $jj, $hh, $mn, $ss) + $pas;
#    $tps += $pas;
  }
#  print "La valeur de list_heures_fin est : @list_heures_fin", $cgi->br();
}
##################################################
sub calcul_data_rdv_edition {
  my ($aa, $mm, $jj, $hh, $mn, $ss, @delta, @sp_heure, $st_hh, $st_mn, $st_delta);
  if(exists $parametres{bouton}) {
#    print $cgi->h1("Bouton = $parametres{bouton}");
    if($parametres{bouton} eq 'OK') {
#        print $cgi->h3('Gestion des informations en provenance du formulaire');
      gere_info_periodicite();
    }
    elsif($parametres{bouton} eq 'Supprimer') {
      gere_suppression_periodicite();
      gere_info_periodicite();
    }
  }
  else {
    db_recherche_info_rdv();
  }
## Génération de la liste list_annee
  foreach (0..9) {
    push @list_annee, $rdv{annee_debut}-5+$_;
  }
# Ajustement de la taille de list_annee en fonction de la date de fin
#  print "La valeur de \$# de la liste list_annee est : $#list_annee et contient l'année N° $list_annee[$#list_annee]", $cgi->br();
  while($list_annee[$#list_annee] < $rdv{annee_fin}) {
    $list_annee[$#list_annee + 1] = $list_annee[$#list_annee] + 1;
  }
## Génération de la liste list_heures_debut
#  print "Les données pour calculer tps_variable sont : $rdv{annee_debut}/$rdv{mois_debut}/$rdv{jour_debut}", $cgi->br();
  my $tps_variable = Mktime($rdv{annee_debut}, $rdv{mois_debut}, $rdv{jour_debut}, 0, 0, 0);
  my $flag_egalite = 0;
  if($parametres{affichage_heure} eq '5') {
    foreach(0..23) {
      $heure_debut = ($_ >= 10) ? "$_:00" : "0$_:00";
      push @list_heures_debut, $heure_debut;
      if($heure_debut eq $rdv{heure_debut}) {
        $heure_fin = $heure_debut;
      }
      if($tps_variable < $tps_debut) {
        $ind_heure_debut = $ind;
      }
      elsif($tps_variable == $tps_debut) {
        $ind_heure_debut = $ind;
        $flag_egalite = 1;
      }
      $ind++;
      $tps_variable += $pas;
    }
  }
  elsif($parametres{affichage_heure} eq '4') {
    foreach(0..23) {
      foreach my $i ('00', '30') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($heure_debut eq $rdv{heure_debut}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  elsif($parametres{affichage_heure} eq '3') {
    foreach(0..23) {
      foreach my $i ('00', '15', '30', '45') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($heure_debut eq $rdv{heure_debut}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  elsif($parametres{affichage_heure} eq '2') {
    foreach(0..23) {
      foreach my $i ('00', '10', '20', '30', '40', '50') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($heure_debut eq $rdv{heure_debut}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  if($flag_egalite == 0) {
    $msg_maj = "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Attention!!!!!!!!!!!!!!!!!!!!!!!!!! Il y a eu modification de l'heure de début du rendez-vous.";
    print "MSG : $msg_maj", $cgi->br();
  }
  @sp_heure = split /:/, $list_heures_debut[$ind_heure_debut];
# Génération des options des heures
  $ind = 0;
  $ind_heure_fin = 0;
  if(($tps_fin - $tps_debut) < 86400) {
# $tps est initialisé a $tps_debut + $pas dans db_recherche_info_rdv
    while (($tps - $tps_debut) < 86400) {
      ($aa, $mm, $jj, $hh, $mn, $ss) =  (Localtime($tps))[0..5];
      @delta = Delta_DHMS($rdv{annee_debut}, $rdv{mois_debut}, $rdv{jour_debut}, $sp_heure[0], $sp_heure[1], 0,$aa, $mm, $jj, $hh, $mn, $ss);
      $st_hh = ($hh >= 10) ? "$hh" : "0$hh";
      $st_mn = ($mn >= 10) ? "$mn" : "0$mn";
      if($delta[2] > 0) {
        $st_delta = ($delta[1] > 0) ? "($delta[1] h, $delta[2] mn)" : "($delta[2] mn)";
      }
      else {
        $st_delta = "($delta[1] h)";
      }
## Génération de la liste list_heures_fin
      push @list_heures_fin, "$st_hh:$st_mn $st_delta";
      $ind_heure_fin = $ind  if($tps == $tps_fin) ;
      $tps += $pas;
      $ind++;
    }
  }
  else {
# $tps est initialisé a la 1ère heure du jour dans db_recherche_info_rdv
    my $fin_journee = $tps + 86400;
    while($tps < $fin_journee) {
      ($aa, $mm, $jj, $hh, $mn, $ss) =  (Localtime($tps))[0..5];
      $st_hh = ($hh >= 10) ? "$hh" : "0$hh";
      $st_mn = ($mn >= 10) ? "$mn" : "0$mn";
## Génération de la liste list_heures_fin
      push @list_heures_fin, "$st_hh:$st_mn";
      $ind_heure_fin = $ind  if($tps == $tps_fin) ;
      $tps += $pas;
      $ind++;
    }
  }
#    print "La valeur de l'heure de fin est : $list_heures_fin[$ind_heure_fin]", $cgi->br();
}


sub calcul_data_periodicite {
my ($aa, $mm, $jj, $hh, $mn, $ss, @delta, @sp_heure, $st_hh, $st_mn, $st_delta);
my ($no_debut_mois, $no_fin_mois, @sp_heure_fin, $duree);
  FIN_P : {
    if($parametres{affichage_heure} eq '5') {
      $pas = 60*60;
      last FIN_P;
    }
    if($parametres{affichage_heure} eq '4') {
      $pas = 30*60;
      last FIN_P;
    }
    if($parametres{affichage_heure} eq '3') {
      $pas = 15*60;
      last FIN_P;
    }
    if($parametres{affichage_heure} eq '2') {
      $pas = 10*60;
      last FIN_P;
    }
  }
## Génération de la liste list_heures_debut en fonction du type d'affichage de l'heure
  if($parametres{affichage_heure} eq '5') {
    foreach(0..23) {
      $heure_debut = ($_ >= 10) ? "$_:00" : "0$_:00";
      push @list_heures_debut, $heure_debut;
      if($heure_debut eq $parametres{rdv_heure_debut}) {
        $heure_fin = $heure_debut;
        $ind_heure_debut = $ind;
      }
      $ind++;
    }
  }
  elsif($parametres{affichage_heure} eq '4') {
    foreach(0..23) {
      foreach my $i ('00', '30') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($heure_debut eq $parametres{rdv_heure_debut}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  elsif($parametres{affichage_heure} eq '3') {
    foreach(0..23) {
      foreach my $i ('00', '15', '30', '45') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($heure_debut eq $parametres{rdv_heure_debut}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  elsif($parametres{affichage_heure} eq '2') {
    foreach(0..23) {
      foreach my $i ('00', '10', '20', '30', '40', '50') {
        $heure_debut = ($_ >= 10) ? "$_:$i" : "0$_:$i";
        push @list_heures_debut, $heure_debut;
        if($heure_debut eq $parametres{rdv_heure_debut}) {
          $heure_fin = $heure_debut;
          $ind_heure_debut = $ind;
        }
        $ind++;
      }
    }
  }
  @sp_heure = split /:/, $list_heures_debut[$ind_heure_debut];
# Recherche du N° du mois
  foreach (@mois) {
     if ($_->[0] eq $parametres{rdv_debut_mois}) {
       $no_debut_mois = $_->[1] ;
       last;
     }
   }
  foreach (@mois) {
     if ($_->[0] eq $parametres{rdv_fin_mois}) {
       $no_fin_mois = $_->[1] ;
       last;
     }
   }
#   print "Décomposition de heure debut : $sp_heure[0], $sp_heure[1]", $cgi->br();
   $tps_debut = Mktime($parametres{rdv_debut_annee}, $no_debut_mois, $parametres{rdv_debut_num_jour}, $sp_heure[0], $sp_heure[1], 0);
#   $tps = Mktime($parametres{rdv_debut_annee}, $no_debut_mois, $parametres{rdv_debut_num_jour}, $sp_heure[0], $sp_heure[1], 0) + $pas;
   @sp_heure_fin = $parametres{rdv_heure_fin}=~ /(\d+):(\d+)/;
   $tps_fin = Mktime($parametres{rdv_fin_annee}, $no_fin_mois, $parametres{rdv_fin_num_jour}, $sp_heure_fin[0], $sp_heure_fin[1], 0);
#   @date_fin = Localtime($tps_fin);
# Génération des options des heures
   $ind_heure_fin = 0;
   $ind = 0;
   if(($tps_fin - $tps_debut) >= 86400) {# durée > à 1 jour
     if($parametres{affichage_heure} eq '5') {
# Génération des heures de fin
       foreach(0..23) {
         $heure_fin = ($_ >= 10) ? "$_:00" : "0$_:00";
         push @list_heures_fin, $heure_fin;
         if($heure_fin eq $parametres{rdv_heure_fin}) {
           $ind_heure_fin = $ind;
         }
         $ind++;
       }
     }
# Génération des durées
     $idx_duree = 0;
     my $diff;
     $ind = 13;
     foreach(0..12) {
       push @duree, "$_ h";
     }
     push @duree, "1 jour";
     $idx_duree = $ind if(($tps_debut + (24*$pas))== $tps_fin);
     $ind++;
     if(($tps_debut + 24*$pas < $tps_fin) && ($tps_debut + 48*$pas > $tps_fin)) {
       $diff = ($tps_fin - $tps_debut)/$pas;
       $diff = sprintf "%5.2f", $diff;
       push @duree, "$diff h";
       $idx_duree = $ind;
       $ind++;
     }
     push @duree, "2 jours";
     $idx_duree = $ind if(($tps_debut + (48*$pas))== $tps_fin);
     $ind++;
     if(($tps_debut + 48*$pas < $tps_fin) && ($tps_debut + 72*$pas > $tps_fin)) {
       $diff = ($tps_fin - $tps_debut)/$pas;
       $diff = sprintf "%5.2f", $diff;
       push @duree, "$diff h";
       $idx_duree = $ind;
       $ind++;
     }
     push @duree, "3 jours";
     $idx_duree = $ind if(($tps_debut + (72*$pas))== $tps_fin);
     $ind++;
     if(($tps_debut + 72*$pas < $tps_fin) && ($tps_debut + 96*$pas > $tps_fin)) {
       $diff = ($tps_fin - $tps_debut)/$pas;
       $diff = sprintf "%5.2f", $diff;
       push @duree, "$diff h";
       $idx_duree = $ind;
       $ind++;
     }
     push @duree, "4 jours";
     $idx_duree = $ind if(($tps_debut + (96*$pas))== $tps_fin);
     $ind++;
     if(($tps_debut + 96*$pas < $tps_fin) && ($tps_debut + 168*$pas > $tps_fin)) {
       $diff = ($tps_fin - $tps_debut)/$pas;
       $diff = sprintf "%5.2f", $diff;
       push @duree, "$diff h";
       $idx_duree = $ind;
       $ind++;
     }
     push @duree, "1 semaine";
     $idx_duree = $ind if(($tps_debut + (168*$pas))== $tps_fin);
     $ind++;
     if(($tps_debut + 168*$pas < $tps_fin) && ($tps_debut + 336*$pas > $tps_fin)) {
       $diff = ($tps_fin - $tps_debut)/$pas;
       $diff = sprintf "%5.2f", $diff;
       push @duree, "$diff h";
       $idx_duree = $ind;
       $ind++;
     }
     push @duree, "2 semaines";
     $idx_duree = $ind if(($tps_debut + (336*$pas))== $tps_fin);
     $ind++;
     if($tps_debut + 336*$pas < $tps_fin) {
       $diff = ($tps_fin - $tps_debut)/$pas;
       $diff = sprintf "%5.2f", $diff;
       push @duree, "$diff h";
       $idx_duree = $ind;
       $ind++;
     }

   }
   else {
     $tps = $tps_debut + $pas;
     while (($tps - $tps_debut) < 86400) {
       ($aa, $mm, $jj, $hh, $mn, $ss) =  (Localtime($tps))[0..5];
       @delta = Delta_DHMS($parametres{rdv_debut_annee}, $no_debut_mois, $parametres{rdv_debut_num_jour}, $sp_heure[0], $sp_heure[1], 0,$aa, $mm, $jj, $hh, $mn, $ss);
       $st_hh = ($hh >= 10) ? "$hh" : "0$hh";
       $st_mn = ($mn >= 10) ? "$mn" : "0$mn";
       if($delta[2] > 0) {
         $st_delta = ($delta[1] > 0) ? "$delta[1] h, $delta[2] mn" : "$delta[2] mn";
       }
       else {
         $st_delta = "$delta[1] h";
       }
## Génération des listes list_heures_fin et duree
       $heure_fin = "$st_hh:$st_mn";
       push @list_heures_fin, $heure_fin;
       push @duree, $st_delta;
       $ind_heure_fin = $ind if("$sp_heure_fin[0]:$sp_heure_fin[1]" eq $heure_fin);
       $tps += $pas;
       $ind++;
     }
     $idx_duree = $ind_heure_fin;
   }

}

sub affiche_ecran_periodicite {
#  lecture_parametres();
  print "Gestion de la périodicité", $cgi->br();
  my $mois = cherche_no_mois($parametres{rdv_debut_mois});
  my $dow = Day_of_Week($parametres{rdv_debut_annee}, $mois, $parametres{rdv_debut_num_jour});
  my $str_debut_jour = ($parametres{rdv_debut_num_jour} <10)? '0'.$parametres{rdv_debut_num_jour}:$parametres{rdv_debut_num_jour};
  my $str_fin_jour = ($parametres{rdv_fin_num_jour} <10)? '0'.$parametres{rdv_fin_num_jour}:$parametres{rdv_fin_num_jour};
  my $str_mois = ($mois <10)? '0'.$mois:$mois;
  my @pl_choix = (1, 2, 3);
  my %pl_label = (1 => ' ', 2 => ' ', 3 => ' ');


  visu_parametres(\%parametres);
  calcul_data_periodicite();
  print start_form();
  print $cgi->start_fieldset({-id => 'periodicite_zone1'}), $cgi->legend("Heure du rendez-vous");
  print $cgi->start_div({-id => 'p_heure'});

  print $cgi->start_div({-id=>'p_debut'}), $cgi->label({-class =>'label_heure', -for=>'p_debut'}, 'Début:');
  print $cgi->popup_menu(-class=>'heure', -name=>'p_heure_debut', -values =>\@list_heures_debut, -default=>"$list_heures_debut[$ind_heure_debut]", -onchange =>"return p_debut_heure_choisie(this);");
  print $cgi->end_div();

  print $cgi->start_div({-id=>'p_fin'}), $cgi->label({-class =>'label_heure', -for=>'p_fin'}, 'Fin:');
  print $cgi->popup_menu(-class=>'heure', -name=>'p_heure_fin', -values =>\@list_heures_fin, -default=>"$list_heures_fin[$ind_heure_fin]", -onchange =>"return p_fin_heure_choisie(this);");
  print $cgi->end_div();

  print $cgi->start_div({-id=>'p_duree'}), $cgi->label({-class =>'label_heure', -for=>'p_duree'}, 'Durée:');
  print $cgi->popup_menu(-class=>'heure', -name=>'p_heure_duree', -values =>\@duree, -default=>"$duree[$idx_duree]", -onchange =>"return p_duree_choisie(this);");
  print $cgi->end_div();

  print $cgi->end_div(), $cgi->end_fieldset();
  print $cgi->start_fieldset({-id => 'periodicite_zone2'}), $cgi->legend("Périodicité");
  print $cgi->start_div({-id => 'p_periodicite'});
  if(exists $parametres{rp_periodicite}) {
#    print $cgi->div({-id=> 'quotidienne'},$cgi->radio_group(-class=>'periodicite',-name => 'p_periodicite', -values => ));
    print $cgi->radio_group(-class=>'periodicite',-name => 'p_periodicite', -values => \@list_periodicite, -default => $parametres{rp_periodicite}, -columns=>1, -onClick => "return gere_ecran_periodicite(this);");
  }
  else {
    print $cgi->radio_group(-class=>'periodicite', -name => 'p_periodicite', -values => \@list_periodicite, -default => "$list_periodicite[1]", -columns=>1, -onClick => "return gere_ecran_periodicite(this);");
  }
  print $cgi->start_div({-id=>'quotidienne'});
  affiche_ecran_p_quotidienne();
  print $cgi->end_div();
  print $cgi->start_div({-id=>'hebdomadaire'});
  affiche_ecran_p_hebdomadaire($dow);
  print $cgi->end_div();
  print $cgi->start_div({-id=>'mensuelle'});
  affiche_ecran_p_mensuelle($dow, $mois);
  print $cgi->end_div();
  print $cgi->start_div({-id=>'annuelle'});
  affiche_ecran_p_annuelle($dow, $mois);
  print $cgi->end_div();
  print $cgi->end_div(), $cgi->end_fieldset();
  print $cgi->start_fieldset({-id => 'periodicite_zone3'}), $cgi->legend("Plage de périodicité");
  print $cgi->start_div({-id => 'p_plage'});
  if(! exists $parametres{rp_periodicite}) {
    print $cgi->start_div({-id=>'pl_debut'}), $cgi->span({-class=>'decale'}, 'Début :'), $cgi->textfield(-name =>'pl_debut', -default => "$str_debut_jour/$str_mois/$parametres{rdv_debut_annee}", -size =>20, -maxlength =>25);
  }
  else { # On récupère la date de départ de la période
    if(exists $parametres{r_pl_debut}) {
#      print $cgi->start_div({-id=>'pl_debut'}), $cgi->span({-class=>'decale'}, 'Début :'), $cgi->textfield(-name =>'pl_debut', -default => $parametres{r_pl_debut}, -size =>20, -maxlength =>25);
      print $cgi->start_div({-id=>'pl_debut'}), $cgi->span({-class=>'decale'}, 'Début :'), $cgi->textfield(-name =>'pl_debut', -default => "$str_debut_jour/$str_mois/$parametres{rdv_debut_annee}", -size =>20, -maxlength =>25);
    }
    else {
      print $cgi->start_div({-id=>'pl_debut'}), $cgi->span({-class=>'decale'}, 'Début :'), $cgi->textfield(-name =>'pl_debut', -default => "$str_debut_jour/$str_mois/$parametres{rdv_debut_annee}", -size =>20, -maxlength =>25);
    }
  }
  print $cgi->a({-onclick =>"return mini_cal(this, 'pl_debut');"}, $cgi->img({-id=>'img_mini_cal_pdebut', -src=>"$::rep/images/application_view_detail.png", -alt=>'Mini calendrier'})), $cgi->div({-id=>'mini_cal_pdebut'}, ' ');
  print $cgi->end_div(); # Fin du div pl_debut
  print $cgi->start_div({-id=>'pl_fin'});
  if(! exists $parametres{rp_periodicite}) {
    print $cgi->radio_group(-name => 'pl_menu_fin', -values => \@pl_choix, -default => '1', -labels => \%pl_label, -columns=>1);
  }
  else {
    if(exists $parametres{r_pl_menu_fin}) {
      print $cgi->radio_group(-name => 'pl_menu_fin', -values => \@pl_choix, -default => $parametres{r_pl_menu_fin}, -labels => \%pl_label, -columns=>1);
    }
    else {
      print $cgi->radio_group(-name => 'pl_menu_fin', -values => \@pl_choix, -default => '1', -labels => \%pl_label, -columns=>1);
    }
  }
  print $cgi->end_div(); # Fin du div pl_fin
  $mois = cherche_no_mois($parametres{rdv_fin_mois});
  $str_mois = ($mois <10)? '0'.$mois:$mois;
  
  print $cgi->start_div({-id=>'pl_label_fin'}), $cgi->div({-name=>'no_date_fin', -onclick=>"return pl_fin_choisie(this);"},'Pas de date de fin');
  if(exists $parametres{r_pl_menu_fin}) {
    if($parametres{r_pl_menu_fin} == 2) {
      print $cgi->start_div(), $cgi->span('Fin après '), $cgi->textfield(-name => 'pl_mchoix2', -default => $parametres{r_pl_mchoix2}, -size => '3', -maxlength=>'5', -onfocus=>"return pl_fin_choisie(this);"), $cgi->span(' occurences'), $cgi->end_div();
      print $cgi->start_div(), $cgi->span('Fin le '), $cgi->textfield(-name => 'pl_fin', -default =>"$str_fin_jour/$str_mois/$parametres{rdv_fin_annee}", -size =>'20', -maxlength => '25', -onfocus=>"return pl_fin_choisie(this);");
      print $cgi->a({-onclick =>"return mini_cal(this, 'pl_fin');"}, $cgi->img({-id=>'img_mini_cal_pfin', -src=>"$::rep/images/application_view_detail.png", -alt=>'Mini calendrier'})), $cgi->div({-id=>'mini_cal_pfin'}, ' '), $cgi->end_div();
      print $cgi->end_div();
    }
    elsif($parametres{r_pl_menu_fin} == 3) {
      print $cgi->start_div(), $cgi->span('Fin après '), $cgi->textfield(-name => 'pl_mchoix2', -default => '10', -size => '3', -maxlength=>'5', -onfocus=>"return pl_fin_choisie(this);"), $cgi->span(' occurences'), $cgi->end_div();
      print $cgi->start_div(), $cgi->span('Fin le '), $cgi->textfield(-name => 'pl_fin', -default =>$parametres{r_pl_fin}, -size =>'20', -maxlength => '25', -onfocus=>"return pl_fin_choisie(this);");
      print $cgi->a({-onclick =>"return mini_cal(this, 'pl_fin');"}, $cgi->img({-id=>'img_mini_cal_pfin', -src=>"$::rep/images/application_view_detail.png", -alt=>'Mini calendrier'})), $cgi->div({-id=>'mini_cal_pfin'}, ' '), $cgi->end_div();
      print $cgi->end_div();

    }
    else {
      print $cgi->start_div(), $cgi->span('Fin après '), $cgi->textfield(-name => 'pl_mchoix2', -default => '10', -size => '3', -maxlength=>'5', -onfocus=>"return pl_fin_choisie(this);"), $cgi->span(' occurences'), $cgi->end_div();
      print $cgi->start_div(), $cgi->span('Fin le '), $cgi->textfield(-name => 'pl_fin', -default =>"$str_fin_jour/$str_mois/$parametres{rdv_fin_annee}", -size =>'20', -maxlength => '25', -onfocus=>"return pl_fin_choisie(this);");
      print $cgi->a({-onclick =>"return mini_cal(this, 'pl_fin');"}, $cgi->img({-id=>'img_mini_cal_pfin', -src=>"$::rep/images/application_view_detail.png", -alt=>'Mini calendrier'})), $cgi->div({-id=>'mini_cal_pfin'}, ' '), $cgi->end_div();
      print $cgi->end_div();
    }
  }
  else {
    print $cgi->start_div(), $cgi->span('Fin après '), $cgi->textfield(-name => 'pl_mchoix2', -default => '10', -size => '3', -maxlength=>'5', -onfocus=>"return pl_fin_choisie(this);"), $cgi->span(' occurences'), $cgi->end_div();
    print $cgi->start_div(), $cgi->span('Fin le '), $cgi->textfield(-name => 'pl_fin', -default =>"$str_fin_jour/$str_mois/$parametres{rdv_fin_annee}", -size =>'20', -maxlength => '25', -onfocus=>"return pl_fin_choisie(this);");
    print $cgi->a({-onclick =>"return mini_cal(this, 'pl_fin');"}, $cgi->img({-id=>'img_mini_cal_pfin', -src=>"$::rep/images/application_view_detail.png", -alt=>'Mini calendrier'})), $cgi->div({-id=>'mini_cal_pfin'}, ' '), $cgi->end_div();
    print $cgi->end_div();
  }
  print $cgi->end_div(), $cgi->end_fieldset();
  affiche_boutons_periodicite();
  gestion_champs_caches_periodicite();
  print $cgi->end_form();
}

sub calcul_fin_hebdo_periodicite {
#Suivant le valeur de type, on a 2 sorties. L'une litérale "jour mois année",
# l'autre au format jj/mm/aaaa
  my ($type, @debut) = @_;
  my ($msg, $jour, $mois, $an, $tps, $tps_debut_semaine, $no_jours, @no_jours, $total_jours_restants, $semaine_jours_restants);
  my ($tps_delta, $irdv, $tps_hm_debut),
#  print "Calcul_fin_hebdo_periodicite() : Le tableau début contient les éléments suivant : @debut", $cgi->br();
# @list_rdv = [id, tps_debut, tps_fin, annee_debut, mois_num_debut, jour_num_debut, heure_debut, mn_debut, annee_fin, mois_num_fin, jour_num_fin, heure_fin, mn_fin]  
  print "Calcul_fin_hebdo_periodicite() : Le tableau list_rdv contient ". scalar(@list_rdv)." éléments, chaque sous-tableau contient ".scalar(@{$list_rdv[0]})." dont les suivants : @{$list_rdv[0]}", $cgi->br();
  $tps_delta = $list_rdv[0][2] - $list_rdv[0][1];
  $tps_hm_debut = 1000*($list_rdv[0][6]*360 + $list_rdv[0][7]);
  if($type == 1) { #sortie litérale
    if($parametres{hebdomadaire} == undef) {
      $msg = " (Erreur) jusqu'au $parametres{rdv_debut_num_jour} ".lc $parametres{rdv_debut_mois}." $parametres{rdv_debut_annee} ";
    }
    else {
        @no_jours = sort ( $cgi->param('hebdomadaire') );
#         $no_jours = $cgi->param('hebdomadaire');
        $jour = $debut[0] + 0;
        $mois = $debut[1] + 0;
        $an = $debut[2];
        $total_jours_restants = $parametres{pl_mchoix2};
        $semaine_jours_restants = 0;
        $tps_debut_semaine = Mktime($debut[2], $mois, $jour, 0, 0, 0);
GLOBAL: while($total_jours_restants > 0) {
          if($total_jours_restants == $parametres{pl_mchoix2}) {
            $tps = $tps_debut_semaine;
            my ($dow) = (Localtime($tps_debut_semaine))[7];
# La 1ère fois, on se positionne sur le lundi
            $tps_debut_semaine -=  ($dow - 1)*86400;
			print "calcul_fin_hebdo_periodicite() : La date de début de semaine est : ", (Localtime($tps_debut_semaine))[2],"/", (Localtime($tps_debut_semaine))[1],"/",(Localtime($tps_debut_semaine))[0],$cgi->br();
          }
          else {
            $tps = $tps_debut_semaine;
          }
SEMAINE:  while($semaine_jours_restants < scalar(@no_jours)) {
            for(my $i = 0; $i < scalar(@no_jours); $i++) {
              my @tps_dow = (Localtime($tps))[0..7];
              if($tps_dow[7] == $no_jours[$i]) {
#			    print "tps_dow[0] = $tps_dow[0], tps_dow[1] = $tps_dow[1], tps_dow[2] = $tps_dow[2], list_rdv[0][6] = $list_rdv[0][6], list_rdv[0][7] = $list_rdv[0][7]", $cgi->br();
			    my $tps_irdv_debut = Mktime($tps_dow[0], $tps_dow[1], $tps_dow[2], $list_rdv[0][6], $list_rdv[0][7], 0);
				my $tps_irdv_fin = $tps_irdv_debut + $tps_delta;
#                print " calcul_fin_hebdo_periodicite() : i= $i, tps_dow[7] = $no_jours[$i]) ?, jour choisi : @tps_dow", $cgi->br();
#				print "L'heure de cdébut du rdv est fixé à $tps_dow[2]/$tps_dow[1]/$tps_dow[0] $parametres{rdv_heure_debut}", $cgi->br();
				my @irdv_debut = (Localtime($tps_irdv_debut))[0..7];
				my @irdv_fin = (Localtime($tps_irdv_fin))[0..7];
#				print "calcul_fin_hebdo_periodicite() : Debut du rendez-vous : $irdv_debut[2]/$irdv_debut[1]/$irdv_debut[0] $irdv_debut[3]:$irdv_debut[4]", $cgi->br();
#				print "calcul_fin_hebdo_periodicite() : Fin du rendez-vous : $irdv_fin[2]/$irdv_fin[1]/$irdv_fin[0] $irdv_fin[3]:$irdv_fin[4]", $cgi->br();
                
				push @list_rdv, [ "$irdv_debut[0]-$irdv_debut[1]-$irdv_debut[2] $irdv_debut[3]:$irdv_debut[4]:00", "$irdv_fin[0]-$irdv_fin[1]-$irdv_fin[2] $irdv_fin[3]:$irdv_fin[4]:00" ];
                print "Calcul_fin_hebdo_periodicite() : Le tableau list_rdv contient ". scalar(@list_rdv)." éléments, le nouveau sous-tableau contient ".scalar(@{$list_rdv[scalar(@list_rdv) - 1]})." dont les suivants : @{$list_rdv[scalar(@list_rdv) -1]}", $cgi->br();				
				
                $semaine_jours_restants++;
                $total_jours_restants--;
                if($total_jours_restants == 0) {
                  last GLOBAL;
                }
                else {
                  if(($semaine_jours_restants == scalar(@no_jours)) || ($tps_dow[7] == 7)) {
                    last SEMAINE;
                  }
                  else {
                    last;
                  }
                }
              }
            }
            $tps+=86400;
#			print "calcul_fin_hebdo_periodicite() : tps est la date : ", (Localtime($tps))[2],"/", (Localtime($tps))[1],"/",(Localtime($tps))[0],$cgi->br();			
          }
          $tps_debut_semaine += 7*$parametres{th1}*86400;
          $semaine_jours_restants = 0;
#		  print "calcul_fin_hebdo_periodicite() : La date de début de semaine est : ", (Localtime($tps_debut_semaine))[2],"/", (Localtime($tps_debut_semaine))[1],"/",(Localtime($tps_debut_semaine))[0],$cgi->br();
        }
        ($an, $mois, $jour) =  (Localtime($tps))[0..2];
        $msg = " jusqu'au $jour ".lc $mois[$mois -1]->[0]." $an";
        $parametres{pl_fin_calculee} = "$an/$mois/$jour 00:00:00";
    }
  }
  else {# type == 2, Sortie jj/mm/aaaa
    ;
  }
  shift @list_rdv;
#  shift @list_rdv;
  print "La taille est list_rdv est maintenant de ". scalar(@list_rdv)." sous tableaux", $cgi->br();
  print "Le tableau list_rdv est transmis en élément caché", $cgi->br();
#  print $cgi->hidden(-name => 'list_rdv', -value => "@list_rdv");
  return $msg;
}

sub calcul_fin_quotidienne_periodicite {
#Suivant le valeur de type, on a 2 sorties. L'une litérale "jour mois année",
# l'autre au format jj/mm/aaaa
  print "calcul_fin_quotidienne_periodicite()", $cgi->br();
  my ($type, @debut) = @_;
  my ($msg, $jour, $mois, $an, $tps, $tps_debut_semaine, @tps_dow, $total_jours_restants, $semaine_jours_restants);
  if($type == 1) { #sortie litérale
    if($parametres{quotidienne} == undef) {
      $msg = " (Erreur) jusqu'au $parametres{rdv_debut_num_jour} ".lc $parametres{rdv_debut_mois}." $parametres{rdv_debut_annee} ";
    }
    elsif($parametres{quotidienne} == 1) {
#      print "debut = $debut[2], $debut[1], $debut[0]", $cgi->br();
      ($an, $mois, $jour) = Add_Delta_Days($debut[2], $debut[1]+0, $debut[0]+0, $parametres{tq1}*($parametres{pl_mchoix2}-1));
      $parametres{pl_fin_calculee} = "$an/$mois/$jour 00:00:00";
      $msg = " jusqu'au $jour ".lc $mois[$mois -1]->[0]." $an";
    }
    elsif($parametres{quotidienne} == 2) {
        $jour = $debut[0] + 0;
        $mois = $debut[1] + 0;
        $an = $debut[2];
        $total_jours_restants = $parametres{pl_mchoix2};
        $semaine_jours_restants = 0;
        $tps_debut_semaine = Mktime($debut[2], $mois, $jour, 0, 0, 0);
GLOBAL: while($total_jours_restants > 0) {
          if($total_jours_restants == $parametres{pl_mchoix2}) {
            $tps = $tps_debut_semaine;
            my ($dow) = (Localtime($tps_debut_semaine))[7];
# La 1ère fois, on se positionne sur le lundi
            $tps_debut_semaine -=  ($dow - 1)*86400;
          }
          else {
            $tps = $tps_debut_semaine;
          }
          @tps_dow = (Localtime($tps))[0..7];
SEMAINE:  while($tps_dow[7] <= 5) { # Maxi des jours ouvrés
            $total_jours_restants--;
            if($total_jours_restants == 0) {
              last GLOBAL;
            }
            else {
              if($tps_dow[7] == 5) {
                    last SEMAINE;
              }
            }
            $tps+=86400;
            @tps_dow = (Localtime($tps))[0..7];
          }
          $tps_debut_semaine += 7*86400;
        }
        ($an, $mois, $jour) =  (Localtime($tps))[0..2];
        $parametres{pl_fin_calculee} = "$an/$mois/$jour 00:00:00";
        $msg = " jusqu'au $jour ".lc $mois[$mois -1]->[0]." $an";
    }
  }
  else {# type == 2, Sortie jj/mm/aaaa
    ;
  }
  return $msg;
}


sub calcul_fin_mensuelle_periodicite {
#Suivant le valeur de type, on a 2 sorties. L'une litérale "jour mois année",
# l'autre au format jj/mm/aaaa
  my ($type, @debut) = @_;
  my ($msg, $jour, $mois, $an, @fin, $tps, $tps_debut_semaine, @tps_dow, $total_jours_restants, $semaine_jours_restants);
  if($type == 1) { #sortie litérale
    if($parametres{mensuelle} == undef) {
      $msg = " (Erreur) jusqu'au $parametres{rdv_debut_num_jour} ".lc $parametres{rdv_debut_mois}." $parametres{rdv_debut_annee} ";
    }
    elsif($parametres{mensuelle} == 1) {
# La date de début est calculé à partir de $parametres{tm2}
      $mois = cherche_no_mois($parametres{rdv_debut_mois});
      ($an, $mois, $jour) = Add_Delta_YM($parametres{rdv_debut_annee}, $debut[1]+0, $debut[0]+0, 0, $parametres{tm2}*($parametres{pl_mchoix2}-1));
    }
    elsif($parametres{mensuelle} == 2) {
      if($parametres{mchoix2} == 8) {
        if($parametres{mchoix1} <= 4) { # Les 4 premiers jours
          ($an, $mois, $jour) = Add_Delta_YM($debut[2], $debut[1], $debut[0], 0, $parametres{tm3}*($parametres{pl_mchoix2}-1));
        }
        else { # le dernier jour
          ($an, $mois, $jour) = Add_Delta_YM($debut[2], $debut[1]+0, $debut[0]+0, 0, $parametres{tm3}*($parametres{pl_mchoix2}-1));
           $jour = Days_in_Month($an, $mois);
        }
      }
      elsif($parametres{mchoix2} == 9) {# jours ouvrés
        if($parametres{mchoix1} <= 4) {# Les 4 premiers jours ouvrés
          my @tps_fin = Add_Delta_YM($debut[2], $debut[1], $debut[0], 0, $parametres{tm3}*($parametres{pl_mchoix2}-1));
          my @tps = Add_Delta_YM($debut[2], $debut[1], 1, 0, $parametres{tm3}*($parametres{pl_mchoix2}-1));
          my $dow = Day_of_Week(@tps);
          my $nb_ouvres = 0;
J_OUVRES: while(1) {
            if($dow >= 6) {# C'est un samedi ou un dimanche, on passe au jour suivant
              @tps =  Add_Delta_Days(@tps, 1);
              $dow = Day_of_Week(@tps);
            }
            else {
              $nb_ouvres++;
              if($nb_ouvres == $parametres{mchoix1}) {# On a le nbre de jours ouvrés souhaité
                if(Mktime(@tps, 0, 0, 0) >= Mktime(@tps_fin, 0, 0, 0)) {
                  $jour = $tps[2];
                  $mois = $tps[1];
                  $an = $tps[0];
                  last J_OUVRES;
                }
                else {# On recommence au début du mois suivant
                  @tps = Add_Delta_YM($tps[0], $tps[1], 1, 0, 1);
                  $dow = Day_of_Week(@tps);
                  $nb_ouvres = 0;
                }
              }
              else {# On n'a pas le nbre de jour ouvré requis, on passe au jour suivant
                @tps =  Add_Delta_Days(@tps, 1);
                $dow = Day_of_Week(@tps);
              }
            }
          }
        }
        else {# Le dernier jour ouvré (les fériés sont inclus)
          my @tps_fin = Add_Delta_YM($debut[2], $debut[1], $debut[0], 0, $parametres{tm3}*($parametres{pl_mchoix2}-1));
          my $jdernier = Days_in_Month($tps_fin[0], $tps_fin[1]);
          my @tps = Add_Delta_YM($debut[2], $debut[1], $jdernier, 0, $parametres{tm3}*($parametres{pl_mchoix2}-1));
          $tps[2] = Days_in_Month($tps[0], $tps[1]);
          my $dow = Day_of_Week(@tps);
DJ_OUVRE: while(1) {
            if($dow >= 6) {# C'est une samedi ou un dimanche, on recule d'un jour
              @tps =  Add_Delta_Days(@tps, -1);
              $dow = Day_of_Week(@tps);
            }
            else {
              if(Mktime(@tps, 0, 0, 0) >= Mktime(@tps_fin, 0, 0, 0)) {
                $jour = $tps[2];
                $mois = $tps[1];
                $an = $tps[0];
                last DJ_OUVRE;
              }
              else {# On recommence au début du mois suivant
                @tps = Add_Delta_YM(@tps, 0, 1);
                $tps[2] = Days_in_Month($tps[0], $tps[1]);# On se met sur le dernier jour du mois
                $dow = Day_of_Week(@tps);
#                $nb_ouvres = 0;
              }
            }
          }
        }
      }
      else {
        ($an, $mois, $jour) = Add_Delta_YM($debut[2], $debut[1]+0, $debut[0]+0, 0, $parametres{tm3}*($parametres{pl_mchoix2}-1));
        @fin = Nth_Weekday_of_Month_Year($an, $mois, $parametres{mchoix2}, $parametres{mchoix1});
        if(@fin == undef) {# La 5ième semaine n'existe pas pour ce mois
          ($an, $mois, $jour) = Nth_Weekday_of_Month_Year($an, $mois, $parametres{mchoix2}, $parametres{mchoix1}-1);
        }
        else {
          ($an, $mois, $jour) = @fin;
        }
      }
    }
  }
  else {# type == 2, Sortie jj/mm/aaaa
    ;
  }
  $parametres{pl_fin_calculee} = "$an/$mois/$jour 00:00:00";
  $msg = " jusqu'au $jour ".lc $mois[$mois -1]->[0]." $an";
  return $msg;
}

sub calcul_fin_annuelle_periodicite {
#Suivant le valeur de type, on a 2 sorties. L'une litérale "jour mois année",
# l'autre au format jj/mm/aaaa
  my ($type, @debut) = @_;
  my ($msg, $jour, $mois, $an, @fin, $tps, $tps_debut_semaine, @tps_dow, $total_jours_restants, $semaine_jours_restants);
  if($type == 1) { #sortie litérale
    if($parametres{annuelle} == undef) {
      $msg = "(Erreur) jusqu'au $parametres{rdv_debut_num_jour} ".lc $parametres{rdv_debut_mois}." $parametres{rdv_debut_annee} ";
    }
    elsif($parametres{annuelle} == 1) {
      ($an, $mois, $jour) = Add_Delta_YM($debut[2], $debut[1], $debut[0], $parametres{pl_mchoix2}-1, 0);
    }
    elsif($parametres{annuelle} == 2) {
      if($parametres{achoix2} <= 7) {
        ($an, $mois, $jour) = Add_Delta_YM($debut[2], $debut[1], $debut[0], $parametres{pl_mchoix2}-1, 0);
        @fin = Nth_Weekday_of_Month_Year($an, $mois, $parametres{achoix2}, $parametres{achoix1});
        if(@fin == undef) {# La 5ième semaine n'existe pas pour ce mois
          ($an, $mois, $jour) = Nth_Weekday_of_Month_Year($an, $mois, $parametres{achoix2}, $parametres{achoix1}-1);
        }
        else {
          ($an, $mois, $jour) = @fin;
        }
      }
      elsif($parametres{achoix2} == 8) {
        if($parametres{achoix1} <= 4) {
           ($an, $mois, $jour) = Add_Delta_YM($debut[2], $debut[1], $debut[0], $parametres{pl_mchoix2}-1, 0);
        }
        else {# dernier jour
          ($an, $mois, $jour) = Add_Delta_YM($debut[2], $debut[1], $debut[0], $parametres{pl_mchoix2}-1, 0);
          $jour = Days_in_Month($an, $mois);# Permet de s'assurer que l'on pointe bien sur le dernier jour du mois
        }
      }
      elsif($parametres{achoix2} == 9) {# Gestion des jours ouvrés hors jours fériés
        if($parametres{achoix1} <= 4) {
          my @tps_fin = Add_Delta_YM($debut[2], $debut[1], $debut[0], $parametres{pl_mchoix2}-1, 0);
          my @tps = Add_Delta_YM($debut[2], $parametres{achoix3}, 1, $parametres{pl_mchoix2}-1, 0);
          my $dow = Day_of_Week(@tps);
          my $nb_ouvres = 0;
AJ_OUVRES: while(1) {
            if($dow >= 6) {# C'est un samedi ou un dimanche, on passe au jour suivant
              @tps =  Add_Delta_Days(@tps, 1);
              $dow = Day_of_Week(@tps);
            }
            else {
              $nb_ouvres++;
              if($nb_ouvres == $parametres{achoix1}) {# On a le nbre de jours ouvrés souhaité
                if(Mktime(@tps, 0, 0, 0) >= Mktime(@tps_fin, 0, 0, 0)) {
                  $jour = $tps[2];
                  $mois = $tps[1];
                  $an = $tps[0];
                  last AJ_OUVRES;
                }
                else {# On recommence au début de l'année suivante
                  @tps = Add_Delta_YM($tps[0], $tps[1], 1, 1, 0);
                  $dow = Day_of_Week(@tps);
                  $nb_ouvres = 0;
                }
              }
              else {# On n'a pas le nbre de jour ouvré requis, on passe au jour suivant
                @tps =  Add_Delta_Days(@tps, 1);
                $dow = Day_of_Week(@tps);
              }
            }
          }
        }
        else {# Dernier jour ouvré
          my @tps_fin = Add_Delta_YM($debut[2], $debut[1], $debut[0], $parametres{pl_mchoix2}-1, 0);
          my @tps = Add_Delta_YM($debut[2], $parametres{achoix3}, 1, $parametres{pl_mchoix2}-1, 0);
          $tps[2]  = Days_in_Month($tps[0], $tps[1]);
          my $dow = Day_of_Week(@tps);
ADJ_OUVRE: while(1) {
            if($dow >= 6) {# C'est une samedi ou un dimanche, on recule d'un jour
              @tps =  Add_Delta_Days(@tps, -1);
              $dow = Day_of_Week(@tps);
            }
            else {
              if(Mktime(@tps, 0, 0, 0) >= Mktime(@tps_fin, 0, 0, 0)) {
                $jour = $tps[2];
                $mois = $tps[1];
                $an = $tps[0];
                last ADJ_OUVRE;
              }
              else {# On recommence au début du mois suivant
                @tps = Add_Delta_YM(@tps, 1, 0);
                $tps[2] = Days_in_Month($tps[0], $tps[1]);# On se met sur le dernier jour du mois
                $dow = Day_of_Week(@tps);
              }
            }
          }
        }
      }
    }
  }
  else {# type == 2, Sortie jj/mm/aaaa
    ;
  }
  $parametres{pl_fin_calculee} = "$an/$mois/$jour 00:00:00";
  $msg = " jusqu'au $jour ".lc $mois[$mois -1]->[0]." $an";
  return $msg;
}

  
  
sub genere_data_periodicite {
# Les données générées à partir de cette fonction sont :
# $msg_plage_periodicite : Message indiquant la péridicité
# $parametres{pl_debut_calculee}, $parametre{pl_fin_calculee}
# les nouvelles date de début et de fin du rendez-vous initial et
# la liste de tous les rendez-vous (dat de début et de fin) associés à cette périodicité
  my (@pl_debut, @debut, @fin, @no_jours, @tps_no_jours, @tps, @duree, @heure, $cpt, $jour, $mois, $an, $tps_pl_debut, $tps_debut, $dow_debut);
  print "genere_data_periodicite()", $cgi->br();
  if(exists $parametres{pl_debut}) {
    @heure = split ":",  $parametres{rdv_heure_debut};
    $heure[0]+= 0;
    $heure[1]+= 0;
    if($parametres{p_periodicite} eq 'Quotidienne') {
# Il faut gérer les cas des jours ouvrables demandes dans la périodicité ce qui peut générer une autre date de début du rendez-vous
      @pl_debut = split /\//, $parametres{pl_debut};
      $jour = $pl_debut[0] + 0;
      $mois = lcfirst $mois[$pl_debut[1] - 1]->[0];
      $msg_plage_periodicite = "$jour $mois $pl_debut[2] ";
      $parametres{pl_debut_calculee} = "$pl_debut[2]/$pl_debut[1]/$pl_debut[0] 00:00:00";
      @debut = ($jour, $pl_debut[1], $pl_debut[2], $heure[0], $heure[1]);
# @list_rdv = [id, annee_debut, mois_num_debut, jour_num_debut, annee_fin, mois_num_fin, jour_num_fin]

    }
    else {
      @pl_debut = split /\//, $parametres{pl_debut};
# conversion en numérique
      $pl_debut[0]+= 0;
      $pl_debut[1]+= 0;
      $pl_debut[2]+= 0;
      $tps_pl_debut = Mktime($pl_debut[2], $pl_debut[1], $pl_debut[0], $heure[0], $heure[1], 0);
      $mois = cherche_no_mois($pl_debut[1]);
      if($parametres{p_periodicite} eq 'Hebdomadaire') {
        $tps = $tps_pl_debut;
        $debut[0] = $pl_debut[2];
        $debut[1] = $pl_debut[1];
        $debut[2] = $pl_debut[0];
#        $debut[3] = $pl_debut[3];
#        $debut[4] = $pl_debut[4];
        $mois = lcfirst $mois[$debut[1] - 1]->[0];
        $dow_debut = Day_of_Week(@debut);
# Récupération de hebdomadaire sous forme de tableau
        @no_jours = sort ( $cgi->param('hebdomadaire') );
# Génération du tableau des dates calculée à partir de @no_jours
#        print "Valeur de tps = $tps, dim(no_jours) = ".scalar(@no_jours), $cgi->br();
        for(my $i = 0; $i < scalar(@no_jours); $i++) {
          @tps = Add_Delta_Days(@debut, $no_jours[$i] - $dow_debut);
          $tps_no_jours[$i] = Mktime(@tps, @heure, 0);
#          print "i = $i, dim (no_jours) = ". $#no_jours.", no_jours[$i] = $no_jours[$i], $no_jours[$i] - $dow_debut = $no_jours[$i] - $dow_debut, tps_no_jours[$i] = $tps_no_jours[$i]", $cgi->br();
        }
        $cpt = 7;
HEBDO: while($cpt >0) {
          for(my $i = 0; $i < scalar(@tps_no_jours); $i++) {
            if($tps <= $tps_no_jours[$i]) {
#              $jour = $debut[2];
              @debut =  (Localtime($tps_no_jours[$i]))[0..2];
              $mois = lcfirst $mois[$debut[1] - 1]->[0];
              $msg_plage_periodicite = "$debut[2] $mois $debut[0] ";
              $parametres{pl_debut_calculee} = "$debut[0]/$debut[1]/$debut[2] 00:00:00";
              last HEBDO;
            }
          }
          if($cpt == 7) {
#Debut d'une nouvelle semaine
            @debut = Add_Delta_Days(@debut, 1+$no_jours[0]);
            $dow_debut = Day_of_Week(@debut);
# Calcul directe de la date de début de la période
#            @debut =  Add_Delta_Days(@debut, $no_jours[0]);
            $tps = Mktime(@debut, @heure, 0);
            $mois = lcfirst $mois[$debut[1] - 1]->[0];
            $msg_plage_periodicite = "$debut[2] $mois $debut[0] ";
            $parametres{pl_debut_calculee} = "$debut[0]/$debut[1]/$debut[2] 00:00:00";
            last HEBDO;
          }
          else {
#         @debut contient maintenant [annee, mois, jour]
            @debut = Add_Delta_Days(@debut, 1);
            $tps = Mktime(@debut, @heure, 0);
            $dow_debut = Day_of_Week(@debut);
          }
          $cpt--;
        }
        $rdv{jour_debut} = $debut[2];
        $rdv{mois_debut} = $debut[1];
        $rdv{annee_debut} = $debut[0];
        $rdv{heure_debut} = ($heure[0]< 9) ?"0$heure[0]": "$heure[0]", ($heure[1]< 9) ? "0$heure[1]": "$heure[1]";
# La date de début du rdv ayant changé, il faut calculuer la date de fin du rdv.
# Récupération de la durée du rdv et de son heure de début
        @duree = split " ", $parametres{p_heure_duree};
# Il faudrat gérer plus tard le fait que la durée intègre des semaines et des jours

        print "l'heure de début du rdv est $heure[0]h $heure[1] mm et la durée du rdv est de : $duree[0]", $cgi->br();
        @tps = Add_Delta_DHMS(@debut, $heure[0], $heure[1], 0, 0, $duree[0], 0, 0);
        $rdv{annee_fin} = $tps[0];
        $rdv{mois_fin} = $tps[1];
        $rdv{jour_fin} = $tps[2];
        $tps[3] = ($tps[3]< 9) ?"0$tps[3]": "$tps[3]";
        $tps[4] = ($tps[4]< 9) ? "0$tps[4]": "$tps[4]";
        $rdv{heure_fin}  = "$tps[3]:$tps[4]";
        print "La date de fin du rdv est $rdv{jour_fin}/$rdv{mois_fin}/$rdv{annee_fin} $rdv{heure_fin}", $cgi->br();

# On remet @debut = [jour, mois, annee]
        my $temp = $debut[0];
        $debut[0] = $debut[2];
        $debut[2] = $temp;
        print "la date de début du rdv est le $rdv{jour_debut}/$rdv{mois_debut}/$rdv{annee_debut}", $cgi->br();
      }
      elsif($parametres{p_periodicite} eq 'Mensuelle') {
        $tps_debut = $tps_pl_debut;
        @debut = @pl_debut;
        if($parametres{mensuelle} == 1) {
# Il faut traiter le cas ou le jour est compris entre [29, 31]
          my $nb_max_mois_courant = Days_in_Month($debut[2], $debut[1]);
          my $tps_date_mois_courant = Mktime($debut[2], $debut[1],$nb_max_mois_courant, 0, 0, 0);
          my @date_suivante = Add_Delta_YM($debut[2], $debut[1], $parametres{tm1}, 0, $parametres{tm2});
          my $nb_max_mois_suivant = Days_in_Month($date_suivante[0], $date_suivante[1]);
          my $tps_date_suivante = Mktime($date_suivante[0], $date_suivante[1],$date_suivante[2], 0, 0, 0);
          my $trouve;
          my $temp = $debut[2];
          $debut[2] = $debut[0];
          $debut[0] = $temp;
# Initialisation avec le jour sélectionné par l'utilisateur
#          print "Date du mois suivant >> $date_suivante[2]/$date_suivante[1]/$date_suivante[0]", $cgi->br();
#          print "Date en cours >> $debut[2]/$debut[1]/$debut[0]", $cgi->br();
MENS1:    while($tps_debut < $tps_date_suivante) {
            if($tps_debut <= $tps_date_mois_courant) {
              if($debut[2] == $parametres{tm1}) { # mois courant
                last MENS1;
              }
            }
            @debut = Add_Delta_Days($debut[0], $debut[1], $debut[2], 1);
            $tps_debut = Mktime(@debut, 0, 0, 0);
#            print "Date en cours >> $debut[2]/$debut[1]/$debut[0]", $cgi->br();
          }
          $jour = $debut[2];
          $mois = lcfirst $mois[$debut[1] - 1]->[0];
          $msg_plage_periodicite = "$jour $mois $debut[0] ";
          $parametres{pl_debut_calculee} = "$debut[0]/$debut[1]/$debut[2] 00:00:00";
# On remet @debut = [jour, mois, annee]
          my $temp = $debut[0];
          $debut[0] = $debut[2];
          $debut[2] = $temp;
        }
        elsif($parametres{mensuelle} == 2) {
          if($parametres{mchoix2} <= 7) {
            @debut = Nth_Weekday_of_Month_Year($pl_debut[2], $pl_debut[1], $parametres{mchoix2}, $parametres{mchoix1});
            if(@debut == undef) {
              @debut = Nth_Weekday_of_Month_Year($pl_debut[2], $pl_debut[1], $parametres{mchoix2}, $parametres{mchoix1}-1);
            }
            $tps_debut = Mktime(@debut, 0, 0, 0);
            if($tps_debut < $tps_pl_debut) {
              my @new_debut = Add_Delta_YM(@debut, 0, $parametres{tm3});
              @debut = Nth_Weekday_of_Month_Year($new_debut[0], $new_debut[1], $parametres{mchoix2}, $parametres{mchoix1});
              if(@debut == undef) {
                @debut = Nth_Weekday_of_Month_Year($new_debut[0], $new_debut[1], $parametres{mchoix2}, $parametres{mchoix1}-1);
              }
            }
#            $jour = $debut[2];
            $mois = lcfirst $mois[$debut[1] - 1]->[0];
            $msg_plage_periodicite = "$debut[2] $mois $debut[0] ";
            $parametres{pl_debut_calculee} = "$debut[0]/$debut[1]/$debut[2] 00:00:00";
# On remet @debut = [jour, mois, annee]
            my $temp = $debut[0];
            $debut[0] = $debut[2];
            $debut[2] = $temp;
          }
          elsif($parametres{mchoix2} == 8) {
            if($parametres{mchoix1} <= 4) {
              $msg_plage_periodicite = "$parametres{mchoix1} ".lcfirst $mois[$debut[1] - 1]->[0]." $parametres{rdv_debut_annee}";
              $parametres{pl_debut_calculee} = "$parametres{rdv_debut_annee}/$debut[1]/$parametres{mchoix1} 00:00:00";
            }
            else {
              $msg_plage_periodicite = Days_in_Month($pl_debut[2], $pl_debut[1])." ".lcfirst $mois[$debut[1] - 1]->[0]." $pl_debut[2]";
              $parametres{pl_debut_calculee} = "$debut[2]/$pl_debut[1]/".Days_in_Month($pl_debut[2], $pl_debut[1])." 00:00:00";
            }
            @debut = @pl_debut;
          }
          elsif($parametres{mchoix2} == 9) {# Gestion des jours ouvrés
            if($parametres{mchoix1} <= 4) {# Les 4 premiers
# On commence la recherche à partir du 1er jour du mois pl_debut
              my @tps;
              $tps[2] = 1;
              $tps[1] = $pl_debut[1];
              $tps[0] = $pl_debut[2];
              my $dow = Day_of_Week(@tps);
              my $nb_ouvres = 0;
J_OUVRES:     while(1) {
                if($dow >= 6) {# C'est un samedi ou un dimanche, on passe au jour suivant
                  @tps =  Add_Delta_Days(@tps, 1);
                  $dow = Day_of_Week(@tps);
                }
                else {
                  $nb_ouvres++;
                  if($nb_ouvres == $parametres{mchoix1}) {# On a le nbre de jours ouvrés souhaité
                    if(Mktime(@tps, 0, 0, 0) >= Mktime($pl_debut[2], $pl_debut[1], $pl_debut[0], 0, 0, 0)) {
                     $jour = $tps[2];
                      $mois = lcfirst $mois[$tps[1]-1]->[0];
                      $an = $tps[0];
                      $msg_plage_periodicite = "$jour $mois $an ";
                      $parametres{pl_debut_calculee} = "$an/$tps[1]/$jour 00:00:00";
                      @debut = @pl_debut;
                      last J_OUVRES;
                    }
                    else {# On recommence au début du mois suivant
                      @tps = Add_Delta_YM($tps[0], $tps[1], 1, 0, 1);
                      $dow = Day_of_Week(@tps);
                      $nb_ouvres = 0;
                    }
                  }
                  else {# On n'a pas le nbre de jour ouvré requis, on passe au jour suivant
                    @tps =  Add_Delta_Days(@tps, 1);
                    $dow = Day_of_Week(@tps);
                  }
                }
              }
            }
            else {# Le dernier
# On recherche le dernier jour du mois à partir du @pl_debut
              my $jdernier = Days_in_Month($pl_debut[2], $pl_debut[1]);
              my @tps = ($pl_debut[2], $pl_debut[1], $jdernier);
              my $dow = Day_of_Week(@tps);
DJ_OUVRE:      while(1) {
                if($dow >= 6) {#C'est un samedi ou un dimanche
                  @tps = Add_delta_Days(@tps, -1);
                  $dow = Day_of_Week(@tps);
                }
                else {
                  if(Mktime(@tps, 0, 0, 0) >= Mktime($pl_debut[2], $pl_debut[1], $pl_debut[0], 0, 0, 0)) {
                    $msg_plage_periodicite = "$tps[2] ".lcfirst $mois[$tps[1]-1]->[0]." $tps[0] ";
                    $parametres{pl_debut_calculee} = "$tps[0]/$tps[1]/$tps[2] 00:00:00";
                    @debut = @pl_debut;
                    last DJ_OUVRE;
                  }
                  else {# On recommence au mois suivant
                      @tps = Add_Delta_YM(@tps, 0, 1);
                      $tps[2] = Days_in_Month($tps[0], $tps[1]);
                      $dow = Day_of_Week(@tps);
                  }
                }
              }
            }
          }
        }
      }
      elsif($parametres{p_periodicite} eq 'Annuelle') {
        $tps = $tps_pl_debut;
        @debut = @pl_debut;
        if($parametres{annuelle} == 1) {
# Il faut traiter le cas ou le jour est compris entre [29, 31]
#          my $nb_max_mois_courant = Days_in_Month($debut[2], $debut[1]);
#          my $tps_date_user = Mktime($debut[2], $debut[1],$nb_max_mois_courant, 0, 0, 0);
          my @date_choisie = ($pl_debut[2], $parametres{achoix}, $parametres{tm1});
          my $tps_date_choisie = Mktime(@date_choisie, 0, 0, 0);
          if($tps_date_choisie < $tps) {# On ajoute un an à date choisie
            @date_choisie = Add_Delta_YM(@date_choisie, 1, 0);
          }
          $debut[0] = $date_choisie[2];
          $debut[1] = $date_choisie[1];
          $debut[2] = $date_choisie[0];
          $mois = lcfirst $mois[$debut[1] - 1]->[0];
          $msg_plage_periodicite = "$debut[0] $mois $debut[2] ";
          $parametres{pl_debut_calculee} = "$debut[2]/$debut[1]/$debut[0] 00:00:00";
        }
        elsif($parametres{annuelle} == 2) {
          if($parametres{achoix2}<= 7) {
            my @date_choisie = Nth_Weekday_of_Month_Year($pl_debut[2], $parametres{achoix3}, $parametres{achoix2}, $parametres{achoix1});
            if(@date_choisie == undef) {
              @date_choisie = Nth_Weekday_of_Month_Year($pl_debut[2], $parametres{achoix3}, $parametres{achoix2}, $parametres{achoix1}-1);
            }
            my $tps_date_choisie = Mktime(@date_choisie, 0, 0, 0);
            if($tps_date_choisie < $tps_pl_debut) {
              @date_choisie = Nth_Weekday_of_Month_Year($pl_debut[2] + 1, $parametres{achoix3}, $parametres{achoix2}, $parametres{achoix1});
              if(@date_choisie == undef) {
                @date_choisie = Nth_Weekday_of_Month_Year($pl_debut[2] + 1, $parametres{achoix3}, $parametres{achoix2}, $parametres{achoix1}-1);
              }
            }
            $msg_plage_periodicite = "$date_choisie[2] ".lcfirst $mois[$date_choisie[1] - 1]->[0]." $date_choisie[0] ";
            $parametres{pl_debut_calculee} = "$date_choisie[0]/$date_choisie[1]/$date_choisie[2] 00:00:00";
            $debut[0] = $date_choisie[2];
            $debut[1] = $date_choisie[1];
            $debut[2] = $date_choisie[0];
          }
          elsif($parametres{achoix2} == 8) {
            if($parametres{achoix1} <= 4) {
              my @date_choisie = ($pl_debut[2], $parametres{achoix3}, $parametres{achoix1});
              my $tps_date_choisie = Mktime(@date_choisie, 0, 0, 0);
              if($tps_date_choisie < $tps_pl_debut) {
                @date_choisie = Add_Delta_YM(@date_choisie, 1, 0);
              }
              $msg_plage_periodicite = "$date_choisie[2] ".lcfirst $mois[$date_choisie[1] - 1]->[0]." $date_choisie[0] ";
              $parametres{pl_debut_calculee} = "$date_choisie[0]/$date_choisie[1]/$date_choisie[2] 00:00:00";
              $debut[0] = $date_choisie[2];
              $debut[1] = $date_choisie[1];
              $debut[2] = $date_choisie[0];
            }
            else { # Le dernier jour
              my $nb_jour_max  = Days_in_Month($pl_debut[2], $parametres{achoix3});
              my @date_choisie = ($pl_debut[2], $parametres{achoix3}, $nb_jour_max);
              my $tps_date_choisie = Mktime(@date_choisie, 0, 0, 0);
              if($tps_date_choisie < $tps_pl_debut) {
                @date_choisie = Add_Delta_YM(@date_choisie, 1, 0);
                $date_choisie[2] = Days_in_Month($date_choisie[0], $date_choisie[1]);
              }
              $msg_plage_periodicite = "$date_choisie[2] ".lcfirst $mois[$date_choisie[1] - 1]->[0]." $date_choisie[0] ";
              $parametres{pl_debut_calculee} = "$date_choisie[0]/$date_choisie[1]/$date_choisie[2] 00:00:00";
              $debut[0] = $date_choisie[2];
              $debut[1] = $date_choisie[1];
              $debut[2] = $date_choisie[0];
            }
          }
          elsif($parametres{achoix2} == 9) {#Gestion des jours ouvrés
            if($parametres{achoix1} <= 4) {
              my @date_choisie = ($pl_debut[2], $parametres{achoix3}, 1);
              my $dow = Day_of_Week(@date_choisie);
              my $nb_ouvres = 0;
AJ_OUVRES:    while(1) {
                if($dow >= 6) {# C'est un samedi ou un dimanche, on passe au jour suivant
                  @date_choisie =  Add_Delta_Days(@date_choisie, 1);
                  $dow = Day_of_Week(@date_choisie);
                }
                else {
                  $nb_ouvres++;
                  if($nb_ouvres == $parametres{achoix1}) {# On a le nbre de jours ouvrés souhaité
                    if(Mktime(@date_choisie, 0, 0, 0) >= Mktime($pl_debut[2], $pl_debut[1], $pl_debut[0], 0, 0, 0)) {
#                     $jour = $date_choisie[2];
                      $mois = lcfirst $mois[$date_choisie[1]-1]->[0];
                      $an = $date_choisie[0];
                      $msg_plage_periodicite = "$date_choisie[2] $mois $date_choisie[0] ";
                      $parametres{pl_debut_calculee} = "$date_choisie[0]/$date_choisie[1]/$date_choisie[2] 00:00:00";
#                      @debut = ($date_choisie[2], $date_choisie[1], $date_choisie[0]);
                      @debut = @pl_debut;
                      last AJ_OUVRES;
                    }
                    else {# On recommence au début du mois suivant
                      @date_choisie = Add_Delta_YM($date_choisie[0], $date_choisie[1], 1, 1, 0);
                      $dow = Day_of_Week(@date_choisie);
                      $nb_ouvres = 0;
                    }
                  }
                  else {# On n'a pas le nbre de jour ouvré requis, on passe au jour suivant
                    @date_choisie =  Add_Delta_Days(@date_choisie, 1);
                    $dow = Day_of_Week(@date_choisie);
                  }
                }
              }
              
            }
            else { # Le dernier jour ouvré

# On recherche le dernier jour du mois à partir du @pl_debut
              my $jdernier = Days_in_Month($pl_debut[2], $parametres{achoix3});
              my @tps = ($pl_debut[2], $parametres{achoix3}, $jdernier);
              my $dow = Day_of_Week(@tps);
ADJ_OUVRE:    while(1) {
                if($dow >= 6) {#C'est un samedi ou un dimanche
                  @tps = Add_Delta_Days(@tps, -1);
                  $dow = Day_of_Week(@tps);
                }
                else {
                  if(Mktime(@tps, 0, 0, 0) >= Mktime($pl_debut[2], $pl_debut[1], $pl_debut[0], 0, 0, 0)) {
                    $msg_plage_periodicite = "$tps[2] ".lcfirst $mois[$tps[1]-1]->[0]." $tps[0] ";
                    $parametres{pl_debut_calculee} = "$tps[0]/$tps[1]/$tps[2] 00:00:00";
                    @debut = @pl_debut;
                    last ADJ_OUVRE;
                  }
                  else {# On recommence l'année suivante
                      @tps = Add_Delta_YM(@tps, 1, 0);
                      $tps[2] = Days_in_Month($tps[0], $tps[1]);# On se positionne au dernier jour du mois
                      $dow = Day_of_Week(@tps);
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  else {
    $msg_plage_periodicite = "$parametres{rdv_debut_num_jour} $parametres{rdv_debut_mois} $parametres{rdv_debut_annee} ";
    $parametres{pl_debut_calculee} = "$parametres{rdv_debut_num_jour}/$parametres{rdv_debut_mois}/$parametres{rdv_debut_annee} 00:00:00";
  }
  if(exists $parametres{pl_menu_fin}) {
    if($parametres{pl_menu_fin} == 2)  {
# Calcul de la date de fin de la plage horaire en fonction du pl_mchoix2 et de
# la valeur de $parametres{p_periodicite}
      if($parametres{p_periodicite} eq 'Hebdomadaire') {
        $msg_plage_periodicite .= calcul_fin_hebdo_periodicite(1, @debut, @fin);
      }
      elsif($parametres{p_periodicite} eq 'Quotidienne') {
        $msg_plage_periodicite .= calcul_fin_quotidienne_periodicite(1, @debut);
      }
      elsif($parametres{p_periodicite} eq 'Mensuelle') {
        $msg_plage_periodicite .= calcul_fin_mensuelle_periodicite(1, @debut);
      }
      elsif($parametres{p_periodicite} eq 'Annuelle') {
        $msg_plage_periodicite.= calcul_fin_annuelle_periodicite(1, @debut);
      }
    }
    elsif($parametres{pl_menu_fin} == 3) {
      @fin =  split /\//, $parametres{pl_fin};
      $jour = $fin[0] + 0;
      $mois = lcfirst $mois[$fin[1] - 1]->[0];
      $msg_plage_periodicite .= "jusqu'au $jour $mois $fin[2] ";
    }
    else {
      ;
    }
  }
  $rdv{msg} = $msg_plage_periodicite;
  print "genere_data_periodicite() : rdv{msg} = $rdv{msg}", $cgi->br();
#  return($msg_plage_periodicite);
}

sub affiche_msg_periodicite {
  print $cgi->start_div({-id=> 'p_regle'}), $cgi->span({-class=>'decale'}, 'Périodicité : ');
  if($parametres{p_periodicite} eq 'Quotidienne') {
    if($parametres{quotidienne} == 1) {
      if($parametres{tq1} > 1) {
        print $cgi->span("A lieu tous les $parametres{tq1} jours à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
      }
      elsif($parametres{tq1} == 1) {
        print $cgi->span("A lieu tous les jours à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
      }
      else {
        print $cgi->span("A lieu tous les jours à partir du $parametres{rdv_debut_num_jour} $parametres{rdv_debut_mois} $parametres{rdv_debut_annee} de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
      }
    }
    else {
        print $cgi->span("A lieu tous les jours ouvrables à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
    }
  }
  elsif($parametres{p_periodicite} eq 'Hebdomadaire') {
    my ($liste_periodicite, @no_hebdo, @hebdo);
    my @hebdo = $cgi->param('hebdomadaire');
#    @no_hebdo = split ' ', @hebdo;
    for(my $i = 0; $i < scalar(@hebdo); $i++) {
      $liste_periodicite .= ' '.$hlabel{$hebdo[$i]}.',';
    }
    $liste_periodicite =~ s/,$//;
    if($parametres{th1} > 1) {
      print $cgi->span("A lieu toutes les $parametres{th1} semaines le".$liste_periodicite." à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
    }
    else {
     print $cgi->span("A lieu chaque semaine le".$liste_periodicite." à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
    }
  }
  elsif($parametres{p_periodicite} eq 'Mensuelle') {
    if($parametres{mensuelle} == 1) {
      if($parametres{tm1} == 1) {
        if($parametres{tm2} > 1) {
          print $cgi->span("A lieu le premier de tous les $parametres{tm2} mois à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
        }
        else {
          print $cgi->span("A lieu le premier de tous les mois à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
        }
      }
      else {
        if($parametres{tm2} > 1) {
          print $cgi->span("A lieu le $parametres{tm1} de tous les $parametres{tm2} mois à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
        }
        else {
          print $cgi->span("A lieu le $parametres{tm1} de tous les mois à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
        }
      }
    }
    else { #Cas n° 2
      if($parametres{tm3} > 1) {
        print $cgi->span("A lieu le $mlabel{$parametres{mchoix1}} $mlabel2{$parametres{mchoix2}} tous les $parametres{tm3} mois à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
      }
      else {
        print $cgi->span("A lieu le $mlabel{$parametres{mchoix1}} $mlabel2{$parametres{mchoix2}} tous les mois à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
      }
    }
  }
  elsif($parametres{p_periodicite} eq 'Annuelle') {
    if($parametres{annuelle} == 1) {
      if($parametres{ta1} > 1) {
        print $cgi->span("A lieu chaque $parametres{ta1} $alabel{$parametres{achoix}} à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
      }
      else {
        print $cgi->span("A lieu chaque premier $alabel{$parametres{achoix}} à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
      }
    }
    else {# cas = 2
      print $cgi->span("A lieu le $mlabel{$parametres{achoix1}} $mlabel2{$parametres{achoix2}} de $alabel{$parametres{achoix3}} à partir du $msg_plage_periodicite de $parametres{rdv_heure_debut} à $parametres{rdv_heure_fin}");
    }
  }
  print $cgi->end_div();
  print $cgi->hidden(-name => 'pl_debut_calculee', -value => $parametres{pl_debut_calculee}) if(exists $parametres{pl_debut_calculee});
  print $cgi->hidden(-name => 'pl_fin_calculee', -value => $parametres{pl_fin_calculee}) if(exists $parametres{pl_fin_calculee});
  print $cgi->hidden(-name => 'msg', -value => $msg_plage_periodicite);
  print $cgi->p("Valeur de pl_debut_calculee = <$parametres{pl_debut_calculee}>, de pl_fin_calculee = <$parametres{pl_fin_calculee}>");
}

sub affiche_ecran_p_quotidienne {
  if(exists $parametres{r_quotidienne}) {
    if($parametres{r_quotidienne} == 1) {
#      print "parametres{r_quotidienne} = $parametres{r_quotidienne}, parametres{r_tq1} = $parametres{r_tq1}", $cgi->br();
      print $cgi->radio_group(-name => 'quotidienne', -values => \@choix, -default => '1', -labels => \%qlabel, -columns=>1);
      print $cgi->start_div({-id =>'q1'}), $cgi->span('Tous les '), $cgi->textfield(-name=>'tq1', -default => $parametres{r_tq1}, -size =>3, -maxlength =>5, -onfocus=> "return p_quotidienne_choisie(this);"), $cgi->span(' jour(s)'), $cgi->end_div();
    }
    else {
      print $cgi->radio_group(-name => 'quotidienne', -values => \@choix, -default => '2', -labels => \%qlabel, -columns=>1);
      print $cgi->start_div({-id =>'q1'}), $cgi->span('Tous les '), $cgi->textfield(-name=>'tq1', -default => '1', -size =>3, -maxlength =>5, -onfocus=> "return p_quotidienne_choisie(this);"), $cgi->span(' jour(s)'), $cgi->end_div();
    }
  }
  else {
    print $cgi->radio_group(-name => 'quotidienne', -values => \@choix, -default => '1', -labels => \%qlabel, -columns=>1);
    print $cgi->start_div({-id =>'q1'}), $cgi->span('Tous les '), $cgi->textfield(-name=>'tq1', -default => '1', -size =>3, -maxlength =>5, -onfocus=> "return p_quotidienne_choisie(this);"), $cgi->span(' jour(s)'), $cgi->end_div();
  }
  print $cgi->div('Tous les jours ouvrables');
}

sub affiche_ecran_p_hebdomadaire {
  my ($dow) = @_;
  my @hebdo;
  if(exists $parametres{r_th1}) {
    print $cgi->span({-class=> 'decale'}, 'Toutes les '), $cgi->textfield(-name=>'th1', -default=>$parametres{r_th1}, -size=>3, -maxlength=>5), $cgi->span(' semaine(s) le :');
  }
  else {
    print $cgi->span({-class=> 'decale'}, 'Toutes les '), $cgi->textfield(-name=>'th1', -default=>'1', -size=>3, -maxlength=>5), $cgi->span(' semaine(s) le :');
  }
  if(exists $parametres{r_hebdomadaire}) {
     @hebdo = split " ", $parametres{r_hebdomadaire};
     print $cgi->start_div(), $cgi->checkbox_group(-name=>'hebdomadaire', -values=>\@hchoix, -labels => \%hlabel, -default=>\@hebdo, -columns=>3), $cgi->end_div();
  }
  else {
    print $cgi->start_div(), $cgi->checkbox_group(-name=>'hebdomadaire', -values=>\@hchoix, -labels => \%hlabel, -default=>$dow, -columns=>3), $cgi->end_div();
  }
}

sub affiche_ecran_p_mensuelle {
  my ($dow, $mois) = @_;
  my $no_semaine = calcul_nieme_dow_mois($dow, $mois);
  print "La date de début est : $parametres{rdv_debut_num_jour}/$mois/$parametres{rdv_debut_annee} ce qui correspond au $no_semaine ième $mlabel2{$dow} de la semaine", $cgi->br();
  my $choix_mensuelle = (exists $parametres{r_mensuelle}) ? $parametres{r_mensuelle} : $choix[0];
  print $cgi->radio_group(-name => 'mensuelle', -values => \@choix, -default => $choix_mensuelle, -labels => \%qlabel, -columns=>1);
  if(exists $parametres{r_mensuelle}){
    if($parametres{r_mensuelle} == 1) {
#      print $cgi->start_div(), $cgi->span('Le '), $cgi->textfield(-name=>'tm1', -default =>$parametres{tm1}, -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' tous les '), $cgi->textfield(-name=>'tm2', -default =>$parametres{tm2}, -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' mois'), $cgi->end_div();
      print $cgi->start_div(), $cgi->span('Le '), $cgi->textfield(-name=>'tm1', -default =>$parametres{rdv_debut_num_jour}, -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' tous les '), $cgi->textfield(-name=>'tm2', -default =>$parametres{r_tm2}, -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' mois'), $cgi->end_div();
      print $cgi->start_div(), $cgi->span('Le '), $cgi->popup_menu(-name=>'mchoix1', -values => \@mchoix, -labels => \%mlabel, -default=> $no_semaine, -onChange=>"return p_mensuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'mchoix2', -values => \@mchoix2, -labels => \%mlabel2, -default=> $dow, -onChange=>"return p_mensuelle_choisie(this);"), $cgi->span(' tous les '), $cgi->textfield(-name=>'tm3', -default => '1', -size =>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' mois'), $cgi->end_div();
    }
    else { # cas = 2
      print $cgi->start_div(), $cgi->span('Le '), $cgi->textfield(-name=>'tm1', -default =>$parametres{rdv_debut_num_jour}, -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' tous les '), $cgi->textfield(-name=>'tm2', -default =>'1', -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' mois'), $cgi->end_div();
      print $cgi->start_div(), $cgi->span('Le '), $cgi->popup_menu(-name=>'mchoix1', -values => \@mchoix, -labels => \%mlabel, -default=> $parametres{r_mchoix1}, -onChange=>"return p_mensuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'mchoix2', -values => \@mchoix2, -labels => \%mlabel2, -default=> $parametres{r_mchoix2}, -onChange=>"return p_mensuelle_choisie(this);"), $cgi->span(' tous les '), $cgi->textfield(-name=>'tm3', -default => $parametres{r_tm3}, -size =>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' mois'), $cgi->end_div();
    }
  }
  else {
    print $cgi->start_div(), $cgi->span('Le '), $cgi->textfield(-name=>'tm1', -default =>$parametres{rdv_debut_num_jour}, -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' tous les '), $cgi->textfield(-name=>'tm2', -default =>'1', -size=>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' mois'), $cgi->end_div();
    print $cgi->start_div(), $cgi->span('Le '), $cgi->popup_menu(-name=>'mchoix1', -values => \@mchoix, -labels => \%mlabel, -default=> $no_semaine, -onChange=>"return p_mensuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'mchoix2', -values => \@mchoix2, -labels => \%mlabel2, -default=> $dow, -onChange=>"return p_mensuelle_choisie(this);"), $cgi->span(' tous les '), $cgi->textfield(-name=>'tm3', -default => '1', -size =>3, -maxlength=>5, -onfocus => "return p_mensuelle_choisie(this);"), $cgi->span(' mois'), $cgi->end_div();
  }
}

sub affiche_ecran_p_annuelle {
  my ($dow, $mois) = @_;
  my $no_semaine = calcul_nieme_dow_mois($dow, $mois);
#  print "La date de début est : $parametres{rdv_debut_num_jour}/$mois/$parametres{rdv_debut_annee} ce qui correspond au $dow de la semaine", $cgi->br();
  my $choix_annuelle = (exists $parametres{r_annuelle}) ? $parametres{r_annuelle} : $choix[0];
  print $cgi->radio_group(-name => 'annuelle', -values => \@choix, -default => $choix_annuelle, -labels => \%qlabel, -columns=>1);
  if(exists $parametres{r_annuelle}) {
    if($parametres{r_annuelle} == 1) {
        print $cgi->start_div(), $cgi->span('Chaque '), $cgi->textfield(-name=>'ta1', -default =>$parametres{r_ta1}, -size=>3, -maxlength=>5, -onfocus => "return p_annuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'achoix', -values => \@achoix, -labels => \%alabel, -default=> $parametres{r_achoix}, -onChange=> "return p_annuelle_choisie(this);"), $cgi->end_div();
        print $cgi->start_div(), $cgi->span('Le '), $cgi->popup_menu(-name=>'achoix1', -values => \@mchoix, -labels => \%mlabel, -default=> $no_semaine, -onChange=> "return p_annuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'achoix2', -values => \@mchoix2, -labels => \%mlabel2, -default=> $dow, -onChange=> "return p_annuelle_choisie(this);"), $cgi->span(' de '), $cgi->popup_menu(-name=>'achoix3', -values => \@achoix, -labels => \%alabel, -default=> $mois, -onChange=> "return p_annuelle_choisie(this);"), $cgi->end_div();
    }
    else { #cas = 2
        print $cgi->start_div(), $cgi->span('Chaque '), $cgi->textfield(-name=>'ta1', -default =>$parametres{rdv_debut_num_jour}, -size=>3, -maxlength=>5, -onfocus => "return p_annuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'achoix', -values => \@achoix, -labels => \%alabel, -default=> $mois, -onChange=> "return p_annuelle_choisie(this);"), $cgi->end_div();
        print $cgi->start_div(), $cgi->span('Le '), $cgi->popup_menu(-name=>'achoix1', -values => \@mchoix, -labels => \%mlabel, -default=> $parametres{r_achoix1}, -onChange=> "return p_annuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'achoix2', -values => \@mchoix2, -labels => \%mlabel2, -default=> $parametres{r_achoix2}, -onChange=> "return p_annuelle_choisie(this);"), $cgi->span(' de '), $cgi->popup_menu(-name=>'achoix3', -values => \@achoix, -labels => \%alabel, -default=> $parametres{r_achoix3}, -onChange=> "return p_annuelle_choisie(this);"), $cgi->end_div();
    }
  }
  else {
    print $cgi->start_div(), $cgi->span('Chaque '), $cgi->textfield(-name=>'ta1', -default =>$parametres{rdv_debut_num_jour}, -size=>3, -maxlength=>5, -onfocus => "return p_annuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'achoix', -values => \@achoix, -labels => \%alabel, -default=> $mois, -onChange=> "return p_annuelle_choisie(this);"), $cgi->end_div();
    print $cgi->start_div(), $cgi->span('Le '), $cgi->popup_menu(-name=>'achoix1', -values => \@mchoix, -labels => \%mlabel, -default=> $no_semaine, -onChange=> "return p_annuelle_choisie(this);"), $cgi->span(' '), $cgi->popup_menu(-name=>'achoix2', -values => \@mchoix2, -labels => \%mlabel2, -default=> $dow, -onChange=> "return p_annuelle_choisie(this);"), $cgi->span(' de '), $cgi->popup_menu(-name=>'achoix3', -values => \@achoix, -labels => \%alabel, -default=> $mois, -onChange=> "return p_annuelle_choisie(this);"), $cgi->end_div();
  }
}

sub calcul_nieme_dow_mois {
# Cherche dans le mois à  quel nième jour de la semaine correspond la date donnée
  my ($dow, $mois) = @_;
  my @date;
  for(my $i = 1; $i < 6; $i++) {
    @date = Nth_Weekday_of_Month_Year($parametres{rdv_debut_annee}, $mois, $dow, $i);
    if($date[2] == $parametres{rdv_debut_num_jour}) {
      return $i;
    }
  }
  return undef;
}

sub gestion_champs_caches_periodicite {
#  print "exécution de la fonction gestion_champs_caches_periodicite", $cgi->br();
  foreach (keys %parametres) {
    next if(($_ eq 'pl_debut_calculee') || ($_ eq 'pl_fin_calculee') || ($_ eq 'r_pl_debut') || ($_ eq 'r_pl_fin') || ($_ eq 'r_pl_menu_fin') || ($_ eq 'r_pl_mchoix2') || ($_ eq 'r_tq1') || ($_ eq 'r_th1') || ($_ eq 'r_tm1') || ($_ eq 'r_tm2') || ($_ eq 'r_tm3') || ($_ eq 'r_ta1') || ($_ eq 'r_achoix') || ($_ eq 'r_achoix1') || ($_ eq 'r_achoix2') || ($_ eq 'r_achoix3') || ($_ eq 'r_mchoix1') || ($_ eq 'r_mchoix2') ||( $_ eq 'r_hebdomadaire') || ($_ eq 'rp_periodicite') || ($_ eq 'r_quotidienne') || ($_ eq 'r_annuelle') || ($_ eq 'r_mensuelle'));
    print $cgi->hidden(-name => "$_", value => $parametres{$_});
#    print "$_ = $parametres{$_} " if(($_ eq 'p_periodicite') || ($_ eq 'rp_periodicite'));
  }
}


sub recherche_autres_rdv {
  ;
}

sub recherche_emplacements {
 ;
}

sub affiche_les_zones {
    affiche_debut_corps_de_page();
    affiche_menu_droit();
    affiche_bas_de_page();
    affiche_fin_corps_de_page();
}
sub affiche_entete_impression {
  print $cgi->start_div({-id=>'entete_impression'}), "$collaborateur[2] $collaborateur[1]", $cgi->hr(), $cgi->end_div();
}

sub affiche_info_impression {
  print $cgi->div({-id=>'info_impression'}, "Pour imprimer, utiliser la fonction print (CRTL+P) ou la fonction aperçu avant impression de votre browser");
}

sub affiche_debut_corps_de_page {
  print "\n", $cgi->start_div({-id => "corps"});
}

sub affiche_bas_de_page  {
  print "\n", $cgi->start_div({id=>"basdepage"});
  print "\n", $cgi->img({-src=>"$rep/images/basdepage.gif", -alt=> "Bas de page"});
  print "\n", $cgi->end_div();
}

sub affiche_fin_corps_de_page {
  print "\n", $cgi->end_div();
  print "\n", $cgi->end_html();
}


sub affiche_barre_outils {
  print $cgi->start_div({id =>'barre_outils'});
  print $cgi->submit(-name => "s_action", value => "Enregistrer et fermer");
  print $cgi->submit(-name => "s_action", value => "Imprimer");
  print $cgi->submit(-name => "s_action", value => "Périodicité");
  print $cgi->submit(-name => "s_action", value => "Inviter les participants");
  print $cgi->submit(-name => "s_action", value => "Supprimer", onclick => 'return delete_rdv();');
  print $cgi->submit(-name => "s_action", value => "Annuler", onclick => 'return annuler();');
  print $cgi->end_div();
}

sub affiche_boutons_periodicite {
  print $cgi->start_div({-id=>'barre_boutons'});
  print $cgi->submit(-name => 'bouton', value => 'OK', -onclick=> "return valide_ecran_periodicite();");
  print $cgi->submit(-name => 'bouton', value => 'Annuler');
  if(exists $parametres{rp_periodicite}) {
    print $cgi->submit(-name => 'bouton', value => 'Supprimer');
  }
  else {
    print $cgi->submit(-name => 'bouton', value => 'Supprimer', -disabled);
  }
  print $cgi->end_div();
}



sub gestion_des_champs_caches {
#  print "exécution de la fonction gestion_des_champs_caches", $cgi->br();
  if(exists $parametres{hebdomadaire}) {
    my @hebdo = $cgi->param('hebdomadaire');
    $parametres{hebdomadaire} = \@hebdo;
  }
#  if((exists $parametres{hebdomadaire}) && (ref($parametres{hebdomadaire}) == 'ARRAY')) {
#    print "Valeurs de hebdomadaire = @{$parametres{hebdomadaire}}", $cgi->br();
#  }
  print $cgi->hidden(-name => 'action', -value => $parametres{action});
  print $cgi->hidden(-name => 'affichage_rdv', -value => $parametres{affichage_rdv});
  print $cgi->hidden(-name => 'affichage_heure', -value => $parametres{affichage_heure});
  print $cgi->hidden(-name => 'ident_user', -value => $parametres{ident_user});
  print $cgi->hidden(-name => 'ident_id', -value => $parametres{ident_id});
  print $cgi->hidden(-name => 'rdv', -value => $rdv{id}) if(exists $rdv{id});
  print $cgi->hidden(-name => 'id_ref', -value => $rdv{id_ref}) if(exists $rdv{id_ref});

# Gestion de la périodicité
  if(exists $parametres{bouton} && ($parametres{bouton} eq 'OK')) {
    print $cgi->hidden(-name => 'rp_periodicite', -value => $parametres{p_periodicite}) if(exists $parametres{p_periodicite});
	my $list_rdv;
	foreach (@list_rdv) {
	  $list_rdv .= "@{$_} ";
	}
	print $cgi->hidden(-name => 'list_rdv', -value => $list_rdv);
    if(exists $parametres{quotidienne}) {
      print $cgi->hidden(-name => 'r_quotidienne', -value => $parametres{quotidienne});
      print $cgi->hidden(-name => 'r_tq1', -value => $parametres{tq1});
    }
    if(exists $parametres{hebdomadaire}) {
      print $cgi->hidden(-name => 'r_hebdomadaire', -value => "@{$parametres{hebdomadaire}}");
      print $cgi->hidden(-name => 'r_th1', -value => $parametres{th1}) if(exists $parametres{th1});
    }
    if(exists $parametres{mensuelle}) {
      print $cgi->hidden(-name => 'r_mensuelle', -value => $parametres{mensuelle});
      if($parametres{mensuelle} == 1) {
        print $cgi->hidden(-name => 'r_tm1', -value => $parametres{tm1});
        print $cgi->hidden(-name => 'r_tm2', -value => $parametres{tm2});
      }
      else {# Cas = 2
        print $cgi->hidden(-name => 'r_mchoix1', -value => $parametres{mchoix1});
        print $cgi->hidden(-name => 'r_mchoix2', -value => $parametres{mchoix2});
        print $cgi->hidden(-name => 'r_tm3', -value => $parametres{tm3});
      }
    }
    if(exists $parametres{annuelle}) {
      print $cgi->hidden(-name => 'r_annuelle', -value => $parametres{annuelle});
      if($parametres{annuelle} == 1) {
        print $cgi->hidden(-name => 'r_ta1', -value => $parametres{ta1});
        print $cgi->hidden(-name => 'r_achoix', -value => $parametres{achoix});
      }
      else {# cas = 2
        print $cgi->hidden(-name => 'r_achoix1', -value => $parametres{achoix1});
        print $cgi->hidden(-name => 'r_achoix2', -value => $parametres{achoix2});
        print $cgi->hidden(-name => 'r_achoix3', -value => $parametres{achoix3});
      }
    }
    if(exists $parametres{pl_menu_fin}) {
      print $cgi->hidden(-name =>'r_pl_menu_fin', -value => $parametres{pl_menu_fin});
      if($parametres{pl_menu_fin} == 2) {
        print $cgi->hidden(-name=>'r_pl_mchoix2', -value => $parametres{pl_mchoix2});
      }
      elsif($parametres{pl_menu_fin} == 3) {
        print $cgi->hidden(-name=>'r_pl_fin', -value => $parametres{pl_fin});
      }
    }
    print $cgi->hidden(-name =>'r_pl_debut', -value => $parametres{pl_debut}) if(exists $parametres{pl_debut});
  }
}

sub cherche_no_mois {
  my ($m) = @_;
  foreach (0.. $#mois) {
    if($mois[$_]->[0] eq $m) {
      return $mois[$_]->[1];
    }
  }
}

sub cherche_no_rappel {
  if(exists $parametres{rdv_rappel}) {
    for(my $i = 0; $i < $#list_rappels; $i++) {
      if($list_rappels[$i] eq $parametres{rdv_rappel}) {
        return $i;
      }
    }
  }
  else {
    return -1;
  }
}
sub gere_info_periodicite {
# Permet de gérer les informations retournées par le bouton OK de l'écran de
# Périodicité. Si le début de la plage horaire est supérieure à l'heure du rdv
# alors la plage horaire du rdv est déplacée de la différence.
# Les éléments pris en compte dans les modifications sont :
# le début de la plage horaire, les heures de début, de fin et la durée du rdv
  my ($vide, $heure, $mn, @pl_debut, @p_heure_debut, @p_heure_fin, $tps_p_debut, $tps_diff);
  my (@duree, @duree_num);
  $rdv{id} = $parametres{rdv} if(exists $parametres{rdv});
#  $rdv{id_user} = $rdv->{id_user};
  $rdv{objet} = $parametres{rdv_objet} if(length $parametres{rdv_objet} > 0);
  $rdv{lieu} = $parametres{rdv_emplt} if(length $parametres{rdv_emplt} > 0);
  $rdv{rappel} = $parametres{rdv_rappel} if ($parametres{rdv_rappel} > -1);
  $mois = cherche_no_mois($parametres{rdv_debut_mois});
  @p_heure_debut = split /:/, $parametres{rdv_heure_debut};
  $tps_debut = Mktime($parametres{rdv_debut_annee}, $mois, $parametres{rdv_debut_num_jour}, $p_heure_debut[0]+0, $p_heure_debut[1]+0, 0);
# Prise en compte de la plage horaire de la periodicité pour déterminer la date du rendez-vous
  if(exists $parametres{pl_debut}) {
    @pl_debut = split /\//, $parametres{pl_debut};
    @p_heure_debut = split /:/, $parametres{p_heure_debut};

    $tps_p_debut = Mktime($pl_debut[2], $pl_debut[1]+0, $pl_debut[0]+0, $p_heure_debut[0]+0, $p_heure_debut[1]+0, 0);
#    $pl_debut[0]+= 0;
    if(($tps_diff = $tps_p_debut - $tps_debut) > 0) {
      $tps_debut = $tps_p_debut;
      $parametres{rdv_debut_annee} = $pl_debut[2];
      $mois = $pl_debut[1]+0;
      $parametres{rdv_debut_mois} = ucfirst $alabel{$mois};
      $parametres{rdv_debut_num_jour} = $pl_debut[0]+0;

    }
  }
  $rdv{annee_debut} = $parametres{rdv_debut_annee};
  $rdv{mois_debut} = $mois;
  $rdv{jour_debut} = $parametres{rdv_debut_num_jour};
  $rdv{heure_debut} = $parametres{rdv_heure_debut};
  $mois = cherche_no_mois($parametres{rdv_fin_mois});
  ($heure, $mn) = split /:/, $parametres{p_heure_fin};
  $tps_fin = Mktime($parametres{rdv_fin_annee}, $mois, $parametres{rdv_fin_num_jour}, $heure, $mn, 0);
  if($tps_diff > 0) {
    $tps_fin += $tps_diff;
    ($parametres{rdv_fin_annee}, $mois, $parametres{rdv_fin_num_jour}) = (Localtime($tps_fin))[0..2];
    $parametres{rdv_fin_mois} = ucfirst($alabel{$mois});
  }
  $rdv{annee_fin} = $parametres{rdv_fin_annee};
  $rdv{mois_fin} = $mois;
  $rdv{jour_fin} = $parametres{rdv_fin_num_jour};
  $rdv{heure_fin} = $parametres{p_heure_fin};
  @p_heure_fin = split /:/, $parametres{p_heure_fin};
  if(($tps_fin - $tps_debut) >= 86400) {
    $tps = Mktime($parametres{rdv_fin_annee}, $mois, $parametres{rdv_fin_num_jour}, 0, 0, 0);
  }
  else {
    $tps = $tps_debut + $pas;
  }
# @list_rdv = [id, tps_debut, tps_fin, annee_debut, mois_num_debut, jour_num_debut, heure_debut, mn_debut, annee_fin, mois_num_fin, jour_num_fin, heure_fin, mn_fin]
  push @list_rdv, [ 0, $tps_debut, $tps_fin, $rdv{annee_debut}, $rdv{mois_fin}, $rdv{jour_debut}, $p_heure_debut[0] + 0, $p_heure_debut[1] + 0, $rdv{annee_fin}, $rdv{mois_fin}, $rdv{jour_fin}, $p_heure_fin[0] + 0, $p_heure_fin[1] + 0  ];

# Prenons en compte les autres informations retournées dans l'écran Périodicité
#  Le type du jour de début et de fin de la plage horaire
  genere_data_periodicite();
}

sub gere_info_plage_horaire {
  ;
}

sub gere_suppression_periodicite {
# permet la suppression de la périodicité en prenant en compte les aspects base de données
  print "La fonction de gestion de la suppression de la périodicité est en cours de développement...", $cgi->br();
  delete $parametres{p_periodicite};
}

################ Requêtes SQL  ###############################################
sub db_enregistre_rdv {
  my ($id_periode, $id_ref, $sql, $sth, $periode, $ref_ligne);
  my $mois_debut = cherche_no_mois($parametres{rdv_debut_mois});
  my $mois_fin = cherche_no_mois($parametres{rdv_fin_mois});
  my $debut = "$parametres{rdv_debut_annee}-$mois_debut-$parametres{rdv_debut_num_jour} $parametres{rdv_heure_debut}:00";
  $parametres{rdv_heure_fin} =~ /(\d+):(\d)/;
  my $fin = "$parametres{rdv_fin_annee}-$mois_fin-$parametres{rdv_fin_num_jour} $1:$2:00";
  my $rappel = cherche_no_rappel();
  if(exists $parametres{rp_periodicite}) {#Si le rdv a une périodicité
    if($parametres{rp_periodicite} eq 'Quotidienne') {
      $periode = '1';
    }
    elsif($parametres{rp_periodicite} eq 'Hebdomadaire') {
      $periode = '2';
    }
    elsif($parametres{rp_periodicite} eq 'Mensuelle') {
      $periode = '3';
    }
    elsif($parametres{rp_periodicite} eq 'Annuelle') {
      $periode = '4';
    }
    print "Le rendez-vous à une periodicité de : $parametres{rp_periodicite}", $cgi->br();
    if(exists $parametres{rdv}) {
      ;
    }
    else {# Le rendez-vous n'existe pas, il faut le créer avec sa périodicité
      $id_periode = id_periodicite();
      if(exists $parametres{pl_debut_calculee} && exists $parametres{pl_fin_calculee}) {
        $sql = "INSERT INTO rdv_periodique (periode, id_periode, dperiode, fperiode, msg) VALUES ($periode, ".$dbh->quote($id_periode).", ".$dbh->quote($parametres{pl_debut_calculee}).", ".$dbh->quote($parametres{pl_fin_calculee}).", ".$dbh->quote($parametres{msg}).")";
        $dbh->do($sql) or die " Erreur : $dbh->errstr";
      }
      elsif(exists $parametres{pl_debut_calculee} && !exists $parametres{pl_fin_calculee}) {
        if($parametres{r_pl_menu_fin} == 1) {
          $sql = "INSERT INTO rdv_periodique (periode, id_periode, dperiode, msg) VALUES ($periode, ".$dbh->quote($id_periode).", ".$dbh->quote($parametres{pl_debut_calculee}).", ".$dbh->quote($parametres{msg}).")";
          $dbh->do($sql) or die " Erreur : $dbh->errstr";
        }
        else {#$parametres{r_pl_menu_fin} == 3
          $sql = "INSERT INTO rdv_periodique (periode, id_periode, dperiode, fperiode, msg) VALUES ($periode, ".$dbh->quote($id_periode).", ".$dbh->quote($parametres{pl_debut_calculee}).", ".$dbh->quote($parametres{r_pl_fin}).", ".$dbh->quote($parametres{msg}).")";
          $dbh->do($sql) or die " Erreur : $dbh->errstr";
        }
      }
      elsif(!exists $parametres{pl_debut_calculee} && !exists $parametres{pl_fin_calculee}) {
        if($parametres{r_pl_menu_fin} == 1) {
          $sql = "INSERT INTO rdv_periodique (periode, id_periode, dperiode, msg) VALUES ($periode, ".$dbh->quote($id_periode).", ".$dbh->quote($parametres{r_pl_debut}).", ".$dbh->quote($parametres{msg}).")";
          $dbh->do($sql) or die " Erreur : $dbh->errstr";
        }
        else {#$parametres{r_pl_menu_fin} == 3
          $sql = "INSERT INTO rdv_periodique (periode, id_periode, dperiode, fperiode, msg) VALUES ($periode, ".$dbh->quote($id_periode).", ".$dbh->quote($parametres{r_pl_debut}).", ".$dbh->quote($parametres{r_pl_fin}).", ".$dbh->quote($parametres{msg}).")";
          $dbh->do($sql) or die " Erreur : $dbh->errstr";
        }
      }
      elsif(!exists $parametres{pl_debut_calculee} && exists $parametres{pl_fin_calculee}) {
        $sql = "INSERT INTO rdv_periodique (periode, id_periode, dperiode, fperiode, msg) VALUES ($periode, ".$dbh->quote($id_periode).", ".$dbh->quote($parametres{r_pl_debut}).", ".$dbh->quote($parametres{pl_fin_calculee}).", ".$dbh->quote($parametres{msg}).")";
        $dbh->do($sql) or die " Erreur : $dbh->errstr";
      }
      $id_ref = $dbh->{mysql_insertid};
	  @list_rdv = $parametres{list_rdv} =~ /(\d+-\d+-\d+ \d+:\d+:\d+) (\d+-\d+-\d+ \d+:\d+:\d+)/g;
#	  print "le tableau list_rdv contient ".scalar(@list_rdv)." dont le premier sous-tableau est : @list_rdv", $cgi->br();
#	  print "Valeur de 1 = $1, Valeur de 2 = $2", $cgi->br();
      $sql = "INSERT INTO rdv (id_user, id_ref, debut, fin, objet, lieu, rappel) VALUES (?, ?, ?, ?, ?, ?, ?)";
	  $sth = $dbh->prepare($sql);
	  $sth->bind_param(1, $collaborateur[0]);
	  $sth->bind_param(2, $id_ref);
	  $sth->bind_param(5, $parametres{rdv_objet});
	  $sth->bind_param(6, $parametres{rdv_emplt});
	  $sth->bind_param(7, $dbh->quote($rappel));
	  for(my $i = 0; $i < scalar(@list_rdv)/2; $i++) {	    
        print "RDV : Date de début = $list_rdv[2*$i], Date de fin = $list_rdv[2*$i + 1]", $cgi->br();	  
		$sth->bind_param(3, $list_rdv[2*$i]);
	    $sth->bind_param(4, $list_rdv[2*$i + 1]);
		$sth->execute() or die "Erreur : $sth->errstr";
	  }
    }
	####### Maintenant, il faut créer les rendez-vous de la période concernée ####
### On utiliser la structure générée à partir de fonctions calcul_fin_xxx_periodicite
  }
  else {### Le rendez-vous n'a pas de périodicité
#  print "Valeur de date de début : $debut, valeur de date de fin : $fin, le N° du rappel est : $rappel", $cgi->br();
    if(exists $parametres{rdv}) {
      $sql = "UPDATE rdv SET debut = ".$dbh->quote($debut).", fin = ".$dbh->quote($fin).", objet = ".$dbh->quote($parametres{rdv_objet}).", lieu = ".$dbh->quote($parametres{rdv_emplt}).", rappel = ".$dbh->quote($rappel)." WHERE id = ".$dbh->quote($parametres{rdv});
    }
    else {
      $sql = "INSERT INTO rdv (id_user, debut, fin, objet, lieu, rappel) VALUES (".$dbh->quote($collaborateur[0])." ,".$dbh->quote($debut)." ,".$dbh->quote($fin)." ,".$dbh->quote($parametres{rdv_objet})." ,".$dbh->quote($parametres{rdv_emplt})." ,".$dbh->quote($rappel).")";
    }
#  print "SQL = $sql", $cgi->br();
    $dbh->do($sql) or die " Erreur : $dbh->errstr";
  }
}

sub db_supprime_rdv {
# Attention, il faudra prendre en compte la suppression des occurences quand il
# y aura des rendez-vous avec périodicité
  my $sql;
  if(exists $parametres{rdv}) {
    $sql = "DELETE FROM rdv  WHERE id = ".$dbh->quote($parametres{rdv})." AND id_user = ".$dbh->quote($collaborateur[0]);
  }
#  print "SQL = $sql", $cgi->br();
  $dbh->do($sql) or die " Erreur : $dbh->errstr";
}

sub id_periodicite() {
  my ($sql, $sth, $ref_ligne);
# Création d'une ligne dans la table correspondant à la bonne période
  if($parametres{rp_periodicite} eq 'Quotidienne') {
    if($parametres{r_quotidienne} == 1) {
      $sql = "SELECT * FROM rdv_qperiode WHERE type = '1' AND xperiode = ".$dbh->quote($parametres{r_tq1});
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $ref_ligne = $sth->fetchrow_hashref;
      if((exists $ref_ligne->{id}) && ($ref_ligne->{id} >0)) {
        return $ref_ligne->{id};
      }
      else {
        $sql = "INSERT INTO rdv_qperiode (type, xperiode) VALUES ('1', ".$dbh->quote($parametres{r_tq1}).")";
        $dbh->do($sql);
        $sql = "SELECT * FROM rdv_qperiode WHERE type = '1' AND xperiode = ".$dbh->quote($parametres{r_tq1});
        $sth = $dbh->prepare($sql);
        $sth->execute();
        $ref_ligne = $sth->fetchrow_hashref;
        return $ref_ligne->{id};
       }
    }
    else {
      $sql = "SELECT * FROM rdv_qperiode WHERE type = '2'";
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $ref_ligne = $sth->fetchrow_hashref;
      if((exists $ref_ligne->{id}) && ($ref_ligne->{id} >0)) {
        return $ref_ligne->{id};
      }
      else {
        $sql = "INSERT INTO rdv_qperiode (type) VALUES ('2')";
        $dbh->do($sql);
        $sql = "SELECT * FROM rdv_qperiode WHERE type = '2'";
        $sth = $dbh->prepare($sql);
        $sth->execute();
        $ref_ligne = $sth->fetchrow_hashref;
        return $ref_ligne->{id};
      }
    }
  }
  elsif($parametres{rp_periodicite} eq 'Hebdomadaire') {
    $sql = "SELECT * FROM rdv_hperiode WHERE xsemaine = ".$dbh->quote($parametres{r_th1})." AND jour = ".$dbh->quote($parametres{r_hebdomadaire});
    $sth = $dbh->prepare($sql);
    $sth->execute();
    $ref_ligne = $sth->fetchrow_hashref;
    if(exists $ref_ligne->{id} && ($ref_ligne->{id} >0)) {
      return $ref_ligne->{id};
    }
    else {
      $sql = "INSERT INTO rdv_hperiode (xsemaine, jour) VALUES (".$dbh->quote($parametres{r_th1}).", ".$dbh->quote($parametres{r_hebdomadaire}).")";
      $dbh->do($sql);
      $sql = "SELECT * FROM rdv_hperiode WHERE xsemaine = ".$dbh->quote($parametres{r_th1})." AND jour = ".$dbh->quote($parametres{r_hebdomadaire});
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $ref_ligne = $sth->fetchrow_hashref;
      return $ref_ligne->{id};
    }
  }
  elsif($parametres{rp_periodicite} eq 'Mensuelle') {
    if($parametres{r_mensuelle} == 1) {
      $sql = "SELECT * FROM rdv_mperiode WHERE m2 = ".$dbh->quote($parametres{r_tm1})." AND m3 = ".$dbh->quote($parametres{r_tm2});
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $ref_ligne = $sth->fetchrow_hashref;
      if(exists $ref_ligne->{id} && ($ref_ligne->{id} >0)) {
        return $ref_ligne->{id};
      }
      else {
        $sql = "INSERT INTO rdv_mperiode (m2, m3) VALUES (".$dbh->quote($parametres{r_tm1}).", ".$dbh->quote($parametres{r_tm2}).")";
        $dbh->do($sql);
        $sql = "SELECT * FROM rdv_mperiode WHERE m2 = ".$dbh->quote($parametres{r_tm1})." AND m3 = ".$dbh->quote($parametres{r_tm2});
        $sth = $dbh->prepare($sql);
        $sth->execute();
        $ref_ligne = $sth->fetchrow_hashref;
        return $ref_ligne->{id};
      }
    }
    else {# $parametres{r_mensuelle} == 2
      $sql = "SELECT * FROM rdv_mperiode WHERE m1 = ".$dbh->quote($parametres{r_mchoix1})." AND m2 = ".$dbh->quote($parametres{r_mchoix2})." AND m3 = ".$dbh->quote($parametres{r_tm3});
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $ref_ligne = $sth->fetchrow_hashref;
      if(exists $ref_ligne->{id} && ($ref_ligne->{id} >0)) {
        return $ref_ligne->{id};
      }
      else {
        $sql = "INSERT INTO rdv_mperiode (m1, m2, m3) VALUES (".$dbh->quote($parametres{r_mchoix1}).", ".$dbh->quote($parametres{r_mchoix2}).", ".$dbh->quote($parametres{r_tm3}).")";
        $dbh->do($sql);
        $sql = "SELECT * FROM rdv_mperiode WHERE m1 = ".$dbh->quote($parametres{r_mchoix1})." AND m2 = ".$dbh->quote($parametres{r_mchoix2})." AND m3 = ".$dbh->quote($parametres{r_tm3});
        $sth = $dbh->prepare($sql);
        $sth->execute();
        $ref_ligne = $sth->fetchrow_hashref;
        return $ref_ligne->{id};
      }
    }
  }
  elsif($parametres{rp_periodicite} eq 'Annuelle') {
    if($parametres{r_annuelle} == 1) {
      $sql = "SELECT * FROM rdv_aperiode WHERE a2 = ".$dbh->quote($parametres{r_ta1})." AND a3 = ".$dbh->quote($parametres{r_achoix});
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $ref_ligne = $sth->fetchrow_hashref;
      if(exists $ref_ligne->{id} && ($ref_ligne->{id} >0)) {
        return $ref_ligne->{id};
      }
      else {
        $sql = "INSERT INTO rdv_aperiode (a2, a3) VALUES (".$dbh->quote($parametres{r_ta1}).", ".$dbh->quote($parametres{r_achoix}).")";
        $dbh->do($sql);
        $sql = "SELECT * FROM rdv_aperiode WHERE a2 = ".$dbh->quote($parametres{r_ta1})." AND a3 = ".$dbh->quote($parametres{r_achoix});
        $sth = $dbh->prepare($sql);
        $sth->execute();
        $ref_ligne = $sth->fetchrow_hashref;
        return $ref_ligne->{id};
      }
    }
    else {# $parametres{r_annuelle} == 2
      $sql = "SELECT * FROM rdv_aperiode WHERE a1 = ".$dbh->quote($parametres{r_achoix1})." AND a2 = ".$dbh->quote($parametres{r_achoix2})." AND a3 = ".$dbh->quote($parametres{r_achoix3});
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $ref_ligne = $sth->fetchrow_hashref;
      if(exists $ref_ligne->{id} && ($ref_ligne->{id} >0)) {
        return $ref_ligne->{id};
      }
      else {
        $sql = "INSERT INTO rdv_aperiode (a1, a2, a3) VALUES (".$dbh->quote($parametres{r_achoix1}).", ".$dbh->quote($parametres{r_achoix2}).", ".$dbh->quote($parametres{r_achoix3}).")";
        $dbh->do($sql);
        $sql = "SELECT * FROM rdv_aperiode WHERE a1 = ".$dbh->quote($parametres{r_achoix1})." AND a2 = ".$dbh->quote($parametres{r_achoix2})." AND a3 = ".$dbh->quote($parametres{r_achoix3});
        $sth = $dbh->prepare($sql);
        $sth->execute();
        $ref_ligne = $sth->fetchrow_hashref;
        return $ref_ligne->{id};
      }
    }
  }
}




sub db_recherche_info_rdv() {
  my $rdv;
  my ($vide, $annee, $mois, $jour, $heure, $mn, $sec);
  my $sql = "SELECT * FROM rdv WHERE id = ".$dbh->quote($parametres{rdv});
  print "SQL = $sql", $cgi->br();
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $rdv = $sth->fetchrow_hashref('NAME_lc');
  print "Les données du rdv récupérées sont : ";
  foreach (keys %$rdv) {
    print "$_ : $rdv->{$_}", $cgi->br();
  }
  $rdv{id} = $rdv->{id};
  $rdv{id_user} = $rdv->{id_user};
  $rdv{id_ref} = $rdv->{id_ref} if((exists $rdv->{id_ref}) && ($rdv->{id_ref} > 0));
  $rdv{objet} = $rdv->{objet} if(length $rdv->{objet} > 0);
  $rdv{lieu} = $rdv->{lieu} if(length $rdv->{lieu} > 0);
  $rdv{rappel} = $rdv->{rappel} if ($rdv->{rappel} > -1);
#  $rdv{msg} = $rdv->{msg} if((exists $rdv->{msg}) && ($rdv->{msg} != null));
#  $rdv{msg} = $rdv->{msg} if(exists $rdv->{msg});  
  ($vide, $annee, $mois, $jour, $heure, $mn, $sec) = split /(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/, $rdv->{debut};
  $tps_debut = Mktime($annee, $mois, $jour, $heure, $mn, $sec);
  $rdv{annee_debut} = $annee;
  $rdv{mois_debut} = $mois;
  $rdv{jour_debut} = $jour;
  $rdv{heure_debut} = "$heure:$mn";
  ($vide, $annee, $mois, $jour, $heure, $mn, $sec) = split /(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/, $rdv->{fin};
  $tps_fin = Mktime($annee, $mois, $jour, $heure, $mn, $sec);
  $rdv{annee_fin} = $annee;
  $rdv{mois_fin} = $mois;
  $rdv{jour_fin} = $jour;
  $rdv{heure_fin} = "$heure:$mn";
  if(($tps_fin - $tps_debut) >= 86400) {
    $tps = Mktime($annee, $mois, $jour, 0, 0, 0);
  }
  else {
    $tps = $tps_debut + $pas;
  }
#  print "Les données du rdv après traitement sont : ", $cgi->br();
#  foreach (keys %rdv) {
#    print "$_ : $rdv{$_}", $cgi->br();
#  }
#  print "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", $cgi->br();
}

##############################################################################
