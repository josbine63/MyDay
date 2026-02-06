# 📚 Guide de synchronisation iCloud pour MyDay

## ☁️ Vue d'ensemble

MyDay propose maintenant la **synchronisation iCloud** pour vos liens personnalisés, vous permettant d'accéder aux mêmes configurations sur tous vos appareils Apple.

---

## 🔑 Fonctionnalités

### ✅ Ce qui est synchronisé

- **Liens personnalisés** : Tous vos mots-clés et raccourcis associés
- **Configuration des liens** : Type de correspondance (exact, contient, commence par)
- **États** : Liens activés/désactivés
- **Ordre** : L'ordre de vos liens est préservé

### 📱 Appareils supportés

- iPhone avec iOS 16.0+
- iPad avec iPadOS 16.0+
- Tous les appareils connectés au même compte iCloud

---

## ⚙️ Configuration

### 1. Activer la synchronisation iCloud

1. Ouvrez MyDay
2. Allez dans **Réglages** ⚙️
3. Appuyez sur **Liens personnalisés** 🔗
4. Activez **Synchronisation iCloud** ☁️

### 2. Vérifier la connexion iCloud

Assurez-vous que :
- ✅ Vous êtes connecté à iCloud sur tous vos appareils
- ✅ iCloud Drive est activé dans Réglages > [Votre nom] > iCloud
- ✅ Vous avez une connexion Internet active

---

## 🚀 Utilisation

### Synchronisation automatique

Une fois activée, la synchronisation se fait **automatiquement** :

1. **Création d'un lien** sur iPhone → Apparaît sur iPad quelques secondes après
2. **Modification d'un lien** sur iPad → Mise à jour sur iPhone
3. **Suppression d'un lien** → Supprimé partout

### Temps de synchronisation

- **Changements locaux** : Instantanés
- **Synchronisation iCloud** : Quelques secondes à 1 minute
- **Premiers lancements** : Jusqu'à 2 minutes pour la synchronisation initiale

### Indicateurs visuels

| Symbole | Signification |
|---------|---------------|
| ☁️ | Synchronisation iCloud activée |
| 📦 | Stockage local uniquement |

---

## 🔐 Confidentialité et sécurité

### Données stockées dans iCloud

Les liens personnalisés sont stockés dans **NSUbiquitousKeyValueStore** :
- ✅ Chiffrement end-to-end (avec clés de votre compte iCloud)
- ✅ Limite de 1 MB (largement suffisant pour les liens)
- ✅ Aucune donnée partagée avec des tiers
- ✅ Vous gardez le contrôle total de vos données

### Que voit Apple ?

Apple ne peut **pas** voir :
- ❌ Le contenu de vos liens
- ❌ Les noms de vos raccourcis
- ❌ Vos mots-clés

Apple peut **uniquement** :
- ✅ Détecter qu'une donnée chiffrée a changé (pour déclencher la sync)
- ✅ Stocker les données chiffrées sur leurs serveurs

### Désactivation de la synchronisation

Si vous désactivez la sync iCloud :
- ✅ Les données restent **locales** sur chaque appareil
- ✅ Aucune donnée n'est supprimée automatiquement
- ✅ Les modifications futures ne se synchronisent plus
- ⚠️ Les données déjà sur iCloud restent jusqu'à nettoyage manuel

---

## 🐛 Dépannage

### Les liens ne se synchronisent pas

**Vérifications** :
1. ✅ iCloud activé sur tous les appareils
2. ✅ Connexion Internet stable
3. ✅ Espace disponible sur iCloud (les liens prennent < 1 KB)
4. ✅ Synchronisation activée dans MyDay sur tous les appareils

**Solutions** :
- Redémarrez l'app sur tous les appareils
- Désactivez puis réactivez la sync iCloud
- Vérifiez Réglages > iCloud > iCloud Drive
- Attendez 1-2 minutes pour la première sync

### Conflits de synchronisation

Si vous modifiez le même lien sur 2 appareils en même temps :
- 🏆 **La dernière modification gagne**
- 🔄 iCloud résout automatiquement les conflits
- ⚠️ Évitez de modifier sur 2 appareils simultanément

### Données incohérentes

Si les données semblent incohérentes :

**Option 1 : Réinitialiser depuis un appareil de référence**
1. Désactivez la sync sur tous les appareils sauf 1
2. Sur l'appareil de référence, activez la sync
3. Attendez 1 minute
4. Réactivez la sync sur les autres appareils

**Option 2 : Nettoyer et recommencer**
1. Désactivez la sync sur tous les appareils
2. Exportez vos liens (capture d'écran ou note)
3. Supprimez tous les liens
4. Recréez-les sur un seul appareil
5. Réactivez la sync

---

## ⚡ Performances

### Limites techniques

- **Taille maximale** : 1 MB (NSUbiquitousKeyValueStore)
- **Nombre de liens** : Illimité en pratique (~1000+ liens possibles)
- **Fréquence de sync** : Temps réel à quelques secondes
- **Conflits** : Résolus automatiquement (dernière modification)

### Optimisations

MyDay optimise la synchronisation :
- ✅ Sauvegarde locale ET iCloud en parallèle
- ✅ Chargement depuis le cache si iCloud indisponible
- ✅ Évite les synchronisations inutiles (détection de changements)

---

## 📊 Gestion des données

### Voir l'utilisation iCloud

1. Réglages > [Votre nom] > iCloud
2. Gérer le stockage
3. Cherchez "MyDay" (si visible)

**Note** : Les liens personnalisés utilisent **NSUbiquitousKeyValueStore**, pas iCloud Drive, donc ils n'apparaissent généralement pas dans la liste des apps.

### Supprimer les données iCloud

**Méthode 1 : Dans MyDay**
1. Désactivez la sync iCloud
2. Supprimez tous les liens
3. Réactivez puis redésactivez la sync (force le nettoyage)

**Méthode 2 : Paramètres système**
1. Réglages > [Votre nom] > iCloud
2. Gérer le stockage
3. MyDay (si visible) > Supprimer les documents

---

## 🔮 Fonctionnalités futures

### Prévu pour les prochaines versions

- [ ] Export/Import de configurations (sauvegarde manuelle)
- [ ] Sync avec CloudKit (pour partage entre utilisateurs)
- [ ] Historique de synchronisation
- [ ] Résolution manuelle de conflits
- [ ] Indicateur de statut de sync en temps réel

---

## ❓ FAQ

### Puis-je utiliser MyDay sans iCloud ?

**Oui** ! La sync iCloud est **optionnelle**. Sans iCloud :
- ✅ Toutes les fonctionnalités de base fonctionnent
- ✅ Vos liens restent locaux sur chaque appareil
- ❌ Pas de synchronisation entre appareils

### Que se passe-t-il si je me déconnecte d'iCloud ?

- ✅ Les données restent locales sur l'appareil
- ⚠️ La synchronisation s'arrête
- ✅ Aucune donnée n'est perdue localement
- ℹ️ Reconnectez-vous pour reprendre la sync

### Puis-je désactiver temporairement la sync ?

**Oui** ! Désactivez le toggle dans Réglages > Liens personnalisés.
- Utile si vous voulez tester des liens sans affecter les autres appareils

### Les raccourcis eux-mêmes sont-ils synchronisés ?

**Non**. MyDay synchronise uniquement :
- ✅ La **configuration** des liens (mots-clés, noms de raccourcis)
- ❌ **Pas** les raccourcis Siri eux-mêmes

Pour synchroniser les raccourcis :
1. Utilisez l'app **Raccourcis** d'Apple
2. Activez la sync iCloud dans Réglages > Raccourcis
3. Les raccourcis se synchronisent automatiquement

### Combien de temps les données restent-elles sur iCloud ?

Tant que :
- ✅ Vous êtes connecté à iCloud
- ✅ Vous n'avez pas supprimé l'app sur tous les appareils
- ✅ Vous n'avez pas nettoyé manuellement les données iCloud

---

## 🛠️ Pour les développeurs

### Architecture technique

```
CustomLinkManager
├── UserDefaults (App Group) ← Stockage local
└── NSUbiquitousKeyValueStore ← Synchronisation iCloud
    ├── Notifications: didChangeExternallyNotification
    ├── Résolution de conflits automatique
    └── Limit: 1 MB / 1024 clés
```

### Flux de données

1. **Sauvegarde locale** → UserDefaults (App Group)
2. **Sauvegarde iCloud** → NSUbiquitousKeyValueStore (si activé)
3. **Notification de changement** → Rechargement automatique
4. **Conflict resolution** → Dernière modification gagne

### Debugging

```swift
// Activer les logs détaillés
Logger.app.debug("☁️ iCloud sync status: \(useICloudSync)")

// Tester la sync manuellement
NSUbiquitousKeyValueStore.default.synchronize()

// Observer les changements
NotificationCenter.default.addObserver(
    forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
    ...
)
```

---

## 📜 Licence et conditions

Ce guide fait partie du projet **MyDay**.
Tous droits réservés.

---

**Version** : 2.0.0  
**Date** : 1er février 2026  
**Auteur** : Assistant AI  
**Status** : ✅ Production Ready

---

*Pour toute question, consultez la documentation complète ou contactez le support.*
