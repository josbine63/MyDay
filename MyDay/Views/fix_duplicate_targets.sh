#!/bin/bash
# fix_duplicate_targets.sh
# Script pour corriger les erreurs de targets dupliqués

echo "🧹 Nettoyage des fichiers de build Xcode..."

# Nettoyer DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/MyDay-*

echo "✅ DerivedData nettoyé"

# Nettoyer le dossier build local si existe
if [ -d "build" ]; then
    rm -rf build
    echo "✅ Dossier build local nettoyé"
fi

echo ""
echo "📝 INSTRUCTIONS MANUELLES (dans Xcode) :"
echo ""
echo "1️⃣  Ouvrez votre projet dans Xcode"
echo ""
echo "2️⃣  Pour CHAQUE fichier suivant :"
echo "    - UserSettings.swift"
echo "    - EventStatusManager.swift"
echo "    - MyDayApp.swift"
echo ""
echo "3️⃣  Faites :"
echo "    a) Cliquez sur le fichier dans le navigateur (panneau gauche)"
echo "    b) Ouvrez l'inspecteur (⌥⌘1 ou View → Inspectors → File)"
echo "    c) Section 'Target Membership' (en bas)"
echo "    d) Décochez TOUT sauf 'MyDay'"
echo ""
echo "4️⃣  Dans Xcode : Product → Clean Build Folder (⇧⌘K)"
echo ""
echo "5️⃣  Dans Xcode : Product → Build (⌘B)"
echo ""
echo "✨ Votre projet devrait compiler sans erreur !"
echo ""
