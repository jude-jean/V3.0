#!/usr/bin/perl -w
# Magasin de chemises et chaussures
use strict;
use lib ("/c/Strawberry/perl/site/lib", "./lib");
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
#use DBI;
use Date::Calc qw(:all);
#use Time::Local;
#use RapportActivite qw(gestion_ra);
use JourDeFete;


# D�claration du r�pertoire de base
our $rep = '../../test/jude/V3.0';
# D�claration pour javascript
my %script = (
        'language'           => "javascript",
        'src'                => "$rep/scripts/outils.js",
);
# D�claration des feuilles de styles
my %style = (
       'src'               => "$rep/styles/test.css",
);
my $rep;
my $cgi = new CGI;
entete_standard();
calcul_fete_paques(2015);
init_feries(2015);
imprime_jours_feries(2015);
print $cgi->br;
est_jour_ferie(6, 4, 2015, \$rep);
print "$rep";
exit();


sub entete_standard {
	print $cgi->header();
	print $cgi->start_html({-Title => "Test_jour_ferie", -script => \%script,
              -style =>\%style, -base => 'true'});
}
