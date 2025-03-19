package Connexion;
use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(deconnexion verif_tps_connexion verif_login connexion_db $tps_connexion $maintenant);

use strict;
use Time::Local;
use RendezVous qw(db_periode_delete_table_rdv);

our $tps_connexion = 600; # Délai de déconnexion
our ($secondes, $minutes, $heures, $jour, $mois, $annee) = (localtime)[0..5];
our $maintenant = timelocal($secondes, $minutes, $heures, $jour, $mois, $annee);

sub verif_login {
  my $login = shift;
  if((length $login < 4) || (length $login > 20) ||($login =~ /^[0-9]\./) || ($login =~ /^[\d\s]*$/) ||
     ($login =~ /[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/)) {
#       print "Login = $login est non conforme", $cgi->br();
	   $::erreur = 1;
       return 0;
     }
  return 1;


}


sub connexion_db {
  my($login, $pswd) = @_;
# Calcul du MD5 du mot de passe
  my $md5 = Digest::MD5->new;
  $md5->add($pswd);
  my $pswd_md5 = $md5->hexdigest;
  my $sql= "SELECT *, COUNT(*) FROM collaborateur WHERE user = ".$::dbh->quote($login)." AND pass = ".$::dbh->quote($pswd_md5)." AND actif = '1'GROUP BY id";
  my $sth = $::dbh->prepare($sql);
  $sth->execute;
  my $cpt;
  @::collaborateur = $sth->fetchrow_array();

  if(defined($::collaborateur[0])) {
   $cpt = pop @::collaborateur;
#    my $id_temp = shift @::collaborateur;
    my $msg_id = "$secondes.$jour.$pswd.$mois.$heures.$login.$minutes$annee";
#    print "La valeur de msg_id est : $msg_id", $cgi->br();
    my $ctx = Digest::SHA->new;
    $ctx->add($msg_id);
    my $sha1_id = $ctx->hexdigest;
    my $recharge = $maintenant + $tps_connexion;
# Insertion dans la table connexion de la base de la ligne de connexion
#    my $debut = timelocal($secondes, $minutes, $heures, $jour, $mois - 1, $annee -1900);
    $sql = "INSERT INTO connexion (id_user, id_connexion, debut, recharge) VALUES (".$::dbh->quote($::collaborateur[0])." ,".$::dbh->quote($sha1_id)." ,".$::dbh->quote($maintenant)." ,".$::dbh->quote($recharge).")";
#    print "connexion_db() : requete sql = $sql", $cgi->br();
    $::dbh->do($sql) or die " Erreur : $::dbh->errstr";
    $::id = $sha1_id;
    push @::collaborateur, ($::collaborateur[0], $sha1_id, $maintenant, 0, $recharge);
	return 1;
  }
  else {
#    print "La valeur de retour de la requête SQL est vide", $cgi->br();
    @::collaborateur = undef;
    $::id = undef;
	$::erreur = 2;
    return 0;
  }
}


#Vérification du temps de connexion. Au delà de 10 mn, relancer la connexion
sub verif_tps_connexion {

#Récupération de recharge de connexion pour la comparaison avec maintenant
	my ($sql, $sth, $recharge);
	$sql = "SELECT recharge FROM connexion WHERE id_connexion = ".$::dbh->quote($::cgi->param('ident_id'));
	$sth = $::dbh->prepare($sql);
	$sth->execute();
	($recharge) = $sth->fetchrow_array();
	if($recharge < $maintenant){
		$sql = "UPDATE connexion SET fin = ".$::dbh->quote($maintenant)." WHERE id_connexion = ".$::dbh->quote($::cgi->param('ident_id'));
		$::dbh->do($sql) or die " Erreur : $::dbh->errstr";
		deconnexion();
		return 0;
	}
	else {
		$recharge = $maintenant + $tps_connexion;
		$sql = "UPDATE connexion SET recharge = ".$::dbh->quote($recharge)." WHERE id_connexion = ".$::dbh->quote($::cgi->param('ident_id'));
		$::dbh->do($sql) or die "Erreur : $::dbh->errstr";
		$::collaborateur[20] = $recharge if(defined($::collaborateur[20]));
		return 1;
	}

}

# Fonction appelée car le paramètre .Connexion prend la valeur Deconnexion
sub deconnexion {
#  my $fin = timelocal($secondes, $minutes, $heures, $jour, $mois - 1, $annee -1900);
	if(defined($::cgi->param('ident_id'))) {
		my $sql = "UPDATE connexion SET fin = ".$::dbh->quote($maintenant)." WHERE id_connexion = ".$::dbh->quote($::cgi->param('ident_id'));
		$::dbh->do($sql) or die " Erreur : $::dbh->errstr";
		$::id = undef if (defined ($::id)); #Permet d'afficher le menu gauche non connecté
		@::collaborateur = undef if (defined(@::collaborateur));
		db_periode_delete_table_rdv();
	}

}


1;
