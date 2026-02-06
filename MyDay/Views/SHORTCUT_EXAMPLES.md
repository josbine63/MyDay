# 📱 Exemples de Raccourcis pour MyDay

Ce document contient des exemples concrets de raccourcis que vous pouvez créer dans l'app Raccourcis d'Apple et utiliser avec MyDay.

---

## 📝 Journaling & Notes

### 1. Journal de Gratitude
**Mot-clé dans MyDay** : `Gratitude`

**Actions dans Raccourcis** :
1. `Demander une entrée` → "Pour quoi es-tu reconnaissant aujourd'hui ?"
2. `Obtenir la date actuelle`
3. `Formater la date` → Format personnalisé : "EEEE d MMMM yyyy à HH:mm"
4. `Texte` : 
   ```
   📅 [Date formatée]
   🙏 [Entrée]
   ───────────────
   ```
5. `Ajouter à la note` → Sélectionner "Journal Gratitude" dans Notes
6. `Afficher la notification` → "✅ Gratitude enregistrée !"

---

### 2. Journal du Matin
**Mot-clé dans MyDay** : `Journal Matin`

**Actions dans Raccourcis** :
1. `Obtenir la météo actuelle`
2. `Obtenir la date actuelle`
3. `Texte` :
   ```
   🌅 [Date]
   🌡️ Météo : [Température]° - [Conditions]
   
   📝 Notes du jour :
   ```
4. `Créer une note` → Dans le dossier "Journal"
5. `Afficher la note` → Note créée
6. `Lire le texte` → "Bonjour ! Il fait [Température] degrés aujourd'hui."

---

### 3. Réflexion du Soir
**Mot-clé dans MyDay** : `Réflexion`

**Actions dans Raccourcis** :
1. `Demander une entrée` → "Qu'as-tu appris aujourd'hui ?"
2. `Demander une entrée` → "Qu'aurais-tu pu mieux faire ?"
3. `Demander une entrée` → "De quoi es-tu fier aujourd'hui ?"
4. `Obtenir la date actuelle`
5. `Texte` :
   ```
   🌙 Réflexion du [Date]
   
   💡 Apprentissages :
   [Réponse 1]
   
   📈 Amélioration :
   [Réponse 2]
   
   ⭐ Fierté :
   [Réponse 3]
   ```
6. `Ajouter à la note` → "Journal de réflexion"

---

## 🏃 Fitness & Santé

### 4. Démarrer Entraînement
**Mot-clé dans MyDay** : `Entraînement`

**Actions dans Raccourcis** :
1. `Définir le mode Ne pas déranger` → Activé pour 1 heure
2. `Démarrer une séance d'entraînement` → Type : Musculation
3. `Lire de la musique` → Playlist : "Workout"
4. `Démarrer le minuteur` → 45 minutes
5. `Lire le texte` → "C'est parti pour 45 minutes d'entraînement !"

---

### 5. Course à Pied
**Mot-clé dans MyDay** : `Course`

**Actions dans Raccourcis** :
1. `Obtenir la météo actuelle`
2. `Si` [Température] > 25
   - `Lire le texte` → "Il fait chaud ! N'oublie pas de boire de l'eau."
3. `Sinon si` [Température] < 10
   - `Lire le texte` → "Il fait froid ! Pense à t'échauffer."
4. `Fin si`
5. `Démarrer une séance d'entraînement` → Type : Course
6. `Lire de la musique` → Playlist : "Running"

---

### 6. Méditation Quotidienne
**Mot-clé dans MyDay** : `Méditation`

**Actions dans Raccourcis** :
1. `Définir le mode Ne pas déranger` → Activé pour 15 minutes
2. `Diminuer la luminosité` → 30%
3. `Démarrer le minuteur` → 10 minutes
4. `Ouvrir l'app` → Calm (ou Headspace, Petit Bambou)
5. `Attendre` → 10 minutes
6. `Lire le texte` → "Bravo ! Tu as pris 10 minutes pour toi."
7. `Rétablir la luminosité automatique`

---

## 🛒 Tâches & Organisation

### 7. Liste de Courses
**Mot-clé dans MyDay** : `Épicerie` ou `Courses`

**Actions dans Raccourcis** :
1. `Afficher la note` → "Liste de Courses"
2. `Obtenir les éléments de la liste de rappels` → Liste : "Courses"
3. `Si` [Nombre d'éléments] > 0
   - `Afficher la notification` → "📝 Tu as [Nombre] articles sur ta liste"

**OU version avancée** :
1. `Ouvrir l'app` → Rappels
2. `Obtenir l'URL de la liste de rappels` → Liste : "Courses"
3. `Ouvrir les URL` → [URL de la liste]

---

### 8. Mode Focus Travail
**Mot-clé dans MyDay** : `Focus` ou `Deep Work`

**Actions dans Raccourcis** :
1. `Définir le mode Focus` → Travail, pendant 2 heures
2. `Ouvrir l'app` → Notion (ou app de travail préférée)
3. `Démarrer le minuteur` → 25 minutes (Pomodoro)
4. `Lire de la musique` → Playlist : "Focus"
5. `Afficher la notification` → "🧠 Mode focus activé pour 25 min"

---

### 9. Préparer Réunion
**Mot-clé dans MyDay** : `Réunion`

**Actions dans Raccourcils** :
1. `Trouver les événements Calendrier` → Titre contient "Réunion", Aujourd'hui
2. `Choisir dans la liste` → [Événements trouvés]
3. `Obtenir les notes de l'événement` → [Événement choisi]
4. `Si` [Notes] n'est pas vide
   - `Créer une note` → Titre : "Préparation [Événement]", Texte : [Notes]
   - `Afficher la note` → [Note créée]
5. `Sinon`
   - `Créer une note` → Titre : "Notes réunion [Événement]"
   - `Afficher la note` → [Note créée]

---

## 💊 Santé & Bien-être

### 10. Prise de Médicaments
**Mot-clé dans MyDay** : `Médicament` ou `Pilule`

**Actions dans Raccourcis** :
1. `Ouvrir l'app` → Santé
2. `Obtenir la date actuelle`
3. `Texte` → "💊 Médicament pris le [Date]"
4. `Ajouter à la note` → "Journal Santé"
5. `Attendre` → 2 secondes
6. `Ouvrir l'URL` → `x-apple-health://MedicationsHealthAppPlugin.healthplugin`
7. `Afficher la notification` → "✅ N'oublie pas d'enregistrer dans Santé"

---

### 11. Boire de l'Eau
**Mot-clé dans MyDay** : `Eau` ou `Hydratation`

**Actions dans Raccourcis** :
1. `Demander un nombre` → "Combien de verres as-tu bu ?"
2. `Calculer` → [Nombre] × 250 (ml par verre)
3. `Logger une quantité de santé` → Type : Eau, Quantité : [Résultat] ml
4. `Afficher la notification` → "💧 [Résultat] ml d'eau ajoutés à Santé"

---

### 12. Suivi du Sommeil
**Mot-clé dans MyDay** : `Dodo` ou `Sommeil`

**Actions dans Raccourcis** :
1. `Obtenir l'heure actuelle`
2. `Calculer` → [Heure] + 8 heures (durée de sommeil souhaitée)
3. `Définir l'alarme` → [Heure calculée]
4. `Définir le mode Focus` → Sommeil, jusqu'à [Heure calculée]
5. `Diminuer la luminosité` → 10%
6. `Activer le mode nuit`
7. `Lire le texte` → "Bonne nuit ! Alarme réglée pour [Heure calculée]"

---

## 🎯 Productivité

### 13. Revue Hebdomadaire
**Mot-clé dans MyDay** : `Revue` ou `Weekly Review`

**Actions dans Raccourcis** :
1. `Obtenir la date actuelle`
2. `Calculer` → [Date] - 7 jours
3. `Trouver les notes` → Modifiées entre [Date calculée] et [Date actuelle]
4. `Choisir dans la liste` → [Notes trouvées]
5. `Afficher la note` → [Note choisie]
6. `Créer une note` → "📊 Revue de la semaine du [Date]"

---

### 14. Timer Pomodoro
**Mot-clé dans MyDay** : `Pomodoro`

**Actions dans Raccourcis** :
1. `Définir le mode Ne pas déranger` → Activé pour 25 minutes
2. `Démarrer le minuteur` → 25 minutes
3. `Lire le texte` → "Début du pomodoro de 25 minutes"
4. `Attendre` → 25 minutes
5. `Lire le texte` → "Pomodoro terminé ! Prends une pause de 5 minutes"
6. `Attendre` → 5 minutes
7. `Demander une entrée` → "Veux-tu continuer ? (oui/non)"
8. `Si` [Réponse] = "oui"
   - `Exécuter le raccourci` → "Timer Pomodoro" (boucle)

---

### 15. Capture d'Idée Rapide
**Mot-clé dans MyDay** : `Idée`

**Actions dans Raccourcis** :
1. `Demander une entrée` → "Quelle est ton idée ?"
2. `Obtenir la date actuelle`
3. `Texte` :
   ```
   💡 [Date courte]
   [Entrée]
   ───────
   ```
4. `Ajouter à la note` → "Boîte à Idées"
5. `Afficher la notification` → "✅ Idée capturée !"

---

## 🎨 Créativité & Loisirs

### 16. Inspiration Quotidienne
**Mot-clé dans MyDay** : `Inspiration`

**Actions dans Raccourcis** :
1. `Obtenir le contenu de l'URL` → `https://zenquotes.io/api/random`
2. `Obtenir un dictionnaire depuis` → [Contenu]
3. `Obtenir la valeur pour "q"` → [Dictionnaire]
4. `Lire le texte` → [Citation]
5. `Créer une note` → Citation du jour avec [Citation]

---

### 17. Écouter Podcast
**Mot-clé dans MyDay** : `Podcast`

**Actions dans Raccourcis** :
1. `Ouvrir l'app` → Podcasts
2. `Obtenir les derniers podcasts` → Abonnements
3. `Choisir dans la liste` → [Podcasts]
4. `Lire` → [Podcast choisi]

---

## 🚗 Déplacements

### 18. Partir au Travail
**Mot-clé dans MyDay** : `Travail` ou `Bureau`

**Actions dans Raccourcis** :
1. `Obtenir les directions` → Vers : [Adresse bureau]
2. `Obtenir la durée du trajet`
3. `Si` [Durée] > 45 minutes
   - `Afficher la notification` → "🚨 Trafic important : [Durée] min. Pars tôt !"
4. `Définir le mode Focus` → Conduite
5. `Lire de la musique` → Playlist : "Commute"
6. `Ouvrir Plans` → Direction vers [Adresse bureau]

---

### 19. Rentrer à la Maison
**Mot-clé dans MyDay** : `Maison` ou `Retour`

**Actions dans Raccourcis** :
1. `Obtenir les directions` → Vers : Maison
2. `Envoyer un message` → À : [Contact], Message : "Je rentre, j'arrive dans [Durée] min"
3. `Définir le mode Focus` → Conduite
4. `Ouvrir Plans` → Direction vers Maison

---

## 🔧 Utilitaires

### 20. Backup Quotidien
**Mot-clé dans MyDay** : `Backup`

**Actions dans Raccourcis** :
1. `Obtenir les notes` → Dossier : "Important"
2. `Créer un PDF à partir de` → [Notes]
3. `Sauvegarder dans iCloud Drive` → Dossier : "Backups/[Date]"
4. `Afficher la notification` → "✅ Backup effectué"

---

## 💡 Conseils pour créer vos raccourcis

### Testez d'abord dans Raccourcis
Avant de lier à MyDay, exécutez le raccourci manuellement pour vérifier qu'il fonctionne.

### Nommez clairement
Utilisez des noms descriptifs :
- ✅ "Journal Gratitude"
- ✅ "Démarrer Entraînement"
- ❌ "Raccourci 1"
- ❌ "Test"

### Utilisez des feedbacks
Ajoutez des notifications ou messages audio pour confirmer l'exécution.

### Combinez des actions
Un raccourci peut faire plusieurs choses séquentiellement.

### Conditions et boucles
Utilisez `Si/Sinon` et `Répéter` pour des raccourcis intelligents.

### Partagez
Vous pouvez partager vos raccourcis avec d'autres via iCloud.

---

## 🔗 Ressources

- [Galerie de Raccourcis Apple](https://www.icloud.com/shortcuts/)
- [Guide Apple Shortcuts](https://support.apple.com/fr-fr/guide/shortcuts/welcome/ios)
- [r/shortcuts (Reddit)](https://www.reddit.com/r/shortcuts/)
- [RoutineHub (communauté)](https://routinehub.co/)

---

**Besoin d'aide ?** Consultez `CUSTOM_LINKS_GUIDE.md` pour le guide complet d'utilisation avec MyDay.
