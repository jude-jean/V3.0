package Facture;
use Exporter;
use Encode qw(encode decode);
use URI::Escape;
@ISA = ('Exporter');
@EXPORT = qw(affiche_facture saisie_facture);

use Date::Calc qw(:all);
use Time::Local;
use JourDeFete qw(est_ferie est_jour_ferie Delta_Dates_AMJ);

my @mois = qw(janvier f&eacute;vrier mars avril mai juin juillet ao&ucirc;t septembre octobre novembre d&eacute;cembre);

#our $client;

sub saisie_facture {
    #print $::cgi->start_div({-class => 'facture'});
    #print $::cgi->start_div({-class => 'nomClientFactureSaisie'});
    #print $::cgi->span('Nom du client : '.$::client->[0]);
    #print $::cgi->end_div();
    #print $::cgi->start_div({-class => 'prenomCollaborateurFactureSaisie'});
    #print $::cgi->span('Prenom du collaborateur : '. ucfirst $::user->[0]);
    #print $::cgi->end_div();
    #print $::cgi->start_div({-class => 'nomCollaborateurFactureSaisie'});
    #print $::cgi->span('nom du collaborateur : '.ucfirst $::user->[1]);
    #print $::cgi->end_div();
    #print $::cgi->start_div({-class => 'dateFactureSaisie'});
    #print $::cgi->span('Annee : '.$::parametres{annee}.', Mois : '.ucfirst $mois[($::parametres{mois_num} - 1)]);
    #print $::cgi->end_div();    
    #print $::cgi->start_div({-class => 'tauxPrestationFactureSaisie'});
    #print $::cgi->span('tauxPrestation : '.$::tauxPrestation->[0]);
    #print $::cgi->end_div();
    #print $::cgi->start_div({-class => 'typeTauxPrestationFactureSaisie'});
    #print $::cgi->span('typeTauxPrestation : '.$::tauxPrestation->[1]);
    #print $::cgi->end_div();                
    #print $::cgi->end_div();

    #print $::cgi->start_table(), $::cgi->table_tr($::cgi->td("Nom du client"),$::cgi->td($::client->[0]));
    #print "@$::jourHeureAFacturer";
    print $::cgi->div({-class => 'titreFacture'}, "D&eacute;tails de la facture");
    print "<table class='factureCreation'>
    <tr class='factureCreationInfos'><td class='col1'>Nom du client</td><td class='col2'>$::client->[0]</td></tr>
    <tr class='factureCreationInfos'><td class='col1'>Pr&eacute;nom du collaborateur</td><td class='col2'>".ucfirst $::user->[1]."</td></tr>
    <tr class='factureCreationInfos'><td class='col1'>Nom du collaborateur</td><td class='col2'>".ucfirst $::user->[0]."</td></tr>
    <tr class='factureCreationInfos'><td class='col1'>Ann&eacute;e</td><td class='col2'>$::parametres{annee}</td></tr>
    <tr class='factureCreationInfos'><td class='col1'>Mois</td><td class='col2'>".ucfirst $mois[($::parametres{mois_num} - 1)]."</td></tr>";
    my $i = 0;
    my $key, $montantFactureHT = 0, $txt = "(", $montantHT, $quantite;

    foreach(@$::jourHeureAFacturer) {
        $key = ($i==0)? 'j' : 'h';
        $quantite = $::jourHeureAFacturer->[$i];
        print $::cgi->hidden(-name => "nbre$key", -value => $quantite);
        $quantite =~ s/\./,/;
        print "<tr class='sousMontant$key'><td>Quantit&eacute;</td><td class='nbre$key'><span class='nbre$key'>$quantite</span></td></tr>";
        print "<tr class='sousMontant$key'><td>".(($key eq 'j')? "Taux journalier":"Taux horaire")."</td><td class='currency'>$::tauxPrestationByType{$key}[0]</td></tr>";
        $montantHT = $::jourHeureAFacturer->[$i]*$::tauxPrestationByType{$key}[0];
        $montantHT = sprintf("%.2f", $montantHT);
        print $::cgi->hidden(-name => "montantFacture$key", -value => $montantHT);
        print $::cgi->hidden(-name => "tauxPrestationByType$key", -value => $::tauxPrestationByType{$key}[0]);
        print $::cgi->hidden(-name => "tauxPrestationId$key", -value => $::tauxPrestationByType{$key}[1]);
        $montantHT =~ s/\./,/;
        $montantHT = convertMilliersToLocal($montantHT);
        print "<tr class='sousMontant$key'><td>Sous Montant ".($i+1)." HT</td><td class='currency'>$montantHT</td></tr>";
        $montantFactureHT +=  $::jourHeureAFacturer->[$i]*$::tauxPrestationByType{$key}[0];

        $i++;
        $txt .= "$i + ";

    }
    $txt =~ s/ \+ $/)/;    
    #"<tr><td>".(($::tauxPrestation->[1] eq 'j')? "Nombre de jours &agrave; facturer":"Nombre d\'heures &agrave; facturer")."</td><td>$::nbreAFacturer</td></tr
    $montantFactureHT = sprintf("%.2f", $montantFactureHT);
    $montantFactureHT =~ s/\./,/;
    $montantFactureHT = convertMilliersToLocal($montantFactureHT);    
    print "<tr class='montantTotal'><td>Montant Total $txt HT</td><td class='currency'>$montantFactureHT</td></tr>
    <tr><td>Date de cr&eacute;ation<div class='tooltip'><sup>*</sup><span class='tooltiptext'>La saisie d\'une date pour l\'&eacute;tablissement d\'une facture est obligatoire</span></div></td><td><input type='date' id='dateCreationFacture' name='dateCreation'/></td></tr>
    </table>";
    affiche_menu_s_actions();
    if(scalar(%::tauxPrestationByType) == 0) {
        afficheAvertissement();
    }
    print $::cgi->div("Taille de %::tauxPrestationByType = ".keys %::tauxPrestationByType);
    foreach(keys %tauxPrestationByType) {
      print 'Type = '.$_.': montant = '.$tauxPrestationByType{$_}->[0].', id = '.$tauxPrestationByType{$_}->[1], $cgi->br();
    }        
#<tr><td>Type du montant de la prestation</td><td>".(($::tauxPrestation->[1] == 'j')? "Taux journalier":"Taux horaire")."</td></tr>
}

sub affiche_facture {
    if($::parametres{action} eq 'impression') {
        print $::cgi->div({-id =>'logo'},$::cgi->img({-alt =>'Logo', -name =>'logo', -src => "$rep/images/logo-w90.jpg"}));
    }
    #print $::cgi->div("\$::facture->[9] = $::facture->[9], \$::raControle->[5] = $::raControle->[5], \$::estAJour = $::estAJour");
    print $::cgi->start_div({-class => 'facture'});
    print $::cgi->start_div({-class => 'adresseFacture'}, "Adresse du client $::parametres{client_id}");
    print $::cgi->span({-class => 'nomClientFacture'}, $::client->[0]);
    if($::client->[1] != undefined && $::client->[1] != null) {
        print $::cgi->span({-class => 'adresseClientFacture'}, $::client->[1]);
    }
    if($::client->[2] != undefined && $::client->[2] != null) {
        print $::cgi->span({-class => 'adresse2ClientFacture'}, $::client->[2]);
    }
    if($::client->[3] != undefined && $::client->[3] != null) {
        print $::cgi->span({-class => 'codePostalClientFacture'}, $::client->[3]);
    }
    #if($::client->[4] != undefined) {
        print $::cgi->span({-class => 'villeClientFacture'}, $::client->[4]);
    #}
    if( $::client->[5] == null) {
        print $::cgi->span({-class => 'paysClientFacture'}, 'France');
    }
    else {
        print $::cgi->span({-class => 'paysClientFacture'}, $::client->[5]);
    }                
    print $::cgi->end_div();
    afficheIntituleFacture();

    #print $::cgi->div({-class => 'referencesFacture'}, "References de la facture");
    afficheReferenceFacture();
    afficheTVAFacture();
    afficheSiretFacture();

    #print $::cgi->div({-class => 'dateFacture'}, "La date de la facture");
    afficheDateFacture();
    #print $::cgi->div({-class => 'objetFacture'}, "Objet de la facture");
    afficheObjetFacture();
    #print $::cgi->div({-class => 'prestations'}, "Tableau des prestations");
    afficheTableauPrestations();
    #print $::cgi->div({-class => 'delaiPaiementFacture'}, "Delai de paiement");
    afficheDelaiPaiement();
    print $::cgi->end_div();
    affiche_menu_s_actions();
    if($::estAJour == 0) {
        afficheAvertissement();
    }
    
}

sub afficheIntituleFacture() {
    #print $::cgi->div({-class => 'intituleFacture'}, "Nom de la facture. Ex: KAJJ202502");
    #print $::cgi->span('secondes = '.$::secondes.', minutes = '.$::minutes.', heures = '.$::heures.', jour ='.$::jour.', mois = '.(($::mois + 1) < 10? "0".($::mois + 1): ($::mois + 1)).', annee = '.($::annee + 1900).' ');
    #print $::cgi->div('parametres{list_arg} = '.$::parametres{mois_num}.' '.$::parametres{annee});
    print $::cgi->start_div({-class => 'intituleFacture'}),
            $::cgi->span('Facture N&deg; '.uc(substr($::client->[0], 0, 2)).uc(substr($::user->[1], 0, 1)).uc(substr($::user->[0], 0, 1)).$::parametres{annee}.($::parametres{mois_num} < 10? "0".$::parametres{mois_num}: $::parametres{mois_num})),
            $::cgi->end_div();
}

sub afficheReferenceFacture() {
    print $::cgi->start_div({-class => 'referenceFacture'}),
            $::cgi->span('R&eacute;f&eacute;rence : '.uc(substr($::client->[0], 0, 2)).uc(substr($::user->[1], 0, 1)).uc(substr($::user->[0], 0, 1)).($::parametres{mois_num} < 10? "0".$::parametres{mois_num}: $::parametres{mois_num}).substr($::parametres{annee}, 2)),
            $::cgi->end_div();
}

sub afficheTVAFacture() {
    print $::cgi->start_div({-class => 'tvaFacture'}),
        $::cgi->span('TVA intra-communautaire : FR 71 444 742 530'),
        $::cgi->end_div();

}

sub afficheSiretFacture() {
    print $::cgi->start_div({-class => 'siretFacture'}),
        $::cgi->span('Siret : 444 742 530 00017'),
        $::cgi->end_div();

}

sub afficheDateFacture() {
    #$::jour = 1;
    my ($annee, $mois, $jour) = split /-/, $::facture->[8];
    print $::cgi->start_div({-class => 'dateFacture'}),
            $::cgi->span('Le '.(($jour == 1)? ($jour+0)."<sup>er</sup>" : ($jour+0)).' '.$mois[($mois-1)].' '.$annee),
            $::cgi->end_div();
}

sub afficheObjetFacture() {
    print $::cgi->start_div({-class => 'objetFacture'}),
            $::cgi->span('Prestations r&eacute;alis&eacute;es en '.$mois[($::parametres{mois_num} - 1)].' '.$::parametres{annee}),
            $::cgi->end_div();
}

sub afficheTableauPrestations() {
    my $quantite = 0, $tvaCalculee = 0, $puHT = 0, $montantTVA = 0, $totalHT = 0, $totalTTC = 0, $montantFactureHT = 0, $montantFactureTVA = 0, $montantFactureTTC = 0;
    print "<table class='tableauPrestations'>
            <thead><tr><th scope='col'>Missions</th><th scope='col'>Nbre</th><th scope='col'>PUHT</th><th scope='col'>Total HT</th><th scope='col'>TVA(20%)</th><th scope='col'>Total TTC</th></thead>
            <tbody>";

    foreach(keys %::tauxPrestationByType) {
        if($_ eq 'j') {
            if($::facture->[9] != 0) {
                $quantite = $::facture->[9];
                $tvaCalculee = ($::facture->[7]*0.2);
                $puHT = sprintf("%.2f", $::tauxPrestationByType{$_}[0]);
                $totalHT = sprintf("%.2f", $::facture->[7]);
                $totalTTC = sprintf("%.2f", ($::facture->[7] + $tvaCalculee));
            }
        }
        if($_ eq 'h') {
            if($::facture->[12] != 0) {
                $quantite = $::facture->[12];
                $tvaCalculee = ($::facture->[11]*0.2);
                $puHT = sprintf("%.2f", $::tauxPrestationByType{$_}[0]);
                $totalHT = sprintf("%.2f", $::facture->[11]);
                $totalTTC = sprintf("%.2f", ($::facture->[11] + $tvaCalculee));                
            }
        }        
        #$quantite = $::facture->[9];
        $montantFactureTVA += $tvaCalculee;
        $montantFactureTTC += $totalTTC;
        $montantFactureHT += $totalHT;
        if($quantite =~ /(.00)$/) {
            $quantite =~ s/$1//;
        }
        else {
            $quantite =~ s/\./,/;
        }    
        #$tvaCalculee = ($::facture->[7]*0.2);
        $montantTVA = sprintf("%.2f", $tvaCalculee);
        $montantTVA =~ s/\./,/;
        $montantTVA = convertMilliersToLocal($montantTVA);
        #$puHT = sprintf("%.2f", $::tauxPrestation->[0]);
        $puHT =~ s/\./,/;
        $puHT = convertMilliersToLocal($puHT);
        #$totalHT = sprintf("%.2f", $::facture->[7]);
        $totalHT =~ s/\./,/;
        $totalHT = convertMilliersToLocal($totalHT);
        #my $totalTTC = $::facture->[7] + $tvaCalculee;
        #$totalTTC = sprintf("%.2f", ($::facture->[7] + $tvaCalculee));
        $totalTTC =~ s/\./,/;
        $totalTTC = convertMilliersToLocal($totalTTC);
        if($quantite != 0)  {
            print "<tr><th scope='row'>".$::mission->[0]."</th><td scope='row' class='quantite$_'><span>$quantite</span></td><td scope='row' class='currency'>$puHT</td><td scope='row' class='currency'>$totalHT</td><td scope='row' class='currency'>$montantTVA</td><td scope='row' class='currency'>$totalTTC</td></tr>";
            $quantite = 0;
        }       
        

    }
    $montantFactureHT = sprintf("%.2f", $montantFactureHT);
    $montantFactureHT =~ s/\./,/;
    $montantFactureTVA = sprintf("%.2f", $montantFactureTVA);
    $montantFactureTVA =~ s/\./,/;
    $montantFactureTTC = sprintf("%.2f", $montantFactureTTC);
    $montantFactureTTC =~ s/\./,/;
    print "</tbody><tfoot><tr><th colspan='3' class='total'>Total</th><td class='currency'>".convertMilliersToLocal($montantFactureHT)."</td><td class='currency'>".convertMilliersToLocal($montantFactureTVA)."</td><td class='currency'>".convertMilliersToLocal($montantFactureTTC)."</td></tr></tfoot>
            </table>";
}

sub afficheDelaiPaiement() {
    my $delaiStr;
    if($::mission->[1] == 0 && $::mission->[2] eq '') {
        return;
    }
    if($::mission->[1] != 0 && $::mission->[2] eq '') {
        print $::cgi->div({-class => 'delaiPaiement'}, "Paiement &agrave; ".$::mission->[1]." jours");
        return;
    }
    if($::mission->[1] == 0 && $::mission->[2] ne '') {
        $delaiStr = lc($::mission->[2]);
        $delaiStr =~ s/é/&eacute;/g;
        $delaiStr =~ s/è/&egrave;/g;
        $delaiStr =~ s/ê/&ecirc;/g;        
        print $::cgi->div({-class => 'delaiPaiement'}, "Paiement &agrave; ".$delaiStr);
        return;
    }
    print $::cgi->div({-class => 'delaiPaiement'}, "Paiement &agrave; ".$::mission->[1]." jours, ".$delaiStr);
}

sub afficheAvertissement() {
    print $::cgi->start_div({-class=>'avertissement', id => 'avertissement'});
    print $::cgi->p({-class=>'avertissementHeader'}, "Avertissement !!"),
        $::cgi->p({-class=>'avertissementBody'}, "Le rapport d'activit&eacute;s a chang&eacute; depuis la cr&eacute;ation de la facture.</br> Le nombre de jours de pr&eacute;sence actuellement d&eacute;fini dans le RA est de <strong>$::raControle->[5]</strong>.</br> La facture a &eacute;t&eacute; &eacute;tablie avec un nombre de jours facturables de <strong>$::facture->[9]</strong>.</br></br>Pour prendre en compte le nombre de jours du RA, il vous faut supprimer la facture existante et en cr&eacute;er une nouvelle");
    print '<button onclick="document.getElementById(\'avertissement\').style.display = \'none\';return false;" aria-label="close" class="x">X</button>';
    print $::cgi->end_div();
}

sub affiche_menu_s_actions {
	print $::cgi->start_div({-id=>'menu_actions'});
	if($::parametres{action} eq 'impression') {
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(0);");
	}
	elsif($::parametres{action} eq 'affichage') {
		print $::cgi->submit(-name =>'s_action', -value =>'Imprimer', -onclick => "return imprimer_facture(0)");		
		print $::cgi->submit(-name =>'s_action', -value =>'Version PDF');
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(0);");
	}
	elsif($::parametres{action} eq 'creation') {
		#vers_sous_menu('Sauvegarder', -onclick =>"return verifDateFacture();");
        print $::cgi->submit(-name =>'s_action', -value => 'Sauvegarder', -onclick =>"return verifDateFacture();");
		print $::cgi->reset;
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(1);");
	}
	else {
		#vers_sous_menu('Sauvegarder');
		#print $::cgi->submit(-name =>'s_action', -value =>'Visualiser', -onclick => "return visualiser_ra()");
		#print $::cgi->submit(-name =>'s_action', -value =>'Imprimer', -onclick => "return imprimer_facture(1)");
        print $::cgi->submit(-name =>'s_action', -value =>'Imprimer');
        print $::cgi->submit(-name =>'s_action', -value =>'Supprimer');
		#print $::cgi->reset;
		#print $::cgi->submit(-name =>'s_action', -value =>'Version PDF');
		print $::cgi->submit(-name =>'Fermer', -onclick =>"return fermer_fenetre(1);");
	}
    print $::cgi->end_div();
}

sub convertMilliersToLocal() {
    my ($initial) = @_;

    if($initial =~ /(\d{1,3})(\d{3}),(\d{2})/) {
        return "$1 $2,$3";
    }
    if($initial =~ /(\d{1,3})(\d{3})(\d{3}),(\d{2})/) {
        return "$1 $2 $3,$4";
    }
    if($initial =~ /(\d{1,3})(\d{3})(\d{3})(\d{3}),(\d{2})/) {
        return "$1 $2 $3 $4,$5";
    }
    if($initial =~ /(\d{1,3})(\d{3})(\d{3})(\d{3})(\d{3}),(\d{2})/) {
        return "$1 $2 $3 $4 $5,$6";
    }            
    return $initial;
}

sub vers_sous_menu {
  print $::cgi->submit(-name=>'s_action', -value=>shift);
}


1;
