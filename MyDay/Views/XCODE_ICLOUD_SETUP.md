# 🔧 Configuration Xcode pour iCloud Sync

## ⚠️ IMPORTANT : Étapes obligatoires avant de compiler

Pour que la synchronisation iCloud fonctionne, vous **devez** activer les capabilities iCloud dans Xcode.

---

## 📋 Checklist de configuration

- [ ] Activer iCloud Capability
- [ ] Sélectionner Key-value storage
- [ ] Configurer le container
- [ ] Vérifier les entitlements
- [ ] Tester sur appareil réel

---

## 🛠️ Étapes détaillées

### 1. Ouvrir le projet dans Xcode

```bash
cd /path/to/MyDay
open MyDay.xcodeproj
```

### 2. Sélectionner la target principale

1. Dans le navigateur de projet (⌘1), cliquez sur **MyDay** (en bleu en haut)
2. Sélectionnez la target **MyDay** (pas le widget)
3. Cliquez sur l'onglet **Signing & Capabilities**

### 3. Ajouter la capability iCloud

1. Cliquez sur **+ Capability** (en haut à gauche)
2. Recherchez et double-cliquez sur **iCloud**
3. Une nouvelle section "iCloud" apparaît

### 4. Configurer iCloud

Dans la section **iCloud** qui vient d'apparaître :

#### Option 1 : Key-value storage
- ✅ **Cochez** "Key-value storage"
- ⚠️ **Ne cochez PAS** "iCloud Documents" (pas nécessaire)
- ⚠️ **Ne cochez PAS** "CloudKit" (pas nécessaire pour l'instant)

#### Option 2 : Containers
- Xcode devrait créer automatiquement un container `iCloud.$(CFBundleIdentifier)`
- Si ce n'est pas le cas :
  1. Cliquez sur **+ Container**
  2. Sélectionnez `iCloud.com.josblais.myday` (ou créez-le)

### 5. Vérifier les entitlements

Xcode devrait avoir créé un fichier `MyDay.entitlements`. Vérifiez son contenu :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.$(CFBundleIdentifier)</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
    
    <!-- Autres entitlements existants -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.josblais.myday</string>
    </array>
</dict>
</plist>
```

**Clé importante** :
```xml
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
```

Cette clé est **essentielle** pour NSUbiquitousKeyValueStore.

### 6. Configuration du widget (optionnel)

Si votre widget doit aussi accéder à iCloud :

1. Sélectionnez la target **MyDayWidget**
2. Répétez les étapes 3-4
3. Assurez-vous que le même container est utilisé

---

## 🧪 Tests

### Test 1 : Vérifier que iCloud est configuré

Ajoutez ce code temporaire dans `CustomLinkManager.init()` :

```swift
#if DEBUG
let store = NSUbiquitousKeyValueStore.default
Logger.app.debug("☁️ iCloud available: \(store.dictionaryRepresentation.isEmpty ? "YES" : "YES (with data)")")
#endif
```

Compilez et lancez l'app. Dans la console :
- ✅ Vous devriez voir "☁️ iCloud available: YES"
- ❌ Si vous voyez une erreur, la configuration est incorrecte

### Test 2 : Test sur 2 appareils

**Prérequis** :
- 2 appareils iOS (iPhone/iPad)
- Connectés au **même compte iCloud**
- App installée sur les 2 appareils

**Procédure** :
1. **iPhone** : Activez "Synchronisation iCloud" dans Réglages > Liens personnalisés
2. **iPhone** : Créez un lien "Test → TestShortcut"
3. **iPad** : Ouvrez MyDay
4. **iPad** : Attendez 30 secondes maximum
5. **iPad** : Vérifiez que le lien "Test" apparaît ✅

### Test 3 : Debug avec Console.app (macOS)

1. Connectez votre iPhone à votre Mac
2. Ouvrez **Console.app** (Applications > Utilitaires)
3. Sélectionnez votre iPhone dans la barre latérale
4. Filtrez par "MyDay" ou "ubiquity"
5. Surveillez les logs lors de la création d'un lien

Logs attendus :
```
[MyDay] ☁️ Sync enabled: true
[MyDay] 💾 1 lien(s) sauvegardé(s) en local
[MyDay] ☁️ 1 lien(s) sauvegardé(s) dans iCloud
[ubiquityd] Syncing key-value store...
```

---

## 🐛 Problèmes courants

### Erreur : "iCloud capability not configured"

**Symptôme** :
```
Error: The iCloud capability is not enabled for this app.
```

**Solution** :
1. Vérifiez que "Key-value storage" est coché
2. Nettoyez le build (⌘⇧K)
3. Recompilez (⌘R)

### Erreur : "Ubiquitous key-value store identifier is not configured"

**Symptôme** :
```
Error: com.apple.developer.ubiquity-kvstore-identifier not found
```

**Solution** :
1. Ouvrez `MyDay.entitlements`
2. Ajoutez manuellement :
```xml
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
```
3. Recompilez

### Aucune synchronisation entre appareils

**Vérifications** :
1. ✅ Les 2 appareils sont sur le **même compte iCloud**
2. ✅ iCloud Drive est activé dans Réglages > iCloud
3. ✅ L'option "Synchronisation iCloud" est activée dans MyDay
4. ✅ Les 2 appareils ont une connexion Internet
5. ✅ Attendez jusqu'à 1-2 minutes pour la première sync

**Astuce de debugging** :
```swift
// Dans CustomLinkManager
NSUbiquitousKeyValueStore.default.synchronize()
Logger.app.debug("🔄 Force sync triggered")
```

### Données incohérentes après modifications

**Symptôme** :
- Liens différents sur chaque appareil
- Données qui "sautent" entre versions

**Solution** :
1. Désactivez la sync sur tous les appareils
2. Sur l'appareil de référence, supprimez tous les liens
3. Recréez les liens souhaités
4. Activez la sync
5. Attendez 1 minute
6. Activez la sync sur les autres appareils

---

## 📱 Configuration du compte développeur Apple

### Si vous avez un compte développeur payant

✅ Tout devrait fonctionner automatiquement.

### Si vous utilisez un compte gratuit

⚠️ Limitations possibles :
- iCloud pourrait ne pas fonctionner en mode développement gratuit
- Certaines capabilities nécessitent un compte payant

**Vérification** :
1. Allez dans Signing & Capabilities
2. Si vous voyez un avertissement jaune/rouge, un compte payant peut être nécessaire

---

## 🔐 Confidentialité : Info.plist

Aucune modification de `Info.plist` n'est nécessaire pour NSUbiquitousKeyValueStore.

**Déjà présent dans MyDay** :
```xml
<key>NSCalendarsUsageDescription</key>
<string>Pour afficher vos événements</string>
<!-- etc. -->
```

**Pas besoin d'ajouter** :
- ❌ Pas de `NSUbiquitousContainersUsageDescription` (deprecated)
- ❌ Pas de permissions iCloud supplémentaires

---

## 🧹 Nettoyage pour tester

### Réinitialiser iCloud Key-Value Store

**Option 1 : Via Xcode (simulateur uniquement)**
```bash
# Effacer les données du simulateur
xcrun simctl erase all
```

**Option 2 : Sur appareil réel**
1. Réglages > [Votre nom] > iCloud
2. Gérer le stockage
3. Trouver MyDay (si visible)
4. Supprimer les données

**Option 3 : Programmatiquement (DEBUG only)**

Ajoutez cette fonction dans `CustomLinkManager` :

```swift
#if DEBUG
func resetICloudData() {
    let store = NSUbiquitousKeyValueStore.default
    store.removeObject(forKey: linksKey)
    store.synchronize()
    
    // Aussi nettoyer local
    defaults.removeObject(forKey: linksKey)
    
    Logger.app.warning("🗑️ Toutes les données iCloud et locales ont été effacées")
}
#endif
```

Appelez-la depuis CustomLinkDebugView.

---

## 📊 Monitoring de la synchronisation

### Logs recommandés

Ajoutez ces logs dans `CustomLinkManager` :

```swift
private func saveLinksToICloud(_ links: [CustomLink]) {
    if let encoded = try? JSONEncoder().encode(links) {
        iCloudStore.set(encoded, forKey: linksKey)
        
        #if DEBUG
        let dataSizeKB = Double(encoded.count) / 1024.0
        Logger.app.debug("☁️ iCloud save: \(links.count) links, \(String(format: "%.2f", dataSizeKB)) KB")
        #endif
        
        let success = iCloudStore.synchronize()
        Logger.app.debug("☁️ Sync trigger: \(success ? "✅" : "❌")")
    }
}
```

### Dashboard iCloud (Apple Developer)

1. Connectez-vous sur https://developer.apple.com
2. Allez dans "Certificates, Identifiers & Profiles"
3. Sélectionnez votre App ID
4. Vérifiez que "iCloud" est activé ✅

---

## ✅ Checklist finale avant release

### Configuration Xcode
- [ ] iCloud capability activée
- [ ] Key-value storage coché
- [ ] Container configuré
- [ ] Entitlements présents
- [ ] Target principale configurée
- [ ] Widget configuré (si applicable)

### Tests
- [ ] Sync entre 2 appareils fonctionne
- [ ] Création de lien se propage
- [ ] Modification de lien se propage
- [ ] Suppression de lien se propage
- [ ] Toggle ON/OFF fonctionne
- [ ] Fallback local fonctionne (mode avion)
- [ ] Conflits résolus automatiquement

### Documentation
- [ ] ICLOUD_SYNC_GUIDE.md à jour
- [ ] ICLOUD_SYNC_SUMMARY.md à jour
- [ ] Ce fichier de configuration à jour
- [ ] Commentaires inline dans le code

### App Store (si applicable)
- [ ] Screenshot montrant la feature iCloud
- [ ] Description mentionnant la sync iCloud
- [ ] Privacy policy mise à jour (si nécessaire)

---

## 🎓 Ressources Apple

### Documentation officielle
- [About Key-Value Storage](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)
- [iCloud Design Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/)
- [Enabling iCloud in Your App](https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app)

### WWDC Sessions
- WWDC 2019: "Designing for Adverse Network and Temperature Conditions"
- WWDC 2017: "What's New in CloudKit"

### Sample Code
- [CloudKitAtlas](https://developer.apple.com/documentation/cloudkit/managing_icloud_containers_with_the_cloudkit_database_app)

---

## 📞 Support

### En cas de problème

1. **Vérifiez les logs** dans Xcode Console
2. **Consultez** ICLOUD_SYNC_GUIDE.md section "Dépannage"
3. **Testez** sur appareil réel (pas simulateur)
4. **Attendez** jusqu'à 2 minutes pour la première sync

---

**Version** : 2.0.0  
**Date** : 1er février 2026  
**Auteur** : Assistant AI  
**Status** : ✅ Ready for Configuration

---

*Suivez ces étapes attentivement pour garantir le bon fonctionnement de la synchronisation iCloud.*
