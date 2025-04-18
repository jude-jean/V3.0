//  Fichier outils.js contenant les fonctions javascript
self.onerror = ma_gestion_erreur;

var jours = [['Dimanche', 'Dim', 0], ['Lundi', 'Lun', 1], ['Mardi', 'Mar', 2], ['Mercredi', 'Mer', 3], ['Jeudi', 'Jeu', 4], ['Vendredi', 'Ven', 5], ['Samedi', 'Sam', 6]];
var mois = [['Janvier', 'Janv', 0], ['FÈvrier', 'FÈv', 1] ,['Mars', 'Mars', 2], ['Avril', 'Avr', 3], ['Mai', 'Mai', 4], ['Juin', 'Juin', 5], ['Juillet', 'Juil', 6], ['Ao˚t', 'Ao˚t', 7], ['Septembre', 'Sep', 8], ['Octobre', 'Oct', 9], ['Novembre', 'Nov', 10], ['DÈcembre', 'DÈc', 11]];
var posRdvsY;

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
  ecrire_dans_console(' Une erreur est survenue dans le code Javscript, voici les dÈtails :\n Message d\'erreur : '+msg+'\n Ligne N∞ : '+line);
  return true;
}


function bascule(zap) {
  if(document.getElementById) {
      var chgt = document.getElementById(zap).style;
      if(chgt.display == "block") {
        chgt.display = "none";
      }
      else {
        chgt.display = "block";
      }
      return false;
  }
  else {
    return true;
  }
}

function select_login() {
	var login = document.getElementById('log');
	if (login !== undefined) {
		login.focus();
	}
}


var args, pas, aujourdhui_debut, aujourdhui_fin, oldeventY;

function anime_rdv(rdv, event) {
// Permet le dÈplacement des rdvs dans le calendrier.
// RÈcupËre les coordonnÈes du rdv
	var x = parseInt(rdv.style.left);
	var y = parseInt(rdv.style.top);
// Calcule la distance entre le rdv et le point ou l'ÈvÈnement a eu lieu
	var deltaX = event.clientX - x;
	var deltaY = event.clientY - y;
	var nb_rdv = document.forms[1].elements['nb_rdv'].value;
	var z_ind = rdv.style.zIndex;
	oldeventY = event.clientY;
// On supprime le gestionnaire de movement de la souris
//	document.removeEventListener("mousemove", moveCursor, true);
// On enregistre les gestionnaires d'ÈvÈnenments
	document.addEventListener("mousemove", moveHandler, true);
	document.addEventListener("mouseup", upHandler, true);
// !l'ùvùnement est traitù, on bloque sa propagation
	event.stopPropagation();
	event.preventDefault();
// Calcul du pas
	var parent_rdv = document.getElementById('cal_visu');
	var list_div = parent_rdv.getElementsByTagName('div');
	var h_pas;
	for(var i = 0; i < list_div.length; i++) {
		if(list_div[i].className == 'rdv_heure_col2') {
			h_pas = list_div[i].offsetHeight;
//          largeur_totale =list_div[i].offsetWidth;
			break;
		}
	}
// Rùcupùration de l'ident du rdv
    var id_rdv = rdv.getAttribute('id');
//	var init_height = parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10)*h_pas;	
	var init_height = parseInt(rdv.style.height);
	var old_border = '1px solid #FFDF80';
	var new_border = '5px dashed red';
	rdv.style.zIndex = 1000 + parseInt(nb_rdv);
	ecrire_dans_console("Old border = "+old_border+", New border = "+new_border+", Init height = "+init_height+", nb_rdv = "+nb_rdv+", zIndex = "+rdv.style.zIndex);
	moveHandler(event);

	function moveHandler(event) {
// DÈplacement l'ÈlÈment de la position courante de la souris, ajustÈe par le delta
		var rdvY = event.clientY -deltaY;
		var limite_haute = document.getElementById('titre_rdv_jour').offsetHeight - parseInt(rdv.style.height);
		var limite_basse = document.getElementById('cal_visu').offsetHeight;
		rdv.style.left = x + 'px';
//		if((rdvY >= document.getElementById('titre_rdv_jour').offsetHeight) && (rdvY <= limite_basse)){
		if((rdvY > limite_haute) && (rdvY < limite_basse)){
			rdv.style.top = rdvY + "px";
			rdv.style.height = init_height+'px';
			rdv.style.border = old_border;
//			ecrire_dans_console("moveHandler() in : height = "+rdv.style.height);
		}
		if ((rdvY <= document.getElementById('titre_rdv_jour').offsetHeight) || (rdvY >= (document.getElementById('cal_visu').offsetHeight - parseInt(rdv.style.height)))){
			rdv.style.height = init_height - 8 +'px';
			rdv.style.border = new_border;
//			ecrire_dans_console("moveHandler() out : height = "+rdv.style.height);
		}
// On arrete la propagation
		event.stopPropagation();
	}

	function upHandler(event) {
// DÈsenregistre les gestionnaires d'ÈvÈnements
		document.removeEventListener("mouseup", upHandler, true);
		document.removeEventListener("mousemove", moveHandler, true);
// On remet la bordure initiale
		rdv.style.height = init_height +'px';
		rdv.style.border = old_border;
		rdv.style.cursor = 'wait';
//		ecrire_dans_console("upHandler() up : height = "+rdv.style.height);
		if(oldeventY != event.clientY) {
			event.stopPropagation();
//			var id_rdv = rdv.getAttribute('id');
			if(document.forms[1].elements['ref_'+id_rdv]) {		
				var msg = "Le rendez-vous a une pÈriodicitÈ.\n\nSi vous souhaitez modifier le rendez-vous, cliquez sur OK\n\nSinon cliquez sur Annuler";
				if(!confirm(msg)) {
					rdv.style.top = y + "px";
					return;
				}
			}

			var limite_basse = document.getElementById('cal_visu').offsetHeight -parseInt(rdv.style.height);
//		ecrire_dans_console('oldeventY = '+oldeventY+', eventY = '+event.clientY);
//		document.getElementById('pos'+id_rdv).value = pos;
//			rdv.style.top = document.getElementById('titre_rdv_jour').offsetHeight + (pos*h_pas) +"px";
//		ecrire_dans_console('event Y = '+event.clientY+', pos = '+pos+', h_pas = '+h_pas);
			var rdvY = event.clientY -deltaY;
			var pos = Math.round(-0.5 + (rdvY  / h_pas));
			rdv.style.top = (pos*h_pas) +"px";
			if(rdvY <= document.getElementById('titre_rdv_jour').offsetHeight) {
//				rdv.style.top = document.getElementById('titre_rdv_jour').offsetHeight+"px";
//				rdvY = document.getElementById('titre_rdv_jour').offsetHeight;
			}	
			else if(rdvY > limite_basse) {
//				rdv.style.top = limite_basse+"px";
			}	
			else {	
//				rdv.style.top = (pos*h_pas) +"px";
			}
//			rdvY = event.clientY -deltaY;
			pos = Math.round(-0.5 + (rdvY  / h_pas));
			ecrire_dans_console("pos ="+pos+", rdvY = "+rdvY+", h_pas = "+h_pas+", rdvY/h_pas = "+(rdvY/h_pas)+", titre_rdv_jour.offsetHeight = "+document.getElementById('titre_rdv_jour').offsetHeight);
			
// on calcule l'url ‡ exÈcuter
			var enfants = rdv.childNodes;
			var heure_debut, heure_fin, hh, mm, jj;
			var hauteur_rdv = parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10);
			for(var i = 0; i < enfants.length; i++) {
				if(enfants[i].nodeName == 'A') {
					var jour_debut = new Date(document.forms[1].elements['annee'].value, document.forms[1].elements['mois'].value -1, document.forms[1].elements['jour'].value, 0, 0);
					var jour_fin = new Date(document.forms[1].elements['annee'].value, document.forms[1].elements['mois'].value -1, document.forms[1].elements['jour'].value, 23, 59);
					var old_rdv_debut = document.forms[1].elements['debut_'+id_rdv].value.split(/(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/);
					var old_rdv_fin = document.forms[1].elements['fin_'+id_rdv].value.split(/(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/);
//					var old_rdv_debut = document.forms[1].elements['debut_'+id_rdv].value;					
					ecrire_dans_console('id_rdv = '+id_rdv+' >>> old_rdv_debut = ('+old_rdv_debut[0]+')'+old_rdv_debut[3]+'/'+old_rdv_debut[2]+'/'+old_rdv_debut[1]+' '+old_rdv_debut[4]+':'+old_rdv_debut[5]+':'+old_rdv_debut[6]);
//					ecrire_dans_console('old_rdv_debut = '+old_rdv_debut);
					old_rdv_debut = new Date(old_rdv_debut[1], parseInt(old_rdv_debut[2]) -1, parseInt(old_rdv_debut[3]), parseInt(old_rdv_debut[4]), parseInt(old_rdv_debut[5]), parseInt(old_rdv_debut[6]));
					old_rdv_fin = new Date(old_rdv_fin[1], parseInt(old_rdv_fin[2]) -1, parseInt(old_rdv_fin[3]), parseInt(old_rdv_fin[4]), parseInt(old_rdv_fin[5]), parseInt(old_rdv_fin[6]));
					ecrire_dans_console('old_rdv_debut = '+old_rdv_debut.toString()+', old_rdv_fin = '+old_rdv_fin.toString());
					if(pos == 0) {
						var rdv_debut = new Date(jour_debut.getTime());
					}
					else {
						var rdv_debut = new Date(jour_debut.getTime() + (pos -1)*60*60*1000);
					}
//					var rdv_fin = new Date(rdv_debut.getTime() + hauteur_rdv*60*60*1000);
					var rdv_fin = new Date(rdv_debut.getTime() + old_rdv_fin.getTime() - old_rdv_debut.getTime());
					ecrire_dans_console("rdv_debut = "+rdv_debut.toString()+", rdv_fin = "+rdv_fin.toString());
					heure_debut = rdv_debut.getHours() <= 9 ? "0"+rdv_debut.getHours() : rdv_debut.getHours();
					if(rdv_fin.getDay() != rdv_debut.getDay()) {
						hh = rdv_fin.getHours() <= 9 ? "0"+rdv_fin.getHours() : rdv_fin.getHours();
						jj = rdv_fin.getDate() <= 9 ? "0"+rdv_fin.getDate() : rdv_fin.getDate();
						mm = rdv_fin.getMonth() <= 9 ? "0"+rdv_fin.getMonth() : rdv_fin.getMonth();
						heure_fin = jj+'/'+mm+'/'+rdv_fin.getFullYear()+' '+hh;
					}
					else {
						heure_fin = rdv_fin.getHours() <= 9 ? "0"+rdv_fin.getHours() : rdv_fin.getHours();
					}
					enfants[i].innerHTML = enfants[i].innerHTML.replace(/(\d+):(\d+) - (\d+):(\d+)/, heure_debut+":$2 - "+heure_fin+":$4");
// Il faut maintenant modifier les champs cachÈs debut et fin qui seront utilisÈs pour constituer la chaine update_rdv
					document.forms[1].elements['debut_'+id_rdv].value = document.forms[1].elements['debut_'+id_rdv].value.replace(/(\d+):(\d+)/, heure_debut+":$2");
					document.forms[1].elements['fin_'+id_rdv].value = document.forms[1].elements['fin_'+id_rdv].value.replace(/(\d+):(\d+)/, heure_fin+":$2");
					var num_rdv = document.forms[1].elements['id_'+id_rdv].value;
// Dans l'avenir, il faudra tenir compte peut-ùtre du type d'affichage en particulier des minutes. Aujourd'hui, ce n'est pas le cas				
					var update_rdv = base+"/rendez_vous/update.pl?ident_id="+document.forms[1].elements['ident_id'].value+"&rdv="+num_rdv+"&debut="+document.forms[1].elements['debut_'+id_rdv].value+"&fin="+document.forms[1].elements['fin_'+id_rdv].value+"&annee="+document.forms[1].elements['annee'].value+"&mois="+document.forms[1].elements['mois'].value+"&jour="+document.forms[1].elements['jour'].value;
//				ecrire_dans_console("update_rdv = "+update_rdv);
//				location.href = update_rdv;
					break;
				}
		
			}
		}
	}

}

function curseur_rdv(rdv, event) {
	rdv.style.cursor = 'crosshair';	

	var parent_rdv = document.getElementById('cal_visu');
	var list_div = parent_rdv.getElementsByTagName('div');
	var h_pas;
    for(var i = 0; i < list_div.length; i++) {
        if(list_div[i].className == 'rdv_heure_col2') {
          h_pas = list_div[i].offsetHeight;
//          largeur_totale =list_div[i].offsetWidth;
          break;
        }
    }
	var id_rdv = rdv.getAttribute('id');
	var pos_rdv = parseInt(document.forms[1].elements['pos_'+id_rdv].value, 10);
	var top_rdv = pos_rdv*h_pas + document.getElementById('titre_rdv_jour').offsetHeight;
	var hauteur_rdv = parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10)*h_pas;
	
// Permet le dùplacement des rdvs dans le calendrier.
// Rùcupùre les coordonnùes du rdv
	var x = parseInt(rdv.style.left);
	var y = parseInt(rdv.style.top);
// Calcule la distance entre le rdv et le point ou l'ùvùnement a eu lieu
	var deltaX = event.clientX - x;
	var deltaY = event.clientY - y;
// On enregistre les gestionnaires d'ùvùnenments
	document.addEventListener("mousemove", moveCursor, true);
	document.addEventListener("mouseout", outCursor, true);
// !l'ùvùnement est traitù, on bloque sa propagation
	event.stopPropagation();
	event.preventDefault();
//	ecrire_dans_console("delta Y = "+deltaY+", hauteur du rdv = "+hauteur_rdv);
	
	function moveCursor(event) {
		deltaY = event.clientY - y;
//		var posYrdv = hauteur_rdv;
//		ecrire_dans_console("event Y = "+event.pageY+", offset Y = "+(event.clientY-244)+", delta Y = "+deltaY+", hauteur du rdv = "+hauteur_rdv+", top = "+y);
// On arrete la propagation
		event.stopPropagation();
	}

	function outCursor(event) {
// Dùsenregistre les gestionnaires d'ùvùnements
		document.removeEventListener("mousemove", moveCursor, true);
		document.removeEventListener("mousout", outCursor, true);
		event.stopPropagation();
/*		var parent_rdv = document.getElementById('cal_visu');
		var list_div = parent_rdv.getElementsByTagName('div');
		var limite_basse = document.getElementById('cal_visu').offsetHeight -parseInt(rdv.style.height);
		var h_pas;
		for(var i = 0; i < list_div.length; i++) {
			if(list_div[i].className == 'rdv_heure_col2') {
				h_pas = list_div[i].offsetHeight;
//          largeur_totale =list_div[i].offsetWidth;
				break;
			}
		}
			var rdvY = event.clientY -deltaY;
			var id_rdv = rdv.getAttribute('id');
			var pos = Math.round(-0.5 + (rdvY  / h_pas));
//		document.getElementById('pos'+id_rdv).value = pos;
//			rdv.style.top = document.getElementById('titre_rdv_jour').offsetHeight + (pos*h_pas) +"px";
			ecrire_dans_console('event Y = '+event.clientY+', pos = '+pos+', h_pas = '+h_pas);
			if(rdvY < document.getElementById('titre_rdv_jour').offsetHeight) {
				rdv.style.top = document.getElementById('titre_rdv_jour').offsetHeight+"px";
			}	
			else if(rdvY > limite_basse) {
				rdv.style.top = limite_basse+"px";
			}	
			else {	
				rdv.style.top = (pos*h_pas) +"px";
			}
			rdv.style.cursor = 'wait';
*/	
	}

}
function cree_ligne() {
/*	var titre = document.getElementsByTagName('h1');
	var css_titre = getComputedStyle(titre[0]);
	var parent_rdv = document.getElementById('cal_visu');
	var list_div = parent_rdv.getElementsByTagName('div');
	var h_pas;
    for(var i = 0; i < list_div.length; i++) {
        if(list_div[i].className == 'rdv_heure_col2') {
          h_pas = list_div[i].offsetHeight;
//          largeur_totale =list_div[i].offsetWidth;
          break;
        }
    }
	var id_rdv = rdv.getAttribute('id');
	var pos_rdv = parseInt(document.forms[1].elements['pos_'+id_rdv].value, 10);
	var top_rdv = pos_rdv*h_pas + document.getElementById('titre_rdv_jour').offsetHeight;
	var hauteur_rdv = parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10)*h_pas;
	var bottom_rdv = top_rdv + hauteur_rdv;
	var css_rdv = getComputedStyle(rdv);

	var x = parseInt(rdv.style.left);
	var y = parseInt(rdv.style.top);
// Calcule la distance entre le rdv et le point ou l'ùvùnement a eu lieu
	var deltaX = event.clientX - x;
	var deltaY = event.clientY - y;

	
	ecrire_dans_console ("event.clientY = "+event.clientY+", top rdv = "+(parseInt(rdv.style.top))+", top rdv calculù = "+top_rdv+", hauteur rdv = "+hauteur_rdv);
	if((event.clientY >= (parseInt(rdv.style.top) + hauteur_rdv - 2)) || (event.clientY <= (parseInt(rdv.style.top) + 2))) {
		rdv.style.cursor = 's-resize';
	}
	else {
		rdv.style.cursor = 'crosshair';
	}
*/

}

function appel_url(bouton) {
  var etat, req, res, motif;
  res = -10;
//  alert ("La valeur de l'url est : "+location+"\nLa valeur de search est :"+location.search+"\nLa taille de search est : "+location.search.length);
  if(location.search == '') {
    return true;
  }
  args = recup_args();

//  AfficheNomsProprietes(document.forms[1].elements['ident_id']);
//  ecrire_dans_console("Le nom du bouton ayant ùtù validù est : "+bouton.value+"\nLa valeur des arguments sont :\n-.Etat = "+args.etat+"\nIdent = "+args.ident);
  switch (bouton.value) {
    case 'Calendrier' :
//      ecrire_dans_console("L'utilisateur a appuyù sur le bouton <Calendrier>");
      req = location.search;
      if(document.forms[1].elements['ident_id'].value != args['ident_id']) {
        req = req.replace(/ident_id=.*/, 'ident_id='+document.forms[1].elements['ident_id'].value);
      }
      if(args[".Etat"] != null) {
        req = req.replace(/Etat=.*?&/, 'Etat='+bouton.value+'&');
        if((args.mois != null) && (args.mois.match(/\d+/) == null)) {
          for(var i = 0; i < mois.length; i++) {
            if(mois[i][0] == args.mois) {
              req = req.replace(/mois=.*?&/, 'mois='+(1+ mois[i][2])+'&');
//              ecrire_dans_console("La nouvelle valeur de req est : "+req+"\nLa valeur de i est :"+i+"\nargs[mois] = "+args.mois+"\nmois[i][0] = "+mois[i][0]+" mois[i][2] = "+mois[i][2]);
              break;
            }
          }
          if(args.jour == null) {
            req = req.concat('&jour=1');
          }
        }
      }
//      ecrire_dans_console("La nouvelle valeur de req = "+req);
      location.search = req;

      break;
      
    case "Rapports d'activitÈs" :
    case "Rapports d'activites" :
//      ecrire_dans_console("L'utilisateur a appuyù sur le bouton <Rapports d'activitùs>");
      req = location.search;
      if(document.forms[1].elements['ident_id'].value != args['ident_id']) {
        req = req.replace(/ident_id=.*/, 'ident_id='+document.forms[1].elements['ident_id'].value);
      }
      req = req.replace(/Etat=.*?&/, "Etat=Rapports d'activites&");
      if((args.mois !=null) && (isNaN(args.mois) == false)) {
        for(var i = 0; i < mois.length; i++) {
          if(mois[i][2] == (args.mois -1)) {
            req = req.replace(/mois=.*?&/, 'mois='+mois[i][0]+'&');
//            ecrire_dans_console("La nouvelle valeur de req est : "+req+"\nLa valeur de i est :"+i+"\nargs[mois] = "+args.mois+"\nmois[i][0] = "+mois[i][0]+" mois[i][2] = "+mois[i][2]);
            break;
          }
        }
        if(args.jour != null) {
          req = req.replace(/&jour=\d{1,2}/, '');
        }
      }

      location.search = req;
//      ecrire_dans_console("La nouvelle valeur de l'url est :"+location);
      break;

    case 'Compte' :
//      ecrire_dans_console("L'utilisateur a appuyù sur le bouton <Compte> et mois ù pour valeur ");
      req = location.search;
      if(document.forms[1].elements['ident_id'].value != args['ident_id']) {
        req = req.replace(/ident_id=.*/, 'ident_id='+document.forms[1].elements['ident_id'].value);
      }
//      ecrire_dans_console("La valeur de req est : "+req+" La valeur de bouton est : "+bouton.value);
      req = req.replace(/Etat=.*?&/, 'Etat='+bouton.value+'&');
//      ecrire_dans_console("La nouvelle valeur de req est : "+req);
      if(args.annee != null) {
        req = req.replace(/annee=.*?&/, '');
      }
      if(args.mois != null) {
        req = req.replace(/mois=.*?&/, '');
      }
      if(args.jour != null) {
        req = req.replace(/&jour=\d{1,2}/, '');
      }
      location.search = req;
//      ecrire_dans_console("La nouvelle valeur de l'url est :"+location);
      break;

    case "DonnÈes sociales" :
//      ecrire_dans_console("L'utilisateur a appuyù sur le bouton <Donnùes sociales>");
      req = location.search;
      if(document.forms[1].elements['ident_id'].value != args['ident_id']) {
        req = req.replace(/ident_id=.*/, 'ident_id='+document.forms[1].elements['ident_id'].value);
      }
      req = req.replace(/Etat=.*?&/, "Etat=Donnees sociales&");
      if(args.mois != null) {
        req = req.replace(/&mois=\d{1,2}/, '');
      }
      if(args.jour != null) {
        req = req.replace(/&jour=\d{1,2}/, '');
      }
      location.search = req;
//      ecrire_dans_console("La nouvelle valeur de l'url est :"+location);
      break;

  }
  return false;
}

function recharge_des_rdv() {
   location.reload(true);
}

function addCharsetUtf8InForm() {
  let form = document.getElementById('connexionForm');
  form.setAttribute('accept-charset','utf-8');  
}

function gestion_affichage_rdv() {
  var parent_rdv, pos, h_pas, list_div, list_rdv_apres, list_rdv_avant, decalage;
  var id_rdv, rdv, nb_rdv, hauteur, largeur, largeur_totale, largeur_dispo;
  var ajust_gauche, nb_rdv_lig, tab_larg;
  var decalage_rdv_heure_col2 = 0;
  var titre = document.getElementsByTagName('H1');
//  ecrire_dans_console("La fenetre contient "+titre.length+" titres H1");
//  ecrire_dans_console("Le titre de la fenetre est : "+titre[0].firstChild.data);
  addCharsetUtf8InForm();
  if(titre[0].firstChild.data.indexOf('Calendrier') == -1) {
    return true;
  }
  args = recup_args();
  if(args.affichage_heure == null) {
    args.affichage_heure = 5;
    pas = 60*60*1000;
  }
  if(args.annee == null) {
    args.annee = document.forms[1].elements['annee'].value;
  }
  if(args.mois == null) {
//    ecrire_dans_console("Le paramùtre mois dans la ligne de commande est nul");
    args.mois = document.forms[1].elements['mois'].value;
  }
/*  else {
    ecrire_dans_console("Le paramùtre mois dans la ligne de commande est ùgale ù :"+args.mois);
  }*/
  if(args.jour == null) {
    args.jour = document.forms[1].elements['jour'].value;
  }
  nb_rdv = document.forms[1].elements['nb_rdv'].value;
//  ecrire_dans_console('La valeur du champs annùe est :'+args.annee+' la valeur du champs mois est :'+args.mois+'\nLa valeur du champs jour est :'+args.jour);

  aujourdhui_debut = new Date(args.annee, parseInt(args.mois, 10) - 1, args.jour);
  aujourdhui_fin = new Date(args.annee, parseInt(args.mois, 10) - 1, args.jour, 23, 59, 59);
//  ecrire_dans_console('La valeur de affichage_heure est :'+args.affichage_heure+'\naujourdhui est :'+aujourdhui_debut+' '+aujourdhui_fin);
//  var cadre =document.getElementById('cal_jour');
//  var elt = document.getElementsByName('rdv_heure_col1');
//  cadre.style.height = 24*cadre.firstChild.offsetHeight+'px';
//  var cadre_droit =document.getElementById('cal_droite');
//  cadre_droit.style.height = cadre.offsetHeight+'px';
  nb_rdv_lig = 0;
    if(args.affichage_heure == 5) {
      if(nb_rdv > 0) {
        parent_rdv = document.getElementById('cal_visu');
        list_div = parent_rdv.getElementsByTagName('div');
        for(var i = 0; i < list_div.length; i++) {
          if(list_div[i].className == 'rdv_heure_col1') {
            ajust_gauche = 3+list_div[i].offsetWidth;
          }
          if(list_div[i].className == 'rdv_heure_col2') {
            h_pas = list_div[i].offsetHeight;
            largeur_totale =list_div[i].offsetWidth - 6;
            break;
          }
        }
        nb_rdv_traite = 0;
        for(var j = 0; j < nb_rdv; j++) {
          id_rdv = 'rdv'+(j+1);
          rdv = document.getElementById(id_rdv);
          nb_rdv_lig = parseInt(document.forms[1].elements['nb_'+id_rdv].value, 10);
//          list_rdv_apres = document.forms[1].elements['apres_'+id_rdv].value.split(/\s+/);
//          list_rdv_avant = document.forms[1].elements['avant_'+id_rdv].value.split(/\s+/);
          decalage = parseFloat(document.forms[1].elements['droite_'+id_rdv].value);
          taille = parseFloat(document.forms[1].elements['taille_'+id_rdv].value);
//          list_rdv_apres = document.forms[1].elements['apres_'+id_rdv].value.split(/\s+/);
//          ecrire_dans_console('Liste des rdv aprùs = '+list_rdv_apres);
          largeur = largeur_totale*taille;
          rdv.style.left =  ajust_gauche + (decalage*largeur_totale)+'px';
//          ecrire_dans_console('La largeur de l\'ùlùment '+rdv.id+' est : '+largeur+'px, son dùcalage est de : '+decalage+'.\nSon parent a pour la largeur :'+parent_rdv.offsetWidth);
          rdv.style.width = largeur-4+'px';
// -parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10) + 1 car il faut tenir compte des bordures
// Pour assurer une parfaite portabilitù, il faudrait faire un test pour sur le type du browser
//		  ecrire_dans_console("haut = "+parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10));
//          rdv.style.top = 1 + decalage_rdv_heure_col2 + h_pas*parseInt(document.forms[1].elements['pos_'+id_rdv].value, 10) + document.getElementById('titre_rdv_jour').offsetHeight+'px';
          rdv.style.top = -4 + h_pas*parseInt(document.forms[1].elements['pos_'+id_rdv].value, 10) + document.getElementById('titre_rdv_jour').offsetHeight+'px';
          hauteur = parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10)*h_pas;
// -3 car il faut tenir compte des bordures des rdv et des lignes du calendrier pour un positionnement correct		  
          rdv.style.height = hauteur - 3+'px';
          rdv.style.border = '1px solid #FFDF80';
          rdv.style.zIndex = 1000 + j;
          rdv.style.backgroundColor = '#FFECB3';
		  largeur += 10;
		  hauteur += 10;
          rdv.style.clip = 'rect(0, '+largeur +'px, '+hauteur +'px, 0)';
          rdv.style.display = 'block';
        }
      }
    }


}

function valide_form_connexion(form) {
  if(form['login'].value == '') {
    ecrire_dans_console('Vous devez saisir un login');
    form['login'].focus();
    return false;
  }
  if(form['pswd'].value == '') {
    ecrire_dans_console('Vous devez saisir un mot de passe');
    form['pswd'].focus();
    return false;
  }

  return true;

}

function valide_login(elt) {
/*  if(elt.value.search(/^[a-z][a-z0-9]{3,}/) == -1) {
    ecrire_dans_console('Le login est incorrect. Il doit avoir au moins 4 caractùres.\nIl doit commencer obligatoirement par une lettre minuscule \net n\'avoir aucune majuscule');
    elt.focus();
    return false;
  }*/
  if((elt.value.length <= 3) ||
     (elt.value.length > 20) ||
     (elt.value.search(/^[0-9\.]/) == 0) ||
     (elt.value.search(/^[\d\s]*$/) == 0) ||
     (elt.value.search(/[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/) >= 0)) {
        ecrire_dans_console('Le login ne peut :\n -Ítre vide ou avoir une taille infÈrieure ‡ 3\n -avoir une taille supÈrieure ‡ 20\n -commencer par un chiffre ou par un point\n -Ítre une combinaison de blancs et de chiffres\n -comprendre des caractËres tels que :\n   $, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ');
        elt.focus();
        return false;
  }

  return true;

}

function valide_modif_compte(bouton) {
  var smenu = bouton.form.elements['smenu'].value;
//  ecrire_dans_console('Sous menu : '+smenu+' le bouton enfoncù est : '+bouton.name+' et sa valeur est '+bouton.value+' sa forme contient '+bouton.form.length+' ùlùments');
  try {
/*    var msg = '';
    for(var i = 0; i < bouton.form.length; i++) {
       msg += ' Elùment nù '+i+' : '+bouton.form.elements[i].name+ ' sa valeur : '+bouton.form.elements[i].value+'\n';
    }
    ecrire_dans_console('La liste des ùlùments du formulaire\n'+msg);
*/
    if(smenu == 'identification') {
      if(bouton.value == 'OK') {
        if((bouton.form.elements['nom'].value != bouton.form.elements['nom_old'].value) ||
           (bouton.form.elements['prenom'].value != bouton.form.elements['prenom_old'].value) ||
           (bouton.form.elements['login'].value != bouton.form.elements['login_old'].value)) {
          ecrire_dans_console('Vous avez modifiÈ certains champs dans le formulaire, vous ne pouvez utiliser le bouton OK :\n 1) -Soit vous dÈsirez sauvegarder vos modifications et quitter le menu, cliquer successivement sur les boutons Appliquer et OK\n 2) -Soit vous souhaitez quitter le menu sans sauvegarder vos modifications, cliquer successivement sur les boutons RÈtablir puis OK');
          return false;
        }
        return true;
      }
      else if(bouton.value == 'Appliquer') { // RÈalisation des tests
        if(bouton.form.elements['nom'].value != bouton.form.elements['nom_old'].value) {
          if((bouton.form.elements['nom'].value.length == 0) ||
             (bouton.form.elements['nom'].value.length > 20) ||
             (bouton.form.elements['nom'].value.search(/^[0-9\.\s]/) == 0) ||
             (bouton.form.elements['nom'].value.search(/^[\d\s]*$/) == 0) ||
             (bouton.form.elements['nom'].value.search(/[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/) >= 0)) {
                ecrire_dans_console('Le nom ne peut :\n -Ítre vide\n -avoir une taille supÈrieure ‡ 20\n -commencer par un chiffre, un espace ou par un point\n -Ítre une combinaison de blancs et de chiffres\n -comprendre des caractËres tels que :\n   $, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ');
                bouton.form.elements['nom'].focus();
                return false;
          }
        }
        if(bouton.form.elements['prenom'].value != bouton.form.elements['prenom_old'].value) {
          if((bouton.form.elements['prenom'].value.length == 0) ||
             (bouton.form.elements['prenom'].value.length > 20) ||
             (bouton.form.elements['prenom'].value.search(/^[0-9\.\s]/) == 0) ||
             (bouton.form.elements['prenom'].value.search(/^[\d\s]*$/) == 0) ||
             (bouton.form.elements['prenom'].value.search(/[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/) >= 0)) {
                ecrire_dans_console('Le prÈnom ne peut :\n -Ítre vide\n -avoir une taille supÈrieure ‡ 20\n -commencer par un chiffre, un espace ou par un point\n -Ítre une combinaison de blancs et de chiffres\n -comprendre des caractËres tels que :\n   $, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ');
                bouton.form.elements['prenom'].focus();
                return false;
          }
        }
        if(bouton.form.elements['login'].value != bouton.form.elements['login_old'].value) {
          if((bouton.form.elements['login'].value.length <= 3) ||
             (bouton.form.elements['login'].value.length > 20) ||
             (bouton.form.elements['login'].value.search(/^[0-9\.\s]/) == 0) ||
             (bouton.form.elements['login'].value.search(/^[\d\s]*$/) == 0) ||
             (bouton.form.elements['login'].value.search(/[\$\^\/\\=\+\#\{\}\"\(\)\[\]\|\`\!\?\,\;\:]/) >= 0)) {
                ecrire_dans_console('Le login ne peut :\n -Ítre vide ou avoir une taille infÈrieure ‡ 4\n -avoir une taille supÈrieure ‡ 20\n -commencer par un chiffre, un espace ou par un point\n -Ítre une combinaison de blancs et de chiffres\n -comprendre des caractËres tels que :\n   $, ^, \\, /, +, =, \(, \), [, ], {, }, \", #, |,\`, !,?, ,, ;, : etc. ');
                bouton.form.elements['login'].focus();
                return false;
          }
        }
        return true;
      }// Fin du if('Appliquer')
    } // Fin du if('identification')
    else if(smenu == 'communication') {
      if(bouton.value == 'OK') {
        if((bouton.form.elements['mail_mission'].value != bouton.form.elements['mail_mission_old'].value) ||
           (bouton.form.elements['tel_mission'].value != bouton.form.elements['tel_mission_old'].value) ||
           (bouton.form.elements['tel_perso'].value != bouton.form.elements['tel_perso_old'].value)) {
          ecrire_dans_console('Vous avez modifiÈ certains champs dans le formulaire, vous ne pouvez utiliser le bouton OK :\n 1) -Soit vous dÈsirez sauvegarder vos modifications et quitter le menu, cliquer successivement sur les boutons Appliquer et OK\n 2) -Soit vous souhaitez quitter le menu sans sauvegarder vos modifications, cliquer successivement sur les boutons RÈtablir puis OK');
          return false;
        }
        return true;
      }
    else if(bouton.value == 'Appliquer') {

        if(bouton.form.elements['mail_mission'].value != bouton.form.elements['mail_mission_old'].value) {
          if(!((bouton.form.elements['mail_mission'].value.search(/^[a-zA-Z]([\w\-\.]*[\w]+)*@[a-zA-Z]([\w\-\.]*[\w]+)*\.[a-zA-Z]+$/) == 0) &&
             (bouton.form.elements['mail_mission'].value.length > 0) &&
             (bouton.form.elements['mail_mission'].value.length < 101))) {
                bouton.form.elements['mail_mission'].focus();
                ecrire_dans_console('L\'adresse mail est incorrecte.\n\nElle doit Ítre de la forme nom@domaine.ext avec\n -nom : mot.mot.---.mot,\n -domaine : mot.mot.---.mot,\n -ext : mot');
                return false;
          }
        }
        if(bouton.form.elements['tel_mission'].value != bouton.form.elements['tel_mission_old'].value) {
          if(!((bouton.form.elements['tel_mission'].value.length >0) &&
           (bouton.form.elements['tel_mission'].value.length < 11) &&
               (bouton.form.elements['tel_mission'].value.search(/^\d{10}$/)== 0))) {
                  bouton.form.elements['tel_mission'].focus();
                  ecrire_dans_console('Le champ TÈl mission est incorrect.\nIl doit obligatoirement comporter un nombre de 10 chiffres');
                  return false;
          }
        }
        if(bouton.form.elements['tel_perso'].value != bouton.form.elements['tel_perso_old'].value) {
          if(!((bouton.form.elements['tel_perso'].value.length >0) &&
               (bouton.form.elements['tel_perso'].value.length < 11) &&
               (bouton.form.elements['tel_perso'].value.search(/^\d{10}$/) == 0))) {
                  bouton.form.elements['tel_perso'].focus();
                  ecrire_dans_console('Le champ TÈl perso est incorrect.\nIl doit obligatoirement comporter un nombre de 10 chiffres');
                  return false;
          }
        }
        return true;
      }// fin du if('Appliquer')
    }// fin du if('communication')
    else if(smenu == 'mot_de_passe') {
          if(bouton.value == 'OK') {
            if((bouton.form.elements['pswd_actuel'].value.length > 0) ||
               (bouton.form.elements['pswd_new1'].value.length > 0) ||
               (bouton.form.elements['pswd_new2'].value.length > 0)) {
                  ecrire_dans_console('Vous avez modifiÈ certains champs dans le formulaire, vous ne pouvez utiliser le bouton OK :\n 1) -Soit vous dÈsirez sauvegarder vos modifications et quitter le menu, cliquer successivement sur les boutons Appliquer et OK\n 2) -Soit vous souhaitez quitter le menu sans sauvegarder vos modifications, cliquer successivement sur les boutons RÈtablir puis OK');
                  return false;
             }
             return true;
          }
          if(bouton.value == 'Appliquer') {
            if((bouton.form.elements['pswd_new1'].value != bouton.form.elements['pswd_new2'].value) ||
               (bouton.form.elements['pswd_new1'].value.length <= 3) ||
               (bouton.form.elements['pswd_new1'].value.length <= 3)) {
                 ecrire_dans_console('Erreur avec le nouveau mot de passe : \n -Soit le deuxiËme mot de passe saisi ne correspond pas au premier\n -Soit sa taile est infÈrieure 4');
                 return false;
               }
            return true;
          }
    }
  }
  catch(e) {
//    ecrire_dans_console(e);
    if(e instanceof Error) {
      ecrire_dans_console(e.name+': '+e.message);
    }
  }
  return true;
}
/**** Fonctions utilisÈes par ra.pl *****************/
var vcourante = ' ';
var valeur_pred;
var msg = '';
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

function calcul_nb_presence(elt) {
  var valeur = elt.value;
  var v, locale, ret1, ret2;
//  ecrire_dans_console('DÈbut de calcul_nb_presence()\n La valeur de vcourante est : '+vcourante+'\n La valeur de valeur_pred est : '+valeur_pred);
  valeur_pred = vcourante;
  vcourante = valeur;
//  msg += '\ncalcul_nb_presence() : valeur = '+valeur+ ' vcourante = '+vcourante+' valeur_pred = '+valeur_pred;
//  ecrire_dans_console(msg);
  if(((ret1 = elt.name.search(/^pmatin_/))== 0) || ((ret2 = elt.name.search(/^paprem_/))== 0)) {
    switch(valeur) {
      case ' ':
      case '0' :
        // ecrire_dans_console('Le compteur a modifiÈ est nb_dispo. Sa valeur est'+elt.form.elements['nb_dispo'].value);
        v = Number(elt.form.elements['nb_dispo'].value);
        v += 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_dispo'].value = v;// ‡ cause de l'arrondi
        break;
     case '1' :
     case '2' :
        // ecrire_dans_console('Le compteur a modifiÈ est nb_presence. Sa valeur est'+elt.form.elements['nb_presence'].value);
        v = Number(elt.form.elements['nb_presence'].value);
        v += 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_presence'].value = v;// ‡ cause de l'arrondi
       break;
     case '3':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_cp. Sa valeur est'+elt.form.elements['nb_cp'].value);
        v = Number(elt.form.elements['nb_cp'].value);
        v += 0.5;
        // // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_cp'].value = v;// ‡ cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v+= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
      case '4':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_rtt. Sa valeur est'+elt.form.elements['nb_rtt'].value);
        v = Number(elt.form.elements['nb_rtt'].value);
        v += 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_rtt'].value = v;// ‡ cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v+= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '5':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_maladie. Sa valeur est'+elt.form.elements['nb_maladie'].value);
        v = Number(elt.form.elements['nb_maladie'].value);
        v += 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_maladie'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v+= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '6':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_recup. Sa valeur est'+elt.form.elements['nb_recup'].value);
        v = Number(elt.form.elements['nb_recup'].value);
        v += 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_recup'].value = v;// ‡ cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v+= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '7':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_formation. Sa valeur est'+elt.form.elements['nb_formation'].value);
        v = Number(elt.form.elements['nb_formation'].value);
        v += 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_formation'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v+= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '8':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_excep. Sa valeur est'+elt.form.elements['nb_excep'].value);
        v = Number(elt.form.elements['nb_excep'].value);
        v += 0.5;
        elt.form.elements['nb_excep'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v+= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '9':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_sssolde. Sa valeur est'+elt.form.elements['nb_sssolde'].value);
        v = Number(elt.form.elements['nb_sssolde'].value);
        v += 0.5;
        elt.form.elements['nb_sssolde'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v+= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
    }
    switch(valeur_pred) {
      case ' ':
      case '0' :
        // ecrire_dans_console('Le compteur a modifiÈ est nb_dispo. Sa valeur est'+elt.form.elements['nb_dispo'].value);
        v = Number(elt.form.elements['nb_dispo'].value);
        v -= 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_dispo'].value = v;// ù cause de l'arrondi
        break;
     case '1' :
     case '2' :
        // ecrire_dans_console('Le compteur a modifiÈ est nb_presence. Sa valeur est'+elt.form.elements['nb_presence'].value);
        v = Number(elt.form.elements['nb_presence'].value);
        v -= 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_presence'].value = v;// ù cause de l'arrondi
       break;
     case '3':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_cp. Sa valeur est'+elt.form.elements['nb_cp'].value);
        v = Number(elt.form.elements['nb_cp'].value);
        v -= 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_cp'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v -= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
      case '4':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_rtt. Sa valeur est'+elt.form.elements['nb_rtt'].value);
        v = Number(elt.form.elements['nb_rtt'].value);
        v -= 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_rtt'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v -= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '5':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_maladie. Sa valeur est'+elt.form.elements['nb_maladie'].value);
        v = Number(elt.form.elements['nb_maladie'].value);
        v -= 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_maladie'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v -= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '6':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_recup. Sa valeur est'+elt.form.elements['nb_recup'].value);
        v = Number(elt.form.elements['nb_recup'].value);
        v -= 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_recup'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v -= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '7':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_formation. Sa valeur est'+elt.form.elements['nb_formation'].value);
        v = Number(elt.form.elements['nb_formation'].value);
        v -= 0.5;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        elt.form.elements['nb_formation'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v -= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '8':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_excep. Sa valeur est'+elt.form.elements['nb_excep'].value);
        v = Number(elt.form.elements['nb_excep'].value);
        v -= 0.5;
        elt.form.elements['nb_excep'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v -= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;
     case '9':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_sssolde. Sa valeur est'+elt.form.elements['nb_sssolde'].value);
        v = Number(elt.form.elements['nb_sssolde'].value);
        v -= 0.5;
        elt.form.elements['nb_sssolde'].value = v;// ù cause de l'arrondi
        v = Number(elt.form.elements['nb_absence'].value);
        v -= 0.5;
        elt.form.elements['nb_absence'].value = v;
       break;

     default :
//     ecrire_dans_console('La valeur de vcourante est :'+vcourante_locale);
    }
  }
  else if((ret1 = elt.name.search(/^hsup0_/))== 0){
    if(valeur == '+') {
      hsup_autres_valeurs(elt);
    }
    else {
      v = Number(elt.form.elements['nb_hsup0'].value);
      if(valeur_pred == '+') {
//        ecrire_dans_console('La valeur de valeur_pred est \' \'\nLa valeur de valeur est '+valeur);
        v = v + Number(valeur);
      }
      else {
        v = v -Number(valeur_pred) + Number(valeur);
//        ecrire_dans_console('La valeur de valeur_pred est '+valeur_pred+'\n La valeur de valeur est :'+valeur);
      }
      elt.form.elements['nb_hsup0'].value = v;
      if(data_save.length > 0) {
        vide_data_save();
      }
    }
  }
  else if((ret1 = elt.name.search(/^hsup25_/))== 0){
    if(valeur == '+') {
      hsup_autres_valeurs(elt);
    }
    else {
      v = Number(elt.form.elements['nb_hsup25'].value);
      if(valeur_pred == '+') {
//        ecrire_dans_console('La valeur de valeur_pred est \' \'\nLa valeur de valeur est '+valeur);
        v = v + Number(valeur);
      }
      else {
        v = v -Number(valeur_pred) + Number(valeur);
//        ecrire_dans_console('La valeur de valeur_pred est '+valeur_pred+'\n La valeur de valeur est :'+valeur);
      }
      elt.form.elements['nb_hsup25'].value = v;
      if(data_save.length > 0) {
        vide_data_save();
      }
    }
  }
  else if((ret1 = elt.name.search(/^hsup50_/))== 0){
    if(valeur == '+') {
      hsup_autres_valeurs(elt);
    }
    else {
      v = Number(elt.form.elements['nb_hsup50'].value);
      if(valeur_pred == '+') {
//        ecrire_dans_console('La valeur de valeur_pred est \' \'\nLa valeur de valeur est '+valeur);
        v = v + Number(valeur);
      }
      else {
        v = v -Number(valeur_pred) + Number(valeur);
//        ecrire_dans_console('La valeur de valeur_pred est '+valeur_pred+'\n La valeur de valeur est :'+valeur);
      }
      elt.form.elements['nb_hsup50'].value = v;
      if(data_save.length > 0) {
        vide_data_save();
      }
    }
  }
  else if((ret1 = elt.name.search(/^hsup100_/))== 0){
    if(valeur == '+') {
      hsup_autres_valeurs(elt);
    }
    else {
      v = Number(elt.form.elements['nb_hsup100'].value);
      if(valeur_pred == '+') {
//        ecrire_dans_console('La valeur de valeur_pred est \' \'\nLa valeur de valeur est '+valeur);
        v = v + Number(valeur);
      }
      else {
        v = v -Number(valeur_pred) + Number(valeur);
//        ecrire_dans_console('La valeur de valeur_pred est '+valeur_pred+'\n La valeur de valeur est :'+valeur);
      }
      elt.form.elements['nb_hsup100'].value = v;
      if(data_save.length > 0) {
        vide_data_save();
      }
    }
  }
}

function valeur_courante(elt) {
  vcourante = elt.value;
//  msg += '\nvaleur_courante() : valeur = '+elt.value+ ' vcourante = '+vcourante+' valeur_pred = '+valeur_pred;
//  ecrire_dans_console(msg);
}
var data_save = [];
var win;

function hsup_autres_valeurs(elt) {
  var v;
  var args = recup_args();
  if(elt.name.search(/^hsup0_/)== 0){
     v = Number(elt.form.elements['nb_hsup0'].value);
     v = v -Number(valeur_pred);
     elt.form.elements['nb_hsup0'].value = v;
  }
  else if(elt.name.search(/^hsup25_/)== 0){
     v = Number(elt.form.elements['nb_hsup25'].value);
     v = v -Number(valeur_pred);
     elt.form.elements['nb_hsup25'].value = v;
  }
  else if(elt.name.search(/^hsup50_/)== 0){
     v = Number(elt.form.elements['nb_hsup50'].value);
     v = v -Number(valeur_pred);
    elt.form.elements['nb_hsup50'].value = v;
  }
  else if(elt.name.search(/^hsup100_/)== 0){
     v = Number(elt.form.elements['nb_hsup100'].value);
     v = v -Number(valeur_pred);
     elt.form.elements['nb_hsup100'].value = v;
  }
//  ecrire_dans_console('Le tableau option a '+elt.options.length+' ÈlÈments.\Son dernier ÈlÈment a pour texte : '+elt.options[elt.options.length - 1].text+'\nLe tableau data_save a '+data_save.length+' ÈlÈments.\nValeur_pred est Ègale ‡ '+valeur_pred);
  if(data_save.length == 0) {
    data_save.push(elt, vcourante, valeur_pred);
    win = window.open(base+"/hsupplus.pl?elt="+data_save[0].name+"&mois="+args.mois+"&annee="+args.annee, "heures_sup", "resizable, status, width=400, height=200");
    win.focus();
  }
  else {
    if(data_save[0].name != elt.name) {
      ecrire_dans_console('Votre demande d\'ajout d\'une nouvelle option dans la liste des choix pour l\'ÈlÈment '+elt.name+' ne peut aboutir.\nIl y a dÈja une demande du mÍme type en cours et non complÈtÈe pour l\'ÈlÈment '+data_save[0].name+'\n\nVous devez terminer cette action avant d\'envisager d\'en ajouter pour l\'ÈlÈment '+elt.name+'.\nVous pouvez :\n-Soit choisir une option et cliquer sur le bouton \'OK\'.\n-Soit fermer la fenÍtre en cliquant sur le bouton \'Fermer\'.');
      elt.value = valeur_pred;

      if(elt.name.search(/^hsup0_/)== 0){
        v = Number(elt.form.elements['nb_hsup0'].value);
        v = v +Number(valeur_pred);
        elt.form.elements['nb_hsup0'].value = v;
      }
      else if(elt.name.search(/^hsup25_/)== 0){
        v = Number(elt.form.elements['nb_hsup25'].value);
        v = v +Number(valeur_pred);
        elt.form.elements['nb_hsup25'].value = v;
      }
      else if(elt.name.search(/^hsup50_/)== 0){
        v = Number(elt.form.elements['nb_hsup50'].value);
        v = v +Number(valeur_pred);
        elt.form.elements['nb_hsup50'].value = v;
      }
      else if(elt.name.search(/^hsup100_/)== 0){
        v = Number(elt.form.elements['nb_hsup100'].value);
        v = v +Number(valeur_pred);
        elt.form.elements['nb_hsup100'].value = v;
      }
    }
    if(win.closed == true) {
      win = window.open(base+"/hsupplus.pl?elt="+data_save[0].name+"&mois="+args.mois+"&annee="+args.annee, "heures_sup", "resizable, status, width=400, height=200");
    }
    win.focus();
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
      ecrire_dans_console('unescape(): ProblËme de codage avec la valeur de '+nom+' Ègale ‡ '+valeur);
      try {
        args[nom] = decodeURIComponent(valeur);
      }
      catch(e) {
        args[nom] = valeur;
        ecrire_dans_console('decodeURIComponent(): ProblËme de codage avec la valeur de '+nom+' Ègale ‡ '+args[nom]);
      }
      finally {
        ecrire_dans_console('Le dÈcodage pour la valeur de '+nom+ ' est Ègale ‡ '+args[nom]);
      }
    }
  }
  return args;
}

function ajouter(elt) {
  elt.options[elt.options.length] = new Option('+', '+', false, false);
}

function vide_data_save() {
  var lg = data_save.length;
//  ecrire_dans_console('Taille de data_save avant la fonction : '+data_save.length);
  for(var i = 0; i < lg; i++) {
    data_save.pop();
  }
//  ecrire_dans_console('Taille de data_save aprùs la fonction : '+data_save.length);
}


function bascule_astreinte(bouton) { // ce sontdes cases ù cocher
  var tab_case = bouton.form.elements[bouton.name];
  var valeur;
  for(var i = 0; i < tab_case.length; i++) {
    if((tab_case[i].checked == true) && (bouton.value != i + 1)) {
      tab_case[i].checked = false;
//      ecrire_dans_console('il faut diminuer de 1 la valeur de nb_ast'+(i+1));
     valeur = bouton.form.elements['nb_ast'+(i+1)].value;
      valeur--;
      bouton.form.elements['nb_ast'+(i+1)].value = valeur;
    }
    else if((tab_case[i].checked == true) && (bouton.value == i + 1)) {
//      ecrire_dans_console('il faut augmenter de 1 la valeur de nb_ast'+(i+1));
      valeur = bouton.form.elements['nb_ast'+(i+1)].value;
      valeur++;
      bouton.form.elements['nb_ast'+(i+1)].value = valeur;
    }
    else if((tab_case[i].checked == false) && (bouton.value == i + 1)) {
//      ecrire_dans_console('il faut diminuer de 1 la valeur de nb_ast'+(i+1));
      valeur = bouton.form.elements['nb_ast'+(i+1)].value;
      valeur--;
      bouton.form.elements['nb_ast'+(i+1)].value = valeur;
    }
  }
}

function visualiser_ra() {
  var rep = confirm(encode('Veillez ‡ enregistrer vos donnÈes nouvellement saisies car elles seront irrÈmÈdiablement perdues.\n\tSouhaitez-vous continuer la visualisation du rapport d\'activitÈs ?'));
  return rep;
}

function supprimer_ra() {
  var rep = confirm('La suppression d\'un rapport d\'activitÈs entraine la perte de toutes les donnÈes saisies dans celui-ci.\n\tSouhaitez-vous supprimer ce rapport d\'activitÈs ?');
  return rep;
}



function fermer_fenetre(opt) {
  if(opt == 1) {
    var rep = confirm('Si vous fermez cette fenÍtre sans avoir sauvegardÈ les donnÈes,\nvous risquez de perdre les modifications effectuÈes.\n\nVoulez-vous fermer cette fenÍtre ?');
    if(rep == true) {
      close();
    }
  }
  else {
    close();
  }
  return false;
}

function imprimer_ra(opt) {
  if(opt == 1) {
    var rep = confirm('Attention : Assurez-vous que vous avez sauvegardÈes les modifications rÈalisÈes.\nDans le cas contraire, elles seront irrÈmÈdiablement perdues.\n\nVoulez-vous continuer l\'impression?');
    if(rep == true) {
	  return true;
    }
    else {
      return false;
    }
  }
  else {
    window.print();
    return false;
  }
    
}

function imprimer_facture(opt) {
  ecrire_dans_console('impression facture');
  let menuBouton = document.getElementById('menu_actions');
  //menuBouton.style.display = 'none';
  window.print();
  //menuBouton.style.display = 'block';
  return false;
}

function verifDateFacture() {
  var dateCreationFacture = document.getElementById('dateCreationFacture');
  if (dateCreationFacture.value == null || dateCreationFacture.value == '') {
    alert('La saisie d\'une date de la facture est obligatoire.');
    return false;
  }   
  return true;
}

function remplissage_presence_ts(bouton) {
  var pres = bouton.form;
  var sel = pres['bo_selectionner'];
  var remplir = pres['bo_remplir'];
  var nb_jours = pres['nb_jours'].value;
  var pres_matin, pres_aprem;
  var selection = pres['bo_selectionner'];
  var v, cpte = 0;
  var rep = confirm('Vous allez remplir les cellules contenant \n\"'+sel.options[selection.selectedIndex].text+'\" avec \"'+remplir.options[remplir.selectedIndex].text+'\"\nEtes-vous d\'accord ?');
  if(rep == true) {
//  AfficheNomsProprietes(selection.options[selection.selectedIndex]);
    for(var i = 1; i <= nb_jours; i++) {
      pres_matin = 'pmatin_'+i;
      pres_aprem = 'paprem_'+i;
      if((pres[pres_matin.toString()] != null) && (pres[pres_matin.toString()].value == sel.value)) {
        pres[pres_matin.toString()].value = remplir.value;
        cpte+=0.5;
      }
      if((pres[pres_aprem.toString()] != null) && (pres[pres_aprem.toString()].value == sel.value)){
        pres[pres_aprem.toString()].value = remplir.value;
        cpte+=0.5;
      }
    }
    ecrire_dans_console('La valeur de cpte est : '+cpte+'\nLa valeur de la selection est : '+sel.value+'\nLa valeur de remplir est :'+remplir.value);
    switch(sel.value) {
      case ' ':
      case '0':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_dispo. Sa valeur est'+pres['nb_dispo'].value);
        v = Number(pres['nb_dispo'].value);
        v -= cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_dispo'].value = v;// ù cause de l'arrondi
        break;
     case '1' :
     case '2' :
        // ecrire_dans_console('Le compteur a modifiÈ est nb_presence. Sa valeur est'+pres['nb_presence'].value);
        v = Number(pres['nb_presence'].value);
        v -= cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_presence'].value = v;// ù cause de l'arrondi
       break;
     case '3':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_cp. Sa valeur est'+pres['nb_cp'].value);
        v = Number(pres['nb_cp'].value);
        v -= cpte;
        // // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_cp'].value = v;// ù cause de l'arrondi
       break;
      case '4':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_rtt. Sa valeur est'+pres['nb_rtt'].value);
        v = Number(pres['nb_rtt'].value);
        v -= cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_rtt'].value = v;// ù cause de l'arrondi
       break;
     case '5':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_maladie. Sa valeur est'+pres['nb_maladie'].value);
        v = Number(pres['nb_maladie'].value);
        v -= cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_maladie'].value = v;// ù cause de l'arrondi
       break;
     case '6':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_recup. Sa valeur est'+pres['nb_recup'].value);
        v = Number(pres['nb_recup'].value);
        v -= cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_recup'].value = v;// ù cause de l'arrondi
       break;
     case '7':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_formation. Sa valeur est'+pres['nb_formation'].value);
        v = Number(pres['nb_formation'].value);
        v -= cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_formation'].value = v;// ù cause de l'arrondi
       break;
     case '8':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_excep. Sa valeur est'+pres['nb_excep'].value);
        v = Number(pres['nb_excep'].value);
        v -= cpte;
        pres['nb_excep'].value = v;// ù cause de l'arrondi
       break;
     case '9':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_sssolde. Sa valeur est'+pres['nb_sssolde'].value);
        v = Number(pres['nb_sssolde'].value);
        v -= cpte;
        pres['nb_sssolde'].value = v;// ù cause de l'arrondi
       break;
    }
    switch(remplir.value) {
      case ' ':
      case '0':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_dispo. Sa valeur est'+pres['nb_dispo'].value);
        v = Number(pres['nb_dispo'].value);
        v += cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_dispo'].value = v;// ù cause de l'arrondi
        break;
     case '1' :
     case '2' :
        // ecrire_dans_console('Le compteur a modifiÈ est nb_presence. Sa valeur est'+pres['nb_presence'].value);
        v = Number(pres['nb_presence'].value);
        v += cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_presence'].value = v;// ù cause de l'arrondi
       break;
     case '3':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_cp. Sa valeur est'+pres['nb_cp'].value);
        v = Number(pres['nb_cp'].value);
        v += cpte;
        // // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_cp'].value = v;// ù cause de l'arrondi
       break;
      case '4':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_rtt. Sa valeur est'+pres['nb_rtt'].value);
        v = Number(pres['nb_rtt'].value);
        v += cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_rtt'].value = v;// ù cause de l'arrondi
       break;
     case '5':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_maladie. Sa valeur est'+pres['nb_maladie'].value);
        v = Number(pres['nb_maladie'].value);
        v += cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_maladie'].value = v;// ù cause de l'arrondi
       break;
     case '6':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_recup. Sa valeur est'+pres['nb_recup'].value);
        v = Number(pres['nb_recup'].value);
        v += cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_recup'].value = v;// ù cause de l'arrondi
       break;
     case '7':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_formation. Sa valeur est'+pres['nb_formation'].value);
        v = Number(pres['nb_formation'].value);
        v += cpte;
        // ecrire_dans_console('La nouvelle valeur de v est : '+v);
        pres['nb_formation'].value = v;// ù cause de l'arrondi
       break;
     case '8':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_excep. Sa valeur est'+pres['nb_excep'].value);
        v = Number(pres['nb_excep'].value);
        v += cpte;
        pres['nb_excep'].value = v;// ù cause de l'arrondi
       break;
     case '9':
        // ecrire_dans_console('Le compteur a modifiÈ est nb_sssolde. Sa valeur est'+pres['nb_sssolde'].value);
        v = Number(pres['nb_sssolde'].value);
        v += cpte;
        pres['nb_sssolde'].value = v;// ù cause de l'arrondi
       break;
    }
  }
  return false;
}

function remplissage_presence(bouton) {
  ecrire_dans_console('La fonction Remplir est actionn\xE9e');
  var pres = bouton.form;
//  var sel = bouton.form.elements[selection.toString()];
  var sel = pres['selection'];
  var nb_jours = pres['nb_jours'].value;
  var list_arg = pres['list_arg'].value;
  var client, client_id;
  var pres_matin, pres_aprem;
  var sel_id, bvalue;
  var cpte_pres = 0;
  var cpte_dispo = 0;
  var cpte = 0;

  for(var i = 0; i < sel.length; i++) {
    if(sel[i].checked == true) {
      sel_id = i;
      break;
    }
  }
  bvalue = (bouton.value == -1) ? ' ' : bouton.value;
  var tvalue = (sel_id == 1) ? ' ' :
               (sel_id == 2) ? '1' :
               (sel_id == 3) ?'0' : sel_id.toString();
  cpte_pres = Number(pres['nb_presence'].value);
  cpte_dispo = Number(pres['nb_dispo'].value);
  ecrire_dans_console('sel_id prend la valeur '+sel_id+'. La valeur de bvaleur est '+bvalue);
  if(sel_id == 0) {// tous les champs sont sùlectionnùs
    for (var i = 1; i <= nb_jours; i++) {
       pres_matin = 'pmatin_'+i;
       pres_aprem = 'paprem_'+i;
	   //ecrire_dans_console('La valeur de pres[pres_matin] est'+pres[pres_matin.toString()].value);
       if((pres[pres_matin.toString()] != null) && (pres[pres_matin.toString()].value != bvalue)){
         if((bvalue == '1') && ((pres[pres_matin.toString()].value == ' ') || (pres[pres_matin.toString()].value == '0'))) {
           cpte += 0.5;
         }
         if(((bvalue == '0') || (bvalue == ' ')) && (pres[pres_matin.toString()].value == '1')) {
           cpte += 0.5;
         }
         pres[pres_matin.toString()].value = bvalue;
       }
       if((pres[pres_aprem.toString()] != null)&& (pres[pres_aprem.toString()].value != bvalue)) {
         if((bvalue == '1') && ((pres[pres_aprem.toString()].value == ' ') || (pres[pres_aprem.toString()].value == '0'))) {
           cpte += 0.5;
         }
         if(((bvalue == '0') || (bvalue == ' ')) && (pres[pres_aprem.toString()].value == '1')) {
           cpte += 0.5;
         }
         pres[pres_aprem.toString()].value = bvalue;
       }
    }
    switch(bvalue) {
      case ' ':
      case '0':
        cpte_pres -= cpte;
        pres['nb_presence'].value  = cpte_pres;
        cpte_dispo += cpte;
        pres['nb_dispo'].value = cpte_dispo;
        break;
      case '1':
        cpte_pres += cpte;
        pres['nb_presence'].value  = cpte_pres;
        cpte_dispo -= cpte;
        pres['nb_dispo'].value = cpte_dispo;
        break;
    }
  }
  else {
    for(var i = 1; i <= nb_jours; i++) {
      pres_matin = 'pmatin_'+i;
      pres_aprem = 'paprem_'+i;
      if((pres[pres_matin.toString()] != null) && (pres[pres_matin.toString()].value == tvalue)) {
         if((bvalue == '1') && ((pres[pres_matin.toString()].value == ' ') || (pres[pres_matin.toString()].value == '0'))) {
           cpte += 0.5;
         }
         if(((bvalue == '0') || (bvalue == ' ')) && (pres[pres_matin.toString()].value == '1')) {
           cpte += 0.5;
         }
        pres[pres_matin.toString()].value = bvalue;
      }

      if((pres[pres_aprem.toString()] != null) && (pres[pres_aprem.toString()].value == tvalue)){
         if((bvalue == '1') && ((pres[pres_aprem.toString()].value == ' ') || (pres[pres_aprem.toString()].value == '0'))) {
           cpte += 0.5;
         }
         if(((bvalue == '0') || (bvalue == ' ')) && (pres[pres_aprem.toString()].value == '1')) {
           cpte += 0.5;
         }
        pres[pres_aprem.toString()].value = bvalue;
      }
    }
    switch(bvalue) {
      case ' ':
      case '0':
          cpte_pres -= cpte;
          pres['nb_presence'].value  = cpte_pres;
          cpte_dispo += cpte;
          pres['nb_dispo'].value = cpte_dispo;
        break;
      case '1':
          cpte_pres += cpte;
          pres['nb_presence'].value  = cpte_pres;
          cpte_dispo -= cpte;
          pres['nb_dispo'].value = cpte_dispo;
        break;
    }
  }
}
var ligne_creation = -1;
var nb_maj = 0; // nb_max_maj = 3 pour  edition
function ra_charge(){
  var args = recup_args();
  focus();
  if(!(args.maj === undefined)) {
//    ecrire_dans_console('Le parametre maj existe dans l\'URL '+location.search.substring(1));
    var racine = opener.document.getElementById('ra_ecran_mensuel');
//    ecrire_dans_console('Le nodeName de racine est : '+racine.nodeName+' son Id est : '+racine.id+' Son nobre d\'enfants est Ègale ‡ : '+racine.childNodes.length);
    if(args.action == 'edition') {// Modification de la ligne de 'crÈation'
      var elt_a = opener.document.createElement("a");
      var text_a = opener.document.createTextNode(args.maj);
      elt_a.appendChild(text_a);
      var url = location.href;
      url = url.replace(/&maj=.*$/, '');
      elt_a.setAttribute("title", 'Editer');
      elt_a.setAttribute("target", 'Edition');
      elt_a.setAttribute("href", url);
      //ecrire_dans_console('Valeur href de elt_a : '+elt_a.getAttribute("href")+'\nValeur de title : '+elt_a.title+'\nValeur de text : '+elt_a.firstChild.nodeValue+'\nValeur de target : '+elt_a.target);
      var frag = opener.document.createDocumentFragment();
      var a_edit = opener.document.createElement("a");
      a_edit.setAttribute("target", 'Edition');
      a_edit.setAttribute("href", url);
      var edit_img = opener.document.createElement("img");
      edit_img.setAttribute("alt", 'Editer-'+args.maj);
      edit_img.setAttribute("title", 'Editer');
      edit_img.setAttribute("src", base+'/images/page_edit.png');
      a_edit.appendChild(edit_img);
      frag.appendChild(a_edit);
      frag.appendChild(opener.document.createTextNode(unescape('%20')));
      var a_del = opener.document.createElement("a");
      a_del.setAttribute("target", 'Suppression');
      var url_del = url.replace(/edition/, 'suppression');
	    url_del = url.replace(/show.pl/, 'delete.pl');
      a_del.setAttribute("href", url_del);
      var del_img = opener.document.createElement("img");
      del_img.setAttribute("alt", 'Supprimer-'+args.maj);
      del_img.setAttribute("title", 'Supprimer');
      del_img.setAttribute("src", base+'/images/page_delete.png');
      a_del.appendChild(del_img);
      frag.appendChild(a_del);
      if(args.maj != 'Technologies et Services' && args.maj != 'Global') {
        frag.appendChild(opener.document.createTextNode(unescape('%20')));
        var a_facture = opener.document.createElement("a");
        a_facture.setAttribute("target", 'Facturation');
        var url_facture = url;
        url_facture = url_facture.replace(/edition/, 'creation');
        url_facture = url_facture.replace(/show.pl/, 'facture.pl');
        a_facture.setAttribute("href", url_facture);
        var facture_img = opener.document.createElement("img");
        facture_img.setAttribute("alt", 'Facturer-'+args.maj);
        facture_img.setAttribute("title", 'Facturer');
        facture_img.setAttribute("src", base+'/images/euro-16.png');
        a_facture.appendChild(facture_img);
        frag.appendChild(a_facture);
      }
      var text_edit = opener.document.createTextNode('A valider');
    }
    var enfants = racine.childNodes;
    //On ne tient pas compte des 2 premiùres lignes du tableau
    for(var i = 2; i < enfants.length; i++) {
      if(nb_maj < 3) {
        //ecrire_dans_console('indice = '+i+' : Son parent est : '+enfants[i].parentNode.nodeName+' avec pour Id : '+enfants[i].parentNode.id+' et pour class : '+enfants[i].parentNode.className);
        if(enfants[i].className ==  'ra_ligne3col') {
          traite_ra_ligne3col(enfants[i], i, args, elt_a, frag, text_edit);
        }
      }
      else {
        return;
      }
    }
  }
}

function traite_ra_ligne3col(obj, lg, args, elt_a, frag, text_edit) {
  var enfants = obj.childNodes;
  for(var i = 0; i < enfants.length; i++) {
    if(enfants[i].nodeName == 'A') {
      //ecrire_dans_console('enfants[i].nodeName = '+enfants[i].nodeName+', enfants['+i+'].firstChild.nodeType = '+enfants[i].firstChild.nodeType);
      if(enfants[i].firstChild.nodeType == Node.TEXT_NODE) {
        if((enfants[i].title == 'CrÈer') && (enfants[i].target == 'Creation')&& (enfants[i].firstChild.data == args.maj)) {
//          ecrire_dans_console('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+' Son texte est '+enfants[i].firstChild.nodeValue);
          enfants[i].parentNode.replaceChild(elt_a, enfants[i]);
          ligne_creation = lg;
          nb_maj++;
//          ecrire_dans_console('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url modifiÈ est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+' Son texte est '+enfants[i].firstChild.nodeValue);
          return;
        }
//       else {
//          ecrire_dans_console('traite_ra_ligne3col() : Ligne 1209 : indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target);
//        }
      }
      else {
        if(enfants[i].firstChild.nodeName == 'IMG') {
//          ecrire_dans_console('indice = '+i+' : Le nodeName est '+enfants[i].nodeName+' et son url est '+enfants[i].href+'\n La class de son parent est '+enfants[i].parentNode.className+' son title est '+enfants[i].title+' Sa target est '+enfants[i].target+'\nALT de son enfant : '+enfants[i].firstChild.alt);
          if((enfants[i].firstChild.title == 'CrÈer') && (enfants[i].target == 'Creation')&& (enfants[i].firstChild.alt == ('CrÈer-'+args.maj))) {
            enfants[i].parentNode.replaceChild(frag, enfants[i]);
            nb_maj++;
            return;
          }
//          else {
//            ecrire_dans_console('Les valeurs du test sont : title : '+enfants[i].firstChild.title+', target : '+enfants[i].target+', Alt : '+enfants[i].firstChild.alt+' testù avec la valeur \'Crùer-'+args.maj+'\'');
//          }
        }
      }
    }
    else {
      if(enfants[i].nodeType == Node.TEXT_NODE) {
//        ecrire_dans_console('Le noeud courant est du Text contentant le texte suivant : '+enfants[i].nodeValue+'\nla classe de son parent est '+enfants[i].parentNode.className+' ligne_creation = '+ligne_creation+' lg = '+lg);
        if(ligne_creation == lg) {
//          ecrire_dans_console('Indice = '+i+' Son parent est : '+enfants[i].parentNode.nodeName+' avec pour Id : '+enfants[i].parentNode.id+' et pour class : '+enfants[i].parentNode.className+' nbligne = '+ligne_creation+' lg = '+lg);
          enfants[i].parentNode.replaceChild(text_edit, enfants[i]);
          nb_maj++;
        }
      }
      else {
//        ecrire_dans_console('Lancement rùcursif de traite_ra_ligne3col');
        traite_ra_ligne3col(enfants[i], lg, args, elt_a, frag, text_edit);
//        ecrire_dans_console('Fin du lancement rùcursif de traite_ra_ligne3col');
      }
    }
  }
}


function AfficheNomsProprietes(obj) {
  var noms = '';
  for(var nom in obj) {
    noms += nom+'  ';
  }
  ecrire_dans_console("les propriÈtÈs de l'objet "+obj.name+" sont :\n"+noms);

}
