package Facture;
use Exporter;
use Encode qw(encode decode);
use URI::Escape;
@ISA = ('Exporter');
@EXPORT = qw(affiche_facture);

use Date::Calc qw(:all);
use Time::Local;
use JourDeFete qw(est_ferie est_jour_ferie Delta_Dates_AMJ);

#our $client;

sub affiche_facture {
    print $::cgi->start_div();
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
    print $::cgi->div({-class => 'intituleFacture'}, "Nom de la facture. Ex: KAJJ202502");
    print $::cgi->div({-class => 'referencesFacture'}, "References de la facture");
    print $::cgi->div({-class => 'dateFacture'}, "La date de la facture");
    print $::cgi->div({-class => 'objetFacture'}, "Objet de la facture");
    print $::cgi->div({-class => 'prestations'}, "Tableau des prestations");
    print $::cgi->div({-class => 'delaiPaiementFacture'}, "Delai de paiement");

    print $::cgi->end_div(); 
}



1;
