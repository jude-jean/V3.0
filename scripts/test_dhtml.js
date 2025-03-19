self.onerror = ma_gestion_erreur;

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

function ecrire_dans_console (texte) {
// Ecrire dans la console si elle est active ou ecrire dans alert
  if (typeof console !== undefined) {
        console.log(texte);    
    }
    else {
        alert(texte);    
    }
}

function anime_rdv(rdv, event) {
// Permet le déplacement des rdvs dans le calendrier.
// Récupère les coordonnées du rdv
	var x = parseInt(rdv.style.left);
	var y = parseInt(rdv.style.top);
// Calcule la distance entre le rdv et le point ou l'évènement a eu lieu
	var deltaX = event.clientX - x;
	var deltaY = event.clientY - y;
	oldeventY = event.clientY;
// On supprime le gestionnaire de movement de la souris
//	document.removeEventListener("mousemove", moveCursor, true);
// On enregistre les gestionnaires d'évènenments
	document.addEventListener("mousemove", moveHandler, true);
	document.addEventListener("mouseup", upHandler, true);
// !l'évènement est traité, on bloque sa propagation
	event.stopPropagation();
	event.preventDefault();


	function moveHandler(event) {
// Déplacement l'élément de la position courante de la souris, ajustée par le delta
		var rdvY = event.clientY -deltaY;
		var limite_basse = document.getElementById('cal_visu').offsetHeight -parseInt(rdv.style.height);
		rdv.style.left = x;
		if((rdvY >= document.getElementById('titre_rdv_jour').offsetHeight) && (rdvY <= limite_basse)){
			rdv.style.top = rdvY + "px";
		}
		else if (rdvY < document.getElementById('titre_rdv_jour').offsetHeight){
			rdv.style.height = (parseInt(rdv.style.height) - (document.getElementById('titre_rdv_jour').offsetHeight + rdvY)) + "px";
			rdv.style.top = document.getElementById('titre_rdv_jour').offsetHeight;
		}
// On arrete la propagation
		event.stopPropagation();
	}

	function upHandler(event) {
// Désenregistre les gestionnaires d'évènements
		document.removeEventListener("mouseup", upHandler, true);
		document.removeEventListener("mousemove", moveHandler, true);
		if(oldeventY != event.clientY) {
			event.stopPropagation();
			var id_rdv = rdv.getAttribute('id');
			if(document.forms[1].elements['ref_'+id_rdv]) {		
				var msg = "Le rendez-vous a une périodicité.\n\nSi vous souhaitez modifier le rendez-vous, cliquez sur OK\n\nSinon cliquez sur Annuler";
				if(!confirm(msg)) {
					rdv.style.top = y + "px";
					return;
				}
			}
			var parent_rdv = document.getElementById('cal_visu');
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
//		ecrire_dans_console('oldeventY = '+oldeventY+', eventY = '+event.clientY);
//		document.getElementById('pos'+id_rdv).value = pos;
//			rdv.style.top = document.getElementById('titre_rdv_jour').offsetHeight + (pos*h_pas) +"px";
//		ecrire_dans_console('event Y = '+event.clientY+', pos = '+pos+', h_pas = '+h_pas);
			var rdvY = event.clientY -deltaY;
			var pos = Math.round(-0.5 + (rdvY  / h_pas));
			if(rdvY <= document.getElementById('titre_rdv_jour').offsetHeight) {
				rdv.style.top = document.getElementById('titre_rdv_jour').offsetHeight+"px";
				rdvY = document.getElementById('titre_rdv_jour').offsetHeight;
			}	
			else if(rdvY > limite_basse) {
				rdv.style.top = limite_basse+"px";
			}	
			else {	
				rdv.style.top = (pos*h_pas) +"px";
			}
//			rdvY = event.clientY -deltaY;
			pos = Math.round(-0.5 + (rdvY  / h_pas));
			ecrire_dans_console("pos ="+pos+", rdvY = "+rdvY+", h_pas = "+h_pas+", rdvY/h_pas = "+(rdvY/h_pas)+", titre_rdv_jour.offsetHeight = "+document.getElementById('titre_rdv_jour').offsetHeight);
			rdv.style.cursor = 'wait';
// on calcule l'url à exécuter
			var enfants = rdv.childNodes;
			var heure_debut, heure_fin, hh, mm, jj;
			var hauteur_rdv = parseInt(document.forms[1].elements['haut_'+id_rdv].value, 10);
			for(var i = 0; i < enfants.length; i++) {
				if(enfants[i].nodeName == 'A') {
//					pos -= 1;

					var jour_debut = new Date(document.forms[1].elements['annee'].value, document.forms[1].elements['mois'].value, document.forms[1].elements['jour'].value, 0, 0);
					var jour_fin = new Date(document.forms[1].elements['annee'].value, document.forms[1].elements['mois'].value, document.forms[1].elements['jour'].value, 23, 59);
					if(pos == 0) {
					var rdv_debut = new Date(jour_debut.getTime());
					}
					else {
						var rdv_debut = new Date(jour_debut.getTime() + (pos -1)*60*60*1000);
					}
					var rdv_fin = new Date(rdv_debut.getTime() + hauteur_rdv*60*60*1000);
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
// Il faut maintenant modifier les champs cachés debut et fin qui seront utilisé pour constituer la chaine update_rdv
					document.forms[1].elements['debut_'+id_rdv].value = document.forms[1].elements['debut_'+id_rdv].value.replace(/(\d+):(\d+)/, heure_debut+":$2");
					document.forms[1].elements['fin_'+id_rdv].value = document.forms[1].elements['fin_'+id_rdv].value.replace(/(\d+):(\d+)/, heure_fin+":$2");
					var num_rdv = document.forms[1].elements['id_'+id_rdv].value;
// Dans l'avenir, il faudra tenir compte peut-être du type d'affichage en particulier des minutes. Aujourd'hui, ce n'est pas le cas				
					var update_rdv = base+"/rendez_vous/update.pl?ident_id="+document.forms[1].elements['ident_id'].value+"&rdv="+num_rdv+"&debut="+document.forms[1].elements['debut_'+id_rdv].value+"&fin="+document.forms[1].elements['fin_'+id_rdv].value+"&annee="+document.forms[1].elements['annee'].value+"&mois="+document.forms[1].elements['mois'].value+"&jour="+document.forms[1].elements['jour'].value;
//				ecrire_dans_console("update_rdv = "+update_rdv);
//				location.href = update_rdv;
					break;
				}
		
			}
		}
	}

}
