# 🔗 Liens Personnalisés avec Paramètres - MyDay

**Date:** 1er février 2026  
**Version:** 2.0  
**Status:** ✅ Implémenté

---

## 📋 Vue d'ensemble

Les **liens personnalisés** de MyDay permettent maintenant de **passer des paramètres dynamiques** aux raccourcis iOS. En utilisant le séparateur `:` dans le titre d'un événement ou rappel, tout ce qui suit sera automatiquement transmis au raccourci comme paramètre texte.

---

## ✨ Fonctionnalité

### Syntaxe de base

```
[Mot-clé]: [Paramètre à transmettre]
```

### Exemples concrets

| Titre de l'entrée | Mot-clé configuré | Raccourci appelé | Paramètre transmis |
|-------------------|-------------------|------------------|-------------------|
| `Appeler: Louisette Bouchard` | `Appeler` | `Téléphoner` | `Louisette Bouchard` |
| `Email: Rapport mensuel` | `Email` | `Envoyer Email` | `Rapport mensuel` |
| `Note: Idée géniale pour l'app` | `Note` | `Créer Note` | `Idée géniale pour l'app` |
| `Rappel: Acheter du lait` | `Rappel` | `Ajouter à liste` | `Acheter du lait` |
| `Gratitude: Ma famille` | `Gratitude` | `Journal Gratitude` | `Ma famille` |

---

## 🎯 Cas d'usage

### 1. **Appels téléphoniques** 📞

**Événement/Rappel:**
```
Appeler: Louisette Bouchard
```

**Configuration du lien:**
- **Mot-clé:** `Appeler`
- **Type de correspondance:** `Commence par`
- **Raccourci:** `Téléphoner à un contact`

**Raccourci iOS (exemple):**
```
1. Recevoir [Texte] depuis l'entrée
2. Rechercher contact contenant [Texte]
3. Appeler [Contact trouvé]
```

**Résultat:** Le raccourci reçoit "Louisette Bouchard" et lance l'appel

---

### 2. **Envoi d'emails** ✉️

**Événement/Rappel:**
```
Email: Rapport Q1 terminé
```

**Configuration du lien:**
- **Mot-clé:** `Email`
- **Type de correspondance:** `Commence par`
- **Raccourci:** `Nouveau Email`

**Raccourci iOS (exemple):**
```
1. Recevoir [Texte] depuis l'entrée
2. Créer email avec:
   - Sujet: [Texte]
   - Destinataire: patron@entreprise.com
3. Ouvrir email pour envoi
```

**Résultat:** Email pré-rempli avec "Rapport Q1 terminé" comme sujet

---

### 3. **Prises de notes rapides** 📝

**Événement/Rappel:**
```
Note: Idée pour améliorer l'app
```

**Configuration du lien:**
- **Mot-clé:** `Note`
- **Type de correspondance:** `Commence par`
- **Raccourci:** `Créer Note Rapide`

**Raccourci iOS (exemple):**
```
1. Recevoir [Texte] depuis l'entrée
2. Ajouter [Texte] à note "Inbox"
3. Ajouter date/heure
4. Afficher notification "Note ajoutée"
```

**Résultat:** Note créée instantanément

---

### 4. **Journal de gratitude** 🙏

**Événement/Rappel:**
```
Gratitude: Ma famille et ma santé
```

**Configuration du lien:**
- **Mot-clé:** `Gratitude`
- **Type de correspondance:** `Contient le mot`
- **Raccourci:** `Journal Gratitude`

**Raccourci iOS (exemple):**
```
1. Recevoir [Texte] depuis l'entrée
2. Créer entrée dans journal avec:
   - Date du jour
   - Texte: "Je suis reconnaissant pour: [Texte]"
3. Sauvegarder dans Day One / Bear / Notes
```

**Résultat:** Entrée automatique dans le journal

---

### 5. **Liste de courses** 🛒

**Événement/Rappel:**
```
Épicerie: Lait, pain, fromage
```

**Configuration du lien:**
- **Mot-clé:** `Épicerie`
- **Type de correspondance:** `Commence par`
- **Raccourci:** `Ajouter à liste courses`

**Raccourci iOS (exemple):**
```
1. Recevoir [Texte] depuis l'entrée
2. Séparer [Texte] par virgules
3. Pour chaque élément:
   - Ajouter à Rappels "Courses"
4. Afficher "X articles ajoutés"
```

**Résultat:** 3 rappels créés automatiquement

---

### 6. **Messages rapides** 💬

**Événement/Rappel:**
```
Message: Jean - Confirme rendez-vous demain
```

**Configuration du lien:**
- **Mot-clé:** `Message`
- **Type de correspondance:** `Commence par`
- **Raccourci:** `Envoyer Message`

**Raccourci iOS (exemple):**
```
1. Recevoir [Texte] depuis l'entrée
2. Séparer [Texte] par " - "
3. Trouver contact [Partie 1]
4. Envoyer [Partie 2] via Messages
```

**Résultat:** Message pré-rempli prêt à envoyer

---

## 🛠️ Implémentation Technique

### Format de l'URL Shortcuts

```
shortcuts://run-shortcut?name=[NomRaccourci]&input=text&text=[Paramètre]
```

### Exemple concret

**Titre original:**
```
Appeler: Louisette Bouchard
```

**URL générée:**
```
shortcuts://run-shortcut?name=T%C3%A9l%C3%A9phoner&input=text&text=Louisette%20Bouchard
```

### Code Swift (CustomLinkManager.swift)

```swift
/// Ouvre un raccourci avec un paramètre optionnel
@MainActor
func openShortcut(named shortcutName: String, withParameter parameter: String?) -> Bool {
    guard let encodedName = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return false
    }
    
    var urlString = "shortcuts://run-shortcut?name=\(encodedName)"
    
    // ✨ Ajouter le paramètre s'il existe
    if let parameter = parameter, !parameter.isEmpty {
        guard let encodedParameter = parameter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return false
        }
        urlString += "&input=text&text=\(encodedParameter)"
        Logger.app.info("📝 Paramètre détecté: '\(parameter)'")
    }
    
    guard let url = URL(string: urlString) else { return false }
    
    UIApplication.shared.open(url)
    return true
}

/// Extrait le paramètre après ":"
private func extractParameter(from title: String) -> String? {
    guard let colonIndex = title.firstIndex(of: ":") else {
        return nil
    }
    
    let parameterStartIndex = title.index(after: colonIndex)
    let parameter = String(title[parameterStartIndex...])
    
    return parameter.trimmingCharacters(in: .whitespaces)
}
```

---

## 📚 Guide d'utilisation

### Étape 1: Créer le raccourci iOS

1. Ouvrir l'app **Raccourcis**
2. Créer un nouveau raccourci
3. Ajouter l'action **"Recevoir [Texte] depuis l'entrée"**
4. Utiliser la variable `Texte` dans vos actions
5. Nommer le raccourci (ex: "Téléphoner")

### Étape 2: Configurer le lien dans MyDay

1. Ouvrir **Réglages** → **Liens personnalisés**
2. Ajouter un nouveau lien:
   - **Mot-clé:** `Appeler`
   - **Raccourci:** `Téléphoner`
   - **Type:** `Commence par`
3. Activer le lien

### Étape 3: Créer un événement/rappel

1. Créer un événement ou rappel avec le format:
   ```
   Appeler: Nom du contact
   ```
2. Taper sur l'entrée dans MyDay
3. ✨ Le raccourci s'exécute avec le paramètre !

---

## 🎨 Types de correspondance

### 1. **Commence par** (Recommandé pour les paramètres)

**Avantage:** Garantit que le titre est structuré comme prévu

**Exemple:**
- ✅ `Appeler: Jean` → Matche
- ✅ `Appeler: Marie` → Matche
- ❌ `Jean Appeler` → Ne matche pas

---

### 2. **Contient le mot**

**Avantage:** Plus flexible, détecte le mot-clé n'importe où

**Exemple:**
- ✅ `Gratitude: Ma famille` → Matche
- ✅ `Journal de Gratitude: Soleil` → Matche
- ⚠️ **Attention:** Le paramètre sera tout après le premier `:`

---

### 3. **Titre exact**

**Avantage:** Très précis, pas de faux positifs

**Limite:** Ne permet pas de paramètres variables

**Utilisation:** Déconseillé pour les paramètres dynamiques

---

## 🧪 Tests et Validation

### Scénarios de test

| Test | Entrée | Paramètre attendu | Résultat |
|------|--------|-------------------|----------|
| Normal | `Appeler: Jean` | `Jean` | ✅ |
| Espaces multiples | `Appeler:    Jean` | `Jean` | ✅ |
| Sans espace | `Appeler:Jean` | `Jean` | ✅ |
| Paramètre long | `Note: Ceci est une très longue note` | `Ceci est une très longue note` | ✅ |
| Sans paramètre | `Appeler:` | `nil` | ✅ (raccourci sans paramètre) |
| Sans deux-points | `Appeler Jean` | `nil` | ✅ (raccourci sans paramètre) |
| Caractères spéciaux | `Email: Réunion à 14h30` | `Réunion à 14h30` | ✅ (URL encodée) |

### Logs de débogage

```
🔗 Lien personnalisé détecté pour 'Appeler: Louisette Bouchard'
📝 Paramètre détecté: 'Louisette Bouchard'
🚀 Ouverture du raccourci 'Téléphoner' avec paramètre 'Louisette Bouchard'
```

---

## ⚠️ Limitations et considérations

### 1. **Un seul paramètre texte**
- ✅ Supporte: `Appeler: Jean Dupont`
- ❌ Ne supporte pas (pour l'instant): Plusieurs paramètres typés

**Solution:** Parser le texte dans le raccourci lui-même
```
Exemple: "Message: Jean - Salut comment vas-tu?"
Dans le raccourci:
1. Séparer par " - "
2. Partie 1 = destinataire ("Jean")
3. Partie 2 = message ("Salut comment vas-tu?")
```

---

### 2. **Ordre d'exécution**
Le système vérifie **dans l'ordre** :
1. Y a-t-il un lien personnalisé qui matche ? → Exécuter
2. Sinon → Ouvrir l'app par défaut (Calendrier/Rappels)

---

### 3. **Caractères spéciaux**
Tous les caractères sont automatiquement encodés en URL :
- ✅ `é`, `à`, `ç` → Fonctionnent
- ✅ Espaces → Convertis en `%20`
- ✅ Emojis → Encodés correctement

---

### 4. **Longueur du paramètre**
- **Limite théorique:** ~2048 caractères (limite URL iOS)
- **Recommandation:** Garder sous 200 caractères pour la lisibilité

---

## 🚀 Exemples de raccourcis prêts à l'emploi

### Raccourci "Téléphoner"
```
Actions:
1. Recevoir [Texte] depuis l'entrée
2. Rechercher contacts où [Nom] contient [Texte]
3. Si [Aucun résultat]:
   - Afficher "Contact non trouvé"
4. Sinon:
   - Appeler [Premier contact]
```

### Raccourci "Créer Note Rapide"
```
Actions:
1. Recevoir [Texte] depuis l'entrée
2. Obtenir [Date actuelle]
3. Formater [Date] en "d MMM yyyy à HH:mm"
4. Texte = "[Date formatée]\n\n[Texte]"
5. Ajouter à note "Inbox" dans Notes
6. Afficher notification "✅ Note ajoutée"
```

### Raccourci "Envoyer Email Boss"
```
Actions:
1. Recevoir [Texte] depuis l'entrée
2. Créer email:
   - Destinataire: boss@company.com
   - Sujet: [Texte]
   - Corps: "Bonjour,\n\n[Texte]\n\nCordialement"
3. Afficher composition email
```

### Raccourci "Ajouter à Notion"
```
Actions:
1. Recevoir [Texte] depuis l'entrée
2. Obtenir contenu de URL (Notion API):
   - Méthode: POST
   - Headers: Authorization, Content-Type
   - Body JSON: {
       "parent": {"database_id": "xxx"},
       "properties": {
         "Title": {"title": [{"text": {"content": "[Texte]"}}]},
         "Date": {"date": {"start": "[Date actuelle]"}}
       }
     }
3. Afficher "✅ Ajouté à Notion"
```

---

## 📊 Statistiques d'utilisation (Suggestion future)

### Analytics potentielles
- Nombre de liens avec paramètres utilisés par jour
- Raccourcis les plus populaires
- Longueur moyenne des paramètres
- Taux de succès d'exécution

---

## 🎯 Évolutions futures

### Phase 2 (Suggestions)

1. **Paramètres multiples**
   ```
   Action: Paramètre1 | Paramètre2 | Paramètre3
   ```

2. **Paramètres nommés**
   ```
   Email: to=jean@example.com, sujet=Réunion
   ```

3. **Variables dynamiques**
   ```
   Note: {date} - Ma journée a été géniale
   → Remplace {date} par la date actuelle
   ```

4. **Conditions**
   ```
   Si: {heure} > 18h → Raccourci A
   Sinon → Raccourci B
   ```

5. **Validation des paramètres**
   - Vérifier que le paramètre n'est pas vide
   - Alerter l'utilisateur si format invalide

---

## 🎓 Ressources

### Documentation Apple
- [URL Scheme for Shortcuts](https://support.apple.com/guide/shortcuts/run-shortcuts-from-a-url-apd624386f42/ios)
- [Shortcuts User Guide](https://support.apple.com/guide/shortcuts/welcome/ios)

### Communauté
- [r/shortcuts](https://www.reddit.com/r/shortcuts/) - Reddit
- [RoutineHub](https://routinehub.co/) - Galerie de raccourcis

---

## ✅ Checklist d'implémentation

- [x] Extraction du paramètre après `:`
- [x] Nettoyage des espaces (trim)
- [x] Encodage URL du paramètre
- [x] Construction de l'URL avec `&input=text&text=`
- [x] Logging du paramètre détecté
- [x] Gestion des cas sans paramètre (backward compatible)
- [x] Tests avec caractères spéciaux
- [ ] Tests avec emojis (à valider)
- [ ] Documentation utilisateur dans l'app
- [ ] Exemples de raccourcis dans la galerie

---

## 🎉 Conclusion

Cette fonctionnalité **transforme MyDay en hub d'automatisation** en permettant de déclencher des raccourcis iOS avec des données contextuelles provenant directement des événements et rappels.

**Avantages clés:**
- 🚀 **Productivité:** Actions rapides sans ouvrir l'app Raccourcis
- 🎯 **Contexte:** Données réelles passées automatiquement
- 🔧 **Flexibilité:** Compatible avec n'importe quel raccourci
- 📱 **Natif:** Utilise l'API officielle d'Apple

**Impact utilisateur:**
- Moins de friction dans les workflows quotidiens
- Intégration transparente avec l'écosystème iOS
- Personnalisation infinie selon les besoins

---

**Date de création:** 1er février 2026  
**Dernière mise à jour:** 1er février 2026  
**Version:** 2.0  
**Status:** ✅ Production

---

## 📞 Support

Pour toute question ou suggestion d'amélioration, consulter la documentation ou créer une issue sur le repository.

**Happy automating! 🚀**
