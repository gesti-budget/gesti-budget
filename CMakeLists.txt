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
# Ajoutez une source à l'exécutable de ce projet.
add_executable (${GBEX_EXE} "gesti-budget.cpp" "gesti-budget.h")

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET ${GBEX_EXE} PROPERTY CXX_STANDARD 20)
endif()

# TODO: Ajoutez des tests et installez des cibles si nécessaire.


# ---------------------------------------------------------------------------
# Affiche les diférentes informations du projet
include(ShowVar)