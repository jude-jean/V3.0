//  Fichier outils.js contenant les fonctions javascript
self.onerror = ma_gestion_erreur;

if(location.hostname.match(/www.etechnoserv/)) {
	var base = '/jude/V3.0';
}
else {
	var base = '/test/jude/V3.0';
}

if(!window.Node) {
  var Node = {
    ELEMENT_NODE: 1,
    ATTRIBUTE_NODE: 2,
    TEXT_NODE: 3,
    COMMENT_NODE: 8,
    DOCUMENT_FRAGMENT_NODE: 11
  }
}

function recup_args() {
  var args = new Object();
  var requete = location.search.substring(1);
  var paires = requete.split("&");
  for(var i = 0; i < paires.length; i++) {
    var pos = paires[i].indexOf('=');
    if(pos == 1) continue;
    var nom = paires[i].substring(0, pos);
    var valeur = paires[i].substring(pos + 1);
    try {
      args[nom] = unescape(valeur);
    }
    catch(e) {
      alert('unescape(): Probl�me de codage avec la valeur de '+nom+' �gale � '+valeur);
      try {
        args[nom] = decodeURIComponent(valeur);
      }
      catch(e) {
        args[nom] = valeur;
        alert('decodeURIComponent(): Probl�me de codage avec la valeur de '+nom+' �gale � '+args[nom]);
      }
      finally {
        alert('Le d�codage pour la valeur de '+nom+ ' est �gale � '+args[nom]);
      }
    }
  }
  return args;
}


function ma_gestion_erreur(msg, url, line) {
  alert(' Une erreur est survenue dans le code Javscript, voici les d�tails :\n Message d\'erreur : '+msg+'\n Ligne N� : '+line);
  return true;
}

function bouton_ok(obj) {
//  alert("C'est la fonction bouton_ok est actionn�e");
  window.close();
  return false;
}

//var largeur = innerWidth;
//var hauteur = innerHeight;
var ligne_delete = -1;
// nb_max_maj = 3 pour  suppression
var nb_maj = 0;
function modifie() {
  var args = recup_args();
//  alert('Avant resize : \nLargeur = '+largeur+' Hauteur = '+hauteur+' Avail Largeur ='+screen.availWidth+' Avail Hauteur '+screen.availHeight+'\nLargeur �cran : '+screen.width+' hauteur �cran : '+screen.height);
  self.resizeTo(600, 420);
//  alert('Apr�s resize : \nLargeur = '+largeur+' Hauteur = '+hauteur+' Avail Largeur ='+screen.availWidth+' Avail Hauteur '+screen.availHeight+'\nLargeur �cran : '+screen.width+' hauteur �cran : '+screen.height);
//  alert('Valeur de status '+args.status);
  if((args.status == 'ok') || (args.nb_lig == '0E0')) {
    var racine = opener.document.getElementById('ra_ecran_mensuel');
    var cree_a = opener.document.createElement("a");
    var url = '/cgi-bin/V3.0/rapports_activites/ra/show.pl?ident_user='+args.ident_user+'&action=creation&annee='+args.annee+'&mois='+args.mois+'&client_id='+args.client_id+'&ident_id='+args.ident_id;
//    alert('Valeur de url dans modifie() : '+url);
//    cree_a.setAttribute("title", 'Cr�er');
    cree_a.setAttribute("target", 'Creation');
    cree_a.setAttribute("href", url);
    var cree_img = opener.document.createElement("img");
    cree_img.setAttribute("alt", 'Cr�er-'+args.client);
    cree_img.setAttribute("title", 'Cr�er');
    cree_img.setAttribute("src", base+'/images/page_blank.png');
    cree_a.appendChild(cree_img);
//    var text_del = opener.document.createTextNode(' ');
//    var frag = opener.document.createDocumentFragment();
    var enfants = racine.childNodes;
//    alert('Nbre d\'�l�ments de la variable enfants : '+enfants.length+'\nLa valeur de la variable nb_maj = '+nb_maj);
// On ne tient pas compte des 2 premi�res lignes du tableau
    for(var i = 2; i < enfants.length; i++) {
      if(nb_maj < 3) {
//        alert('indice = '+i+' : Son parent est : '+enfants[i].parentNode.nodeName+' avec pour Id : '+enfants[i].parentNode.id+' et pour class : '+enfants[i].parentNode.className);
        if(enfants[i].className ==  'ra_ligne3col') {
          traite_ra_ligne3col(enfants[i], i, args, url, cree_a);
        }
      }
      else {
//        alert('La variable nb_maj = '+nb_maj);
        return;
      }
    }
    if(nb_maj < 3) {
      alert('La mise en jour de la f�netre principale de l\'application n\'a pas pu �tre enti�rement men�e � bien.\nIl vous est vivement conseill� d\'actualiser la page de votre navigateur pour prendre en compte les modifications survenues suite aux r�centes actions que vous venez d\'entreprendre');
    }
  }
}

var frag_enfants = 0;
function traite_ra_ligne3col(obj, lg, args, url, cree_a) {
  alert('Lacement de la fonction traite_ra_ligne3col avec les arguments : lg = '+lg+' url = '+url);
  var enfants = obj.childNodes;
  for(var i = 0; i < enfants.length; i++) {
    if(enfants[i].nodeName == 'A') {
      if(enfants[i].firstChild.nodeType == Node.TEXT_NODE) {
        if((enfants[i].title == 'Editer') && (enfants[i].target == 'Edition')&& (enfants[i].firstChild.data == args.client)) {
          enfants[i].setAttribute("target", 'Creation');
          enfants[i].setAttribute("title", 'Cr�er');
          enfants[i].setAttribute("href", url);
          ligne_delete = lg;
          nb_maj++;
//          alert('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url modifi� est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+' Son texte est '+enfants[i].firstChild.nodeValue);
          return;
        }
      }
      else {
        var frere;
        if(enfants[i].firstChild.nodeName == 'IMG') {
//          alert('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+'\nALT de son enfant : '+enfants[i].firstChild.alt);
          if((enfants[i].firstChild.title == 'Editer') && (enfants[i].target == 'Edition')&& (enfants[i].firstChild.alt == ('Editer-'+args.client))) {
            enfants[i].parentNode.replaceChild(cree_a, enfants[i]);
            frere = enfants[i].nextSibling;
//            if(frere != null) {
//              alert('frere est diff�rent de null, son NodeName = '+frere.nodeName+', son texte est <'+frere.data+'> La class de son parent est '+frere.parentNode.className);
//            }
//            alert('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url modifi� est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+'\nALT de son enfant : '+enfants[i].firstChild.alt);
//            if((frere.nodeType == Node.TEXT_NODE) && (frere.data == unescape('%20'))) {
            if(frere.nodeType == Node.TEXT_NODE) {
//              alert('Ce noeud est � supprimer : indice = '+i+' : Le nodeName est '+frere.nodeName+' et son texte est '+frere.data+'\n La class de son parent est '+enfants[i].parentNode.className);
              enfants[i].parentNode.removeChild(frere);
              frere = enfants[i].nextSibling;
//              if(frere != null) {
//                alert('frere est diff�rent de null, son NodeName = '+frere.nodeName+' La class de son parent est '+frere.parentNode.className);
//              }
              if((frere.firstChild.title == 'Supprimer') && (frere.target == 'Suppression')&& (frere.firstChild.alt == ('Supprimer-'+args.client))) {
//                alert('Ce noeud est � supprimer : indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+'\nALT de son enfant : '+enfants[i].firstChild.alt);
                enfants[i].parentNode.removeChild(frere);
                nb_maj++;
                return;
              }
            }
            else {
//              alert('Les caract�ristiques du noeud frere non supprim� sont : son type : <'+frere.nodeType+'> Sa valeur : <'+frere.data+'> La class de son parent : '+frere.parentNode.className);
              return;
            }
          }
//          else {
//            alert('Les valeurs du test sont : title : '+enfants[i].firstChild.title+', target : '+enfants[i].target+', Alt : '+enfants[i].firstChild.alt+' test� avec la valeur \'Cr�er-'+args.maj+'\'');
//          }
        }
      }
    }
    else {
      if(enfants[i].nodeType == Node.TEXT_NODE) {
//        alert('Le noeud courant est du Text contentant le texte suivant : <'+enfants[i].nodeValue+'>\nla classe de son parent est '+enfants[i].parentNode.className+' nbligne = '+ligne_delete+' lg = '+lg);
        if(ligne_delete == lg) {
//          alert('Indice = '+i+' Son parent est : '+enfants[i].parentNode.nodeName+' avec pour Id : '+enfants[i].parentNode.id+' et pour class : '+enfants[i].parentNode.className+' nbligne = '+ligne_delete+' lg = '+lg);
          enfants[i].data = ' '; // en attendant de changer la taille du div
//          alert('Le noeud text a �t� modif� et a pour valeur actuelle '+enfants[i].data+'\nLes caract�ritisques du noeud modifi�es sont :la classe de son parent est '+enfants[i].parentNode.className+' nbligne = '+ligne_delete+' lg = '+lg);
          nb_maj++;
        }
      }
      else {
//        alert('Lancement r�cursif de traite_ra_ligne3col');
        traite_ra_ligne3col(enfants[i], lg, args, url, cree_a);
//        alert('Fin du lancement r�cursif de traite_ra_ligne3col');
      }
    }

  }

}
