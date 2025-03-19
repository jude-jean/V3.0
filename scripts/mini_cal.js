//  Fichier outils.js contenant les fonctions javascript
self.onerror = ma_gestion_erreur;
var jours_cal = new Array();
var calendrier;
var base = '../../test/jude/V3.0';
var motif = /etechnoserv.com/;
//ecrire_dans_console('base = '+base);
//ecrire_dans_console('url = '+location);
if(motif.test(location)) {
//  ecrire_dans_console('Nous sommes sur le site de production');
  base = '..';
}
else {
//  ecrire_dans_console('Nous sommes sur le site de développement');
  base = '/test/jude/V3.0';
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
var type = 0;// La valeur par défaut utilisée dans le menu du rdv
var nom_cible, obj_cible;

function ma_gestion_erreur(msg, url, line) {
  alert(' Une erreur est survenue dans le code Javscript, voici les détails :\n Message d\'erreur : '+msg+'\n Ligne N° : '+line);
  return true;
}
var visible, invisible;
function mini_cal(obj, cible) {
  var ind;
  visible = obj.firstChild.id.slice(4);
  invisible;
  if(visible.search(/debut/) > 0) {
    invisible = visible.replace(/debut/, 'fin');
  }
  else {
    invisible = visible.replace(/fin/, 'debut');
  }
// IL faut checked l'option 
   p_choisie_valeur(document.getElementsByName('pl_menu_fin'), '3');  
//  alert('L\'id de l\'image de l\'ancre A est : '+obj.firstChild.id+'\nL\'id du calendrier visible est '+visible+'\nL\'id du calendrier invisible est '+invisible);
//  alert('display de visible '+document.getElementById(visible).style.display);
  if(arguments.length == 2){
//    alert("La cible est : "+cible);
    nom_cible = cible;
    type = 1; // La valeur générique
  }
  calendrier = document.getElementById(visible);
//  AfficheNomsProprietes(calendrier);
  if(calendrier.style.display == 'block') {
    calendrier.style.display = 'none';
    if(navigator.appName.indexOf('Microsoft') != -1) {
//      alert('Test de la valeur de document.all[calendrier.id]');
      if(document.all['c_'+calendrier.id]) {
        document.all['c_'+calendrier.id].style.display = 'none';
        if(calendrier.id.indexOf('debut') != -1) {
          document.all['rdv_fin'].style.position = 'relative';
        }
      }
//      alert('Fin du test de la valeur de document.all[c_'+calendrier.id+']');
    }
  }
  else {
    calcul_calendrier();
    affiche_calendrier();
    if (navigator.appName.indexOf('Microsoft') != -1) {
      document.all['c_'+calendrier.id].style.display = 'block';
      if(calendrier.id.indexOf('debut') != -1) {
        document.all['rdv_fin'].style.position = 'static';
      }
    }
    calendrier.style.display = 'block';
    document.getElementById(invisible).style.display = 'none';
    if(navigator.appName.indexOf('Microsoft') != -1) {
      if(document.all['c_'+invisible]) {
        document.all['c_'+invisible].style.display = 'none';
        if(invisible.indexOf('debut') != -1) {
          document.all['rdv_fin'].style.position = 'relative';
        }
      }
    }
  }
}

function mois_suivant() {
// A modifier
  var nb_jours_mois_suivant;
  var j_suivant;
  var premier_jour_mois_suivant = new Date(jour_mois.getFullYear(), jour_mois.getMonth(), nb_jours_mois);
  premier_jour_mois_suivant.setTime(premier_jour_mois_suivant.getTime() + 86400*1000);
//  alert('Le premier jour du mois suivant est :'+premier_jour_mois_suivant.toString());
  if(premier_jour_mois_suivant.getMonth() == 11) {
    nb_jours_mois_suivant = 31;
  }
  else {
    nb_jours_mois_suivant = nbre_jours_mois(premier_jour_mois_suivant.getMonth()+1, premier_jour_mois_suivant.getFullYear());
  }
  j_suivant = jour_mois.getDate();
  if(jour_mois.getDate() > nb_jours_mois_suivant) {
     j_suivant = nb_jours_mois_suivant;
  }
  var d = new Date(premier_jour_mois_suivant.getFullYear(), premier_jour_mois_suivant.getMonth(), j_suivant);
/*  if((d.getDate() != nb_jours_mois_suivant) && (d.getMonth() == 9)) {
    d.setTime(d.getTime() + 3600*1000);
  }
*/
//  alert('N° du mois en cours : '+jour_mois.getMonth()+'\nLe jour précédent sélectionné est '+jour_sel+'\nLe 1er jour du mois suivant est '+premier_jour_mois_suivant.toString()+'\nNbre de jours du mois suivant = '+nb_jours_mois_suivant+'\nLa date sélectionnée est '+d.toString());
  jour_sel = d.getDate();
  mois_sel = d.getMonth();
  an_sel = d.getFullYear();
  calcul_calendrier(1);
  affiche_calendrier();
  if(type == 1) {
    modifie_valeur_cible();
  }
}

function mois_precedent() {
// A modifier
  var nb_jours_mois_precedent, j_precedent;
  var dernier_jour_mois_precedent = new Date(jour_mois.getFullYear(), jour_mois.getMonth(), 1);
  dernier_jour_mois_precedent.setTime(dernier_jour_mois_precedent.getTime() - 86400*1000);

  if(dernier_jour_mois_precedent.getMonth() == 0) {
    nb_jours_mois_precedent = 31;
  }
  else {
    nb_jours_mois_precedent = nbre_jours_mois(dernier_jour_mois_precedent.getMonth()+1, dernier_jour_mois_precedent.getFullYear());
  }
  j_precedent = jour_mois.getDate();
  if(jour_mois.getDate() > nb_jours_mois_precedent) {
    j_precedent = nb_jours_mois_precedent;
  }
  var d = new Date(dernier_jour_mois_precedent.getFullYear(), dernier_jour_mois_precedent.getMonth(), j_precedent);
/*  if((d.getDate() != nb_jours_mois_precedent) && (d.getMonth() == 1)) {
    d.setTime(d.getTime() + 3600*1000);
  }
*/
//  alert('N° du mois en cours : '+jour_mois.getMonth()+'\nLe dernier jour du mois precedent est '+dernier_jour_mois_precedent.toString()+'\nNbre de jours du mois present = '+nb_jours_mois+'\nLe jour sélectionné est :'+d.toString());
  jour_sel = d.getDate();
  mois_sel = d.getMonth();
  an_sel = d.getFullYear();
  calcul_calendrier(1);
  affiche_calendrier();
  if(type == 1) {
    modifie_valeur_cible();
  }
}

var jour_sel, mois_sel, an_sel, nb_jours_mois;
function calcul_calendrier() {
  switch(type) {
    case 0 :
      if(arguments.length == 0) {
        if(visible.search(/debut/) > 0) {
          jour_sel = document.forms[0].elements['rdv_debut_num_jour'].value;
          mois_sel = document.forms[0].elements['rdv_debut_mois'].selectedIndex;
          an_sel = document.forms[0].elements['rdv_debut_annee'].value;
        }
        else {
          jour_sel = document.forms[0].elements['rdv_fin_num_jour'].value;
          mois_sel = document.forms[0].elements['rdv_fin_mois'].selectedIndex;
          an_sel = document.forms[0].elements['rdv_fin_annee'].value;
        }
      }
      break;
      
   case 1 :
      if(arguments.length == 0) {
        obj_cible = document.getElementsByName(nom_cible);//C'est un tableau
//        alert('La valeur dans la cible est : '+obj_cible[0].value);
        var tab_jour = obj_cible[0].value.match(/\d+/g);
//        alert('La valeur de tab_jour est '+ tab_jour+'. Sa taille est '+tab_jour.length);
        jour_sel = parseInt(tab_jour[0], 10);
        mois_sel = parseInt(tab_jour[1], 10) -1;
        an_sel = parseInt(tab_jour[2]);
//        alert('jour_sel = '+jour_sel+' mois_sel = '+mois_sel+' an_sel = '+an_sel);
      }
      break;
  }
  jours_cal = [];
  nb_jours_mois = nbre_jours_mois((mois_sel + 1), an_sel);
  var jour = new Date(an_sel, mois_sel, 1, 0, 0);
  var debut_semaine = 0;
// On remonte au 1er lundi du mois précédent
  do {
    if(jours_cal.length > 0) {
      if(jour.getHours() == 1) {// heure d'été
        jour.setTime(jour.getTime() - 3600*1000);
      }
      if(jours_cal[jours_cal.length - 1].getDate() == jour.getDate()) {// heure d'hiver
        jour.setTime(jour.getTime() + 3600*1000);
      }
      jours_cal.unshift(jour);
    }
    else {
      jours_cal.unshift(jour);
    }
    if(jour.getDay() != jours[1][2]) {
//Ce n'est pas un lundi, création d'un nouvel objet Date à stocker
      jour = new Date(jour.getTime() -86400*1000);
    }
    else {
      debut_semaine = 1;
    }
  }
  while(debut_semaine == 0);
// On se positionne sur le 1er jour du mois
  jour = new Date(jours_cal[jours_cal.length - 1].getTime());
// On ajoute tous les jours du mois
  while(jour.getDate() < nb_jours_mois) {
    jour = new Date(jour.getTime() +86400*1000);
    if(jour.getHours() == 1) { // heure d'été
      jour.setTime(jour.getTime() - 3600*1000);
    }
    if(jours_cal[jours_cal.length - 1].getDate() == jour.getDate()) {// heure d'hiver
      jour.setTime(jour.getTime() + 3600*1000);
    }
    jours_cal.push(jour);
  }
// On ajoute les jours du mois suivant jusqu'au 1 er dimanche
  while(jour.getDay() != jours[0][2]) {
    jour = new Date(jour.getTime() +86400*1000);
    if(jour.getHours() == 1) { // heure d'été
      jour.setTime(jour.getTime() - 3600*1000);
    }
    if(jours_cal[jours_cal.length - 1].getDate() == jour.getDate()) {// heure d'hiver
      jour.setTime(jour.getTime() + 3600*1000);
    }
    jours_cal.push(jour);
  }
//  alert('Les données du calendrier sont :\nLe 1er jour : '+jours_cal[0].toLocaleString()+'\nLe dernier jour : '+jours_cal[jours_cal.length - 1].toLocaleString()+' la taille de jours_cal est :'+jours_cal.length+' Le nombre de jours du mois est : '+nb_jours_mois);
}

var debut_mois, fin_mois, jour_mois;
function affiche_calendrier() {
  var lig;
  efface(calendrier);
  lig = document.createElement('div');
  lig.setAttribute('id', 'titre_mini_annee');
  var text = document.createTextNode(an_sel);
  lig.appendChild(text);
  calendrier.appendChild(lig);
  lig = document.createElement('div');
  lig.setAttribute('id', 'titre_mini_mois');
  var div = document.createElement('div');
  div.setAttribute('id', 't11_mini_mois');
  div.onclick = mois_precedent;
//  var lk = document.createElement('a');
  
  var img = document.createElement('img');
  img.setAttribute('src', base+'/images/nav_left_blue.png');
  img.setAttribute('id', 'img_mois_prev');
//  lk.appendChild(img);
  div.appendChild(img);
  lig.appendChild(div);

  div = document.createElement('div');
  div.setAttribute('id', 't12_mini_mois');
//  alert('affiche_calendrier :  valeur de mois_sel = '+mois_sel);
  text = document.createTextNode(mois[mois_sel][0]);
  div.appendChild(text);
  lig.appendChild(div);

  div = document.createElement('div');
  div.setAttribute('id', 't13_mini_mois');
  div.onclick = mois_suivant;
  var img = document.createElement('img');
  img.setAttribute('src', base+'/images/nav_right_blue.png');
  img.setAttribute('id', 'img_mois_next');
  div.appendChild(img);
  lig.appendChild(div);
  calendrier.appendChild(lig);

  div = document.createElement('div');
  div.setAttribute('id', 'titre_lig_semaine');
  var div2 = document.createElement('div');
  div2.setAttribute('className', 'cel_jour');
  div2.setAttribute('class', 'cel_jour');
  text = document.createTextNode('L');
  div2.appendChild(text);
  div.appendChild(div2);
  div2 = document.createElement('div');
  div2.setAttribute('className', 'cel_jour');
  div2.setAttribute('class', 'cel_jour');
  text = document.createTextNode('M');
  div2.appendChild(text);
  div.appendChild(div2);
  div2 = document.createElement('div');
  div2.setAttribute('className', 'cel_jour');
  div2.setAttribute('class', 'cel_jour');
  text = document.createTextNode('M');
  div2.appendChild(text);
  div.appendChild(div2);
  div2 = document.createElement('div');
  div2.setAttribute('className', 'cel_jour');
  div2.setAttribute('class', 'cel_jour');
  text = document.createTextNode('J');
  div2.appendChild(text);
  div.appendChild(div2);
  div2 = document.createElement('div');
  div2.setAttribute('className', 'cel_jour');
  div2.setAttribute('class', 'cel_jour');
  text = document.createTextNode('V');
  div2.appendChild(text);
  div.appendChild(div2);
  div2 = document.createElement('div');
  div2.setAttribute('className', 'cel_jour');
  div2.setAttribute('class', 'cel_jour');
  text = document.createTextNode('S');
  div2.appendChild(text);
  div.appendChild(div2);
  div2 = document.createElement('div');
  div2.setAttribute('className', 'cel_jour');
  div2.setAttribute('class', 'cel_jour');
  text = document.createTextNode('D');
  div2.appendChild(text);
  div.appendChild(div2);
  calendrier.appendChild(div);
  var semaine = document.createElement('div');
  var jour;
  debut_mois = new Date(an_sel, mois_sel, 1, 0, 0);
  fin_mois = new Date(an_sel, mois_sel, nb_jours_mois, 23, 59, 59);
  jour_mois = new Date(an_sel, mois_sel, jour_sel, 0, 0);
  var aujourdhui = new Date();
  aujourdhui = new Date(aujourdhui.getFullYear(), aujourdhui.getMonth(), aujourdhui.getDate());
  semaine.setAttribute('className', 'lig_semaine');
  semaine.setAttribute('class', 'lig_semaine');
  for(var i = 0; i < jours_cal.length; i++) {
    if((i%7 == 0) && (i >0)) {
      calendrier.appendChild(semaine);
      semaine = document.createElement('div');
      semaine.setAttribute('className', 'lig_semaine');
      semaine.setAttribute('class', 'lig_semaine');
    }
    jour = document.createElement('div');
    jour.onclick = jour_selectionne;
    if((jours_cal[i].getTime() < debut_mois.getTime()) || (jours_cal[i].getTime() > fin_mois.getTime())) {
      jour.setAttribute('className', 'cel_jour_inactif');
      jour.setAttribute('class', 'cel_jour_inactif');
    }
    else if(jours_cal[i].getTime() == jour_mois.getTime()) {
      jour.setAttribute('id', 'cel_jour_actif');
    }
    else if(jours_cal[i].getTime() == aujourdhui.getTime()) {
      jour.setAttribute('id', 'cel_aujourdhui');
    }
    else {
      jour.setAttribute('className', 'cel_jour');
      jour.setAttribute('class', 'cel_jour');
    }
    text = document.createTextNode(jours_cal[i].getDate());
    jour.appendChild(text);
    semaine.appendChild(jour);
  }
  calendrier.appendChild(semaine);
  if(navigator.appName.indexOf('Microsoft') != -1) {
    if(!document.all['c_'+calendrier.id]) {
//      alert('Creation d\'un objet iframe');
      var calque = document.createElement('iframe');
//      alert('L\'objet iframe '+calque+' est créé');
      calque.frameBorder = 0;
      calque.style.position = 'absolute';
      calque.style.top = '23px';
      calque.style.left = '149px';
      calque.style.width = '134px';
      calque.style.height = '175px';
      calque.style.zIndex = '100';
      calque.style.display = 'none';
//      calque.style.visibility = 'visible';
      calque.setAttribute('id', 'c_'+calendrier.id);
      calendrier.parentNode.insertBefore(calque, calendrier);
//      alert('Insertion de l\'objet iframe');
    }
  }
}

function jour_selectionne() {
//  alert('La valeur de className est : '+this.className+' La valeur de Id est : '+this.id );
  if(this.className.length != 0) {
    for(var i = 0; i < jours_cal.length; i++) {
      if(jours_cal[i].getDate() == this.firstChild.nodeValue) {
        if((this.className == 'cel_jour_inactif') && ((jours_cal[i].getTime() < debut_mois.getTime()) || (jours_cal[i].getTime() > fin_mois.getTime()))) {
//          alert('Le jour sélectionné en dehors du mois est '+jours_cal[i].toLocaleString());
          if(type == 0) {
            gere_la_selection(i);
          }
          else { // type = 1
            modifie_valeur_cible(i);
            calendrier.style.display = 'none';
            if(navigator.appName.indexOf('Microsoft') != -1) {
              document.all['c_'+calendrier.id].style.display = 'none';
              if(calendrier.id.indexOf('debut') != -1) {
                document.all['rdv_fin'].style.position = 'relative';
              }
            }
          }
          return;
        }
        if((this.className == 'cel_jour') && (jours_cal[i].getTime() >= debut_mois.getTime()) && (jours_cal[i].getTime() <= fin_mois.getTime())) {
//          alert('Le jour sélectionné dans le mois est '+jours_cal[i].toLocaleString());
          if(type == 0) {
            gere_la_selection(i);
          }
          else { // type = 1
            modifie_valeur_cible(i);
            calendrier.style.display = 'none';
            if(navigator.appName.indexOf('Microsoft') != -1) {
              document.all['c_'+calendrier.id].style.display = 'none';
              if(calendrier.id.indexOf('debut') != -1) {
                document.all['rdv_fin'].style.position = 'relative';
              }
            }
          }
          return;
        }
      }
    }
  }
  else {
    for(var i = 0; i < jours_cal.length; i++) {
      if((jours_cal[i].getDate() == this.firstChild.nodeValue) && (jours_cal[i].getTime() >= debut_mois.getTime()) && (jours_cal[i].getTime() <= fin_mois.getTime())) {
//        alert('Valeur de i : '+i+' Long de Id : '+this.id.length+' Id = '+this.id);
          if(type == 0) {
            gere_la_selection(i);
          }
          else { // type = 1
            modifie_valeur_cible(i);
            calendrier.style.display = 'none';
            if(navigator.appName.indexOf('Microsoft') != -1) {
              document.all['c_'+calendrier.id].style.display = 'none';
              if(calendrier.id.indexOf('debut') != -1) {
                document.all['rdv_fin'].style.position = 'relative';
              }
            }
          }
          return;
      }
//        alert('Le jour sélectionné est '+jours_cal[i].toLocaleString()+' et pourID : '+this.id)
    }
  }
  return;
}

function efface(obj) {
  var enfants = obj.childNodes;
  for(var i = enfants.length - 1; i >= 0; i--) {
    obj.removeChild(enfants[i]);
  }
}

function modifie_valeur_cible(i) {
  var str_jour, str_mois;
//Vérifie si la propriete onfocus est définie par le programme en Perl pour obj
  if(obj_cible[0].hasOwnProperty('onfocus') == true) {
    obj_cible[0].onfocus();
  }
  if(arguments.length == 0) {
    str_jour = (jour_sel < 10) ? '0'+jour_sel : jour_sel;
    str_mois = (mois_sel + 1 < 10) ? '0'+(mois_sel+1) : (1+mois_sel);
    obj_cible[0].value = str_jour+'/'+str_mois+'/'+an_sel;
  }
  else {
    jour_sel = jours_cal[i].getDate();
    mois_sel = jours_cal[i].getMonth();
    an_sel = jours_cal[i].getFullYear();
    str_jour = (jours_cal[i].getDate() < 10) ? '0'+jours_cal[i].getDate() : jours_cal[i].getDate();
    str_mois = (jours_cal[i].getMonth() + 1 < 10) ? '0'+(jours_cal[i].getMonth()+1) : (1+jours_cal[i].getMonth());
    obj_cible[0].value = str_jour+'/'+str_mois+'/'+jours_cal[i].getFullYear();
  }

}

function gere_la_selection(i) {
  var d_debut, d_fin;
  if(calendrier.id.search(/debut/) >0) {
// Le calendrier visible concerne la date de début
    var h_debut = document.forms[0].elements['rdv_heure_debut'].value.split(':');
    d_debut = new Date(jours_cal[i].getTime() + (1000*3600*parseInt(h_debut[0], 10)) +  (1000*60*parseInt(h_debut[1], 10)));
    d_fin = calcul_date_fin_select(d_debut, 1);
    var diff = d_fin - d_debut;
//    alert('Les données en entrée de gere_la_selection() sont le nom du calendrier : '+calendrier.id+' et le jour selectionné : '+d_debut.toLocaleString()+'\ndiff = '+diff);
// Affiche le mois de d_fin
    document.forms[0].elements['rdv_fin_mois'].selectedIndex = d_fin.getMonth();
// Affiche le jour de la semaine correspondant à d_fin
    document.forms[0].elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
    document.forms[0].elements['rdv_fin_num_jour'].selectedIndex = d_fin.getDate() -1;
// date de début du rendez-vous
    document.forms[0].elements['rdv_debut_jour'].value = jours[d_debut.getDay()][1];
    document.forms[0].elements['rdv_debut_num_jour'].selectedIndex = d_debut.getDate() -1;
    document.forms[0].elements['rdv_debut_mois'].selectedIndex = d_debut.getMonth();
// Gestion de l'année de debut et de fin du rendez-vous
    if((d_debut.getFullYear() >= document.forms[0].elements['rdv_debut_annee'].options[0].value) && (d_debut.getFullYear() <= document.forms[0].elements['rdv_debut_annee'].options[document.forms[0].elements['rdv_debut_annee'].options.length -1].value) && (d_fin.getFullYear() >= document.forms[0].elements['rdv_fin_annee'].options[0].value) && (d_fin.getFullYear() <= document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length -1].value)) {
      for(var j = 0; j < document.forms[0].elements['rdv_fin_annee'].options.length; j++) {
//      alert('options[i].text = '+document.forms[0].elements['rdv_fin_annee'].options[i].text+'\ngetFullYear = '+d_fin.getFullYear()+'\ni = '+i);
        if(document.forms[0].elements['rdv_debut_annee'].options[j].value == d_debut.getFullYear()) {
          document.forms[0].elements['rdv_debut_annee'].selectedIndex = j;
        }
        if(document.forms[0].elements['rdv_fin_annee'].options[j].value == d_fin.getFullYear()) {
          document.forms[0].elements['rdv_fin_annee'].selectedIndex = j;
          break;
        }
      }
    }
    else {// La date de début est inférieure à la date la plus petite dans le select
      if((diff = document.forms[0].elements['rdv_debut_annee'].options[0].value - d_debut.getFullYear()) > 0) {
//        alert('L\'année de début : '+d_debut.getFullYear()+'n\'est pas incluse dans le tableau options. Le nombre d\'années à inclure est : '+diff);
        var nb_annee = document.forms[0].elements['rdv_debut_annee'].options.length + diff;
        document.forms[0].elements['rdv_debut_annee'].options.length = 0;
        document.forms[0].elements['rdv_fin_annee'].options.length = 0;
        for(j = 0; j < nb_annee; j++) {
          var opt1 = new Option(d_debut.getFullYear() + j, d_debut.getFullYear() + j);
          var opt2 = new Option(d_debut.getFullYear() + j, d_debut.getFullYear() + j);
          document.forms[0].elements['rdv_debut_annee'].options [j] = opt1;
          document.forms[0].elements['rdv_fin_annee'].options[j] = opt2;
//          alert('La taille du tableau d\'options est pour date de fin : '+document.forms[0].elements['rdv_fin_annee'].options.length+' pour date de début : '+document.forms[0].elements['rdv_debut_annee'].options.length);
        }
        document.forms[0].elements['rdv_debut_annee'].selectedIndex = 0;
        document.forms[0].elements['rdv_fin_annee'].selectedIndex = an_courant[1] - an_courant[0];
      }
      else {// La date de fin est plus grande que la plus grande date dans le select
        diff = d_fin.getFullYear() - document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length- 1].value;
//        alert('L\'année de fin : '+d_fin.getFullYear()+'n\'est pas incluse dans le tableau options. Le nombre d\'années à ajouter est : '+diff);
        for(j = 0; j < diff; j++) {
          var opt1 = new Option();
          opt1.text = parseInt(document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length - 1].value, 10) + 1;
          opt1.value = opt1.text;
          var opt2 = new Option();
          opt2.text = parseInt(document.forms[0].elements['rdv_debut_annee'].options[document.forms[0].elements['rdv_debut_annee'].options.length - 1].value, 10) + 1;
          opt2.value = opt2.text;
//          alert('Valeur de opt1.text : '+opt1.text+' valeur de opt2.text : '+opt2.text);
          document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length] = opt1;
          document.forms[0].elements['rdv_debut_annee'].options[document.forms[0].elements['rdv_debut_annee'].options.length] = opt2;
//          alert('La taille du tableau d\'options est pour date de fin : '+document.forms[0].elements['rdv_fin_annee'].options.length+' pour date de début : '+document.forms[0].elements['rdv_debut_annee'].options.length);
        }

        document.forms[0].elements['rdv_fin_annee'].selectedIndex = document.forms[0].elements['rdv_fin_annee'].options.length - 1;
        document.forms[0].elements['rdv_debut_annee'].selectedIndex = document.forms[0].elements['rdv_fin_annee'].selectedIndex - (an_courant[1] - an_courant[0]);
      }
    }
//    alert('Appel de gestion_affiche_heures_fin() avec les dates suivantes '+d_debut.toLocaleString()+' '+d_fin.toLocaleString()+' avec l\'écart à conserver');
    gestion_affiche_heures_fin(d_debut, d_fin, 1);
    valide_heure_rdv(d_debut);
  }
  else {
// le calendrier visible concerne la date de fin
    var h_debut = document.forms[0].elements['rdv_heure_debut'].value.split(':');
    d_debut = new Date(document.forms[0].elements['rdv_debut_annee'].value, document.forms[0].elements['rdv_debut_mois'].selectedIndex, document.forms[0].elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
// calcul de la date de fin
    if(document.forms[0].elements['rdv_heure_fin'].value.indexOf('(') > 0) {
      var h_fin = document.forms[0].elements['rdv_heure_fin'].value.split(':');
      var mn_fin = h_fin[1].split('(');
      d_fin = new Date(jours_cal[i].getTime() + (1000*3600*parseInt(h_fin[0], 10)) + (1000*60*parseInt(mn_fin[0], 10)));
    }
    else {
      var h_fin = document.forms[0].elements['rdv_heure_fin'].value.split(':');
//      alert('La valeur a spliter est : '+document.forms[0].elements['rdv_heure_fin'].value+' Les éléments splités sont : '+h_fin[0]+' '+h_fin[1]);
      d_fin = new Date(jours_cal[i].getTime() +(1000*3600*parseInt(h_fin[0], 10)) +(1000*60*parseInt(h_fin[1], 10)));
    }
//    alert('La date de fin est : '+d_fin.toLocaleString()+' avec un écart non conservé');
    var diff = d_fin - d_debut;
//    alert('Les données en entrée de gere_la_selection() sont le nom du calendrier : '+calendrier.id+' et le jour selectionné : '+d_fin.toLocaleString()+'\ndiff = '+diff);
    if(diff < 0) {
      alert('La date de fin est inférieure à la date de début du rendez-vous.\nCette opération est impossible.');
      return;
    }
    else {
      document.forms[0].elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
      document.forms[0].elements['rdv_fin_num_jour'].selectedIndex = d_fin.getDate() -1;
      document.forms[0].elements['rdv_fin_mois'].selectedIndex = d_fin.getMonth();
      if((d_fin.getFullYear() >= document.forms[0].elements['rdv_fin_annee'].options[0].value) && (d_fin.getFullYear() <= document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length -1].value)) {
        for(var j = 0; j < document.forms[0].elements['rdv_fin_annee'].options.length; j++) {
//      alert('options[i].text = '+document.forms[0].elements['rdv_fin_annee'].options[i].text+'\ngetFullYear = '+d_fin.getFullYear()+'\ni = '+i);
          if(document.forms[0].elements['rdv_fin_annee'].options[j].value == d_fin.getFullYear()) {
            document.forms[0].elements['rdv_fin_annee'].selectedIndex = j;
            break;
          }
        }
      }
      else {
        diff = d_fin.getFullYear() - document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length- 1].value;
//        alert('L\'année de fin : '+d_fin.getFullYear()+'n\'est pas incluse dans le tableau options. Le nombre d\'années à ajouter est : '+diff);
        for(j = 0; j < diff; j++) {
          var opt1 = new Option();
          opt1.text = parseInt(document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length - 1].value, 10) + 1;
          opt1.value = opt1.text1;
          var opt2 = new Option();
          opt2.text = parseInt(document.forms[0].elements['rdv_debut_annee'].options[document.forms[0].elements['rdv_debut_annee'].options.length - 1].value, 10) + 1;
          opt2.value = opt2.text;
//          alert('Valeur de opt1.text : '+opt1.text+' valeur de opt2.text : '+opt2.text);
          document.forms[0].elements['rdv_fin_annee'].options[document.forms[0].elements['rdv_fin_annee'].options.length] = opt1;
          document.forms[0].elements['rdv_debut_annee'].options[document.forms[0].elements['rdv_debut_annee'].options.length] = opt2;
          alert('La taille du tableau d\'options est pour date de fin : '+document.forms[0].elements['rdv_fin_annee'].options.length+' pour date de début : '+document.forms[0].elements['rdv_debut_annee'].options.length);
        }
        document.forms[0].elements['rdv_debut_annee'].selectedIndex = an_courant[0];
        document.forms[0].elements['rdv_fin_annee'].selectedIndex = document.forms[0].elements['rdv_fin_annee'].options.length - 1;
      }
//      alert('Appel de gestion_affiche_heures_fin() avec les dates suivantes '+d_debut.toLocaleString()+' '+d_fin.toLocaleString()+' sans l\'écart à conserver');
      gestion_affiche_heures_fin(d_debut, d_fin, 0);
    }
  }
  sauve_date_heure(d_debut, d_fin);
  calendrier.style.display = 'none';
  if(navigator.appName.indexOf('Microsoft') != -1) {
//    if(document.all['c_'+calendrier.id]) {
      document.all['c_'+calendrier.id].style.display = 'none';
      if(calendrier.id.indexOf('debut') != -1) {
        document.all['rdv_fin'].style.position = 'relative';
      }
//    }
  }
  return false;
}



