# === Validation : ce fichier doit être appelé depuis le CMakeLists.txt racine ===
#
# Ce bloc vérifie que le `CMakeLists.txt` actuel (dans src/) est bien inclus via
# un `add_subdirectory(src)` depuis le script principal.
# Si ce n’est pas le cas (c'est-à-dire exécuté directement), on affiche une erreur bloquante.

get_directory_property(m_hasParent PARENT_DIRECTORY)
if(NOT m_hasParent)
    message(FATAL_ERROR "Ce fichier doit être utilisé via le script CMake principal (top-level CMakeLists.txt) !")
endif()
unset(m_hasParent)

# === Inclusion du module pour vérifier la compatibilité des options du compilateur C++ ===
include(CheckCXXCompilerFlag)

# === 🔔 Configuration des options de compilation (warnings, charset, plateformes) ===

# --- ⚠️ Niveaux d’avertissements activés selon le compilateur ---
if(MSVC)
    # 🪟 Sous Windows avec Visual Studio :
    # Supprime tous les anciens flags /W0 à /W4 de la chaîne de compilation
    string(REGEX REPLACE "(^| )[/-](w|W[0-4])( |$)" " " CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
    string(REGEX REPLACE "(^| )[/-](w|W[0-4])( |$)" " " CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    
    # Force le niveau d'avertissement maximal raisonnable (/W4)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W4")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")

else()
    # 🐧 Sous Linux/macOS (GCC / Clang) : vérifie la compatibilité des flags avant de les activer

    # Teste si le compilateur supporte les options ci-dessous
    check_cxx_compiler_flag(-Wduplicated-cond Wduplicated-cond)
    check_cxx_compiler_flag(-Wduplicated-branches Wduplicated-branches)
    check_cxx_compiler_flag(-Wnull-dereference Wnull-dereference)
    check_cxx_compiler_flag(-Wlogical-op Wlogical-op)

    # Active les warnings valides + options standards
    add_compile_options(
        -Wall                         # tous les avertissements de base
        -Wextra                       # avertissements supplémentaires
        -Wno-unknown-pragmas          # ne pas signaler les pragmas non reconnus
        -Wformat=2                    # vérification stricte des formats printf/scanf
        $<$<BOOL:${Wduplicated-cond}>:-Wduplicated-cond>        # Active l'avertissement sur les conditions dupliquées (if/else avec la même condition) 
                                                                # mais uniquement si la variable CMake Wduplicated-cond est vraie 
                                                                # (cette variable est définie plus haut par check_cxx_compiler_flag).

        $<$<BOOL:${Wduplicated-branches}>:-Wduplicated-branches> # Avertissement si deux branches (if/else) contiennent exactement le même code.
                                                                 # Ajouté seulement si le compilateur le supporte.

        $<$<BOOL:${Wnull-dereference}>:-Wnull-dereference>     # Avertissement sur les déréférencements nuls détectés à la compilation.
                                                                # Inclus uniquement si l’option est reconnue.

        $<$<BOOL:${Wlogical-op}>:-Wlogical-op>                 # Avertissement sur les erreurs logiques courantes (ex: && au lieu de ||, 
                                                              # ou tests toujours vrais/faux). Activé seulement si disponible.

    )

    # Si compilateur récent (GCC >= 6), on ajoute des vérifications plus strictes
    if(NOT (CMAKE_COMPILER_IS_GNUCXX AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 6))
        check_cxx_compiler_flag(-Wuseless-cast Wuseless-cast)
        add_compile_options(
            -Werror=old-style-cast               # les vieux cast sont des erreurs
            $<$<BOOL:${Wuseless-cast}>:-Werror=useless-cast> # même chose pour cast inutiles
        )
    endif()
endif()

# --- 🌐 Gestion de l'encodage des sources sous Visual Studio ---
if(MSVC)
    # Teste si le flag /utf-8 est supporté (Visual Studio 2015+)
    check_cxx_compiler_flag(/utf-8 MSVC_UFT8_CXX_FLAG)
    if(MSVC_UFT8_CXX_FLAG)
        # 🌐 Active l'encodage UTF-8 pour les sources
        add_compile_options(/utf-8)
    else()
        # 🩹 Pour les anciens MSVC, injecte un pragma via un header forcé
        file(GENERATE
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/msvc_build_header_$<CONFIG>.h
            CONTENT "#pragma execution_character_set(\"utf-8\")"
        )
        add_compile_options(/FI"${CMAKE_CURRENT_BINARY_DIR}/msvc_build_header_$<CONFIG>.h")
    endif()
endif()

# --- 🔢 Injection des informations de version dans le code source ---
# Génère le fichier versions.h à partir du template versions.h.in
configure_file(versions.h.in versions.h @ONLY)
# Ajoute le dossier courant à l’include path pour pouvoir inclure versions.h
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# --- ⚙️ Fichier spécifique à la plateforme (plateforme-dependant) ---
# Utilisé pour abstraire les différences de comportement selon OS

if(APPLE)
    set(GBEX_PLATFDEP mac.mm)   # Objective-C++ source spécifique macOS

elseif(UNIX)
    set(GBEX_PLATFDEP unix.cpp) # Code spécifique Linux/Unix

elseif(WIN32)
    set(GBEX_PLATFDEP win.cpp)  # Code spécifique Windows

    # Génère le fichier de ressources .rc pour Windows (icône, version, etc.)
    configure_file(
        "${PROJECT_SOURCE_DIR}/resources/gbex.rc.in"
        gbex.rc @ONLY)
    set(GBEX_RC "${CMAKE_CURRENT_BINARY_DIR}/gbex.rc")
endif()

# Ajoutez une source à l'exécutable de ce projet.
#add_executable (${GBEX_EXE} main.cpp main. "winmain.cpp"h)
add_executable (${GBEX_EXE} WIN32
    winmain.cpp 
    winmain.h
    "${GBEX_RC}")
