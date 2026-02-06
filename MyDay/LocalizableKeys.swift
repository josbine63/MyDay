// LocalizableKeys.swift

import Foundation

enum L10n {
    static var permissionsTitle: String {
        NSLocalizedString("permissionsTitle", comment: "Titre de la vue des permissions")
    }

    static var permissionsCalendar: String {
        NSLocalizedString("permissionsCalendar", comment: "Libellé de permission pour le calendrier")
    }

    static var permissionsReminders: String {
        NSLocalizedString("permissionsReminders", comment: "Libellé de permission pour les rappels")
    }

    static var permissionsPhotos: String {
        NSLocalizedString("permissionsPhotos", comment: "Libellé de permission pour les photos")
    }

    static var permissionsHealth: String {
        NSLocalizedString("permissionsHealth", comment: "Libellé de permission pour la santé")
    }

    static var permissionsAllow: String {
        NSLocalizedString("permissionsAllow", comment: "Texte du bouton pour autoriser une permission")
    }

    static var permissionsContinue: String {
        NSLocalizedString("permissionsContinue", comment: "Texte du bouton pour continuer après avoir accordé les permissions")
    }
}
