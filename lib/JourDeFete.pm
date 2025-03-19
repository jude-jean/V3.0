package JourDeFete;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(&init_feries &ferie_du_mois &verif_fete_paques &calcul_fete_paques
          &ferie_du_mois &est_ferie &Delta_Dates_AMJ &imprime_jours_feries
          &est_jour_ferie);

# @EXPORT_OK = qw(&est_ferie);

use Date::Calc qw(:all);
use strict;

my %calcul_fete_paques = (
	"Lundi Gras" => [-48],
	"Mardi Gras" => [-47],
	"Mercredi des Cendres" => [-46],
	"Dimanche des Rameaux" => [-7],
	"Vendredi Saint" => [-2],
	"Samedi de Pâques" => [-1],
	"Lundi de Pâques" => [1, "Ferie"],
	"Ascension" => [39, "Ferie"],
	"Dimanche de Pentecôte" => [49],
	"Lundi de Pentecôte" => [50, "Ferie"],
	"Fête-Dieu" => [60],
	);

my %calcul_ferie_france = (		
	"Jour de l\'an" => [1, 1],
	"Fête du travail" => [1, 5],
	"Armistice 1945" => [8, 5],
	"Fête nationale" => [14, 7],
	"Assomption" => [15, 8],
	"Toussaint" => [1, 11],
	"Armistice 1918" => [11, 11],
	"Noël" => [25, 12],
	);

my %jours_feries;

my %fete_paques;

sub calcul_fete_paques {
	my ($an) = @_;
	my @paques = Easter_Sunday($an);
	$fete_paques{"$an\\Paques"} = [@paques, "Ferie"];
	foreach (keys %calcul_fete_paques) {
		$fete_paques{"$an\\$_"} = [Add_Delta_Days(@paques,
			$calcul_fete_paques{$_}->[0]), $calcul_fete_paques{$_}->[1]];
	}		
	
}


sub ferie_du_mois {
	my ($no_mois, $an, $mois) = @_;

	my $cle;

#Calcul férié France
	foreach $cle (keys %{$mois}) {
		foreach (keys %calcul_ferie_france) {
			if(($mois->{$cle}->[0] == $calcul_ferie_france{$_}->[0]) &&
			($no_mois == $calcul_ferie_france{$_}->[1])) {
				push @{$mois->{$cle}}, "Ferie";
			}
		}
		foreach (keys %fete_paques) {
			if(($mois->{$cle}->[0] == $fete_paques{$_}->[2]) &&
			($no_mois == $fete_paques{$_}->[1]) &&
			($an == $fete_paques{$_}->[0])) {
				my $nom = $_;
				$nom =~ s/^\w+\\//;
				push @{$mois->{$cle}}, $nom;
				if(defined($fete_paques{$_}->[3])) {
					push @{$mois->{$cle}}, $fete_paques{$_}->[3];
				}
			}
		}
	}

}

sub verif_fete_paques {
	foreach (keys %fete_paques) {
		if(defined($fete_paques{$_}->[3])) {
			print "$_ : $fete_paques{$_}->[0]/$fete_paques{$_}->[1]/$fete_paques{$_}->[2] -> $fete_paques{$_}->[3]\n";
		}
		else {
			print "$_ : $fete_paques{$_}->[0]/$fete_paques{$_}->[1]/$fete_paques{$_}->[2]\n";
		}
	}
}



sub init_feries {
	my ($an) = @_;

	my @paques = Easter_Sunday($an);
	foreach (keys %calcul_fete_paques) {
		if(defined($calcul_fete_paques{$_}->[1]) && ($calcul_fete_paques{$_}->[1] eq "Ferie")) {
			$jours_feries{$_} = [Add_Delta_Days(@paques,$calcul_fete_paques{$_}->[0])];
		}
	}
	foreach (keys %calcul_ferie_france) {
		$jours_feries{$_} = [$an, $calcul_ferie_france{$_}->[1],$calcul_ferie_france{$_}->[0]];
	}
#	imprime_jours_feries($an);
	return(\%jours_feries);
}

sub imprime_jours_feries {
	my ($an) = @_;
	$, = " ";
	print "Impression des jours feries pour l'annee $an\n";
	foreach (keys %jours_feries) {
		print "$_ : @{$jours_feries{$_}}\n";
	}
}

sub est_ferie {
  my ($jour, $mois, $an) = @_;
  calcul_fete_paques($an);
  init_feries($an);
  
  foreach (keys %jours_feries) {
    if(($an == $jours_feries{$_}->[0]) && ($mois == $jours_feries{$_}->[1])
               &&($jour == $jours_feries{$_}->[2])) {
         return 1;
    }
  }
         return 0;
}
sub est_jour_ferie {
  my ($jour, $mois, $an, $rep) = @_;
  calcul_fete_paques($an);
  init_feries($an);

  foreach (keys %jours_feries) {
    if(($an == $jours_feries{$_}->[0]) && ($mois == $jours_feries{$_}->[1])
               &&($jour == $jours_feries{$_}->[2])) {
         $$rep = $_;
         return;
    }
  }
         $$rep = '0';
         return;
}

sub Delta_Dates_AMJ {
# Calcul du delta en jours, mois année
my (@debut, @fin);
@debut = @_[0..2];
@fin = @_[3..6];
my $Djours = Delta_Days($debut[0], $debut[1], $debut[2],
             $fin[0], $fin[1], $fin[2]);
my $i_mois = $debut[1];
my $i_an = $debut[0];
my @nbre_jours_mois;
my ($j_an, $j_mois);
my $Dj = 0;
my $Dm = 0;
my $Da = 0;
my $di_jour = 0;
my $ok = 1;
$j_an = ($i_mois < 12) ? $i_an : $i_an + 1;
$j_mois = ($i_mois <12) ? $i_mois + 1: 1;
$di_jour = Delta_Days($i_an, $i_mois, $debut[2], $j_an, $j_mois, $debut[2]);
#    print "\ndi_jour = $di_jour, i_an = $i_an, i_mois = $i_mois, j_an = $j_an, j_mois = $j_mois, Djours = $Djours, Da = $Da, Dm = $Dm, Dj = $Dj";
do   {
  if($Djours >= $di_jour) {
    $Djours += -$di_jour;
    if($i_mois < 12) {
      $i_mois++;
    }
    else {
      $i_mois = 1;
      $i_an++;
    }
    $ok = 1;
    $j_an = ($i_mois < 12) ? $i_an : $i_an + 1;
    $j_mois = ($i_mois <12) ? $i_mois + 1: 1;
    $di_jour = Delta_Days($i_an, $i_mois, $debut[2], $j_an, $j_mois, $debut[2]);
    if($Dm < 11) {
      $Dm++;
    }
    else {
      $Dm = 0;
      $Da++;
    }
#    print "\ndi_jour = $di_jour, i_an = $i_an, i_mois = $i_mois, j_an = $j_an, j_mois = $j_mois, Djours = $Djours, Da = $Da, Dm = $Dm, Dj = $Dj";
  }
  else {
    $ok = 0;
  }

}
while($ok);
$Dj = $Djours;
#print "\nL'ecart entre ces 2 dates est de : ",($Da >0)?"$Da an(s) ":'',($Dm >0)?"$Dm mois ":'',($Dj>0)?"$Dj jour(s)":'';
return ($Da, $Dm, $Dj);


}

1;