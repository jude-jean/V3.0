#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5  qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DBI;
use Date::Calc qw(:all);
use Time::Local;



my @boutons_bas = ( ["Donn�es sociales", 0x1],
                    ["Rapports d'activit�s", 0x2],
                    ["Calendrier", 0x4],
                    ["Compte", 0x8]);

# D�claration des identifications de connexion
our $id;
#my $login;
our @collaborateur;
my %parametres = ();
our $dbh;
our $tps_connexion = 600; # D�lai de connexion sans inactivit�

our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
our $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);
$mois += 1;
$annee += 1900;

# Date de cr�ation de Technologies et Services
our @date_ts = (2003, 1, 1);
my @msg_maj;
my $ecran_actuel;

my %action = (
 'creation'              => [ \&creer_rdv, 'Cr�ation' ],
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
 'P�riodicit�'        => \&periodicite_rdv,
);

my (%rdv, @list_rdv, %list_rdv);
my @emplt = ("4 rue de la bo�tie", "121, Bl du g�n�ral de Gaulle", "45, avenue Matignon");

my (@list_jours_mois, @list_mois, @list_annee, @list_heures_debut, @duree, $ind_annee_debut, $ind_annee_fin, $ind_heure_debut, $ind_heure_fin, @list_heures_fin);
my ($heure_debut, $heure_fin, $tps_debut, $tps_fin, $tps, $pas, @date_debut, @date_fin, $idx_duree);
my $nb_jours_mois = 31;
my ($msg_maj, $msg_plage_periodicite);

my @mois = (['Janvier', 1, 'Jan'], ['F�vrier', 2, 'F�v'], ['Mars',3, 'Mars'], ['Avril',4, 'Avr'], ['Mai', 5, 'Mai'], ['Juin', 6, 'Juin'], ['Juillet', 7, 'Juil'], ['Ao�t', 8, 'Ao�t'], ['Septembre', 9, 'Sep'], ['Octobre', 10, 'Oct'], ['Novembre', 11, 'Nov'], ['D�cembre', 12, 'D�c']);
my @jours = (['Lundi', 1, 'Lun'], ['Mardi', 2, 'Mar'], ['Mercredi',3, 'Mer'], ['Jeudi',4, 'Jeu'], ['Vendredi', 5, 'Ven'], ['Samedi', 6, 'Sam'], ['Dimanche', 7, 'Dim']);
my @list_rappels = ("5 minutes", "10 minutes", "15 minutes", "30 minutes", "1 heure", "2 heures", "3 heures", "4 heures", "5 heures", "6 heures", "7 heures", "8 heures", "9 heures", "10 heures", "11 heures", "0.5 jours", "1 jour", "2 jours", "3 jours", "4 jours", "1 semaine", "2 semaines");
my @list_dispo = ('Libre', 'Provisoire', 'Occup�(e)', 'Absent(e) du bureau');
my @list_categories = ('Aucune', 'Bureau', 'Important', 'Personnel', 'Cong�', 'Participation obligatoire', 'D�placement requis', 'N�cessite pr�paration', 'Anniversaire', 'Appel t�l�phonique');
my @list_periodicite = ('Quotidienne', 'Hebdomadaire', 'Mensuelle', 'Annuelle');
my @choix = ('1', '2');
my %qlabel = ( 1 => '', 2 => '');
my @hchoix = (1, 2, 3, 4, 5, 6, 7);
my %hlabel =(1=> 'lundi', 2 => 'mardi', 3 => 'mercredi', 4 => 'jeudi', 5 => 'vendredi', 6 => 'samedi', 7 => 'dimanche');
my @mchoix = (1, 2, 3, 4, 5);
my %mlabel = (1 => 'premier', 2 => 'deuxi�me', 3 => 'troisi�me', 4 => 'quatri�me', 5 => 'dernier');
my @mchoix2 = (8, 9, 1, 2, 3, 4, 5, 6, 7);
my %mlabel2 = (1=> 'lundi', 2 => 'mardi', 3 => 'mercredi', 4 => 'jeudi', 5 => 'vendredi', 6 => 'samedi', 7 => 'dimanche', 8 => 'jour', 9 => 'jour ouvr�');
my @achoix = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
my %alabel = (1=>'janvier', 2=>'f�vrier', 3=>'mars', 4=>'avril', 5=>'mai', 6=>'juin', 7=>'juillet', 8=>'ao�t', 9=>'septembre', 10=>'octobre', 11=>'novembre', 12=>'d�cembre');

our $cgi = new CGI;

#Connexion � la base de donn�e.
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "probl�me de connexion � la base de donn�es db447674934 : $!";
	# D�claration du r�pertoire de base
	$rep = '..';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib";

}
else {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "probl�me de connexion � la base de donn�es collaborateur : $!";
	$rep = '../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}
use Etechnoserv;
use Calendrier qw(calendrier);
use JourDeFete qw(est_ferie Delta_Dates_AMJ);

# D�claration du r�pertoire de base
# D�claration du r�pertoire de base
#our $rep = '../../../test/jude/V3.0';

my @script = (
        { 'language'           => "javascript",
          'src'                => "$rep/scripts/ets_cal.js"
        },
        {
          'language'           => "javascript",
          'src'                => "$rep/scripts/mini_cal.js"
        },
);

# D�claration des feuilles de styles
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

lecture_parametres(\%parametres);
if(defined($::parametres{ident_id})) {
  @collaborateur = info_id($::parametres{ident_id});
# Il faudra d�commenter cette partie pour faire une demande de connexion en cas
# de d�lai d�pass�.
#  if(verif_tps_connexion() == 0) {# d�lai d�pass�
#    @collaborateur = undef;
#    $id = undef;
#  }
}
if(exists($::parametres{s_action})) {
  if(exists($s_action{$::parametres{s_action}})) {
    $s_action{$::parametres{s_action}}->();
  }
  else {
    entete_standard();
    print "Pas de fonction d�finie pour le param�tre $::parametres{s_action}";
  }
}
elsif(exists($::parametres{action})) {
  if(exists($action{$::parametres{action}})) {
    $action{$::parametres{action}}->[0]->();
  }
  else {
    entete_standard();
    print "Pas de fonction d�finie pour le param�tre $::parametres{action}";
  }
}
else {
  entete_standard();
  visu_parametres(\%parametres);
  print "Pas de param�tre 'action' ni 's_action' d�fini dans la requete. Fin du programme";
  exit;
}


exit;
##################### D�but des fonctions #####################################
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
    -script => \@script, -base => 'true', -onLoad => 'recharge_calendrier(1);window.setTimeout("self.close()", 5000);'});

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
  if(exists($::parametres{bouton})) {
    if(($::parametres{bouton} eq 'OK') || ($::parametres{bouton} eq 'Supprimer')) {
# Pour l'instant, on edite le rdv sans prise en compte des donn�es p�riodicit�
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



##############################################################################
