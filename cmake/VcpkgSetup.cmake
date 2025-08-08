# ---------------------------------------------------------------------------
# ===        Intégration automatique de vcpkg (toolchain et triplet)      ===
# ---------------------------------------------------------------------------
#
# Configuration automatique de l’intégration avec vcpkg si l’environnement
# est configuré (variable d’environnement VCPKG_ROOT présente).
#
# Objectifs :
# 1. Forcer l'utilisation du fichier toolchain de vcpkg s’il n’est pas déjà défini,
#    ou chaîner un autre toolchain s’il est présent.
# 2. Propager automatiquement le triplet cible par défaut défini dans l'environnement
#    (ex: x64-windows, x64-linux) si aucun triplet spécifique n’est encore défini.
# ---------------------------------------------------------------------------

# Chargement automatique du fichier toolchain vcpkg
if(DEFINED ENV{VCPKG_ROOT})
    if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
        # Aucun fichier de toolchain défini → on utilise celui de vcpkg
        set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
            CACHE STRING "")
    elseif(NOT CMAKE_TOOLCHAIN_FILE MATCHES "vcpkg.cmake$")
        # Un autre toolchain est défini → on le chaînera via vcpkg
        set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}")
        set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
            CACHE STRING "")
    endif()
endif()

# Propagation automatique du triplet cible à partir de la variable d'environnement
if(DEFINED ENV{VCPKG_DEFAULT_TRIPLET} AND NOT DEFINED VCPKG_TARGET_TRIPLET)
    set(VCPKG_TARGET_TRIPLET "$ENV{VCPKG_DEFAULT_TRIPLET}" CACHE STRING "")
endif()