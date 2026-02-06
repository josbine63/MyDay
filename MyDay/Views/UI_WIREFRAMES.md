# 🖼️ Wireframes & Maquettes UI

Ce document présente les interfaces utilisateur du système de liens personnalisés.

---

## 📱 Vue 1 : Réglages avec Liens Personnalisés

```
┌─────────────────────────────────────┐
│ ←  Réglages                         │
├─────────────────────────────────────┤
│                                      │
│ SOURCES DE DONNÉES                   │
│                                      │
│ 📅  Calendriers                  › │
│                                      │
│ ✓  Listes de rappels             › │
│                                      │
│ 🔗  Liens personnalisés          › │
│     3 actif(s)                       │
│                                      │
│ 📷  Photos                       › │
│     ✓                                │
│                                      │
│ ❤️  Santé                        › │
│     ✓                                │
│                                      │
├─────────────────────────────────────┤
│                                      │
│ FONCTIONNALITÉS                      │
│                                      │
│ ✨  Pensée du jour         [✓]      │
│                                      │
│ 🔮  Horoscope quotidien    [✓]      │
│                                      │
└─────────────────────────────────────┘
```

---

## 📱 Vue 2 : Liste des Liens Personnalisés (Vide)

```
┌─────────────────────────────────────┐
│ ←  Liens personnalisés     Modifier │
├─────────────────────────────────────┤
│                                      │
│           🔗                         │
│                                      │
│     Aucun lien personnalisé          │
│                                      │
│  Créez des raccourcis pour ouvrir    │
│  automatiquement vos notes, apps     │
│  ou actions préférées depuis votre   │
│  agenda.                             │
│                                      │
├─────────────────────────────────────┤
│                                      │
│ ➕ Ajouter un lien                   │
│                                      │
└─────────────────────────────────────┘
```

---

## 📱 Vue 3 : Liste avec Liens Configurés

```
┌─────────────────────────────────────┐
│ ←  Liens personnalisés     Modifier │
├─────────────────────────────────────┤
│                                      │
│ LIENS ACTIFS                         │
│                                      │
│ 🔗  Gratitude                        │
│     Contient le mot                  │
│     ▶️  Journal Gratitude   [▶️]    │
│                                      │
│ 🔗  Épicerie                         │
│     Contient le mot                  │
│     ▶️  Liste Courses       [▶️]    │
│                                      │
│ ⭕  Méditation                       │
│     Commence par                     │
│     ▶️  Calme               [▶️]    │
│                                      │
│ Balayez pour supprimer ou réorganiser│
│                                      │
├─────────────────────────────────────┤
│                                      │
│ ➕ Ajouter un lien                   │
│                                      │
└─────────────────────────────────────┘
```

**Légende** :
- 🔗 = Lien actif (bleu)
- ⭕ = Lien désactivé (gris)
- [▶️] = Bouton de test

---

## 📱 Vue 4 : Swipe Actions

```
┌─────────────────────────────────────┐
│                                      │
│ [▶️ Activer] 🔗  Gratitude    [🗑️]  │
│              Contient le mot         │
│              ▶️  Journal             │
│                                      │
└─────────────────────────────────────┘
```

**Swipe gauche** : 🗑️ Supprimer
**Swipe droite** : ⏸️ Désactiver / ▶️ Activer

---

## 📱 Vue 5 : Formulaire d'Ajout/Édition

```
┌─────────────────────────────────────┐
│ Annuler    Nouveau lien   Enregistrer│
├─────────────────────────────────────┤
│                                      │
│ DÉTECTION                            │
│                                      │
│ Mot-clé à détecter                   │
│ ┌─────────────────────────────────┐ │
│ │ Gratitude_____________          │ │
│ └─────────────────────────────────┘ │
│                                      │
│ Type de correspondance               │
│ Contient le mot              ∨      │
│                                      │
│ Le titre doit contenir le mot        │
│ "gratitude"                          │
│                                      │
├─────────────────────────────────────┤
│                                      │
│ ACTION                               │
│                                      │
│ Nom du raccourci                     │
│ ┌─────────────────────────────────┐ │
│ │ Journal Gratitude_______________│ │
│ └─────────────────────────────────┘ │
│                                      │
│ ↗️  Ouvrir l'app Raccourcis          │
│                                      │
│ Entrez le nom exact du raccourci     │
│ à exécuter. Créez-le dans l'app      │
│ Raccourcis si nécessaire.            │
│                                      │
├─────────────────────────────────────┤
│                                      │
│ Lien actif                    [✓]   │
│                                      │
│ Les liens désactivés sont conservés  │
│ mais ne seront pas utilisés.         │
│                                      │
└─────────────────────────────────────┘
```

---

## 📱 Vue 6 : Formulaire Édition (avec test)

```
┌─────────────────────────────────────┐
│ Annuler    Modifier le lien  Enregistrer│
├─────────────────────────────────────┤
│                                      │
│ DÉTECTION                            │
│ Gratitude                            │
│ Contient le mot                  ∨  │
│                                      │
│ ACTION                               │
│ Journal Gratitude                    │
│ ↗️  Ouvrir l'app Raccourcis          │
│                                      │
│ Lien actif                    [✓]   │
│                                      │
├─────────────────────────────────────┤
│                                      │
│ ▶️  Tester le raccourci              │
│                                      │
│ Vérifiez que le raccourci fonctionne │
│ correctement.                        │
│                                      │
└─────────────────────────────────────┘
```

---

## 📱 Vue 7 : Agenda SANS lien personnalisé

```
┌─────────────────────────────────────┐
│            Jeudi                     │
│         30 janvier 2026              │
├─────────────────────────────────────┤
│                                      │
│ 📅  Réunion d'équipe        10:00   │
│                                      │
│ 🗓️  Appeler le dentiste     14:30   │
│                                      │
│ 💊  Médicament              20:00   │
│                                      │
└─────────────────────────────────────┘
```

---

## 📱 Vue 8 : Agenda AVEC liens personnalisés

```
┌─────────────────────────────────────┐
│            Jeudi                     │
│         30 janvier 2026              │
├─────────────────────────────────────┤
│                                      │
│ 📅  Gratitude 🔗            08:00 ☑️ │
│                                      │
│ 💊  Médicament              09:00 ☑️ │
│                                      │
│ 🗓️  Épicerie 🔗             14:00 ☑️ │
│                                      │
│ 📅  Réunion                 15:30 ☑️ │
│                                      │
│ 🧘  Méditation 🔗           19:00 ☑️ │
│                                      │
└─────────────────────────────────────┘
```

**Badge 🔗** = Lien personnalisé configuré

**Comportement au tap** :
- **Sans 🔗** : Ouvre Calendrier/Rappels
- **Avec 🔗** : Lance le raccourci automatiquement

---

## 📱 Vue 9 : Debug View (DEBUG only)

```
┌─────────────────────────────────────┐
│ ←  Debug Liens                       │
├─────────────────────────────────────┤
│                                      │
│ TEST DE MATCHING                     │
│                                      │
│ Titre à tester                       │
│ ┌─────────────────────────────────┐ │
│ │ Ma Gratitude quotidienne________│ │
│ └─────────────────────────────────┘ │
│                                      │
│ [Tester le matching]                 │
│                                      │
│ ✅  Gratitude (Contient)             │
│     MATCH ✓                          │
│                                      │
│ ❌  Test (Exact)                     │
│                                      │
├─────────────────────────────────────┤
│                                      │
│ TEST DE RACCOURCI                    │
│                                      │
│ Nom du raccourci                     │
│ ┌─────────────────────────────────┐ │
│ │ Journal Gratitude_______________│ │
│ └─────────────────────────────────┘ │
│                                      │
│ [Tester l'ouverture]                 │
│                                      │
│ ✅ Ouverture réussie                 │
│                                      │
├─────────────────────────────────────┤
│                                      │
│ INFORMATIONS                         │
│                                      │
│ Nombre de liens          3           │
│ Liens actifs             2           │
│ Premier lien             Gratitude   │
│                                      │
└─────────────────────────────────────┘
```

---

## 🎨 Palette de Couleurs

| Élément | Couleur | Usage |
|---------|---------|-------|
| Badge 🔗 | Purple (.purple) | Liens personnalisés |
| Lien actif | Blue (.blue) | État activé |
| Lien désactivé | Gray (.gray) | État désactivé |
| Test réussi | Green (.green) | Validation |
| Test échoué | Red (.red) | Erreur |
| Action swipe activer | Green | Activation |
| Action swipe désactiver | Orange | Pause |
| Action swipe supprimer | Red | Destruction |

---

## 🔤 Typographie

| Élément | Font | Weight |
|---------|------|--------|
| Titre lien | .headline | Regular |
| Type matching | .caption | Regular |
| Nom raccourci | .caption | Regular |
| Badge compteur | .caption | Regular |
| Description | .subheadline | Regular |
| Footer | .caption | Regular |

---

## 📐 Espacements

- **Padding horizontal** : 16pt
- **Padding vertical** : 12pt
- **Espacement entre éléments** : 8pt
- **Espacement sections** : 20pt
- **Corner radius** : 12pt

---

## ♿ Accessibilité

### VoiceOver
- Liens personnalisés : "Lien personnalisé : [Keyword]. [Type]. Ouvre [Raccourci]. [État]"
- Badge dans agenda : "A un lien personnalisé configuré"
- Bouton test : "Tester le raccourci [Nom]"

### Dynamic Type
- Support des tailles de police système
- Textes redimensionnables

### Couleurs
- Contraste suffisant pour tous les badges
- Mode sombre pris en charge automatiquement

---

## 🎬 Animations

### Transitions
- Liste vide → Liste avec liens : Fade in
- Ajout d'un lien : Slide from bottom (sheet)
- Suppression : Swipe + fade out
- Activation/désactivation : Opacity change

### Feedback haptique
- Ajout : `.success`
- Suppression : `.warning`
- Test réussi : `.success`
- Test échoué : `.error`

---

## 📱 States & Interactions

### État Normal
```
🔗  Gratitude
    Contient le mot
    ▶️  Journal Gratitude    [▶️]
```

### État Désactivé
```
⭕  Gratitude (opacité 60%)
    Contient le mot
    ▶️  Journal Gratitude    [▶️]
```

### Swipe Gauche (Supprimer)
```
🔗  Gratitude              [🗑️ Supprimer]
```

### Swipe Droite (Toggle)
```
[⏸️ Désactiver]  🔗  Gratitude
```

### Editing Mode
```
☰ 🔗  Gratitude
    Contient le mot
    ▶️  Journal Gratitude
```

---

*Ces wireframes représentent l'implémentation actuelle du système de liens personnalisés.* 📐
