package Etechnoserv;
#use URI::Escape;

use Exporter;
@ISA = ('Exporter');
#@EXPORT = qw(info_id lecture_parametres visu_parametres $rep genere_chaine);
@EXPORT = qw(info_id lecture_parametres visu_parametres genere_chaine);

use strict;
use Encode qw(encode decode);
#our $rep = '../../test/jude/V3.0';
#Récupération des infos de $id comprenant les données des tables collaborateur et connexion
sub info_id {
  my $id = shift;
  my $sql = "SELECT * FROM collaborateur, connexion WHERE (collaborateur.id=connexion.id_user) AND (connexion.id_connexion = ".$::dbh->quote($id).")";
#  print "info_id() : sql = $sql", $cgi->br();
  my $sth = $::dbh->prepare($sql);
  $sth->execute;
  my @collaborateur = $sth->fetchrow_array();
  if(defined($collaborateur[0])) {
#    print "Le login du collaborateur est : $collaborateur[3]", $cgi->br();
    return @collaborateur;
  }
  else {
    print "Impossible de récupérer les infos pour le collaborateur";
    return;
  }
}

sub lecture_parametres {
  my ($parametres) = @_;
  foreach ($::cgi->param) {
    if($_ =~ /Enregistre/) {
	  $parametres->{s_action} = "Enregistrer et fermer";
	}elsif($_ =~ /Imprime/) {
	  $parametres->{s_action} = "Imprimer";
	}elsif($_ =~ /Insere/) {
	  $parametres->{s_action} = "Ajoute un fichier";
	  }elsif($_ =~ /Periodicite/) {
	  $parametres->{s_action} = "Périodicité";
	}elsif($_ =~ /Invite/) {
      $parametres->{s_action} = "Inviter les participants";
    }elsif($_ =~ /Supprime/) {
      $parametres->{s_action} = "Supprimer";
    }elsif($_ =~ /Annule/) {
      $parametres->{s_action} = "Annuler";
    }else {	  
	  $parametres->{$_} = $::cgi->param($_);
	}
  }
#  $parametres->{NbreHedomadaire} = $i;
  if(exists($parametres->{list_arg})) {
    my %list_arg = ();
    %list_arg = (split /=|\//, $parametres->{list_arg});
    foreach (keys %list_arg) {
      if($_ == 'mois') {
        $parametres->{mois} = $list_arg{mois};
      }
      else {
        $parametres->{$_} = $list_arg{$_};
      }
      
    }
  }  
}
sub visu_parametres {
  my ($parametres) = @_;
#  my @hebdo;
  foreach (keys %$parametres) {
    print "$_ => $parametres->{$_}", $::cgi->br();
    if($_ eq 'hebdomadaire') {
#	  @hebdo = $::cgi->param('hebdomadaire');
      print "Le parametre hebdomadaire contient les éléments : (";
      foreach ($::cgi->param('hebdomadaire')) {
	    print "$_ ";
	  }
	  print ")",$::cgi->br();
	}  
    if($_ eq 'r_hebdomadaire') {
#	  @hebdo = $::cgi->param('hebdomadaire');
      print "Le parametre r_hebdomadaire contient les éléments : (";
      foreach ($::cgi->param('r_hebdomadaire')) {
	    print "$_ ";
	  }
	  print ")",$::cgi->br();
	}  
  }
}

sub genere_chaine {
	my $chaine;
	my ($parametres) = @_;
	foreach (keys %$parametres) {
		next if(($_ eq 's_action') && (($::cgi->referer =~ /rendez_vous\/new.pl/) || ($::cgi->referer =~ /rendez_vous\/open.pl/)));
		next if(($_ eq 'msg') && ($::cgi->url =~ /rendez_vous\/open.pl/));
		if($_ eq 'hebdomadaire') {
			foreach my $jour ($::cgi->param('hebdomadaire')) {
				$chaine .= "hebdomadaire=$jour&";
			}
		}
		elsif($_ eq 'r_hebdomadaire') {
			foreach my $jour ($::cgi->param('r_hebdomadaire')) {
				$chaine .= "r_hebdomadaire=$jour&";
			}
		}

		else {
			$chaine .= "$_=$parametres->{$_}&";
		}
	}
	$chaine =~ s/.$//;
#	return uri_escape($chaine);
	return "$chaine";
}


1;