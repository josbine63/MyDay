# 🧪 Tests

## Note sur les tests

Ce projet utilise des **tests manuels** effectués par le développeur plutôt que des tests unitaires automatisés.

### Pourquoi ?

- ✅ Tests manuels sur appareil réel plus pertinents pour cette feature
- ✅ Les raccourcis Apple ne fonctionnent pas bien dans les simulateurs
- ✅ Validation visuelle et comportementale préférée
- ✅ Réduction de la complexité du projet

### Scénarios de test manuels recommandés

#### 1. Test de création de lien
- [ ] Créer un raccourci dans l'app Raccourcis
- [ ] Ajouter un lien dans MyDay
- [ ] Vérifier la sauvegarde

#### 2. Test de matching
- [ ] Lien avec correspondance "Exact"
- [ ] Lien avec correspondance "Contient"
- [ ] Lien avec correspondance "Commence par"
- [ ] Vérifier les majuscules/minuscules
- [ ] Vérifier les accents

#### 3. Test d'activation
- [ ] Créer un événement correspondant
- [ ] Vérifier la présence du badge 🔗
- [ ] Toucher l'événement → Le raccourci doit se lancer

#### 4. Test de gestion
- [ ] Modifier un lien
- [ ] Désactiver/Activer un lien
- [ ] Supprimer un lien
- [ ] Réorganiser les liens

#### 5. Test de persistance
- [ ] Créer des liens
- [ ] Fermer l'app complètement
- [ ] Rouvrir → Les liens doivent être présents

#### 6. Test d'erreurs
- [ ] Lien vers un raccourci inexistant
- [ ] Mot-clé vide
- [ ] Nom de raccourci vide

---

## Tests automatisés retirés

Les tests unitaires ont été volontairement retirés du projet car :
- Nécessitent XCTest ou Swift Testing framework
- Complexité supplémentaire non nécessaire pour ce projet
- Le développeur préfère tester manuellement sur appareil réel

---

*Si vous souhaitez réintroduire des tests automatisés, consultez `CUSTOM_LINKS_IMPLEMENTATION.md` section "Tests".*
