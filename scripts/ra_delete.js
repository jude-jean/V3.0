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
      alert('unescape(): Problùme de codage avec la valeur de '+nom+' ùgale ù '+valeur);
      try {
        args[nom] = decodeURIComponent(valeur);
      }
      catch(e) {
        args[nom] = valeur;
        alert('decodeURIComponent(): Problùme de codage avec la valeur de '+nom+' ùgale ù '+args[nom]);
      }
      finally {
        alert('Le dùcodage pour la valeur de '+nom+ ' est ùgale ù '+args[nom]);
      }
    }
  }
  return args;
}

function ecrire_dans_console (texte) {
  // Ecrire dans la console si elle est active ou ecrire dans alert
    if (typeof console !== 'undefined') {
          console.log(texte);    
      }
      else {
          alert(texte);    
      }
  
  }
  

function ma_gestion_erreur(msg, url, line) {
  alert(' Une erreur est survenue dans le code Javscript, voici les dùtails :\n Message d\'erreur : '+msg+'\n Ligne Nù : '+line);
  return true;
}

function bouton_ok(obj) {
//  alert("C'est la fonction bouton_ok est actionnùe");
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
//  alert('Avant resize : \nLargeur = '+largeur+' Hauteur = '+hauteur+' Avail Largeur ='+screen.availWidth+' Avail Hauteur '+screen.availHeight+'\nLargeur ùcran : '+screen.width+' hauteur ùcran : '+screen.height);
  self.resizeTo(600, 420);
//  alert('Aprùs resize : \nLargeur = '+largeur+' Hauteur = '+hauteur+' Avail Largeur ='+screen.availWidth+' Avail Hauteur '+screen.availHeight+'\nLargeur ùcran : '+screen.width+' hauteur ùcran : '+screen.height);
//  alert('Valeur de status '+args.status);
  if((args.status == 'ok') || (args.nb_lig == '0E0')) {
    var racine = opener.document.getElementById('ra_ecran_mensuel');
    var cree_a = opener.document.createElement("a");
    var url = base+'/rapports_activites/ra/show.pl?ident_user='+args.ident_user+'&action=creation&annee='+args.annee+'&mois='+args.mois+'&client_id='+args.client_id+'&ident_id='+args.ident_id;
//    alert('Valeur de url dans modifie() : '+url);
//    cree_a.setAttribute("title", 'Crùer');
    cree_a.setAttribute("target", 'Creation');
    cree_a.setAttribute("href", url);
    var cree_img = opener.document.createElement("img");
    cree_img.setAttribute("alt", 'CrÈer-'+args.client); 
    cree_img.setAttribute("title", 'CrÈer');
    cree_img.setAttribute("src", base+'/images/page_blank.png');
    cree_a.appendChild(cree_img);
//    var text_del = opener.document.createTextNode(' ');
//    var frag = opener.document.createDocumentFragment();
    var enfants = racine.childNodes;
//    alert('Nbre d\'ùlùments de la variable enfants : '+enfants.length+'\nLa valeur de la variable nb_maj = '+nb_maj);
// On ne tient pas compte des 2 premiùres lignes du tableau
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
      alert('La mise en jour de la fenÍtre principale de l\'application n\'a pas pu Ítre entiËrement menÈe ‡ bien.\nIl vous est vivement conseillÈ d\'actualiser la page de votre navigateur pour prendre en compte les modifications survenues suite aux rÈcentes actions que vous venez d\'entreprendre');
    }
  }
}

var frag_enfants = 0;
function traite_ra_ligne3col(obj, lg, args, url, cree_a) {
  //alert('Lacement de la fonction traite_ra_ligne3col avec les arguments : lg = '+lg+' url = '+url);
  var enfants = obj.childNodes;
  for(var i = 0; i < enfants.length; i++) {
    if(enfants[i].nodeName == 'A') {
      if(enfants[i].firstChild.nodeType == Node.TEXT_NODE) {
        if((enfants[i].title == 'Editer') && (enfants[i].target == 'Edition')&& (enfants[i].firstChild.data == args.client)) {
          enfants[i].setAttribute("target", 'Creation');
          enfants[i].setAttribute("title", 'CrÈer');
          enfants[i].setAttribute("href", url);
          ligne_delete = lg;
          nb_maj++;
          //alert('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url modifiù est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+' Son texte est '+enfants[i].firstChild.nodeValue);
          return;
        }
      }
      else {
        var frere, j = 0;
        if(enfants[i].firstChild.nodeName == 'IMG') {
          //alert('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+'\nALT de son enfant : '+enfants[i].firstChild.alt);
          if((enfants[i].firstChild.title == 'Editer') && (enfants[i].target == 'Edition')&& (enfants[i].firstChild.alt == ('Editer-'+args.client))) {
            enfants[i].parentNode.replaceChild(cree_a, enfants[i]);
            //ecrire_dans_console('j = '+j);
            frere = enfants[i].nextSibling;
            // Suppression dans l'ordre de l'espace
            if(frere != undefined && frere.nodeType == Node.TEXT_NODE) {
              //alert('Ce noeud est ù supprimer : indice = '+i+' : Le nodeName est '+frere.nodeName+' et son texte est '+frere.data+'\n La class de son parent est '+enfants[i].parentNode.className);
              enfants[i].parentNode.removeChild(frere);
              //ecrire_dans_console('j = '+j+' remove espace');
              frere = enfants[i].nextSibling;
            }
            // Suppression de noeud Supprimer
            if((frere != undefined && frere.firstChild.title == 'Supprimer') && (frere.target == 'Suppression')&& (frere.firstChild.alt == ('Supprimer-'+args.client))) {
            //alert('Ce noeud est ù supprimer : indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+'\nALT de son enfant : '+enfants[i].firstChild.alt);
              enfants[i].parentNode.removeChild(frere);
              //ecrire_dans_console('j = '+j+' remove Supprimer');
              frere = enfants[i].nextSibling;
              nb_maj++;
            }
            // Suppression de l'espace
            if(frere != undefined && frere.nodeType == Node.TEXT_NODE) {
              //alert('Ce noeud est ù supprimer : indice = '+i+' : Le nodeName est '+frere.nodeName+' et son texte est '+frere.data+'\n La class de son parent est '+enfants[i].parentNode.className);
              enfants[i].parentNode.removeChild(frere);
              //ecrire_dans_console('j = '+j+' remove espace');
              frere = enfants[i].nextSibling;
            }
            // Suppression du noeud Facturer                            
            if((frere != undefined && frere.firstChild.title == 'Facturer') && (frere.target == 'Facturation')&& (frere.firstChild.alt == ('Facturer-'+args.client))) {
              //alert('Ce noeud est ù supprimer : indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+'\nALT de son enfant : '+enfants[i].firstChild.alt);
                enfants[i].parentNode.removeChild(frere);
                //ecrire_dans_console('j = '+j+' remove Facturer');
                //nb_maj++;
            }
          }
          //else {
          //  alert('Les valeurs du test sont : title : '+enfants[i].firstChild.title+', target : '+enfants[i].target+', Alt : '+enfants[i].firstChild.alt+' testù avec la valeur \'Crùer-'+args.maj+'\'');
          //}
        }
      }
    }
    else {
      if(enfants[i].nodeType == Node.TEXT_NODE) {
//        alert('Le noeud courant est du Text contentant le texte suivant : <'+enfants[i].nodeValue+'>\nla classe de son parent est '+enfants[i].parentNode.className+' nbligne = '+ligne_delete+' lg = '+lg);
        if(ligne_delete == lg) {
//          alert('Indice = '+i+' Son parent est : '+enfants[i].parentNode.nodeName+' avec pour Id : '+enfants[i].parentNode.id+' et pour class : '+enfants[i].parentNode.className+' nbligne = '+ligne_delete+' lg = '+lg);
          enfants[i].data = ' '; // en attendant de changer la taille du div
//          alert('Le noeud text a ùtù modifù et a pour valeur actuelle '+enfants[i].data+'\nLes caractùritisques du noeud modifiùes sont :la classe de son parent est '+enfants[i].parentNode.className+' nbligne = '+ligne_delete+' lg = '+lg);
          nb_maj++;
        }
      }
      else {
//        alert('Lancement rùcursif de traite_ra_ligne3col');
        traite_ra_ligne3col(enfants[i], lg, args, url, cree_a);
//        alert('Fin du lancement rùcursif de traite_ra_ligne3col');
      }
    }

  }

}
