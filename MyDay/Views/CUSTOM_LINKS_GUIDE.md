# 🔗 Guide des Liens Personnalisés

## Vue d'ensemble

Les **Liens Personnalisés** vous permettent d'associer vos entrées d'agenda à des actions automatiques via l'app **Raccourcis** d'Apple. Lorsque vous touchez une entrée dans votre agenda, MyDay peut automatiquement ouvrir une note spécifique, lancer une playlist, démarrer un minuteur, ou toute autre action que vous aurez configurée.

---

## 🎯 Cas d'usage

### Exemples pratiques

| Entrée d'agenda | Action automatique |
|----------------|-------------------|
| **Gratitude** | Ouvrir une note "Journal de gratitude" |
| **Épicerie** | Afficher la liste de courses |
| **Méditation** | Lancer une méditation guidée + minuteur |
| **Rendez-vous client** | Ouvrir le dossier client dans Notes |
| **Entraînement** | Démarrer une playlist + tracker de fitness |
| **Médicaments** | Ouvrir l'app Santé + logger la prise |

---

## 🚀 Configuration

### Étape 1 : Créer un raccourci

1. Ouvrez l'app **Raccourcis** sur votre iPhone
2. Touchez **+** pour créer un nouveau raccourci
3. Ajoutez les actions souhaitées :
   - **Ouvrir une note** : Recherchez "Afficher la note" → Sélectionnez votre note
   - **Ouvrir une app** : Recherchez "Ouvrir l'app" → Choisissez l'app
   - **Actions multiples** : Combinez plusieurs actions (ex : ouvrir note + lancer minuteur)
4. Touchez l'icône ⚙️ en haut et donnez un **nom** à votre raccourci
   - Exemple : "Journal Gratitude"
   - ⚠️ **Notez bien ce nom, vous en aurez besoin !**

### Étape 2 : Créer un lien dans MyDay

1. Dans MyDay, allez dans **Réglages** → **Liens personnalisés**
2. Touchez **➕ Ajouter un lien**
3. Remplissez le formulaire :
   - **Mot-clé** : Le mot à détecter dans vos entrées (ex : "Gratitude")
   - **Type de correspondance** :
     - `Contient le mot` : Détecte "Gratitude", "gratitude", "Ma Gratitude", etc.
     - `Titre exact` : Doit être exactement "Gratitude" (sensible à la casse)
     - `Commence par` : Détecte "Gratitude...", mais pas "Ma Gratitude"
   - **Nom du raccourci** : Le nom EXACT du raccourci créé à l'étape 1
4. Touchez **Enregistrer**

### Étape 3 : Tester

1. Dans la liste des liens, touchez l'icône **▶️** pour tester immédiatement
2. Si le raccourci ne se lance pas :
   - Vérifiez l'orthographe du nom (majuscules, accents, espaces)
   - Vérifiez que le raccourci existe dans l'app Raccourcis
   - Assurez-vous que le raccourci n'est pas dans un dossier privé

---

## 🎨 Utilisation

### Dans l'agenda

- Les entrées avec un lien personnalisé affichent une petite icône **🔗** violette
- Touchez l'entrée pour :
  - **Lien configuré** : Lance automatiquement le raccourci
  - **Pas de lien** : Ouvre l'app par défaut (Calendrier ou Rappels)

### Gestion des liens

#### Activer/Désactiver
Balayez un lien vers la droite et touchez **⏸️ Désactiver**
- Le lien est conservé mais ne sera pas utilisé
- Utile pour tester ou désactiver temporairement

#### Modifier
Touchez un lien dans la liste pour l'éditer

#### Supprimer
Balayez vers la gauche et touchez **🗑️ Supprimer**

#### Réorganiser
Touchez **Modifier** en haut à droite, puis glissez les ☰ pour changer l'ordre
- **Important** : Le premier lien qui correspond est utilisé

---

## 💡 Conseils et astuces

### Priorité des liens

Si plusieurs liens correspondent à une entrée, **le premier dans la liste** est utilisé.

**Exemple** :
1. `Gratitude` (exact) → Raccourci A
2. `Grat` (contient) → Raccourci B

Pour "Gratitude" → Lance le Raccourci A
Pour "Ma Gratitude" → Lance le Raccourci B

### Actions complexes

Vous pouvez créer des raccourcis sophistiqués :

```
1. Afficher la note "Journal Gratitude"
2. Lire du texte : "Temps de gratitude !"
3. Démarrer minuteur 5 minutes
4. Lire playlist "Méditation"
```

### Raccourcis avec paramètres

Créez un raccourci qui demande des informations :

```
1. Demander une entrée texte : "Qu'es-tu reconnaissant aujourd'hui ?"
2. Ajouter à la note "Journal Gratitude"
3. Afficher notification : "Entrée enregistrée !"
```

### Intégration avec d'autres apps

Les raccourcis peuvent interagir avec de nombreuses apps :
- **Notes** : Créer, ouvrir, ajouter du contenu
- **Rappels** : Ajouter des tâches
- **Musique** : Lire une playlist
- **Minuteur** : Lancer un compte à rebours
- **Santé** : Logger des données
- **Apps tierces** : Bear, Notion, Things, etc. (si elles supportent les raccourcis)

---

## ❓ Dépannage

### Le raccourci ne se lance pas

**Vérifications** :
1. ✅ Le nom du raccourci est-il **exactement** identique ?
   - Majuscules, minuscules, accents, espaces comptent
2. ✅ Le raccourci existe-t-il dans l'app Raccourcis ?
3. ✅ Le raccourci n'est-il pas dans un dossier privé/partagé ?
4. ✅ Avez-vous accordé les permissions nécessaires au raccourci ?

**Test manuel** :
Dans MyDay → Réglages → Liens personnalisés → Touchez ▶️ sur le lien

### Plusieurs liens se déclenchent

Changez l'ordre des liens ou ajustez les types de correspondance :
- Mettez les liens **exacts** en premier
- Mettez les liens **contient** en dernier

### Le badge 🔗 n'apparaît pas

- Vérifiez que le mot-clé correspond bien au titre de l'entrée
- Vérifiez que le lien est **activé** (pas en pause)

---

## 🔒 Confidentialité

- Tous les liens sont stockés **localement** sur votre appareil
- Aucune donnée n'est envoyée à des serveurs externes
- Les raccourcis s'exécutent avec **vos permissions** iOS

---

## 🆕 Idées de raccourcis populaires

### 📝 Journaling
- **Gratitude quotidienne** : Ouvre note + demande 3 choses positives
- **Journal du matin** : Ouvre note + affiche la météo
- **Réflexion du soir** : Ouvre note + pose questions guidées

### 🏃 Fitness
- **Entraînement** : Lance playlist + démarre chronomètre
- **Étirements** : Ouvre routine + minuteur 10 min
- **Course** : Lance app fitness + playlist

### 🧘 Bien-être
- **Méditation** : Ouvre app Calm/Headspace + mode Ne pas déranger
- **Respiration** : Lance exercice de respiration + minuteur
- **Sommeil** : Active mode nuit + alarme + playlist douce

### 🎯 Productivité
- **Focus profond** : Mode Ne pas déranger + minuteur 25 min + playlist
- **Réunion** : Ouvre note agenda + lance enregistrement audio
- **Revue hebdomadaire** : Ouvre notes de la semaine + to-do list

---

## 📚 Ressources

- [Documentation Apple Shortcuts](https://support.apple.com/fr-fr/guide/shortcuts/welcome/ios)
- [Galerie de raccourcis](https://www.icloud.com/shortcuts/)
- [Communauté r/shortcuts](https://www.reddit.com/r/shortcuts/)

---

**Astuce finale** : Commencez simple ! Créez d'abord un lien basique (ex : ouvrir une note), puis ajoutez progressivement de la complexité une fois à l'aise. 🚀
