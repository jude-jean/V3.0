#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);

our $cgi = new CGI;
our ($rep, $rep_pl);
if($cgi->server_name =~ /etechnoserv/) {
	# Déclaration du répertoire de base
	$rep = '.';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib";

}
else {
	$rep = '../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}

our @script = (
        { 'language'           => "javascript",
          'src'                => "$rep/scripts/test_dhtml.js"
        },
);

# Déclaration des feuilles de styles
our @liens = [
       Link({
         'rel'             => 'stylesheet',
         'type'            => 'text/css',
         'href'            => "$rep/styles/test_dhtml.css",
         'media'           => 'screen',
       }),
       Link({
         'rel'             => 'shortcut icon',
         'href'            => "$rep/images/favicon.ico",
       }),
	   
];



entete_standard();
print $cgi->div({-id => 'entete'}, "Voici l'entete");
print $cgi->h1("Ceci est un test DHTML");
print $cgi->start_div({-id => 'droite'}), $cgi->start_div({-id => 'cadre'});
print $cgi->div({-id => 'rdv', -onmousedown=>"return anime_rdv(this, event);"}, $cgi->span({-id =>'rdv_heure'},"xx:xx - xx:xx"), $cgi->span({-id => 'rdv_msg'}, "RDV avec Nadine"));
foreach(0..20) {
	print $cgi->div({-class => 'ligne'}, "$_");
}

print $cgi->end_div(),$cgi->end_html();

exit();

sub entete_standard {
	print $cgi->header();
	print $cgi->start_html({-Title => "Test DHTML", -script => \@script,
              -head =>@liens, -base => 'true'});
}
