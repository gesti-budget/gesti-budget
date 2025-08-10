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


# Désactive tous les avertissements lors de la compilation des sources dans 3rd/
# (dossier des dépendances tierces, souvent du code externe que l’on ne veut pas « polluer » de warnings)

if(MSVC)  # Cas du compilateur Microsoft Visual C++
    # Retire toute option /W0, /W1, /W2, /W3 ou /W4 déjà présente dans les flags C
    string(REGEX REPLACE "(^| )[/-]W[0-4]( |$)" " " CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
    # Idem pour les flags C++
    string(REGEX REPLACE "(^| )[/-]W[0-4]( |$)" " " CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

    # Force le niveau d’avertissement à /W0 (aucun warning) pour le C
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W0")
    # Force le niveau d’avertissement à /W0 pour le C++
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W0")

else()  # Cas des compilateurs GCC/Clang et autres
    # Option -w : supprime tous les avertissements
    add_compile_options("-w")
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake") 

# Intégration le librairie tierce : RapidJson
#include(RapidJson)

# Intégration le librairie tierce : Lua
# include(Lua)

# Crée une bibliothèque statique à partir du fichier source cgitemplate/html_template.cpp
# STATIC → compilée en une archive .a (Linux/macOS) ou .lib (Windows)
# EXCLUDE_FROM_ALL → ne sera pas compilée automatiquement avec "make all" ou build par défaut

#add_library(HTML-template STATIC EXCLUDE_FROM_ALL cgitemplate/html_template.cpp)

# Ajoute le dossier "cgitemplate" comme chemin d'inclusion pour cette bibliothèque
# SYSTEM → indique que ce sont des "system headers" → les warnings éventuels dans ces fichiers sont ignorés
# INTERFACE → ce chemin est transmis aux cibles qui lieront avec HTML-template, mais pas utilisé pour compiler HTML-template lui-même

#target_include_directories(HTML-template SYSTEM INTERFACE cgitemplate)


include(wxSQLite3)

#set(RapidJSON_VERSION ${RapidJSON_VERSION} PARENT_SCOPE)
#set(Lua_VERSION ${LUA_VERSION_STRING} PARENT_SCOPE)
set(wxSQLite3_VERSION ${wxSQLite3_VERSION} PARENT_SCOPE)
set(WXSQLITE3_HAVE_CODEC ${WXSQLITE3_HAVE_CODEC} PARENT_SCOPE)
message(WARNING "Configuring 3rd library...")