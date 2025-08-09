# === Configuration de la dépendance wxWidgets ===
#
# Ce bloc :
# - Configure la recherche de la bibliothèque wxWidgets
# - Gère les limitations de CMake < 3.25 avec un module personnalisé
# - Corrige la détection des bibliothèques statiques sur macOS
# - Crée une cible INTERFACE wxWidgets pour simplifier son usage dans tout le projet

# 📌 Workaround pour CMake < 3.25
# Avant la version 3.25, le module FindwxWidgets.cmake de CMake ne gérait pas bien
# certaines versions de wxWidgets. On ajoute donc un chemin personnalisé s’il faut.
if(CMAKE_VERSION VERSION_LESS 3.25)
    list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/util")
endif()

# Active la recherche des versions Release et Debug de wxWidgets
set(wxWidgets_USE_REL_AND_DBG ON)

# 🔍 Recherche de wxWidgets avec les composants nécessaires
find_package(wxWidgets 2.9.2 REQUIRED
    COMPONENTS core qa html xml aui adv stc webview base
    OPTIONAL_COMPONENTS scintilla)

# 🍎 Cas spécifique : utilisation statique sur macOS
if(APPLE AND wxWidgets_LIBRARIES MATCHES "${CMAKE_STATIC_LIBRARY_PREFIX}wx_baseu-[0-9\\.]+${CMAKE_STATIC_LIBRARY_SUFFIX}")
    # On remplace les dépendances dynamiques par leurs équivalents statiques (ex: png, jpeg)
    foreach(deplib png jpeg)
        find_library(${deplib}path ${CMAKE_STATIC_LIBRARY_PREFIX}${deplib}${CMAKE_STATIC_LIBRARY_SUFFIX})
        if(${deplib}path)
            string(REPLACE "-l${deplib}" "${${deplib}path}" wxWidgets_LIBRARIES "${wxWidgets_LIBRARIES}")
        endif()
    endforeach()
    unset(deplib)
    unset(${deplib}path)
endif()

# 🎯 Création d'une cible INTERFACE wxWidgets (modern CMake)
# Cela simplifie la gestion des include, defines, flags et bibliothèques
add_library(wxWidgets INTERFACE)

# ---------------------------------------------------------------------------
# Ciblage moderne avec add_library(wxWidgets INTERFACE)
# Ce bloc configure les propriétés de la cible INTERFACE wxWidgets.
#
# Cela permet d’exposer tous les paramètres nécessaires (includes, librairies,
# options, macros) aux cibles qui l’utilisent via target_link_libraries().
#
# Chaque instruction est expliquée ci-dessous :
# ---------------------------------------------------------------------------

# 1️⃣ Inclut les headers de wxWidgets dans les projets qui dépendent de cette cible
# - SYSTEM : marque les includes comme externes (réduction des warnings)
# - INTERFACE : transmet les includes aux cibles dépendantes
target_include_directories(wxWidgets SYSTEM INTERFACE ${wxWidgets_INCLUDE_DIRS})

# 2️⃣ Spécifie les bibliothèques à linker (libwx_baseu, libwx_coreu, etc.)
# - INTERFACE : les cibles dépendantes hériteront des liaisons
target_link_libraries(wxWidgets INTERFACE ${wxWidgets_LIBRARIES})

# 3️⃣ Transmet les options de compilation nécessaires (ex: -fPIC, -pthread)
# - ${wxWidgets_CXX_FLAGS} est fourni par find_package(wxWidgets)
target_compile_options(wxWidgets INTERFACE ${wxWidgets_CXX_FLAGS})

# 4️⃣ Définit les macros à la compilation (ex: wxUSE_UNICODE, etc.)
# - wxNO_UNSAFE_WXSTRING_CONV=1 : désactive les conversions implicites wxString <-> char*
# - $<$<CONFIG:Debug>:...> : applique les définitions debug uniquement en Debug
target_compile_definitions(wxWidgets INTERFACE ${wxWidgets_DEFINITIONS}
    wxNO_UNSAFE_WXSTRING_CONV=1
    $<$<CONFIG:Debug>:${wxWidgets_DEFINITIONS_DEBUG}>
)
