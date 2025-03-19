#!/usr/bin/perl -w
use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use DBI;

our %parametres =();

our $cgi = new CGI;

our ($rep, $rep_pl, $dbh);

if($cgi->server_name =~ /etechnoserv/) {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("dbi:mysql:database=db447674934;host=db447674934.db.1and1.com;user=dbo447674934;password=t1ands6")
	or die "probl�me de connexion � la base de donn�es db447674934 : $!";
	# D�claration du r�pertoire de base
	$rep = '../..';
	$rep_pl = '/jude/V3.0';
	use lib "/homepages/42/d74330965/htdocs/jude/V3.0/lib/";
}
else {
#Connexion � la base de donn�e.
	$dbh = DBI->connect("DBI:mysql:database=collaborateur", "root", "t1ands6")
	or die "probl�me de connexion � la base de donn�es collaborateur : $!";
	$rep = '../../../../test/jude/V3.0';
	$rep_pl = '/cgi-bin/V3.0';
	use lib "/usr/lib/cgi-bin/V3.0/lib";
}

use Etechnoserv;


lecture_parametres(\%parametres);
print $cgi->header();
print $cgi->start_html({-Title => "Erreur v1.0"});
print $cgi->start_div();
print " Voici la liste des parametres du programmes appelant", $cgi->br();
visu_parametres(\%parametres);
print $cgi->end_div(), $cgi->end_html();
