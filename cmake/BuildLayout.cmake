# === Configuration des chemins de sortie et du layout de build (Visual Studio & cross-platform) ===
#
# Ce bloc :
# - Définit où placer les exécutables générés
# - Ajuste le comportement de Visual Studio pour qu'il intègre la cible INSTALL par défaut
# - Force un chemin d’installation local propre si aucun n’a été défini

# Dossier par défaut pour les exécutables (binaries)
set(GBEX_BIN_DIR bin)

## 🎯 Ajustements spécifiques pour Visual Studio ##
if(MSVC)
    message(STATUS "Tuning for Visual Studio IDE")

    # Si aucun préfixe d’installation n’est défini, on force un répertoire local dans le build dir
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        set(CMAKE_INSTALL_PREFIX "${PROJECT_BINARY_DIR}/install"
            CACHE PATH "Install directory used by INSTALL target" FORCE)
    endif()

    # 🔁 Redirige les exécutables vers le dossier d’installation configuré (ex: build/install/bin/)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY $<1:${CMAKE_INSTALL_PREFIX}/${GBEX_BIN_DIR}>)

    # 💡 Visual Studio 2015+ (CMake 3.3+) : ajoute automatiquement la cible INSTALL dans l’IDE
    if(NOT CMAKE_VERSION VERSION_LESS 3.3)
        set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD ON)
    endif()
endif()
