# === Configuration du compilateur (standard, flags, compatibilité par plateforme) ===
# Inclus :
# - sélection de C++23 ou C++17 selon la version du compilateur
# - flags spécifiques à MSVC et AppleClang
# - ajout de _CRT_SECURE_NO_WARNINGS et compilation parallèle (/MP)

# === Détection du nom et de la version de l'outil de génération (make, ninja, MSBuild, etc.) ===
#
# Ce bloc identifie automatiquement quel outil est utilisé pour générer le projet,
# puis exécute une commande spécifique à cet outil pour en extraire la version.
# Cela permet de consigner ou afficher la version de l'outil actif durant la génération.

# Récupère uniquement le nom du programme de génération, sans extension (ex: "ninja", "MSBuild")
get_filename_component(CMAKE_MAKE_NAME "${CMAKE_MAKE_PROGRAM}" NAME_WE)

# Traitement selon l’outil détecté
if(CMAKE_MAKE_NAME STREQUAL "MSBuild")
    # MSBuild (Visual Studio)
    execute_process(
        COMMAND "${CMAKE_MAKE_PROGRAM}" /nologo /version
        OUTPUT_VARIABLE CMAKE_MAKE_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
    )
    set(CMAKE_MAKE_VERSION "MSBuild ${CMAKE_MAKE_VERSION}")

elseif(CMAKE_MAKE_NAME STREQUAL "ninja")
    # Ninja (build system rapide utilisé notamment avec Clang ou Visual Studio)
    execute_process(
        COMMAND "${CMAKE_MAKE_PROGRAM}" --version
        OUTPUT_VARIABLE CMAKE_MAKE_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
    )
    set(CMAKE_MAKE_VERSION "Ninja ${CMAKE_MAKE_VERSION}")

elseif(CMAKE_MAKE_NAME STREQUAL "xcodebuild")
    # Xcode (build Apple/macOS)
    execute_process(
        COMMAND "${CMAKE_MAKE_PROGRAM}" -version
        OUTPUT_VARIABLE CMAKE_MAKE_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
    )
    string(REGEX REPLACE "\n.*" "" CMAKE_MAKE_VERSION "${CMAKE_MAKE_VERSION}")

else()
    # Autre outil (fallback générique)
    execute_process(
        COMMAND "${CMAKE_MAKE_PROGRAM}" --version
        OUTPUT_VARIABLE CMAKE_MAKE_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
    )
    string(REGEX REPLACE "\n.*" "" CMAKE_MAKE_VERSION "${CMAKE_MAKE_VERSION}")
endif()

# Si l'environnement Visual Studio est actif, récupère aussi sa version
if(DEFINED ENV{VisualStudioVersion})
    set(VS_VERSION $ENV{VisualStudioVersion})
endif()


# === Configuration du compilateur et des outils d'accélération de build ===

# ---------------------------------------------------------------------------
# ⚙️ Paramètres généraux du compilateur
# ---------------------------------------------------------------------------

# === Définition dynamique du standard C++ selon le compilateur et sa version ===
#
# Ce bloc détecte automatiquement le compilateur utilisé (MSVC, GCC, Clang)
# et sa version, pour activer le support de C++23 si disponible.
# Sinon, il bascule sur C++17 comme fallback sécurisé.
#
# Cela permet :
# - d'exploiter les fonctionnalités modernes quand elles sont supportées
# - tout en conservant la compatibilité sur des machines plus anciennes

if (MSVC)
    # 🎯 MSVC (Microsoft Visual C++) : on vérifie MSVC_VERSION
    # MSVC 19.38 correspond à Visual Studio 2022 version 17.8
    if (MSVC_VERSION GREATER_EQUAL 1938)
        message(STATUS "MSVC >= 19.38 détecté : activation de C++23")
        set(CMAKE_CXX_STANDARD 23)
    else()
        message(STATUS "MSVC trop ancien : fallback vers C++17")
        set(CMAKE_CXX_STANDARD 17)
    endif()

elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # 🐧 GCC (GNU Compiler Collection)
    # GCC 13.0+ supporte C++23
    if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 13)
        message(STATUS "GCC >= 13 détecté : activation de C++23")
        set(CMAKE_CXX_STANDARD 23)
    else()
        message(STATUS "GCC trop ancien : fallback vers C++17")
        set(CMAKE_CXX_STANDARD 17)
    endif()

elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # 🍎 Clang (AppleClang ou LLVM Clang)
    # Clang 17.0+ supporte correctement C++23
    if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 17)
        message(STATUS "Clang >= 17 détecté : activation de C++23")
        set(CMAKE_CXX_STANDARD 23)
    else()
        message(STATUS "Clang trop ancien : fallback vers C++17")
        set(CMAKE_CXX_STANDARD 17)
    endif()

else()
    # 🔍 Cas inconnu : on joue la sécurité
    message(WARNING "Compilateur inconnu : C++17 sélectionné par défaut")
    set(CMAKE_CXX_STANDARD 17)
endif()

# 🔒 On rend le standard obligatoire (pas de fallback implicite)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Spécificités pour MSVC (Visual Studio)
if(MSVC)
    # Désactive les warnings liés aux fonctions C considérées comme "non sécurisées"
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    # Active la compilation parallèle (multicore)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")

# Spécificité pour macOS (Xcode 10+ avec AppleClang)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL AppleClang)
    # Force l’utilisation de libc++ au lieu de libstdc++ pour assurer la compatibilité
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++ -lc++abi")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif()
