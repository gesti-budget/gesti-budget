cmake_minimum_required (VERSION 3.30 FATAL_ERROR)


# ---------------------------------------------------------------------------
# cmake/
# ├── Version.cmake                 # Gestion des versions (NEWS, suffixe instable)
# ├── GitInfo.cmake                 # Extraction des infos Git (branche, commit, date)
# ├── VcpkgSetup.cmake              # Détection et intégration automatique de vcpkg
# ├── BuildHeader.cmake             # Génération du build.h
# ├── LinuxDetection.cmake          # Détection OS/distro Linux
# ├── CompilerSetup.cmake           # Configuration du compilateur et des outils de cache
# ├── CacheTool.cmake               # Configuration du cache de compilation (ccache/clcache)
# ├── PlatformPaths.cmake	        # Définition des chemins de ressources selon la plateforme
# ├── GraphVizExport.cmake          # Options pour l'export Graphviz des dépendances
# ├── WxWidgetsSetup.cmake          # Configuration de wxWidgets (si nécessaire)
# ├── CurlSetup.cmake               # Configuration de la dépendance CURL/libcurl
# ├── BuildLayout.cmake             # Configuration des chemins de build et ressources
# ├── PackagingSetup.cmake          # Configuration de l'archivage et packaging
# ├── CPackSetup.cmake              # Configuration de CPack pour les paquets multiplateformes
# └── install.cmake                # Installation des fichiers générés (build.h, etc.)
# === Chargement des modules CMake personnalisés ===
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake") 


# 🔢 Gestion de la version du projet (extrait de NEWS)
include(Version)

# 📦 Détection de vcpkg et configuration du toolchain
include(VcpkgSetup)


# === Configuration du format de debug pour Visual Studio (MSVC) ===
# Si la politique CMP0141 (CMake ≥ 3.28) est disponible,
# active le support du rechargement à chaud (Edit & Continue) pour MSVC en Debug.
# Activez Rechargement à chaud pour les compilateurs MSVC si cela est pris en charge.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

project (GBEX VERSION ${GBEX_VERSION})

# Options de configuration du projet
option(GBEX_PORTABLE_INSTALL "Inclure un fichier gbexini.db3 vide dans l'installation Windows (mode portable)" OFF)
option(GBEX_ENCRYPTION_OPTIONAL "Compiler même si la bibliothèque wxsqlite ne prend pas en charge le chiffrement" OFF)

# Nom du fichier exécutable généré
set(GBEX_EXE gbex)

# 📝 Génération du fichier build.h (version + date/heure de build)
include(BuildHeader)

# 🎯 Récupération des infos Git (branche, commit, date)
include(GitInfo)


# 🐧 Détection de la distribution Linux (via lsb_release, etc.)
include(LinuxDetection)

# ⚙️ Configuration du compilateur (C++17/23, flags MSVC, AppleClang, etc.)
include(CompilerSetup)

# 🚀 Détection et configuration d’un outil de cache de compilation
include(CacheTool)

# 📊 Configuration pour l’export des dépendances au format Graphviz
include(GraphVizExport)

# 🧱 Définition des chemins vers ressources/doc selon la plateforme
include(PlatformPaths)

# 📚 Chargement de la dépendance wxWidgets
include(WxWidgetsSetup)


# 🌐 Chargement de la dépendance libcurl (avec fallback avancé)
include(CurlSetup)


add_subdirectory(3rd/fmt)

# 📦 Mise en place de l’arborescence de build et des répertoires d’installation
include(BuildLayout)

## Inclusion des sous-dossiers qui déclarent des cibles (executables, bibliothèques) ##
add_subdirectory(3rd)
add_subdirectory(po)
add_subdirectory(src)

# 📦 Génération des packages de thèmes et rapports (zip .mmextheme/.grm)
include(PackagingSetup)

## Tuning for VisualStudio IDE ##
if(NOT CMAKE_VERSION VERSION_LESS 3.6)
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${GBEX_EXE})
endif()

# 📦 Configuration de l'installation des fichiers générés et des ressources
include(install)

# 📦 Configuration de CPack pour la création de paquets multiplateformes 
include(CPackSetup)

# TODO: Ajoutez des tests et installez des cibles si nécessaire.


# ---------------------------------------------------------------------------
# Affiche les diférentes informations du projet
include(ShowVar)