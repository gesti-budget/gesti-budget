# 📌 En résumé
# LuaGlue : crée une cible INTERFACE qui expose juste ses includes
# (pas de compilation).
# 
# Lua :
# 
# Si Lua est installée → utilise l’implémentation système.
# 
# Sinon → compile Lua à partir du code source embarqué.
# 
# Compatibilité : 
# ajoute toujours LUA_COMPAT_5_2 pour garder le support d’anciennes API.
# 
# Portabilité :
# 
# Sur Linux, vérifie et lie la lib dl (chargement dynamique).
# 
# Sur non-Windows, active plusieurs définitions d’adaptation
# (LUA_USE_POSIX, LUA_USE_DLOPEN, etc.)

# --- Déclaration de LuaGlue ---
# Bibliothèque INTERFACE → pas de compilation, uniquement un ensemble de propriétés (include dirs, flags…)
add_library(LuaGlue INTERFACE)

# Ajoute le dossier d’includes LuaGlue/include en tant que "system include" (pour éviter les warnings sur ce code tiers)
target_include_directories(LuaGlue SYSTEM INTERFACE LuaGlue/include)


# --- Recherche de Lua déjà installée sur le système ---
find_package(Lua)

if(LUA_FOUND)
    # Si Lua est trouvée, créer une bibliothèque INTERFACE qui pointe vers son installation
    add_library(Lua INTERFACE)
    target_include_directories(Lua SYSTEM INTERFACE ${LUA_INCLUDE_DIR}) # Chemins d’inclusion
    target_link_libraries(Lua INTERFACE ${LUA_LIBRARIES})               # Bibliothèques à lier

else()
    # Si Lua n’est pas trouvée, compiler Lua à partir du code source inclus dans le projet
    add_library(Lua STATIC EXCLUDE_FROM_ALL
        lua/lapi.c
        lua/lapi.h
        lua/lauxlib.c
        lua/lauxlib.h
        lua/lbaselib.c
        lua/lbitlib.c
        lua/lcode.c
        lua/lcode.h
        lua/lcorolib.c
        lua/lctype.c
        lua/lctype.h
        lua/ldblib.c
        lua/ldebug.c
        lua/ldebug.h
        lua/ldo.c
        lua/ldo.h
        lua/ldump.c
        lua/lfunc.c
        lua/lfunc.h
        lua/lgc.c
        lua/lgc.h
        lua/linit.c
        lua/liolib.c
        lua/llex.c
        lua/llex.h
        lua/llimits.h
        lua/lmathlib.c
        lua/lmem.c
        lua/lmem.h
        lua/loadlib.c
        lua/lobject.c
        lua/lobject.h
        lua/lopcodes.c
        lua/lopcodes.h
        lua/loslib.c
        lua/lparser.c
        lua/lparser.h
        lua/lprefix.h
        lua/lstate.c
        lua/lstate.h
        lua/lstring.c
        lua/lstring.h
        lua/lstrlib.c
        lua/ltable.c
        lua/ltable.h
        lua/ltablib.c
        lua/ltests.c
        lua/ltests.h
        lua/ltm.c
        lua/ltm.h
        lua/lua.c
        lua/lua.h
        lua/luaconf.h
        lua/lualib.h
        lua/lundump.c
        lua/lundump.h
        lua/lutf8lib.c
        lua/lvm.c
        lua/lvm.h
        lua/lzio.c
        lua/lzio.h
    )

    # Copie le wrapper C++ lua.hpp dans le dossier de build
    configure_file(${PROJECT_SOURCE_DIR}/resources/lua.hpp lua.hpp COPYONLY)

    # Ajoute les chemins d’inclusion : source Lua + répertoire binaire (où lua.hpp a été copié)
    target_include_directories(Lua SYSTEM INTERFACE lua ${CMAKE_CURRENT_BINARY_DIR})

    # Définitions spécifiques pour plateformes non Windows
    if(NOT WIN32)
        target_compile_definitions(Lua PRIVATE
            LUA_USE_POSIX
            LUA_USE_DLOPEN
            LUA_USE_STRTODHEX
            LUA_USE_AFORMAT
            LUA_USE_LONGLONG
            LUA_COMPAT_5_2) # Active compatibilité avec Lua 5.2
    endif()

    # Sous Linux, vérifier que la lib "dl" est disponible (pour dlopen)
    if(LINUX)
        include(CheckLibraryExists)
        CHECK_LIBRARY_EXISTS(${CMAKE_DL_LIBS} dlopen "" HAVE_DLOPEN)
        if(NOT HAVE_DLOPEN)
            message(SEND_ERROR "Could not find required dl library.")
        endif()
        target_link_libraries(Lua PRIVATE ${CMAKE_DL_LIBS})
    endif()

    # Extraction de la version de Lua depuis lua.h
    file(STRINGS lua/lua.h
        LUA_VERSION_STRING
        REGEX "#define LUA_VERSION_(MAJOR|MINOR|RELEASE)[\t ]+\"[0-9]+\"")
    string(REPLACE ";" "." LUA_VERSION_STRING "${LUA_VERSION_STRING}")
    string(REGEX REPLACE "[^0-9.]+" "" LUA_VERSION_STRING ${LUA_VERSION_STRING})
endif()


# --- Définitions communes ---
# Ajoute la compatibilité Lua 5.2 à tous ceux qui utilisent la cible Lua
target_compile_definitions(Lua INTERFACE LUA_COMPAT_5_2)
