package Showgestioncompte;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(gestion_compte menu_compte_verif_donnees);
use strict;

my %compte = (
  'identification'            => \&menu_compte_identification,
  'communication'     => \&menu_compte_communication,
  'missions'          => \&menu_compte_missions,
  'motdepasse'          => \&menu_compte_mot_de_passe,
#  'OK'                => \&menu_compte_ok,
#  'Appliquer'         => \&menu_compte_appliquer,
#  'Annuler'           => \&gestion_compte,
);

my %msg = (
	'100'	=> "Mise à jour réussie",
	'101'	=> "Le champ Nom n'est pas valide",
	'102'	=> "Le champ Prénom n'est pas valide",
	'103'	=> "Le champ Login n'est pas valide",
	'201'	=> "L'adresse mail est incorrecte", 
	'202'	=> "Le champ Tél mission est incorrect",
	'203'	=> "Le champ Tél perso est incorrect",
	'301'	=> "Le mot de passe saisi n'est pas égal au mot de passe actuel",
	'302'	=> "Pour le nouveau mot de passe : Le deuxième mot de passe ne correspond pas au premier",
	'303'	=> "La taille du nouveau mot de passe doit être au moins égale à 4",
);

sub gestion_compte {
  my $actif = shift;
  return unless $actif;
  return unless $::id;
  my $smenu = $::cgi->param('smenu')|| 'identification';
  
  print $::cgi->h1("Gestion du compte $::collaborateur[3]");
  print $::cgi->start_div({-id => 'Menu_gestion_compte'});
  print $::cgi->start_ul(),
        $::cgi->li($::cgi->a({-href => "$::rep_pl/donnees_sociales/show.pl?ident_id=$::id"}, 'Retour'));
  if($smenu eq 'identification') {
    print $::cgi->li({-id => "active"}, $::cgi->a({-id => "courant", -href => "$::rep_pl/compte/identification/show.pl?smenu=$smenu&ident_id=$::id"}, 'Identification'));
#utile pour déterminer le menu actif quand on utilise les boutons OK Appliquer
    print $::cgi->hidden(-name=>'smenu', -value=>'identification');
  }
  else {
   print $::cgi->li($::cgi->a({-href => "$::rep_pl/compte/identification/show.pl?smenu=identification&ident_id=$::id"}, 'Identification'));
  }
  if($smenu eq 'communication') {
    print $::cgi->li({-id => "active"}, $::cgi->a({-id => "courant", -href => "$::rep_pl/compte/communication/show.pl?smenu=$smenu&ident_id=$::id"}, 'Communication'));
    print $::cgi->hidden(-name=>'smenu', -value=>'communication');
  }
  else {
    print $::cgi->li($::cgi->a({-href => "$::rep_pl/compte/communication/show.pl?smenu=communication&ident_id=$::id"}, 'Communication'));
  }
  if($smenu eq 'missions') {
    print $::cgi->li({-id => "active"}, $::cgi->a({-id=> "courant", -href => "$::rep_pl/compte/missions/show.pl?smenu=$smenu&ident_id=$::id"}, 'Missions'));
    print $::cgi->hidden(-name=>'smenu', -value=>'missions');
  }
  else {
      print $::cgi->li($::cgi->a({-href => "$::rep_pl/compte/missions/show.pl?smenu=missions&ident_id=$::id"}, 'Missions'));
  }
  if($smenu eq 'motdepasse') {
    print $::cgi->li({-id => "active"}, $::cgi->a({-id =>"courant", -href => "$::rep_pl/compte/motdepasse/show.pl?smenu=$smenu&ident_id=$::id"}, 'Mot de passe'));
    print $::cgi->hidden(-name=>'smenu', -value=>'mot_de_passe');
  }
  else {
   print $::cgi->li($::cgi->a({-href => "$::rep_pl/compte/motdepasse/show.pl?smenu=motdepasse&ident_id=$::id"}, 'Mot de passe'));
  }
  print $::cgi->end_ul();
  print $::cgi->end_div(); # Fin du div de Menu_gestion_compte

  return unless $smenu;
  my $fonction = $compte{$smenu}; # Exécution de la fonction du sous menu de compte
  $fonction->();
}

# Document qui affiche le menu de gestion du compte
sub menu_compte_identification {
  my $no_msg = $::cgi->param('no_msg');
  print $::cgi->start_div({-id => 'Identification'}),
   $::cgi->start_fieldset(), $::cgi->legend('Etat Civil'), $::cgi->start_div({-class => 'infos'}), $::cgi->start_div({-class => 'Ligne2col'}), $::cgi->div({-class => 'Ligne2col1'},"Nom") ,
   $::cgi->textfield(-name=>"nom", -default=> "$::collaborateur[1]", -size=> 20),
   $::cgi->end_div(),
   $::cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $::cgi->div({-class => 'Ligne2col1'}, "Prénom"),
   $::cgi->textfield(-name=>"prenom", -default=> "$::collaborateur[2]", -size=> 20),
   $::cgi->end_div(), $::cgi->end_div();
   if(defined $no_msg) {
     print $::cgi->start_div({-class => 'msg_info'}),
           $::cgi->span("*$msg{$no_msg}"), $::cgi->end_div(), $::cgi->end_fieldset();
   }
   else {
     print $::cgi->end_fieldset();
   }
   print $::cgi->start_fieldset(), $::cgi->legend('Données professionnelles'), $::cgi->start_div({-class => 'infos'}), $::cgi->start_div({-class => 'Ligne2col'}), $::cgi->div({-class => 'Ligne2col1'}, "Login"),
   $::cgi->textfield(-name=>"login", -default=> "$::collaborateur[3]", -size=> 20),
   $::cgi->end_div(),
   $::cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $::cgi->div({-class => 'Ligne2col1'}, "Fonction"),
   $::cgi->textfield(-name=>'fonction', -default=> "$::collaborateur[7]", -size=> 40, -disabled),
   $::cgi->end_div(), $::cgi->end_div();
#   if((defined $::msg_maj[0]) && ($::msg_maj[0] eq 'identification') &&
#      ($::msg_maj[1] == 3)) {
#     print $::cgi->start_div({-class => 'msg_info'}),
#           $::cgi->span("*$::msg_maj[2]"), $::cgi->end_div(), $::cgi->end_fieldset();
#   }
#   else {
     print $::cgi->end_fieldset();
#   }
  menu_compte_enregistrer('7');# Droits d'activer OK, enregistrer et annuler
  print $::cgi->end_div(); # Fin du div Identification
# Afin de modifier les paramêtres
  $::cgi->delete('nom_old');
  $::cgi->delete('prenom_old');
  $::cgi->delete('login_old');

  print $::cgi->hidden(-name =>'nom_old', -value => "$::collaborateur[1]"), $::cgi->hidden(-name => 'prenom_old', -value => "$::collaborateur[2]"), $::cgi->hidden(-name => 'login_old', -value => "$::collaborateur[3]");
}

sub menu_compte_communication {
	my $no_msg = $::cgi->param('no_msg');
  print $::cgi->start_div({-id => 'Communication'}),
   $::cgi->start_fieldset(), $::cgi->legend('Données chez le client'), $::cgi->start_div({-class => 'infos'}), $::cgi->start_div({-class => 'Ligne2col'}), $::cgi->div({-class => 'Ligne2col1'},"E-mail mission"),
   $::cgi->textfield(-name=>'mail_mission', -default=> "$::collaborateur[10]", -size=> 40),
   $::cgi->end_div(),
   $::cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $::cgi->div({-class => 'Ligne2col1'}, "Tél. mission"),
   $::cgi->textfield(-name=>"tel_mission", -default=> "$::collaborateur[11]", -size=> 12),
   $::cgi->end_div(), $::cgi->end_div();
  if(defined $no_msg) {
        print $::cgi->start_div({-class => 'msg_info'}),
         $::cgi->span("*$msg{$no_msg}"), $::cgi->end_div(), $::cgi->end_fieldset();
  }
  else {
       print $::cgi->end_fieldset();
  }
  print $::cgi->start_fieldset(), $::cgi->legend('Données personnelles'), $::cgi->start_div({-class => 'infos'}), $::cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $::cgi->div({-class => 'Ligne2col1'}, "Tél. perso"),
   $::cgi->textfield(-name=>"tel_perso", -default=> "$::collaborateur[12]", -size=> 12),
   $::cgi->end_div(), $::cgi->end_div();
#  if((defined $::msg_maj[0]) && ($::msg_maj[0] eq 'communication') &&
#    ($::msg_maj[1] == 3)) {
#       print $::cgi->start_div({-class => 'msg_info'}),
#        $::cgi->span("*$::msg_maj[2]"), $::cgi->end_div(), $::cgi->end_fieldset();
#  }
#  else {
    print $::cgi->end_fieldset();
#  }
  menu_compte_enregistrer('7'); # Droits d'activer OK, enregistrer et annuler
  print $::cgi->end_div(); # Fin du div Communication
  $::cgi->delete('mail_mission_old');
  $::cgi->delete('tel_mission_old');
  $::cgi->delete('tel_perso_old');
  print $::cgi->hidden(-name =>'mail_mission_old', -value => "$::collaborateur[10]"),
        $::cgi->hidden(-name =>'tel_mission_old', -value => "$::collaborateur[11]"),
        $::cgi->hidden(-name =>'tel_perso_old', -value => "$::collaborateur[12]");
}

sub menu_compte_missions {
  my $sql = "SELECT idclient FROM  affectation WHERE idcollaborateur = ".$::dbh->quote($::collaborateur[0]);
  my $sth = $::dbh->prepare($sql);
  $sth->execute();
  my ($client, @client);
  ($client) = $sth->fetchrow_array();
  if(defined($client)) {
    $sql = "SELECT * FROM client WHERE id = ".$::dbh->quote($client);
    $sth = $::dbh->prepare($sql);
    $sth->execute();
    @client = $sth->fetchrow_array();
    print $::cgi->start_div({-id => 'Missions'}),
     $::cgi->start_fieldset(), $::cgi->legend('Contact technique client'), $::cgi->start_div({-class => 'infos'}),
     $::cgi->start_div({-class => 'Ligne2col'}), $::cgi->div({-class => 'Ligne2col1'}, "Nom du client"),
     $::cgi->textfield(-name=>'nom_client', -default=> "$client[1]", -size=> 40, -disabled),
     $::cgi->end_div(),
     $::cgi->start_div({-class => 'Ligne2col'}), $::cgi->div({-class => 'Ligne2col1'}, "Nom du contact"),
     $::cgi->textfield(-name=>'nom_contact', -default=> "$client[12] $client[11]", -size=> 40, -disabled),
     $::cgi->end_div(),
     $::cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $::cgi->div({-class => 'Ligne2col1'}, "Téléphone"),
     $::cgi->textfield(-name=>'tel_contact', -default=> "$client[18]", -size=> 40, -disabled),
     $::cgi->end_div(), $::cgi->end_div(), $::cgi->end_fieldset();
  }
  else {
    print $::cgi->p($::cgi->em("Aucun client n'est affecté"), $::cgi->br, "En cas d'erreur, contacter votre responsable de contact");
  }
  menu_compte_enregistrer('4'); # Droits d'activer OK
  print $::cgi->end_div(); # Fin du div Missions
}

sub menu_compte_mot_de_passe {
#  my ($paquetage, $fichier, $ligne, $routine) = caller(2);
#  print " La pile d'execution du programme est : $paquetage, $fichier, $ligne, $routine";
	my $no_msg = $::cgi->param('no_msg');
  if((defined $::msg_maj[0]) && ($::msg_maj[1] == 0)) {
    $::cgi->delete('pswd_actuel');
    $::cgi->delete('pswd_new1');
    $::cgi->delete('pswd_new2');
  }
  print $::cgi->start_div({-id => 'Mot_de_passe'}),
        $::cgi->start_fieldset(), $::cgi->legend('Changement de mot de passe'), $::cgi->start_div({-class => 'infos'}), $::cgi->start_div({-class => 'Ligne2col'}), $::cgi->div({-class => 'Ligne2col1'}, "Le mot de passe actuel"),
        $::cgi->password_field(-name=>'pswd_actuel', -size=> 20, -value => undef),
        $::cgi->end_div(),
        $::cgi->start_div({-class => 'Ligne2col'}), $::cgi->div({-class => 'Ligne2col1'}, "Le nouveau mot de passe"),
        $::cgi->password_field(-name=>"pswd_new1", -size=> 20, -value => undef),
        $::cgi->end_div(),
        $::cgi->start_div({-class => 'Ligne2col', -id => 'derniere_ligne'}), $::cgi->div({-class => 'Ligne2col1'}, "Le nouveau mot de passe"),
        $::cgi->password_field(-name=>"pswd_new2", -size=> 20, -value => undef),
        $::cgi->end_div(), $::cgi->end_div();
  if(defined $no_msg) {
       print $::cgi->start_div({-class => 'msg_info'}),
        $::cgi->span("*$msg{$no_msg}"), $::cgi->end_div(), $::cgi->end_fieldset();
  }
  else {
    print $::cgi->end_fieldset();
  }
  menu_compte_enregistrer('7'); # Droits d'activer OK, enregistrer et annuler
  print $::cgi->end_div(); # Fin du div Mot de passe
#  print $::cgi->hidden(-name => 'pswd_actuel', -value => ' ');
#  print $::cgi->hidden(-name => 'pswd_new1', -value => ' ');
#  print $::cgi->hidden(-name => 'pwsd_new2', -value => ' ');
}

sub menu_compte_enregistrer {
  my $droits = shift;
 if($droits & '1') { # droits d'activation de Annuler
  print $::cgi->div({-class => 'menu_enregistrer'}, vers_compte('OK', $droits & '4'),
                vers_compte('Appliquer', $droits & '2'),
                $::cgi->reset());
 }
 else {
  print $::cgi->div({-class => 'menu_enregistrer'}, vers_compte('OK', $droits & '4'),
                vers_compte('Appliquer', $droits & '2'),
                $::cgi->reset({-disabled}));
 }
}


sub vers_compte {
  my $valeur = shift;
  my $droits = shift;
#  print $::cgi->p("Les droits pour le bouton $valeur sont : $droits");
  if($droits) {
    $::cgi->submit({-name => ".Etat", value => $valeur, -onclick => "return valide_modif_compte(this);"});
  }
  else {
    $::cgi->submit({-name => ".Etat", value => $valeur, -onclick => "return valide_modif_compte(this);", -disabled});
#  $::cgi->submit({-name => ".Etat", value => $valeur, -onclick => $fonction});
  }
}

# Vérification des données avant la mise à jour
sub menu_compte_verif_donnees {
  my $smenu = shift;
  if($smenu eq 'identification') {
    my($nom, $prenom, $login) = @_;
    unless($nom eq $::collaborateur[1]) {
      if((length $nom <= 0) || (length $nom > 20) || ($nom =~/^[0-9\.\s]/) ||
         ($nom =~ /^[\d\s]*$/) ||
         ($nom =~ /[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/)) {
            $::msg_maj[0] = $smenu;
            $::msg_maj[1] = 1;
            $::msg_maj[2] = "Le champ nom ne peut être vide, avoir une taille supérieure à 20, commencer par un chiffre, un espace ou par un point. Il ne peut être une combinaison de blancs et de chiffres et comprendre des caractères tels que :".$::cgi->br." &nbsp; &nbsp;$, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ";
            $::no_msg = 101;
			return 1;
      }
    }
    unless($prenom eq $::collaborateur[2]) {
      if((length $prenom <= 0) || (length $prenom > 20) || ($prenom =~/^[0-9\.\s]/) ||
         ($prenom =~ /^[\d\s]*$/) ||
         ($prenom =~ /[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/)) {
            $::msg_maj[0] = $smenu;
            $::msg_maj[1] = 2;
            $::msg_maj[2] = "Le champ prenom ne peut être vide, avoir une taille supérieure à 20, commencer par un chiffre, un espace ou par un point. Il ne peut être une combinaison de blancs et de chiffres et comprendre des caractères tels que :".$::cgi->br." &nbsp; &nbsp;$, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ";
            $::no_msg = 102;
			return 2;
      }
    }
    unless($login eq $::collaborateur[3]) {
      if((length $login < 4) || (length $login > 20) || ($login =~/^[0-9\.\s]/) ||
         ($login =~ /^[\d\s]*$/) ||
         ($login =~ /[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/)) {
            $::msg_maj[0] = $smenu;
            $::msg_maj[1] = 3;
            $::msg_maj[2] = "Le champ login ne peut être vide, avoir une taille inférieure à 4 et supérieure à 20, commencer par un chiffre, un espace ou par un point. Il ne peut une combinaison de blancs et de chiffres et comprendre des caractères tels que :".$::cgi->br." &nbsp; &nbsp;$, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ";
            $::no_msg = 103;
			return 3;
      }
    }
    return 0;
  }
  if($smenu eq 'communication') {
    my($mail_mission, $tel_mission, $tel_perso) = @_;
    unless($mail_mission eq $::collaborateur[10]) {
      if(!(($mail_mission =~ /^[a-zA-Z]([\w\-\.]*[\w]+)*@[a-zA-Z]([\w\-\.]*[\w]+)*\.[a-zA-Z]+$/) &&
          (length $mail_mission > 0) && (length $mail_mission < 101))) {
            $::msg_maj[0] = $smenu;
            $::msg_maj[1] = 1;
            $::msg_maj[2] = "L'adresse mail est incorrecte. Elle doit être de la forme nom\@domaine.ext avec :".$::cgi->br()."&nbsp;&nbsp;-nom et domaine : mot.mot.---.mot,".$::cgi->br()."&nbsp;&nbsp;-ext : mot";
            $::no_msg = 201;
			return 1;
      }
    }
    unless($tel_mission eq $::collaborateur[11]) {
      if(!((length $tel_mission >0) && (length $tel_mission < 11) &&
          ($tel_mission =~ /^\d{10}$/))) {
            $::msg_maj[0] = $smenu;
            $::msg_maj[1] = 2;
            $::msg_maj[2] = "Le champ Tél mission est incorrect. Il doit être un nombre de 10 chiffres";
            $::no_msg = 202;
			return 2;
      }
    }
    unless($tel_perso eq $::collaborateur[12]) {
      if(!((length $tel_perso >0) && (length $tel_perso < 11) &&
          ($tel_perso =~ /^\d{10}$/))) {
            $::msg_maj[0] = $smenu;
            $::msg_maj[1] = 3;
            $::msg_maj[2] = "Le champ Tél perso est incorrect. Il doit être un nombre de 10 chiffres";
            $::no_msg = 203;
			return 3;
      }
    }
    return 0;
  }
  if($smenu eq 'motdepasse') {
    my($pswd, $pswd1, $pswd2) = @_;
    my $md5 = Digest::MD5->new;
    my $pswd_md5;
    $md5->add($pswd);
    $pswd_md5 = $md5->hexdigest;
    unless($pswd_md5 eq $::collaborateur[4]) {
      $::msg_maj[0] = $smenu;
      $::msg_maj[1] = 1;
      $::msg_maj[2] = "Le mot de passe saisi n'est pas égal au mot de passe actuel";
	  $::no_msg = 301;
      return 1;
    }
    unless($pswd1 eq $pswd2) {
      $::msg_maj[0] = $smenu;
      $::msg_maj[1] = 1;
      $::msg_maj[2] = "Erreur sur le nouveau mot de passe : Le deuxième mot de passe ne correspond pas au premier";
      $::no_msg = 302;
	  return 1;
    }
    if((length $pswd1 <= 3) || (length $pswd2 <= 3)) {
      $::msg_maj[0] = $smenu;
      $::msg_maj[1] = 1;
      $::msg_maj[2] = "Erreur sur le nouveau mot de passe : Sa taille doit être au moins égale à 4";
      $::no_msg = 303;
	  return 1;
    }
    return 0;
  }
}



1;