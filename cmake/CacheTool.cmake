# === Détection et configuration d’un outil de cache de compilation ===
# Tente de détecter `clcache` (Windows) ou `ccache` (Linux/macOS)
# et configure CMake pour les utiliser automatiquement.

# ---------------------------------------------------------------------------
# 🚀 Intégration automatique de ccache (Linux/macOS) ou clcache (Windows)
# ---------------------------------------------------------------------------

# Si aucune variable CCACHE_PROGRAM n’est encore définie, on tente de la détecter
if(NOT CCACHE_PROGRAM)
    if(MSVC)
        find_program(CCACHE_PROGRAM clcache)  # Pour Windows/MSVC
        set(_PARAM --help)                   # clcache ne supporte pas --version
    else()
        find_program(CCACHE_PROGRAM ccache)  # Pour GCC/Clang
        set(_PARAM --version)
    endif()

    # Si trouvé, on interroge sa version
    if(CCACHE_PROGRAM)
        execute_process(
            COMMAND "${CCACHE_PROGRAM}" ${_PARAM}
            OUTPUT_VARIABLE CCACHE_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        # Extraction de la version uniquement (ex: "ccache version 4.7" → "4.7")
        string(REGEX REPLACE "\n.*" "" CCACHE_VERSION "${CCACHE_VERSION}")
        string(REGEX REPLACE ".* " "" CCACHE_VERSION "${CCACHE_VERSION}")
        string(REGEX REPLACE "^v" "" CCACHE_VERSION "${CCACHE_VERSION}")

        # Message d'état
        if(CCACHE_VERSION)
            message(STATUS "Outil de cache détecté : ${CCACHE_PROGRAM} (version ${CCACHE_VERSION})")
        else()
            message(STATUS "Outil de cache détecté : ${CCACHE_PROGRAM}")
        endif()
    else()
        message(STATUS "Aucun outil de cache de compilation trouvé (ccache/clcache)")
    endif()
    unset(_PARAM)
endif()

# ---------------------------------------------------------------------------
# 🔁 Application concrète du cache détecté
# ---------------------------------------------------------------------------

if(CCACHE_PROGRAM)
    if(MSVC)
        # Pour MSVC, configuration via variables globales Visual Studio

        get_filename_component(CCACHE_EXEC "${CCACHE_PROGRAM}" NAME CACHE)
        get_filename_component(CCACHE_PATH "${CCACHE_PROGRAM}" DIRECTORY CACHE)
        file(TO_NATIVE_PATH "${CCACHE_PATH}" CCACHE_PATH)

        if(NOT CMAKE_VERSION VERSION_LESS 3.13)
            # CMake >= 3.13 : méthode moderne pour VS
            list(APPEND CMAKE_VS_GLOBALS
                "CLToolExe=${CCACHE_EXEC}"
                "CLToolPath=${CCACHE_PATH}"
                "TrackFileAccess=false")
        elseif(NOT DEFINED ENV{VCPKG_ROOT})
            # Méthode alternative pour anciennes versions CMake (<3.13) et sans vcpkg

            # Définition d'un hook appelé à chaque création de target
            function(any_target_hook)
                set(NON_COMPILE_TARGETS INTERFACE IMPORTED UNKNOWN ALIAS)
                list(FIND NON_COMPILE_TARGETS "${ARGV1}" found)
                if(${found} GREATER -1)
                    return()
                endif()
                set_target_properties(${ARGV0} PROPERTIES VS_GLOBAL_CLToolExe "${CCACHE_EXEC}")
                set_target_properties(${ARGV0} PROPERTIES VS_GLOBAL_CLToolPath "${CCACHE_PATH}")
                set_target_properties(${ARGV0} PROPERTIES VS_GLOBAL_TrackFileAccess false)
            endfunction()

            # Redéfinition de add_library et add_executable pour intercepter les appels
            function(add_library)
                _add_library(${ARGN})
                any_target_hook(${ARGN})
            endfunction()

            function(add_executable)
                _add_executable(${ARGN})
                any_target_hook(${ARGN})
            endfunction()
        endif()

    else()
        # Pour GCC/Clang : configuration standard
        if(NOT CMAKE_VERSION VERSION_LESS 3.4)
            set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
            set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
        else()
            # Méthode alternative pour les anciennes versions de CMake (< 3.4)
            set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
            set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK "${CCACHE_PROGRAM}")
        endif()
    endif()
endif()
