#!/usr/bin/perl -w
# Script affichant la fenetre d'ajout des heures supplÃ©mentaires
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);

# DÃ©claration du rÃ©pertoire de base
#my $rep = '../../test/jude/V3.0';
# DÃ©claration pour javascript

#my $elt;
my $cgi = new CGI;
my $user = $cgi->param('ident_user');
my $mois = $cgi->param('mois');
my $annee = $cgi->param('annee');
my $client_id = $cgi->param('client_id');
my $client = $cgi->param('client');
my $ra_id = $cgi->param('ra_id');
my $status = $cgi->param('status');
my $nb_lig = $cgi->param('nb_lig');
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
	# DÃ©claration du rÃ©pertoire de base
	$rep = './';
	$rep_pl = '/jude/V3.0';
}
else {
	$rep = '../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
}
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/ra_delete.js",
);
# DÃ©claration des feuilles de styles
my %style = (
       'src'               => "$rep/styles/ra_delete.css",
);

my @liens = [
       Link({
         'rel'             => 'shotcut icon',
#         'type'            => 'image/png',
         'href'            => "$rep/images/favicon.ico",
       }),
];



entete_standard();
#print "Valeur de status : $status", $cgi->br();
print $cgi->start_form(-onsubmit => "return bouton_ok(this);");
print $cgi->div({-id =>'titre_delete'}, "Rapport d'activités - Suppression");
print $cgi->div("L'adresse HTTP appelante est $ENV{HTTP_REFERER}");
if($status eq 'ok') {
  print $cgi->div({-id => 'ligne1'}, "La suppression du rapport d'activités s'est terminée avec succès.");
  print $cgi->div({-id => 'ligne2'}, "Les caractéristiques du rapport d'activités supprimé sont :");
  print $cgi->div({-id => 'ligne3'}, $cgi->div({-class => 'col1'}, "Mois :&nbsp;"), $cgi->div({-class => 'col2'}, "$mois"));
  print $cgi->div({-id => 'ligne4'}, $cgi->div({-class => 'col1'}, "Année :&nbsp;"), $cgi->div({-class => 'col2'}, "$annee"));
  print $cgi->div({-id => 'ligne5'}, $cgi->div({-class => 'col1'}, "Client :&nbsp;"), $cgi->div({-class => 'col2'}, "$client"));
  print $cgi->div({-id => 'ligne6'}, $cgi->div({-class => 'col1'}, "N° du rapport d'activités :&nbsp;"), $cgi->div({-class => 'col2'}, "$ra_id"));
}
else {
  print $cgi->div({-id => 'ligne1'}, "La suppression du rapport d'activités s'est terminée avec des erreurs.");
  print $cgi->div({-id => 'ligne2'}, "Contacter votre administrateur et communiquez lui les informations suivantes :");
  print $cgi->div({-id => 'ligne3'}, $cgi->div({-class => 'col1'}, "Mois :&nbsp;"), $cgi->div({-class => 'col2'}, "$mois"));
  print $cgi->div({-id => 'ligne4'}, $cgi->div({-class => 'col1'}, "Année :&nbsp;"), $cgi->div({-class => 'col2'}, "$annee"));
  print $cgi->div({-id => 'ligne5'}, $cgi->div({-class => 'col1'}, "Client :&nbsp;"), $cgi->div({-class => 'col2'}, "$client"));
  print $cgi->div({-id => 'ligne6'}, $cgi->div({-class => 'col1'}, "N° du rapport d'activités :&nbsp;"), $cgi->div({-class => 'col2'}, "$ra_id"));
  print $cgi->start_div({-id => 'ligne7'}), $cgi->div({-class => 'col1'}, "Nombre de lignes supprimées :&nbsp;");
  if($nb_lig ne '0E0') {
    print $cgi->div({-class => 'col2'}, "$nb_lig"), $cgi->end_div();
  }
  else {
    print $cgi->div({-class => 'col2'}, "$nb_lig*"), $cgi->end_div();
    print $cgi->div({-id=> 'Ligne8'}, "*Le nombre de lignes supprimées indique que le rapport d'actvités $ra_id avait déjà  été supprimé.", $cgi->br(), "La fenêtre de base de l'application a été mise à jour en tenant compte de ces nouvelles informations.");
  }
}
print $cgi->start_div({-id => 'bouton'});
print $cgi->submit(-value =>'OK');
print $cgi->end_div();
print $cgi->end_form();
print $cgi->end_html();
exit;

sub entete_standard {
	print $cgi->header();
	print $cgi->start_html({-head => @liens, -Title => "etechnoserv.com v3.0 - Suppression de rapport d'activités", -script => \%script,
              -style =>\%style, -base => 'true', -onLoad =>"return modifie();"});
}

