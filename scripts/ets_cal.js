//  Fichier ets_cal.js contenant les fonctions javascript
self.onerror = ma_gestion_erreur;
var args;
var jours = [['Dimanche', 'Dim', 0], ['Lundi', 'Lun', 1], ['Mardi', 'Mar', 2], ['Mercredi', 'Mer', 3], ['Jeudi', 'Jeu', 4], ['Vendredi', 'Ven', 5], ['Samedi', 'Sam', 6]];
var mois = [['Janvier', 'Janv', 0], ['Février', 'Fév', 1] ,['Mars', 'Mars', 2], ['Avril', 'Avr', 3], ['Mai', 'Mai', 4], ['Juin', 'Juin', 5], ['Juillet', 'Juil', 6], ['Août', 'Aôut', 7], ['Septembre', 'Sep', 8], ['Octobre', 'Oct', 9], ['Novembre', 'Nov', 10], ['Décembre', 'Déc', 11]];
var an_courant, mois_courant, jour_courant, heure_courant, mn_courant, l_jour_courant;
var debut_courant = new Date();
var fin_courant = new Date();
var iframe_debut, iframe_fin;
var pas;
var aujourdhui;
var sp;

if(location.hostname.match(/www.etechnoserv/)) {
	var base = '/jude/V3.0';
}
else {
	var base = '/test/jude/V3.0';
}
  
function ma_gestion_erreur(msg, url, line) {
  alert(' Une erreur est survenue dans le code Javscript, voici les détails :\n Le code concerné est : '+url+'\n Message d\'erreur : '+msg+'\n Ligne N° : '+line);
  return true;
}

function se_reconnecter() {
	location.href = base+'/etechnoserv.pl?err=3';
}

function ecran_charge() {
//  if(navigator.appName.indexOf('Microsoft') != -1) png_fix_ie();
//  alert("La fonction ecran_charge a été appelée");
//  alert('Debut de ecran_charge() : Heure de debut = '+document.forms[0].elements['rdv_heure_debut'].value+' heure de fin = '+document.forms[0].elements['rdv_heure_fin'].value);
  an_courant = new Array();
  mois_courant = new Array();
  jour_courant = new Array();
  l_jour_courant = new Array();
  heure_courant = new Array();
  mn_courant = new Array();
  args = recup_args();
  calcul_pas_horaire();
/** Calcul et stockage de la date de début et de fin *****************/
  var h_debut = document.forms[0].elements['rdv_heure_debut'].value.split(':');
  debut_courant = new Date(document.forms[0].elements['rdv_debut_annee'].value, document.forms[0].elements['rdv_debut_mois'].selectedIndex, document.forms[0].elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
//  var h_fin = document.forms[0].elements['rdv_heure_fin'].value.split(':');
//  var mn_fin = h_fin[1].split('(');
  if(document.forms[0].elements['rdv_heure_fin'].value.indexOf('(') > 0) {
    var h_fin = document.forms[0].elements['rdv_heure_fin'].value.split(':');
    var h_delta = h_fin[1].split('h');
    var mn_fin = h_fin[1].split('(');
    fin_courant = new Date(document.forms[0].elements['rdv_fin_annee'].value, document.forms[0].elements['rdv_fin_mois'].selectedIndex, document.forms[0].elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(mn_fin[0], 10));
  }
  else {
    var h_fin = document.forms[0].elements['rdv_heure_fin'].value.split(':');
    fin_courant = new Date(document.forms[0].elements['rdv_fin_annee'].value, document.forms[0].elements['rdv_fin_mois'].selectedIndex, document.forms[0].elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(h_fin[1], 10));
  }
//  alert('Fin de ecran_charge() : Heure de debut = '+debut_courant.toString()+' heure de fin = '+fin_courant.toString());
//  fin_courant = new Date(document.forms[0].elements['rdv_fin_annee'].value, document.forms[0].elements['rdv_fin_mois'].selectedIndex, document.forms[0].elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(h_fin[1], 10));

//  fin_courant.setTime(debut_courant.getTime() + pas);
  sauve_date_heure(debut_courant, fin_courant);
  sp = document.getElementById('rdv_msg');
  valide_heure_rdv();
  window.focus();
//  Vérifie si l'utilisateur souhaite le rendez-vous unique ou alors la série
   var flag_periodicite;
   var user_choix;
  if(document.forms[0].elements['id_ref'] !== undefined) {
    flag_periodicite =document.forms[0].elements['id_ref'].value;
    user_choix = document.forms[0].elements['user_c'].value;  
    ecrire_dans_console("La valeur de flag_periodicité est :"+flag_periodicite+"\nLa valeur de user_choix est :"+user_choix);    
  }
  var rdv_objet =document.forms[0].elements['rdv_objet'].value;
  if (flag_periodicite != null) {
    switch(user_choix) {
	    case '-1' :
			var msg = "\""+rdv_objet+"\" est un rendez-vous périodique.\n\nSi vous souhaitez ouvrir la série de rendez-vous, cliquez sur OK\n\nSi vous souhaitez n'ouvrir que le rendez-vous, cliquez sur Annuler";
			if(confirm(msg)) {
				document.forms[0].elements['user_c'].value = 1;
// Si on ouvre la série, on fait disparaitre les champs spécifiques à un seul rendez-vous
				document.getElementById('rdv_debut').style.display = 'none';
				document.getElementById('rdv_fin').style.display = 'none';
			}
			else {
				document.forms[0].elements['user_c'].value = 0;
			}
			break;
		
		case '1' :
			document.forms[0].elements['user_c'].value = 1;
// Si on ouvre la série, on fait disparaitre les champs spécifiques à un seul rendez-vous
			document.getElementById('rdv_debut').style.display = 'none';
			document.getElementById('rdv_fin').style.display = 'none';
			break;
	}	
  }
  return false;
}

function recharge_calendrier(flag) {
  var titre = opener.document.getElementsByTagName('H1');
//  alert("La fenetre root contient "+titre.length+" titres H1");
//  alert("Le titre de la fenetre root est : "+titre[0].firstChild.data);
  if(titre[0].firstChild.data.indexOf('Calendrier') != -1) {
//    alert('On recharge la feuille root');
    opener.recharge_des_rdv();
  }
  if(flag == 0) {
    close();
  }
}

function delete_rdv() {
  var msg;
  obj_rdv = document.forms[0].elements['rdv_objet'].value;
  msg = "Vous demander la suppression du rendez-vous ayant pour objet : \n\""+obj_rdv+"\"\n\nConfirmez-vous votre demande ?";
  if(confirm(msg)) {
    return true;
  }
  else {
    return false;
  }
}

function annuler() {
  var msg = "Vous êtes sur le point d'abandonner la saisie du rendez-vous en cours.\n\nConfirmez-vous que vous souhaitez abandonner la saisie en cours?";
  if(confirm(msg)) {
    close();
  }
  else {  
    return false;
  }
}

function valide_heure_rdv(d_debut) {
  aujourdhui = new Date();
  if(arguments.length == 0) {
    var h_debut = document.forms[0].elements['rdv_heure_debut'].value.split(':');
    d_debut = new Date(document.forms[0].elements['rdv_debut_annee'].value, document.forms[0].elements['rdv_debut_mois'].selectedIndex, document.forms[0].elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  }
//  AfficheNomsProprietes(sp);
  if(aujourdhui.getTime() > d_debut.getTime()) {
//    alert('Ce rendez-vous a lieu a une date révolue. Le type du noeud est : '+sp.nodeType);
    if(sp.firstChild.data.length <= 1) {
      sp.firstChild.data  = 'Ce rendez-vous a lieu a une date révolue.';
    }
    else {
      if(sp.firstChild.data.indexOf('Ce rendez-vous a lieu a une date révolue.') == -1) {
        sp.firstChild.appendData('\nCe rendez-vous a lieu a une date révolue.');
      }

    }

    sp.style.backgroundColor = '#FFFFB3';
	sp.style.display = 'block';
  }
  else {
//    alert('La date de ce rdv est valide.');
	sp.style.display = 'none';
    sp.firstChild.data  = '';
//    sp.style.backgroundColor = 'transparent';
  }
  return false;
}

function calcul_pas_horaire() {
//  if(d
  if(args.affichage_heure == 5) pas = 60*60*1000;
  else if(args.affichage_heure == 4) pas = 30*60*1000;
  else if(args.affichage_heure == 3) pas = 15*60*1000;
  else if(args.affichage_heure == 2) pas = 10*60*1000;
}

function sauve_date_heure(d_debut, d_fin) {
  an_courant[0] = document.forms[0].elements['rdv_debut_annee'].selectedIndex;
  an_courant[1] = document.forms[0].elements['rdv_fin_annee'].selectedIndex;
  mois_courant[0] = document.forms[0].elements['rdv_debut_mois'].selectedIndex;
  mois_courant[1] = document.forms[0].elements['rdv_fin_mois'].selectedIndex;
  jour_courant[0] = document.forms[0].elements['rdv_debut_num_jour'].selectedIndex;
  jour_courant[1] = document.forms[0].elements['rdv_fin_num_jour'].selectedIndex;
  l_jour_courant[0] = document.forms[0].elements['rdv_debut_jour'].value;
  l_jour_courant[1] = document.forms[0].elements['rdv_fin_jour'].value;
  heure_courant[0] = document.forms[0].elements['rdv_heure_debut'].selectedIndex;
  heure_courant[1] = document.forms[0].elements['rdv_heure_fin'].selectedIndex;
  debut_courant = d_debut;
  fin_courant = d_fin;
}

function png_fix_ie() {
  var arVersion = navigator.appVersion.split("MSIE")
  var version = parseFloat(arVersion[1])
  if((version >= 5.5) && (document.body.filters)) {
    for(var i=0; i<document.images.length; i++) {
      alert('png_fix_ie() : nbre de fois utilisé = '+i+' Nbre d\'images dans le fichier ='+document.images.length);
      var img = document.images[i];
      var imgName = img.src.toUpperCase();
      alert('png_fix_ie() : nom de l\'image : '+imgName);
      if(imgName.substring(imgName.length-3, imgName.length) == "PNG") {
        var imgID = (img.id) ? "id='" + img.id + "' " : "";
        var imgClass = (img.className) ? "class='" + img.className + "' " : "";
        var imgTitle = (img.title) ? "title='" + img.title + "' " : "title='" + img.alt + "' ";
        var imgStyle = "display:inline-block;" + img.style.cssText;
        if(img.align == "left") imgStyle = "float:left;" + imgStyle;
        if(img.align == "right") imgStyle = "float:right;" + imgStyle;
        if(img.parentElement.href) imgStyle = "cursor:hand;" + imgStyle;
         var strNewHTML = "<span " + imgID + imgClass + imgTitle
         + "; style=\"" + "width:" + img.width + "px; height:" + img.height + "px;" + imgStyle + ";"
         + "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader"
         + "(src=\'" + img.src + "\', sizingMethod='scale');\"></span>";
         img.outerHTML = strNewHTML;
         i = i-1;
      }
    }
  }
}


function ferme_hsupplus() {
  var racine = opener.document.forms[0].elements[opener.data_save[0].name];
  racine.options[0].selected = true;
  opener.vide_data_save();
  close();
  return false;
}

function emplt_choisi(obj) {
//  AfficheNomsProprietes(obj);
  obj.form.elements['rdv_emplt'].value = obj.value;
  return false;
}

function rappel_choisi(obj) {
//  alert('Valeur de rappel : '+obj.checked+' Etat de disable '+obj.form.elements['rdv_rappel'].disabled);
  if(obj.checked == true) {
    obj.form.elements['rdv_rappel'].disabled = false;
  }
  else {
    obj.form.elements['rdv_rappel'].disabled = true;
  }
}

function debut_num_jour_choisi(obj) {
  var diff_opt, nb_opt, str_opt;
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
  var mn_fin = h_fin[1].split('(');
  if(est_date_valide(obj.value, obj.form.elements['rdv_debut_mois'].selectedIndex + 1,obj.form.elements['rdv_debut_annee'].value) == 0) {
    alert('La date sélectionnée n\'existe pas dans le calendrier. Veuillez faire un autre choix!');
    obj.selectedIndex = jour_courant[0];
    return false;
  }
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, obj.form.elements['rdv_debut_mois'].selectedIndex, obj.value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));

  var d_fin = calcul_date_fin_select(d_debut, 1);
  var diff = d_fin - d_debut;
//  alert('Valeur de d_debut = '+d_debut.toLocaleString()+' Valeur de d_fin = '+d_fin.toLocaleString()+' diff = '+diff);
// Affiche le mois de d_fin
    obj.form.elements['rdv_fin_mois'].selectedIndex = d_fin.getMonth();
// Affiche le jour de la semaine correspondant à d_fin
    obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
    obj.form.elements['rdv_fin_num_jour'].selectedIndex = d_fin.getDate() -1;
// Gestion de l'année de fin du rendez-vous
    if(d_fin.getFullYear() <= obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_debut_annee'].options.length -1].value) {
        for(var j = 0; j < obj.form.elements['rdv_fin_annee'].options.length; j++) {
//      alert('options[i].text = '+obj.form.elements['rdv_fin_annee'].options[i].text+'\ngetFullYear = '+d_fin.getFullYear()+'\ni = '+i);
          if(obj.form.elements['rdv_fin_annee'].options[j].value == d_fin.getFullYear()) {
            obj.form.elements['rdv_fin_annee'].selectedIndex = j;
            break;
          }
        }
      }
      else {
        diff = d_fin.getFullYear() - obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length- 1].value;
//        alert('L\'année de fin : '+d_fin.getFullYear()+'n\'est pas incluse dans le tableau options. Le nombre d\'années à ajouter est : '+diff);
        var opt1 = new Option();
        opt1.text = parseInt(obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length - 1].value, 10) + 1;
        opt1.value = opt1.text;
        var opt2 = new Option();
        opt2.text = parseInt(obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length - 1].value, 10) + 1;
        opt2.value = opt2.text;
//        alert('Valeur de opt1.text : '+opt1.text+' valeur de opt2.text : '+opt2.text);
        obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length] = opt1;
        obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length] = opt2;
//        alert('La taille du tableau d\'options est pour date de fin : '+obj.form.elements['rdv_fin_annee'].options.length+' pour date de début : '+obj.form.elements['rdv_debut_annee'].options.length);
        obj.form.elements['rdv_fin_annee'].selectedIndex = obj.form.elements['rdv_fin_annee'].length -1;
      }
//  }
  obj.form.elements['rdv_debut_jour'].value = jours[d_debut.getDay()][1];
  gestion_affiche_heures_fin(d_debut, d_fin, 1);
  sauve_date_heure(d_debut, d_fin);
  valide_heure_rdv(d_debut);
  return false;
}

function fin_num_jour_choisi(obj) {
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
  var mn_fin = h_fin[1].split('(');
  if(est_date_valide(obj.value, obj.form.elements['rdv_fin_mois'].selectedIndex + 1,obj.form.elements['rdv_fin_annee'].value) == 0) {
    alert('La date sélectionnée n\'existe pas dans le calendrier. Veuillez faire un autre choix!');
    obj.selectedIndex = jour_courant[1];
    return false;
  }
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, obj.form.elements['rdv_debut_mois'].selectedIndex, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var d_fin = calcul_date_fin_select(d_debut, 0);
  var diff = d_fin - d_debut;
  if(diff < 0) {
    alert('La date de fin est inférieure à la date de début du rendez-vous.\nCette opération est impossible.');
    obj.selectedIndex = jour_courant[1];
//    obj.form.elements['rdv_fin_jour'].value = l_jour_courant[1];
    return false;
  }
  else {
    obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
//   alert('Valeur de d_debut'+d_debut.toLocaleString()+'\nValeur de d_fin'+d_fin.toLocaleString());
  }
  gestion_affiche_heures_fin(d_debut, d_fin, 0);
  sauve_date_heure(d_debut, d_fin);
 return false;
}

function debut_mois_choisi(obj) {
  if(est_date_valide(obj.form.elements['rdv_debut_num_jour'].value, obj.selectedIndex + 1,obj.form.elements['rdv_debut_annee'].value) == 0) {
    alert('La date sélectionnée n\'existe pas dans le calendrier. Veuillez faire un autre choix!');
    obj.selectedIndex = mois_courant[0];
    return false;
  }
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
  var mn_fin = h_fin[1].split('(');
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, obj.selectedIndex, obj.form.elements['rdv_debut_num_jour'].selectedIndex + 1, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var d_fin = calcul_date_fin_select(d_debut, 1);
  var diff = d_fin - d_debut;
//  alert('Voici la valeur de date de début '+d_debut.toLocaleString()+' la nouvelle date de fin '+d_fin.toLocaleString()+' Valeur du pas = '+pas);
// Affiche le mois de d_fin
    obj.form.elements['rdv_fin_mois'].selectedIndex = d_fin.getMonth();
// Affiche le jour de la semaine correspondant à d_fin
    obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
    obj.form.elements['rdv_fin_num_jour'].selectedIndex = d_fin.getDate() -1;
// Affiche l'année correspondante
    if(d_fin.getFullYear() <= obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_debut_annee'].options.length -1].value) {
      for(var j = 0; j < obj.form.elements['rdv_fin_annee'].options.length; j++) {
//      alert('options[i].text = '+obj.form.elements['rdv_fin_annee'].options[i].text+'\ngetFullYear = '+d_fin.getFullYear()+'\ni = '+i);
        if(obj.form.elements['rdv_fin_annee'].options[j].value == d_fin.getFullYear()) {
          obj.form.elements['rdv_fin_annee'].selectedIndex = j;
          break;
        }
      }
    }
    else {
      diff = d_fin.getFullYear() - obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length- 1].value;
//      alert('L\'année de fin : '+d_fin.getFullYear()+'n\'est pas incluse dans le tableau options. Le nombre d\'années à ajouter est : '+diff);
      var opt1 = new Option();
      opt1.text = parseInt(obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length - 1].value, 10) + 1;
      opt1.value = opt1.text;
      var opt2 = new Option();
      opt2.text = parseInt(obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length - 1].value, 10) + 1;
      opt2.value = opt2.text;
      obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length] = opt1;
      obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length] = opt2;
      obj.form.elements['rdv_fin_annee'].selectedIndex = obj.form.elements['rdv_fin_annee'].length -1;
    }
// On s'occupe de la partie de date et heure du début
// Affiche le jour de la semaine correspondant à d_fin
  obj.form.elements['rdv_debut_jour'].value = jours[d_debut.getDay()][1];
  obj.form.elements['rdv_debut_num_jour'].selectedIndex = d_debut.getDate() -1;
  gestion_affiche_heures_fin(d_debut, d_fin, 1);
  sauve_date_heure(d_debut, d_fin);
  valide_heure_rdv(d_debut);
}

function fin_mois_choisi(obj) {
  var a_debut, a_fin, j_debut, j_fin;
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
  var mn_fin = h_fin[1].split('(');
  if(est_date_valide(obj.form.elements['rdv_fin_num_jour'].value, obj.form.elements['rdv_fin_mois'].selectedIndex + 1,obj.form.elements['rdv_fin_annee'].value) == 0) {
    alert('La date sélectionnée n\'existe pas dans le calendrier. Veuillez faire un autre choix!');
    obj.selectedIndex = mois_courant[1];
    return false;
  }
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, obj.form.elements['rdv_debut_mois'].selectedIndex, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var d_fin = calcul_date_fin_select(d_debut, 0);
  var diff = d_fin - d_debut;
  if(diff < 0) {
    alert('La date de fin est inférieure à la date de début du rendez-vous.\nCette opération est impossible.');
    obj.form.elements['rdv_fin_mois'].selectedIndex = mois_courant[1];
    return false;
  }
  obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
  gestion_affiche_heures_fin(d_debut, d_fin, 0);
  sauve_date_heure(d_debut, d_fin);
}

function debut_annee_choisie(obj) {
  if(est_date_valide(obj.form.elements['rdv_debut_num_jour'].value, obj.form.elements['rdv_debut_mois'].selectedIndex + 1,obj.value) == 0) {
    alert('La date sélectionnée n\'existe pas dans le calendrier. Veuillez faire un autre choix!');
    obj.selectedIndex = an_courant[0];
    return false;
  }
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
  var mn_fin = h_fin[1].split('(');
  var d_debut = new Date(obj.value, obj.form.elements['rdv_debut_mois'].selectedIndex, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var d_fin = calcul_date_fin_select(d_debut, 1);
  var diff = d_fin - d_debut;
// Affiche le mois de d_fin
  obj.form.elements['rdv_fin_mois'].selectedIndex = d_fin.getMonth();
// Affiche le jour de la semaine correspondant à d_fin
  obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
  obj.form.elements['rdv_fin_num_jour'].selectedIndex = d_fin.getDate() -1;
// Gestion de l'année de la date de fin
  if(d_fin.getFullYear() <= obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_debut_annee'].options.length -1].value) {
    for(var j = 0; j < obj.form.elements['rdv_fin_annee'].options.length; j++) {
//      alert('options[i].text = '+obj.form.elements['rdv_fin_annee'].options[i].text+'\ngetFullYear = '+d_fin.getFullYear()+'\ni = '+i);
      if(obj.form.elements['rdv_fin_annee'].options[j].value == d_fin.getFullYear()) {
        obj.form.elements['rdv_fin_annee'].selectedIndex = j;
        break;
      }
    }
  }
  else {
    diff = d_fin.getFullYear() - obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length- 1].value;
    var opt1 = new Option();
    opt1.text = parseInt(obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length - 1].value, 10) + 1;
    opt1.value = opt1.text;
    var opt2 = new Option();
    opt2.text = parseInt(obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length - 1].value, 10) + 1;
    opt2.value = opt2.text;
    obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length] = opt1;
    obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length] = opt2;
    obj.form.elements['rdv_fin_annee'].selectedIndex = obj.form.elements['rdv_fin_annee'].length -1;
  }
  obj.form.elements['rdv_debut_jour'].value = jours[d_debut.getDay()][1];
  gestion_affiche_heures_fin(d_debut, d_fin, 1);
  sauve_date_heure(d_debut, d_fin);
  valide_heure_rdv(d_debut);
}

function fin_annee_choisie(obj) {
  if(est_date_valide(obj.form.elements['rdv_fin_num_jour'].value, obj.form.elements['rdv_fin_mois'].selectedIndex + 1,obj.value) == 0) {
    alert('La date sélectionnée n\'existe pas dans le calendrier. Veuillez faire un autre choix!');
    obj.selectedIndex = an_courant[1];
    return false;
  }
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
  var mn_fin = h_fin[1].split('(');
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, obj.form.elements['rdv_debut_mois'].selectedIndex, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var d_fin = calcul_date_fin_select(d_debut, 0);
  var diff = d_fin - d_debut;
  if(diff < 0) {
    alert('La date de fin est inférieure à la date de début du rendez-vous.\nCette opération est impossible.');
    obj.form.elements['rdv_fin_annee'].selectedIndex = an_courant[1];
    return false;
  }
  obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
  gestion_affiche_heures_fin(d_debut, d_fin, 0);
  sauve_date_heure(d_debut, d_fin);
}

function ecrire_dans_console (texte) {
// Ecrire dans la console si elle est active ou ecrire dans alert
  if (typeof console !== undefined) {
        console.log(texte);    
    }
    else {
        alert(texte);    
    }

}

function debut_heure_choisie(obj) {
// Il faudra prendre en compte les minutes avec les autres types d'affichage
//  alert("La fonction debut_heure_choisie a été appelée");
  ecrire_dans_console("La fonction debut_heure_choisie a été appelée");
  var str_opt;
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, obj.form.elements['rdv_debut_mois'].selectedIndex, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var d_fin = calcul_date_fin_select(d_debut, 1);
// Affiche le mois de d_fin
  obj.form.elements['rdv_fin_mois'].selectedIndex = d_fin.getMonth();
// Affiche le jour de la semaine correspondant à d_fin
  obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
  obj.form.elements['rdv_fin_num_jour'].selectedIndex = d_fin.getDate() -1;
  if(d_fin.getFullYear() <= obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_debut_annee'].options.length -1].value) {
    for(var j = 0; j < obj.form.elements['rdv_fin_annee'].options.length; j++) {
      if(obj.form.elements['rdv_fin_annee'].options[j].value == d_fin.getFullYear()) {
        obj.form.elements['rdv_fin_annee'].selectedIndex = j;
        break;
      }
    }
  }
  else {
    diff = d_fin.getFullYear() - obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length- 1].value;
    var opt1 = new Option();
    opt1.text = parseInt(obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length - 1].value, 10) + 1;
    opt1.value = opt1.text;
    var opt2 = new Option();
    opt2.text = parseInt(obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length - 1].value, 10) + 1;
    opt2.value = opt2.text;
    obj.form.elements['rdv_fin_annee'].options[obj.form.elements['rdv_fin_annee'].options.length] = opt1;
    obj.form.elements['rdv_debut_annee'].options[obj.form.elements['rdv_debut_annee'].options.length] = opt2;
    obj.form.elements['rdv_fin_annee'].selectedIndex = obj.form.elements['rdv_fin_annee'].length -1;
  }
  gestion_affiche_heures_fin(d_debut, d_fin, 1);
  sauve_date_heure(d_debut, d_fin);
  valide_heure_rdv(d_debut);
}

function fin_heure_choisie(obj) {
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, obj.form.elements['rdv_debut_mois'].selectedIndex, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  alert("La fonction fin_heure_choisie a été appelée");
  if(obj.form.elements['rdv_heure_fin'].value.indexOf('(') >0) {
    var h_fin = obj.form.elements['rdv_heure_fin'].value.split('(');
    var h_delta = h_fin[1].split('h');
    var mn_fin = h_fin[1].split('(');
// Il faudra prendre en compte les minutes avec les autres types d'affichage
    var d_fin = new Date(d_debut.getTime() + 1000*3600*h_delta[0]);
  }
  else {
    var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
    var d_fin = new Date(obj.form.elements['rdv_fin_annee'].value, obj.form.elements['rdv_fin_mois'].selectedIndex, obj.form.elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(h_fin[1], 10));
  }
  var diff = d_fin - d_debut;
  if(diff < 0) {
    alert('La date de fin est inférieure à la date de début du rendez-vous.\nCette opération est impossible.');
    obj.form.elements['rdv_heure_fin'].selectedIndex = heure_courant[1];
    return false;
  }
  else {
// Affiche le mois de d_fin
    obj.form.elements['rdv_fin_mois'].selectedIndex = d_fin.getMonth();
// Affiche le jour de la semaine correspondant à d_fin
    obj.form.elements['rdv_fin_jour'].value = jours[d_fin.getDay()][1];
    obj.form.elements['rdv_fin_num_jour'].selectedIndex = d_fin.getDate() -1;
    for(var i = 0; i < obj.form.elements['rdv_fin_annee'].options.length; i++) {
      if(obj.form.elements['rdv_fin_annee'].options[i].value == d_fin.getFullYear()) {
        obj.form.elements['rdv_fin_annee'].selectedIndex = i;
        break;
      }
    }
  }
  gestion_affiche_heures_fin(d_debut, d_fin, 0);
  sauve_date_heure(d_debut, d_fin);
}

function calcul_date_fin_select(d_debut, ecart) {
  var d_fin;
  if(ecart == 1) { // On conserve l'écart entre les 2 dates
    d_fin = new Date(d_debut.getTime() + fin_courant.getTime() - debut_courant.getTime());
//    alert('La date de fin est : '+d_fin.toLocaleString()+' avec un écart concervé. fin_courant = '+fin_courant.toLocaleString()+' debut_courant = '+debut_courant.toLocaleString());
    var texte = 'La date de fin est : '+d_fin.toLocaleString()+' avec un écart concervé. fin_courant = '+fin_courant.toLocaleString()+' debut_courant = '+debut_courant.toLocaleString();
	ecrire_dans_console(texte);
	}
  else {
    if(document.forms[0].elements['rdv_heure_fin'].value.indexOf('(') > 0) {
      var h_fin = document.forms[0].elements['rdv_heure_fin'].value.split(':');
      var h_delta = h_fin[1].split('h');
      var mn_fin = h_fin[1].split('(');
      d_fin = new Date(document.forms[0].elements['rdv_fin_annee'].value, document.forms[0].elements['rdv_fin_mois'].selectedIndex, document.forms[0].elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(mn_fin[0], 10));
    }
    else {
      var h_fin = document.forms[0].elements['rdv_heure_fin'].value.split(':');
      d_fin = new Date(document.forms[0].elements['rdv_fin_annee'].value, document.forms[0].elements['rdv_fin_mois'].selectedIndex, document.forms[0].elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(h_fin[1], 10));
    }
  }
  return d_fin;
}

function gestion_affiche_heures_fin(d_debut, d_fin, ecart) {
  var ind = -1;
  var diff
//  alert("La fonction gestion_affiche_heures_fin a été appelée par "+caller);
    document.forms[0].elements['rdv_heure_fin'].options.length = 0;
  if((diff = d_fin - d_debut) >= (1000*86400)) { // supérieure à 1 jour
// On recrée le tableau d'options
    if(args.affichage_heure == 5) {
      var st_heure = d_fin.getHours() > 9 ? d_fin.getHours() : '0'+d_fin.getHours();
      var st_mn  = d_fin.getMinutes() > 9 ? d_fin.getMinutes() : '0'+d_fin.getMinutes();
      var new_heure = st_heure+':'+st_mn;
      for(var i = 0; i <= 23; i++) {
        var opt = new Option();
        opt.text = i <=9 ? '0'+i+':00' : i+':00';
        opt.value = opt.text;
        if(new_heure == opt.text) {
          ind = i;
        }
        document.forms[0].elements['rdv_heure_fin'].options[document.forms[0].elements['rdv_heure_fin'].options.length] = opt;
      }
    }
    document.forms[0].elements['rdv_heure_fin'].options.selectedIndex = ind;
  }
  else { //inférieure à 1 jour
// il faut recreer toutes les options à partir de la date de fin en ajoutant la durée
    var j;
//    document.forms[0].elements['rdv_heure_fin'].options.length = 0;
    if(ecart == 1) {
      var d = new Date(d_debut.getTime() + pas);
      j = 1;
    }
    else {
      var d = new Date(d_debut.getTime());
      j = 0;
    }
    if(args.affichage_heure == 5) {
      for(var i = j; i <= 23; i++) {
        var opt = new Option();
        var str_opt = d.getHours() <= 9 ? '0'+d.getHours()+':00 ('+i+' h)' : d.getHours()+':00 ('+i+' h)';
        opt.text = str_opt;
        opt.value = opt.text;
        if((d.getHours() == d_fin.getHours()) && (d.getMinutes() == d_fin.getMinutes())) {
          opt.selected = true;
        }
        document.forms[0].elements['rdv_heure_fin'].options[document.forms[0].elements['rdv_heure_fin'].options.length] = opt;
        d.setTime(d.getTime() + 1000*3600);
      }
    }
  }
}
/************ Fonctions pour la périodicité **********************************/
/** Les champs cachés concernant les heures seront utilisées comme sauvegarde
** des anciennes valeurs. Ils seron donc modifés à chaque déclenchement d'une
** fonction onchange */
function calcul_pas_horaire_periodicite(obj) {
  if(obj.form.elements['affichage_heure'].value == 5) pas = 60*60*1000;
  else if(obj.form.elements['affichage_heure'].value == 4) pas = 30*60*1000;
  else if(obj.form.elements['affichage_heure'].value == 3) pas = 15*60*1000;
  else if(obj.form.elements['affichage_heure'].value == 2) pas = 10*60*1000;
}

function p_debut_heure_choisie(obj) {

  if(!confirm("Toutes les exceptions associées à ce rendez-vous périodique seront supprimées.\n\nDésirez-vous continuer?" )) {
    for(var j = 0; j < obj.options.length; j++) {
//      alert('options[i].text = '+obj.form.elements['p_heure_debut'].options[i].text+'\ngetFullYear = '+d_fin.getFullYear()+'\ni = '+i);
      if(obj.options[j].value == document.forms[0].elements['rdv_heure_debut'].value) {
          obj.selectedIndex = j;
          break;
      }
    }  
	return;
  }
  var str_opt;
  var h_new_debut = obj.form.elements['p_heure_debut'].value.split(':');
  var mois_debut = obj.form.elements['rdv_debut_mois'].value;
  calcul_pas_horaire_periodicite(obj);
//  alert('Le mois de début est '+mois_debut);


  for(var i = 0; i < mois.length; i++) {
    if(mois[i][0] == mois_debut) {
      mois_debut = mois[i][2];
      break;
    }
  }
//  alert('son N° est :'+mois_debut);
  var d_new_debut = new Date(obj.form.elements['rdv_debut_annee'].value, mois_debut, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_new_debut[0], 10), parseInt(h_new_debut[1], 10));
//  var duree = obj.form.elements['p_heure_duree'].value;
  var d_new_fin = calcul_date_fin_selon_duree(obj, d_new_debut, mois_debut);
//  alert('La nouvelle date de début est :'+d_new_debut.toString()+'\nLa nouvelle date de fin est '+d_new_fin.toString());
  gestion_affiche_heures_fin_periodicite(obj, d_new_debut, d_new_fin);
// Mise à jour des champs cachés pour l'heure de début
   if(obj.form.elements['affichage_heure'].value == 5) {
     obj.form.elements['rdv_heure_debut'].value = d_new_debut.getHours() >= 10 ? d_new_debut.getHours()+':00' : '0'+d_new_debut.getHours()+':00';
   }

}

function p_fin_heure_choisie(obj) {
/** il faut calculer la nouvelle durée, modifier le champ p_duree_heure et
** mettre à jour les champs cachés concernés */
//  alert('la fonction p_fin_heure_choisie a été lancée');

  if(!confirm("Toutes les exceptions associées à ce rendez-vous périodique seront supprimées.\n\nDésirez-vous continuer?" )) {
    obj.selectedIndex = 0;
	return;
  }

  calcul_pas_horaire_periodicite(obj);
  var h_new_debut = obj.form.elements['p_heure_debut'].value.split(':');
  var mois_debut = obj.form.elements['rdv_debut_mois'].value;
  for(var i = 0; i < mois.length; i++) {
    if(mois[i][0] == mois_debut) {
      mois_debut = mois[i][2];
      break;
    }
  }
  var d_new_debut = new Date(obj.form.elements['rdv_debut_annee'].value, mois_debut, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_new_debut[0], 10), parseInt(h_new_debut[1], 10));
  var h_new_fin = obj.form.elements['p_heure_fin'].value.split(':');
  var mois_fin = obj.form.elements['rdv_fin_mois'].value;
  for(var i = 0; i < mois.length; i++) {
    if(mois[i][0] == mois_fin) {
      mois_fin = mois[i][2];
      break;
    }
  }

//  var d_new_fin = new Date(obj.form.elements['rdv_fin_annee'].value, mois_fin, obj.form.elements['rdv_fin_num_jour'].value, parseInt(h_new_fin[0], 10), parseInt(h_new_fin[1], 10));
//  alert('La valeur de date de fin est : '+d_new_fin.toString());
// Calcul de la date de fin
  var d_new_fin = new Date(d_new_debut.getTime() + ((1 + obj.form.elements['p_heure_fin'].options.selectedIndex)*pas));
  alert('La nouvelle valeur de date de fin est : '+d_new_fin.toString());
// Gestion du champ p_heure_durée
  gere_duree_periodicite(obj, d_new_debut, d_new_fin);
/* Maj des champs cachés */
  obj.form.elements['rdv_fin_num_jour'].value = d_new_fin.getDate();
  obj.form.elements['rdv_fin_annee'].value = d_new_fin.getFullYear();
  var no_mois_fin = d_new_fin.getMonth();
  for(var i = 0; i < mois.length; i++) {
    if(mois[i][2] == no_mois_fin) {
      obj.form.elements['rdv_fin_mois'].value = mois[i][0];
      break;
    }
  }
  var st_heure = (d_new_fin.getHours() >= 10) ? d_new_fin.getHours() : "0"+d_new_fin.getHours();
  var st_mn = (d_new_fin.getMinutes() >= 10) ? d_new_fin.getMinutes() : "0"+d_new_fin.getMinutes();
  if(d_new_fin.getTime() - d_new_debut.getTime() < 86400*1000) {
    obj.form.elements['rdv_heure_fin'].value = st_heure+':'+st_mn+' ('+obj.form.elements['p_heure_duree'].value+')';
  }
  else {
    obj.form.elements['rdv_heure_fin'].value = st_heure+':'+st_mn;
  }
}


function p_duree_choisie(obj) {
/** Il faut calculer la nouvelle date de fin, modifier le champs p_heure_fin et
les champs cachés associés à la date de fin */
/* La méthode de calcul change en fonction de la durée (< à 1 jour ou non)*/
  if(!confirm("Toutes les exceptions associées à ce rendez-vous périodique seront supprimées.\n\nDésirez-vous continuer?" )) {
    for(var j = 0; j < obj.options.length; j++) {
	   if((result = document.forms[0].elements['rdv_heure_fin'].value.indexOf(obj.options[j].value)) != -1) {
			obj.selectedIndex = j;
          break;
       }
    }  
	return;
  }
  var duree = obj.form.elements['p_heure_duree'].options[obj.form.elements['p_heure_duree'].options.selectedIndex].value;
  var tab_duree = duree.split(' ');
  var ajoute;
  switch (tab_duree[1]) {
    case 'jour':
    case 'jours':
      ajoute = tab_duree[0]*86400*1000;
      break;
    case 'semaine':
    case 'semaines':
      ajoute = tab_duree[0]*7*86400*1000;
      break;
    case 'h':
      ajoute = parseFloat(tab_duree[0])*3600*1000;
//      alert('Valeur de tab_duree[0] en chaine '+tab_duree[0]+' puis en float : '+parseFloat(tab_duree[0])+' puis en int : '+parseInt(tab_duree[0], 10));
  }
  var h_debut = obj.form.elements['p_heure_debut'].value.split(':');
  var mois_debut = obj.form.elements['rdv_debut_mois'].value;
  calcul_pas_horaire_periodicite(obj);
//  alert('Le mois de début est '+mois_debut);
  for(var i = 0; i < mois.length; i++) {
    if(mois[i][0] == mois_debut) {
      mois_debut = mois[i][2];
      break;
    }
  }
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, mois_debut, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var d_new_fin = new Date(d_debut.getTime() + ajoute);
/* Mise à jour des champs cachés concernant la date et l'heure de fin */
  obj.form.elements['rdv_fin_num_jour'].value = d_new_fin.getDate();
  obj.form.elements['rdv_fin_annee'].value = d_new_fin.getFullYear();
  var no_mois_fin = d_new_fin.getMonth();
  for(var i = 0; i < mois.length; i++) {
    if(mois[i][2] == no_mois_fin) {
      obj.form.elements['rdv_fin_mois'].value = mois[i][0];
      break;
    }
  }
/** Gère la liste des options de p_heure_fin et la date de fin dans rdv_heure_fin     **/
  gere_options_heure_fin(obj, d_debut, d_new_fin);

}

function gere_duree_periodicite(obj, debut, fin) {
  var duree = fin.getTime() - debut.getTime();
  var idx_jour = -1;
/* On détermine si p_heure_durée contient semaine ou pas */
  for(var i = 0; i < obj.form.elements['p_heure_duree'].options.length; i++) {
    if(obj.form.elements['p_heure_duree'].options[i].value.indexOf('jour') > 0) {
      idx_jour = i;
    }
  }
  if(idx_jour >= 0) {
    if(duree <= 86400*1000/2) { // demi_journée
//      alert('La nouvelle duree entre les dates de début et de fin est : '+duree/pas);
      obj.form.elements['p_heure_duree'].options.selectedIndex = duree/pas;
    }
    else {
      ajoute_option_duree_periodicite(obj, duree, debut, fin);
    }
  }
  else {
    alert("La liste d'options p_heure_duree ne contient pas de terme semaine\nLa duree est : "+duree/pas+" avec pas = "+pas);
    obj.form.elements['p_heure_duree'].options.selectedIndex = (duree/pas) -1;
  }
}

function ajoute_option_duree_periodicite(obj, duree, debut, fin) {
/*Permet d'ajouter au bon endroit dans la liste des options une nouvelle option.
La liste des options contient des durées de l'ordre de la semaine et des jours.
les différentes valeurs remarquables de duréee sont :
- compris entre la demi-journée et 1 jour
- égale à 1 jour
- compris entre 1 jour et 2 jours
- etc.
Il faut chercher l'indice de la première option contenant jour.
*/
  var taille = obj.form.elements['p_heure_duree'].options.length + 1;
  var idx, idx_jour, idx_12h, idx_2jours, idx_3jours, idx_4jours, idx_semaine, idx_2semaines;
  for(var i = 0; i < taille; i++) {
    if(obj.form.elements['p_heure_duree'].options[i].value == '12 h' ) {
      idx_12h = i;
      continue;
    }
    if(obj.form.elements['p_heure_duree'].options[i].value == '1 jour') {
      idx_jour = i;
      break;
    }
  }
  switch (duree) {
    case 86400*1000 :
      obj.form.elements['p_heure_duree'].options[idx_jour].selected = true;
      return;
    case 2*86400*1000 :
      for(var i = idx_jour + 1; i < taille; i++) {
        if(obj.form.elements['p_heure_duree'].options[i].value == '2 jours') {
          obj.form.elements['p_heure_duree'].options[i].selected = true;
          return;
        }
      }
    case 3*86400*1000 :
      for(var i = idx_jour + 2; i < taille; i++) {
        if(obj.form.elements['p_heure_duree'].options[i].value == '3 jours') {
          obj.form.elements['p_heure_duree'].options[i].selected = true;
          return;
        }
      }
    case 4*86400*1000 :
      for(var i = idx_jour + 3; i < taille; i++) {
        if(obj.form.elements['p_heure_duree'].options[i].value == '4 jours') {
          obj.form.elements['p_heure_duree'].options[i].selected = true;
          return;
        }
      }
    case 7*86400*1000 :
      for(var i = idx_jour + 4; i < taille; i++) {
        if(obj.form.elements['p_heure_duree'].options[i].value == '1 semaine') {
          obj.form.elements['p_heure_duree'].options[i].selected = true;
          return;
        }
      }
    case 14*86400*1000 :
      for(var i = idx_jour + 5; i < taille; i++) {
        if(obj.form.elements['p_heure_duree'].options[i].value == '2 semaines') {
          obj.form.elements['p_heure_duree'].options[i].selected = true;
          return;
        }
      }
    default:
      var tab_value;
      var st_duree = duree/pas;
/* On détermine les indices des différentes bornes */
      for(var i = idx_jour + 1; i < taille; i++) {
        if(obj.form.elements['p_heure_duree'].options[i].value == '2 jours' ) {
          idx_2jours = i;
          continue;
        }
        if(obj.form.elements['p_heure_duree'].options[i].value == '3 jours') {
          idx_3jours = i;
          continue;
        }
        if(obj.form.elements['p_heure_duree'].options[i].value == '4 jours' ) {
          idx_4jours = i;
          continue;
        }
        if(obj.form.elements['p_heure_duree'].options[i].value == '1 semaine') {
          idx_semaine = i;
          continue;
        }
        if(obj.form.elements['p_heure_duree'].options[i].value == '2 semaines') {
          idx_2semaines = i;
          break;
        }
      }
      if(duree < 86400*1000) {
/* On détermine l'index à partir duquel il faut faire l'insertion */
        for(idx = idx_12h + 1; idx < idx_jour; idx++) {
          tab_value = obj.form.elements['p_heure_duree'].options[idx].value.split(' ');
          if(tab_value[0] == st_duree.toFixed(2)) {
            obj.form.elements['p_heure_duree'].options[idx].selected = true;
            return;
          }
          if(parseFloat(tab_value) > st_duree) {
            break;
          }
        }
      }
      else if((duree > 86400*1000) && (duree < 2*86400*1000)) {
        for(idx = idx_jour + 1; idx < idx_2jours; idx++) {
          tab_value = obj.form.elements['p_heure_duree'].options[idx].value.split(' ');
          if(tab_value[0] == st_duree.toFixed(2)) {
            obj.form.elements['p_heure_duree'].options[idx].selected = true;
            return;
          }
          if(parseFloat(tab_value) > st_duree) {
            break;
          }
        }
      }
      else if((duree > 2*86400*1000) && (duree < 3*86400*1000)) {
        for(idx = idx_2jours + 1; idx < idx_3jours; idx++) {
          tab_value = obj.form.elements['p_heure_duree'].options[idx].value.split(' ');
          if(tab_value[0] == st_duree.toFixed(2)) {
            obj.form.elements['p_heure_duree'].options[idx].selected = true;
            return;
          }
          if(parseFloat(tab_value) > st_duree) {
            break;
          }
        }
      }
      else if((duree > 3*86400*1000) && (duree < 4*86400*1000)) {
        for(idx = idx_3jours + 1; idx < idx_4jours; idx++) {
          tab_value = obj.form.elements['p_heure_duree'].options[idx].value.split(' ');
          if(tab_value[0] == st_duree.toFixed(2)) {
            obj.form.elements['p_heure_duree'].options[idx].selected = true;
            return;
          }
          if(parseFloat(tab_value) > st_duree) {
            break;
          }
        }
      }
      else if((duree > 4*86400*1000) && (duree < 7*86400*1000)) {
        for(idx = idx_4jours + 1; idx < idx_semaine; idx++) {
          tab_value = obj.form.elements['p_heure_duree'].options[idx].value.split(' ');
          if(tab_value[0] == st_duree.toFixed(2)) {
            obj.form.elements['p_heure_duree'].options[idx].selected = true;
            return;
          }
          if(parseFloat(tab_value) > st_duree) {
            break;
          }
        }
      }
      else if((duree > 7*86400*1000) && (duree < 14*86400*1000)) {
        for(idx = idx_semaine + 1; idx < idx_2semaines; idx++) {
          tab_value = obj.form.elements['p_heure_duree'].options[idx].value.split(' ');
          if(tab_value[0] == st_duree.toFixed(2)) {
            obj.form.elements['p_heure_duree'].options[idx].selected = true;
            return;
          }
          if(parseFloat(tab_value) > st_duree) {
            break;
          }
        }
      }
      else {
        for(idx = idx_2semaines + 1; idx < (taille -1); idx++) {
//          alert("Taille = "+taille+" idx_2semaines = "+idx_2semaines+" idx = "+idx);
          tab_value = obj.form.elements['p_heure_duree'].options[idx].value.split(' ');
          if(tab_value[0] == st_duree.toFixed(2)) {
            obj.form.elements['p_heure_duree'].options[idx].selected = true;
            return;
          }
          if(parseFloat(tab_value) > st_duree) {
            break;
          }
        }
      }
      obj.form.elements['p_heure_duree'].options.selectedIndex = -1;
      if(idx == (taille - 1)) {
        var opt = new Option();
        opt.value = st_duree.toFixed(2)+' h';
        opt.text = opt.value;
        opt.selected = true;
        obj.form.elements['p_heure_duree'].options[idx] = opt;
      }
      else {
        var old_opt = new Option();
        old_opt.value = obj.form.elements['p_heure_duree'].options[idx].value;
        old_opt.text = obj.form.elements['p_heure_duree'].options[idx].text;
        var opt = new Option();
        opt.value = st_duree.toFixed(2)+' h';
        opt.text = opt.value;
        opt.selected = true;
        obj.form.elements['p_heure_duree'].options[idx] = opt;
        for(var i = idx; i < taille; i++) {
          opt = obj.form.elements['p_heure_duree'].options[i+1];
          obj.form.elements['p_heure_duree'].options[i+1] = old_opt;
          old_opt = opt;
        }
      }
  }
}


function gere_options_heure_fin(obj, debut, fin) {
  var st_heure = (fin.getHours() >= 10) ? fin.getHours() : "0"+fin.getHours();
  var st_mn = (fin.getMinutes() >= 10) ? fin.getMinutes() : "0"+fin.getMinutes();
  var new_heure = st_heure+':'+st_mn;
//Remise à 0 de la liste d'options
  obj.form.elements['p_heure_fin'].options.length = 0;
  if(fin.getTime() - debut.getTime() >= 86400*1000) {// > 1 jour
    obj.form.elements['rdv_heure_fin'].value = new_heure;
    if(obj.form.elements['affichage_heure'].value == 5) {
//      st_heure = d_fin.getHours() > 9 ? d_fin.getHours() : '0'+d_fin.getHours();
//      st_mn  = d_fin.getMinutes() > 9 ? d_fin.getMinutes() : '0'+d_fin.getMinutes();
      for(var i = 0; i <= 23; i++) {
        var opt = new Option();
        opt.text = i <=9 ? '0'+i+':00' : i+':00';
        opt.value = opt.text;
        if(new_heure == opt.text) {
          ind = i;
        }
        obj.form.elements['p_heure_fin'].options[obj.form.elements['p_heure_fin'].options.length] = opt;
      }
    }
    obj.form.elements['p_heure_fin'].options.selectedIndex = ind;
  }
  else { // < 1 jour
    var tps = new Date(debut.getTime() + pas);
    var tps_fin = new Date(debut.getTime() + 86400*1000);
    var tps_h, tps_m, opt;
    obj.form.elements['rdv_heure_fin'].value = new_heure+' ('+obj.form.elements['p_heure_duree'].value+')';
    if(obj.form.elements['affichage_heure'].value == 5) {
      while(tps.getTime() < tps_fin.getTime()) {
        tps_h = tps.getHours() > 9 ? tps.getHours() : '0'+tps.getHours();
        tps_m = tps.getMinutes() > 9 ? tps.getMinutes() : '0'+tps.getMinutes();
        opt = new Option();
        opt.text = tps_h+':'+tps_m;
        opt.value = opt.text;
        if(new_heure == opt.text) {
          opt.selected = true;
        }
        obj.form.elements['p_heure_fin'].options[obj.form.elements['p_heure_fin'].options.length] = opt;
        tps.setTime(tps.getTime() + pas);
      }
    }

  }
}

function calcul_date_fin_selon_duree(obj, d_new_debut, no_mois_debut) {
/** Ici, on utilise les champs caches pour récupérer l'ancienne valeur de la
** date de début **/
  var h_debut = obj.form.elements['rdv_heure_debut'].value.split(':');
  var d_debut = new Date(obj.form.elements['rdv_debut_annee'].value, no_mois_debut, obj.form.elements['rdv_debut_num_jour'].value, parseInt(h_debut[0], 10), parseInt(h_debut[1], 10));
  var no_mois_fin = obj.form.elements['rdv_fin_mois'].value;
  for(var i = 0; i < mois.length; i++) {
    if(mois[i][0] == no_mois_fin) {
      no_mois_fin = mois[i][2];
      break;
    }
  }
  if(obj.form.elements['rdv_heure_fin'].value.indexOf('(') > 0) {
    var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
    var h_delta = h_fin[1].split('h');
    var mn_fin = h_fin[1].split('(');
    var d_fin = new Date(obj.form.elements['rdv_fin_annee'].value, no_mois_fin, obj.form.elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(mn_fin[0], 10));
  }
  else {
    var h_fin = obj.form.elements['rdv_heure_fin'].value.split(':');
    var d_fin = new Date(obj.form.elements['rdv_fin_annee'].value, no_mois_fin, obj.form.elements['rdv_fin_num_jour'].value, parseInt(h_fin[0], 10), parseInt(h_fin[1], 10));
  }
  var diff = d_fin - d_debut;
  var d_new_fin = new Date(d_new_debut.getTime() + diff);
/* Mise à jour des champs cachés concernant la date et l'heure de fin */
  obj.form.elements['rdv_fin_num_jour'].value = d_new_fin.getDate();
  obj.form.elements['rdv_debut_annee'].value = d_new_fin.getFullYear();
  no_mois_fin = d_new_fin.getMonth();
  for(var i = 0; i < mois.length; i++) {
    if(mois[i][2] == no_mois_fin) {
      obj.form.elements['rdv_fin_mois'].value = mois[i][0];
      break;
    }
  }
  var st_heure = (d_new_fin.getHours() > 10) ? d_new_fin.getHours() : "0"+d_new_fin.getHours();
  var st_mn = (d_new_fin.getMinutes() > 10) ? d_new_fin.getMinutes() : "0"+d_new_fin.getMinutes();
  if(obj.form.elements['rdv_heure_fin'].value.indexOf('(') > 0) {
    obj.form.elements['rdv_heure_fin'].value = st_heure+':'+st_mn+' ('+obj.form.elements['p_heure_duree'].value+')';
  }
  else {
    obj.form.elements['rdv_heure_fin'].value = st_heure+':'+st_mn;
  }
  return d_new_fin;
}

function gestion_affiche_heures_fin_periodicite(obj, d_debut, d_fin) {
  if(d_fin.getTime() - d_debut.getTime() < 86400*1000) { // inférieur à 1 jour
/* Il faut recrer toutes les options du champ p_heure_fin */
    var j = 1;
    obj.form.elements['p_heure_fin'].options.length = 0;
    var d = new Date(d_debut.getTime() + pas);
    if(obj.form.elements['affichage_heure'].value == 5) {
      for(var i = j; i <= 23; i++) {
        var opt = new Option();
        var str_opt = d.getHours() <= 9 ? '0'+d.getHours()+':00' : d.getHours()+':00';
        opt.text = str_opt;
        opt.value = opt.text;
        obj.form.elements['p_heure_fin'].options[obj.form.elements['p_heure_fin'].options.length] = opt;
        d.setTime(d.getTime() + 1000*3600);
      }
    }
    var idx_duree = obj.form.elements['p_heure_duree'].value.split(' ');
    obj.form.elements['p_heure_fin'].options.selectedIndex = idx_duree[0] - 1;
  }
  else { // supérieur à 1 jour
    var str_hh = d_fin.getHours() <= 9 ? '0'+d_fin.getHours() : d_fin.getHours();
    var str_mn = d_fin.getMinutes() <= 9 ? '0'+d_fin.getMinutes() : d_fin.getMinutes();
    var str_heure_fin = str_hh+':'+str_mn;
    if(obj.form.elements['p_heure_fin'].options[0].value != '00:00') {
/* On génére une nouvelle liste d'options */
      obj.form.elements['p_heure_fin'].options.length = 0;
      if(obj.form.elements['affichage_heure'].value == 5) {
        for(var i = 0; i <= 23; i++) {
          var opt = new Option();
          opt.text = i <=9 ? '0'+i+':00' : i+':00';
          opt.value = opt.text;
          if(str_heure_fin == opt.text) {
            opt.selected = true;
          }
          obj.form.elements['p_heure_fin'].options[obj.form.elements['p_heure_fin'].options.length] = opt;
        }
      }
    }
    else {
/* On recherche l'option à sélectionnée */
      for(var i = 0; i < obj.form.elements['p_heure_fin'].options.length; i++) {
        if(obj.form.elements['p_heure_fin'].options[i].value == str_heure_fin) {
          obj.form.elements['p_heure_fin'].options[i].selected = true;
          break;
        }
      }
    }
  }
}

function affiche_periodicite_choisie() {
  var ecran, minuscule;
  var choix = document.getElementsByName('p_periodicite');
  for (var i = 0; i < choix.length; i++) {
    ecran = document.getElementById(choix[i].value.toLowerCase());
    if(choix[i].defaultChecked == true) {
//      alert("L'écran sélectionné est "+choix[i].value);
      ecran.style.display = 'block';
      break;
    }
  }
}

function gere_ecran_periodicite(obj) {
  var ecran;
  var choix = document.getElementsByName('p_periodicite');
//  alert("le nombre d'élements de choix est : "+choix.length);
  for (var i = 0; i < choix.length; i++) {
//    alert("L'écran sélectionné est "+choix[i].value);
    ecran = document.getElementById(choix[i].value.toLowerCase());
//    AfficheNomsProprietes(ecran);
    if(choix[i].checked == true) {
      ecran.style.display = 'block';
    }
    else {
      ecran.style.display = 'none';
    }
  }
}

function p_quotidienne_choisie(obj) {
  var q = document.getElementsByName('quotidienne');
  p_choisie_valeur(q, '1');
}

function p_mensuelle_choisie(obj) {
  var m = document.getElementsByName('mensuelle');
  if((obj.name == 'tm1') || (obj.name == 'tm2')) {
    p_choisie_valeur(m, '1');
  }
  else {
    p_choisie_valeur(m, '2');
  }
}

function p_annuelle_choisie(obj) {
  var a = document.getElementsByName('annuelle');
  if((obj.name == 'ta1') || (obj.name == 'achoix')) {
    p_choisie_valeur(a, '1');
  }
  else {
    p_choisie_valeur(a, '2');
  }
}

function pl_fin_choisie(obj) {
/*  alert('Coucou');
  AfficheNomsProprietes(obj);
  if(obj.name == undefined) {
    alert("Type de l'objet"+obj.type+"NodeType de l'objet"+obj.nodeType+"Name de l'élement Parent : "+obj.parentNode.name);
  }*/
/* Gestion des 3 cas possibles avec default pour le no_date_fin */
  var h = document.getElementsByName('pl_menu_fin');
  switch(obj.name) {
/*    case 'no_date_fin' :
     p_choisie_valeur(h, '1');
     break;
*/
    case 'pl_mchoix2' :
      p_choisie_valeur(h, '2');
      break;

   case 'pl_fin' :
     p_choisie_valeur(h, '3');
     break;

   default : // C'est le cas pour no_date_fin
   
     p_choisie_valeur(h, '1');
//     alert("NodeName de l'objet"+obj.nodeName+" NodeType de l'objet"+obj.nodeType);
     break;
  }
}

function p_choisie_valeur(choix, valeur) {
  for(var i = 0; i < choix.length; i++) {
    if(choix[i].value == valeur) {
      choix[i].checked = true;
    }
    else {
      choix[i].checked = false;
    }
  }
}

function valide_ecran_periodicite() {
//  alert("Validation de l'écran de périodicité");
  var choix = document.getElementsByName('p_periodicite');
  for (var i = 0; i < choix.length; i++) {
    if(choix[i].checked == true) {
      switch(choix[i].value) {
        case 'Quotidienne' :
          var q = document.getElementsByName('tq1');
          var int_q = parseInt(q[0].value, 10);
//          AfficheNomsProprietes(q);
          if(isNaN(q[0].value) || (q[0].value < 1) || isNaN(int_q) || (int_q < 1)) {
            alert("La valeur saisie dans le champ texte doit être un nombre supérieur ou égale à 1.\nVeuillez, SVP, saisir une nouvelle valeur ou cliquer sur Annuler.");
            q[0].select();
            return false;
          }
          else {
            q[0].value = int_q;
          }
          break;
          
        case 'Hebdomadaire' :
          var h = document.getElementsByName('th1');
          var int_h  = parseInt(h[0].value, 10);
          if(isNaN(h[0].value) || (h[0].value < 1) || isNaN(int_h) || (int_h < 1)) {
            alert("La valeur saisie dans le champ texte doit être un nombre supérieure ou égale à 1.\nVeuillez, SVP, saisir une nouvelle valeur ou cliquer sur Annuler.");
            h[0].select();
            return false;
          }
          else {
            h[0].value = int_h;
          }
          break;
          
        case 'Mensuelle' :
          var list_m = document.getElementsByName('mensuelle');
          for(var j = 0; j < list_m.length; j++) {
            alert("Valeur de mensuelle "+list_m[j].value+" valeur de j = "+j);
            if(list_m[j].checked == true) {
              switch (list_m[j].value) {
                case '1' :
                  var m1 = document.getElementsByName('tm1');
                  var int_m1 = parseInt(m1[0].value, 10);
                  if(isNaN(m1[0].value) || (m1[0].value < 1) || isNaN(int_m1) || (int_m1 < 1)) {
                    alert("La valeur saisie dans le champ texte doit être un nombre supérieure ou égale à 1.\nVeuillez, SVP, saisir une nouvelle valeur ou cliquer sur Annuler.");
                    m1[0].select();
                    return false;
                  }
                  else {
                    m1[0].value = int_m1;
                  }
                  m1 = undefined;
                  var m2 = document.getElementsByName('tm2');
                  var int_m2 = parseInt(m2[0].value, 10);
                  if(isNaN(m2[0].value) || (m2[0].value < 1) || isNaN(int_m2) || (int_m2 < 1)) {
                    alert("La valeur saisie dans le champ texte doit être un nombre supérieure ou égale à 1.\nVeuillez, SVP, saisir une nouvelle valeur ou cliquer sur Annuler.");
                    m2[0].select();
                    return false;
                  }
                  else {
                    m2[0].value = int_m2;
                  }
                  m2 = undefined;
                  break;
                
                case '2' :
                  var m3 = document.getElementsByName('tm3');
                  var int_m3 = parseInt(m3[0].value, 10);
                  if(isNaN(m3[0].value) || (m3[0].value < 1) || isNaN(int_m3) || (int_m3 < 1)) {
                    alert("La valeur saisie dans le champ texte doit être un nombre supérieure ou égale à 1.\nVeuillez, SVP, saisir une nouvelle valeur ou cliquer sur Annuler.");
                    m3[0].select();
                    return false;
                  }
                  else {
                    m3[0].value = int_m3;
                  }
                  break;
              }
              break; // fait sortir de la boucle for()
            }
          }
          break;
          
        case 'Annuelle' :
          var a = document.getElementsByName('ta1');
          var int_a = parseInt(a[0].value, 10);
          if(isNaN(a[0].value) || (a[0].value < 1) || isNaN(int_a) || (int_a < 1)) {
            alert("La valeur saisie dans le champ texte doit être un nombre supérieure ou égale à 1.\nVeuillez, SVP, saisir une nouvelle valeur ou cliquer sur Annuler.");
            a[0].select();
            return false;
          }
          else {
            a[0].value = int_a;
          }
          break;
      }
    }
  }
  return true;
}


/*****************************************************************************/

function AfficheNomsProprietes(obj) {
  var noms = '';
  for(var nom in obj) {
    noms += nom+'  ';
  }
  alert("les propriétés de l'objet "+obj.name+" sont :\n"+noms);

}

function est_date_valide(jour, mois, annee) {
  var nb_jours = nbre_jours_mois(mois, annee);
  if(jour > nb_jours) {
    return 0;
  }
  else return 1;
}
function nbre_jours_mois(mois, annee) {
  var nb_jours = 31;
  if(mois == 4 || mois == 6 || mois == 9 || mois == 11) nb_jours--;
  if(mois == 2) {
    nb_jours -= 3;
    if(annee % 4 == 0) nb_jours++;
    if(annee % 100 == 0) nb_jours--;
    if(annee % 400 == 0) nb_jours++;
  }
  return nb_jours;
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
      alert('unescape(): Problème de codage avec la valeur de '+nom+' égale à '+valeur);
      try {
        args[nom] = decodeURIComponent(valeur);
      }
      catch(e) {
        args[nom] = valeur;
        alert('decodeURIComponent(): Problème de codage avec la valeur de '+nom+' égale à '+args[nom]);
      }
      finally {
        alert('Le décodage pour la valeur de '+nom+ ' est égale à '+args[nom]);
      }
    }
  }
  return args;
}

