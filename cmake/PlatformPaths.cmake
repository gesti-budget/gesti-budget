# === Définition des chemins spécifiques à la plateforme cible ===
# Chemins vers les ressources, icônes, documentation, etc.
# pour Windows, macOS (.app), Linux (arborescence FHS).

# === Définition des chemins de ressources selon la plateforme (macOS, Windows, Linux) ===
#
# Ce bloc permet d’adapter dynamiquement :
# - les chemins vers les icônes et ressources (images, thèmes, rapports, etc.)
# - les dossiers de documentation
# en fonction du système d’exploitation cible (Apple, Windows, Linux).
#
# Cela garantit que les fichiers sont installés aux bons emplacements,
# tout en maintenant une logique portable pour le packaging.

if(APPLE)
    # 🍎 macOS : configuration spécifique pour bundle d'application .app

    # Nom de l'icône à inclure dans le bundle
    set(MACOSX_APP_ICON_NAME mmex.icns)

    # Chemin complet de l'icône source (utilisé pour Info.plist)
    set(MACOSX_APP_ICON_FILE "${PROJECT_SOURCE_DIR}/resources/${MACOSX_APP_ICON_NAME}")

    # Dossier où seront placés les fichiers de documentation dans le bundle .app
    set(MMEX_DOC_DIR ${MMEX_EXE}.app/Contents/SharedSupport/doc)

    # Dossier des ressources embarquées dans le .app (icônes, thèmes, rapports…)
    set(MMEX_RES_DIR ${MMEX_EXE}.app/Contents/Resources)

elseif(WIN32)
    # 🪟 Windows : structure simplifiée dans le même dossier que l'exécutable
    set(GBEX_DOC_DIR docs)
    set(GBEX_RES_DIR res)

else()
    # 🐧 Linux ou autres Unix : structure de type FHS (Filesystem Hierarchy Standard)
    set(GBEX_DOC_DIR share/doc/mmex)
    set(GBEX_RES_DIR share/mmex/res)
endif()

# 🔗 Définition des sous-dossiers standards pour les ressources
set(GBEX_RES_DIR_THEMES "${GBEX_RES_DIR}/themes")    # thèmes UI
set(GBEX_RES_DIR_REPORTS "${GBEX_RES_DIR}/reports")  # rapports HTML