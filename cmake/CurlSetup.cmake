# === Détection et configuration avancée de la dépendance CURL/libcurl ===
#
# Cette section gère plusieurs cas :
# - Recherche via find_package() avec ou sans CONFIG/COMPONENTS selon la version
# - Support de curl 7.57+ (avec fichiers de configuration)
# - Fallback avec pkg-config si find_package échoue
# - Création manuelle de la cible CURL::libcurl si nécessaire
# - Compatibilité avec des versions de CMake < 3.12 et curl < 7.61.1
#
# En sortie, une cible IMPORTED nommée CURL::libcurl est créée
# avec les bonnes propriétés (include, defines, linkage).

# curl >= 7.57 peut utiliser find_package avec CONFIG
find_package(CURL QUIET COMPONENTS libcurl CONFIG)

# curl >= 7.62 a supprimé COMPONENTS → fallback si nécessaire
if(NOT CURL_FOUND AND NOT CURL_VERSION VERSION_LESS 7.62)
    find_package(CURL QUIET CONFIG)
endif()

if(CURL_FOUND)
    message(STATUS "Found CURL: ${CURL_LIBRARIES} (found version \"${CURL_VERSION}\")")

    # Récupère le type de bibliothèque (STATIC ou SHARED)
    get_target_property(LIBCURL_TYPE CURL::libcurl TYPE)

    # curl < 7.61.1 n’exporte pas CURL_STATICLIB correctement → on le force si nécessaire
    if(CURL_VERSION VERSION_LESS 7.61.1 AND LIBCURL_TYPE STREQUAL STATIC_LIBRARY)
        set_target_properties(CURL::libcurl PROPERTIES
            INTERFACE_COMPILE_DEFINITIONS CURL_STATICLIB)
    endif()

else()
    # 🔍 Fallback : recherche manuelle via pkg-config
    set(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_FIND_LIBRARY_PREFIXES} lib)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES} _imp.lib -d.lib -d_imp.lib)

    find_package(PkgConfig)
    if(PkgConfig_FOUND)
        set(PKG_CONFIG_USE_CMAKE_PREFIX_PATH ON)
        PKG_SEARCH_MODULE(CURL libcurl)

        if(CURL_FOUND)
            # Pour CMake < 3.12, il faut parfois détecter manuellement la lib à linker
            if(NOT CURL_LINK_LIBRARIES)
                find_library(CURL_LINK_LIBRARIES NAMES ${CURL_LIBRARIES}
                    HINTS "${CURL_LIBDIR}" NO_DEFAULT_PATH)
                if(NOT CURL_LINK_LIBRARIES)
                    message(WARNING "CURL library file cannot be found!")
                endif()
            endif()

            # Distinction entre STATIC / SHARED selon nom du fichier détecté
            if(NOT CURL_LINK_LIBRARIES MATCHES "_imp.lib$|${CMAKE_SHARED_LIBRARY_SUFFIX}$")
                # 💡 Cas STATIC
                list(REMOVE_ITEM CURL_STATIC_LIBRARIES ${CURL_LIBRARIES})
                add_library(CURL::libcurl STATIC IMPORTED)
                set_target_properties(CURL::libcurl PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${CURL_STATIC_INCLUDE_DIRS}"
                    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${CURL_STATIC_INCLUDE_DIRS}"
                    INTERFACE_COMPILE_DEFINITIONS CURL_STATICLIB
                    INTERFACE_LINK_LIBRARIES "${CURL_STATIC_LIBRARIES}"
                    IMPORTED_LINK_INTERFACE_LANGUAGES C
                    IMPORTED_LOCATION "${CURL_LINK_LIBRARIES}")
                link_directories(CURL_STATIC_LIBRARY_DIRS)
            else()
                # 💡 Cas SHARED
                add_library(CURL::libcurl SHARED IMPORTED)
                set_target_properties(CURL::libcurl PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIRS}"
                    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIRS}")

                if(WIN32)
                    set_target_properties(CURL::libcurl PROPERTIES
                        IMPORTED_IMPLIB "${CURL_LINK_LIBRARIES}")
                else()
                    set_target_properties(CURL::libcurl PROPERTIES
                        IMPORTED_LOCATION "${CURL_LINK_LIBRARIES}")
                endif()
            endif()

            message(STATUS "Found CURL: ${CURL_LINK_LIBRARIES} (found version \"${CURL_VERSION}\")")
        endif()
    endif()

    # Fallback final avec MODULE si tout échoue
    if(NOT CURL_FOUND)
        find_package(CURL REQUIRED COMPONENTS libcurl MODULE)

        # Détection manuelle selon static / shared
        if(NOT CURL_LIBRARIES MATCHES "_imp.lib$|${CMAKE_SHARED_LIBRARY_SUFFIX}$")
            # Static
            set_target_properties(CURL::libcurl PROPERTIES
                INTERFACE_COMPILE_DEFINITIONS CURL_STATICLIB
                IMPORTED_LINK_INTERFACE_LANGUAGES C
                IMPORTED_LOCATION "${CURL_LIBRARIES}")
        else()
            # Shared
            if(WIN32)
                set_target_properties(CURL::libcurl PROPERTIES
                    IMPORTED_IMPLIB "${CURL_LIBRARIES}")
            else()
                add_library(CURL::libcurl SHARED IMPORTED)
                set_target_properties(CURL::libcurl PROPERTIES
                    IMPORTED_LOCATION "${CURL_LIBRARIES}")
            endif()
        endif()

        set_target_properties(CURL::libcurl PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIRS}"
            INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIRS}")

        set(CURL_VERSION ${CURL_VERSION_STRING})
    endif()
endif()
