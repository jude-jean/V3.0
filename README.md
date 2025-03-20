# etechnoserv_v3.0

Ce projet comprend les développements réalisés principalement en Perl.

Son but : Développer de nouvelles fonctionnalités du site internet de Technologies & Services.

Le projet a commencé en 2010 ou peut-être même avant.

La nouvelle fonctionnalité à l'étude concerne l'établissement d'une facture à partir du rapport d'activités mensuel.

## Avertissements

Le développement a été initialement r&alisé en utilisant l'encodage Windows 1252 dans l'éditeur Notepad. Le passage à VsCode a généré des soucis au niveau des accents. Par défaut VsCode lit et sauvegarde les fichiers avec l'encodage UTF-8. Cette différence d'encodage a eu pour consquéence que plusieurs fontionnalités, en particulier dans du code Javascript, ne fonctionnait plus.

La solution la plus fiable est d'utilisé l'UTF-8 par tout avec les fonction d'encodage et de décodage (HTML, Javascript, etc.).

La solution mise en place pour le moment est d'utiliser l'encodage Windows1252 pour les fichiers Javascript et de modifier l'encodage des accents dans HTML.

Les mots posant problèmes sont :

- Février
- Août
- Décembre
- Créer
- Etc