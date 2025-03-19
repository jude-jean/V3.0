//  Fichier outils.js contenant les fonctions javascript
self.onerror = ma_gestion_erreur;

function ma_gestion_erreur(msg, url, line) {
  alert(' Une erreur est survenue dans le code Javscript, voici les détails :\n Message d\'erreur : '+msg+'\n Ligne N° : '+line);
  return true;
}

function valide_hsupplus(elt) {
//  alert('Le nom de l\'élément origine est : '+opener.data_save[0].name+'\n Sa valeur courante est: '+opener.data_save[1]+'\n Sa valur précédente est : '+opener.data_save[2]);
  var err;
//  alert('L\'élément sélectionné est : '+elt.elements['hsupplus'].value);
  var racine = opener.document.forms['f_ra'].elements[opener.data_save[0].name];
  var old_value, old_text;

  if(elt.elements['hsupplus'].value != ' ') {
    opener.ajouter(opener.data_save[0]);
    try {
      racine.options[racine.options.length - 2].value = elt.elements['hsupplus'].value;
      racine.options[racine.options.length - 2].text = elt.elements['hsupplus'].value;
      racine.options[racine.options.length - 2].selected = true;
      racine.options[racine.options.length - 2].defaultSelected = false;
      opener.vcourante = elt.elements['hsupplus'].value;
    }
    catch(err) {
      alert('Une erreur a eu lieu, voici les détails : \n Nom de l\'erreur : '+err.name+'\n Message : '+err.message+'\n Infos sur l\'option \n  -Value : '+option_new.value+'\n  -Text : '+option_new.text+'\n  -Selected : '+option_new.selected+'\n  -DefaultSelected : '+option_new.defaultSelected+'\n  -Index : '+option_new.index);
    }
    racine = opener.document.forms['f_ra'];
    if(opener.data_save[0].name.search(/^hsup0_/)== 0){
      v = Number(racine.elements['nb_hsup0'].value);
      v = v + Number(elt.elements['hsupplus'].value);
      racine.elements['nb_hsup0'].value = v;
    }
    else if(opener.data_save[0].name.search(/^hsup25_/)== 0){
      v = Number(racine.elements['nb_hsup25'].value);
      v = v + Number(elt.elements['hsupplus'].value);
      racine.elements['nb_hsup25'].value = v;
    }
    else if(opener.data_save[0].name.search(/^hsup50_/)== 0){
      v = Number(racine.elements['nb_hsup50'].value);
      v = v + Number(elt.elements['hsupplus'].value);
      racine.elements['nb_hsup50'].value = v;
    }
    else if(opener.data_save[0].name.search(/^hsup100_/)== 0){
      v = Number(racine.elements['nb_hsup100'].value);
      v = v + Number(elt.elements['hsupplus'].value);
      racine.elements['nb_hsup100'].value = v;
    }
  }
  else {
    racine.options[0].selected = true;
  }
// Vide le tablean data_save[]
  opener.vide_data_save();
  close();
  return false;
}

function ferme_hsupplus() {
  var racine = opener.document.forms[0].elements[opener.data_save[0].name];
  racine.options[0].selected = true;
  opener.vide_data_save();
  close();
  return false;
}

/*
function AfficheNomsProprietes(obj) {
  var noms = '';
  for(var nom in obj) {
    noms += nom+'  ';
  }
  alert("les propriétés de l'objet "+obj.name+" sont :\n"+noms);

}
*/