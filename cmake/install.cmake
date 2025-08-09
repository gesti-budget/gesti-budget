# === 🧳 Bloc INSTALL : Configuration du bundle macOS (.app) ===
#
# Ce bloc est **exécuté uniquement sur macOS** (APPLE défini)
# Il configure les propriétés nécessaires pour créer une application macOS
# proprement empaquetée avec CMake (style .app)
# via les options `MACOSX_BUNDLE_*` et un fichier Info.plist.

if(APPLE)

    # ➤ Nettoyage de la version instable pour la concaténer proprement
    # Ex : transforme "Beta.1" → "B1", "Alpha.2" → "A2" pour un usage court
    # Cette version sera concaténée à la version de base dans le bundle version
    string(REGEX REPLACE "^(.).*\\.([0-9]+)$" "\\1\\2"
        MMEX_VERSION_UNSTABLE_SHORT ${MMEX_VERSION_WITH_UNSTABLE})

    # === ℹ️ Configuration des métadonnées du bundle macOS ===
    #
    # Ces propriétés seront insérées dans le fichier Info.plist généré
    # CMake injecte ces valeurs si tu fournis un template `.plist.in` via
    # la propriété `MACOSX_BUNDLE_INFO_PLIST`.

    set_target_properties(${MMEX_EXE} PROPERTIES

        # Nom du bundle visible (ex: "MoneyManagerEx")
        MACOSX_BUNDLE_BUNDLE_NAME ${PROJECT_NAME}

        # Nom de l’exécutable à lancer
        MACOSX_BUNDLE_EXECUTABLE_NAME ${MMEX_EXE}

        # Identifiant unique de l’application (reverse-DNS)
        MACOSX_BUNDLE_GUI_IDENTIFIER org.moneymanagerex.${MMEX_EXE}

        # Numéro de version du bundle (utilisé en interne par macOS)
        # Ex : "1.6.3Beta1"
        MACOSX_BUNDLE_BUNDLE_VERSION "${MMEX_VERSION}${MMEX_VERSION_UNSTABLE_SHORT}"

        # Version courte affichée à l’utilisateur
        # Ex : "1.6.3"
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${MMEX_VERSION}

        # Version longue affichée (ex : "1.6.3-Beta.1")
        MACOSX_BUNDLE_LONG_VERSION_STRING ${MMEX_VERSION_FULL}

        # Texte de droits d’auteur (affiché dans le Finder ou via AppleScript)
        MACOSX_BUNDLE_COPYRIGHT "Copyright © 2009-2017 Nikolay\n\
Copyright © 2011-2017 LiSheng\n\
Copyright © 2013-2017 James, Gabriele\n\
Copyright © 2010-2017 Stefano\n\
Copyright © 2009-2010 VaDiM, Wesley Ellis"

        # Nom du fichier d’icône (doit être inclus dans les ressources du bundle)
        MACOSX_BUNDLE_ICON_FILE ${MACOSX_APP_ICON_NAME}

        # Chemin vers le fichier template Info.plist à utiliser (modèle .in)
        # Les variables comme @MACOSX_BUNDLE_BUNDLE_VERSION@ y seront remplacées.
        MACOSX_BUNDLE_INFO_PLIST "${PROJECT_SOURCE_DIR}/resources/MacOSXBundleInfo.plist.in"
    )
endif()


# === INSTALLATION POUR WINDOWS ===
#
# Ce bloc configure l'installation spécifique à Windows, en traitant :
# - la version portable (mmexini.db3)
# - les DLL wxWidgets nécessaires
# - la configuration du runtime Visual C++
# - les bibliothèques système requises

if(WIN32)

    # === 🎒 Gestion du mode "portable" (sans installation) ===
    if(GBEX_PORTABLE_INSTALL)
        # La version portable a besoin d'un fichier de configuration vide par défaut (mmexini.db3)
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/mmexini.db3" "")
        install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/mmexini.db3"
            DESTINATION "${GBEX_DOC_DIR}")  # Placé dans le dossier de documentation de l’appli
    endif()

    # === 📦 Ajout des DLL partagées de wxWidgets à l'installation ===

    # ➤ On extrait le suffixe du nom du dossier des bibliothèques wxWidgets
    get_filename_component(WXDLLSUFF "${wxWidgets_LIB_DIR}" NAME)

    # Si ce suffixe contient "_dll", on suppose que c’est une build dynamique de wxWidgets
    if(WXDLLSUFF MATCHES "_dll$")
        
        # Ex : transforme "vc143_dll" → "vc143.dll"
        string(REPLACE _dll .dll WXDLLSUFF ${WXDLLSUFF})

        # Préfixe pour les noms de DLL wxWidgets, ex : "31u" pour wxWidgets 3.1.x
        set(WXDLLPREF ${wxWidgets_VERSION_MAJOR}${wxWidgets_VERSION_MINOR})

        # Certains numéros mineurs impairs nécessitent le patch (ex : 3.1.2 → 312u)
        if(wxWidgets_VERSION_MINOR MATCHES "^[13579]$")
            set(WXDLLPREF ${WXDLLPREF}${wxWidgets_VERSION_PATCH})
        endif()

        # Ajoute le suffixe Unicode aux noms des DLL
        set(WXDLLPREF ${WXDLLPREF}u)

        # === DLLs pour les builds Release ===
        if(NOT CMAKE_INSTALL_DEBUG_LIBRARIES_ONLY)
            list(APPEND GBEX_WXDLLS
                wxbase${WXDLLPREF}
                wxbase${WXDLLPREF}_net
                wxbase${WXDLLPREF}_xml
                wxmsw${WXDLLPREF}_adv
                wxmsw${WXDLLPREF}_aui
                wxmsw${WXDLLPREF}_core
                wxmsw${WXDLLPREF}_html
                wxmsw${WXDLLPREF}_qa
                wxmsw${WXDLLPREF}_stc
                wxmsw${WXDLLPREF}_webview)
        endif()
        
        # === DLLs pour les builds Debug ===
        if(CMAKE_INSTALL_DEBUG_LIBRARIES)
            
            # Ajoute le suffixe "d" pour les builds Debug (ex: wxbase312ud.dll)
            set(WXDLLPREF ${WXDLLPREF}d)
            list(APPEND GBEX_WXDLLS
                wxbase${WXDLLPREF}
                wxbase${WXDLLPREF}_net
                wxbase${WXDLLPREF}_xml
                wxmsw${WXDLLPREF}_adv
                wxmsw${WXDLLPREF}_aui
                wxmsw${WXDLLPREF}_core
                wxmsw${WXDLLPREF}_html
                wxmsw${WXDLLPREF}_qa
                wxmsw${WXDLLPREF}_stc
                wxmsw${WXDLLPREF}_webview)
        endif()

        # === Recherche des DLL réelles à inclure ===
        # On essaie plusieurs suffixes potentiels (liés au build wxWidgets)
        foreach(m_dll ${GBEX_WXDLLS})
            set(m_dll "${wxWidgets_LIB_DIR}/${m_dll}")
            foreach(m_ext
                vc_mmex.dll vc_custom.dll vc_x64_mmex.dll vc_x64_custom.dll
                "${WXDLLSUFF}" NOTFOUND)
                
                if(EXISTS "${m_dll}_${m_ext}")
                    list(APPEND CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS "${m_dll}_${m_ext}")
                    break()
                elseif(NOT m_ext)
                    message(SEND_ERROR "${m_dll}_${WXDLLSUFF} not found")
                endif()
            endforeach()
        endforeach()

        # Nettoyage
        unset(m_dll)
        unset(m_ext)
        unset(GBEX_WXDLLS)
        unset(WXDLLSUFF)
    endif()

    # === 🧱 Ajout des bibliothèques UCRT pour compatibilité Windows ancienne version ===
    set(CMAKE_INSTALL_UCRT_LIBRARIES ON)

    # === 🔒 Infos importantes sur la redistribution des DLL de debug Visual Studio ===
    #
    # Les DLLs de debug Visual Studio NE PEUVENT PAS être redistribuées légalement,
    # il est donc préférable de ne pas les inclure dans les paquets publiés.
    #
    # → Ces lignes sont volontairement commentées pour éviter une infraction
    #
    # set(CMAKE_INSTALL_DEBUG_LIBRARIES ON)
    # set(CMAKE_INSTALL_DEBUG_LIBRARIES_ONLY ON)

    # === 📦 Inclut automatiquement les DLLs système nécessaires (VC runtime, UCRT, etc.) ===
    include(InstallRequiredSystemLibraries)

endif()

# Fichier d'aide'
install(FILES
    contrib.txt
    README.TXT
    DESTINATION "${GBEX_DOC_DIR}")
install(FILES
    license.txt
    DESTINATION "${GBEX_DOC_DIR}/help")
install(DIRECTORY
    docs/
    DESTINATION "${GBEX_DOC_DIR}/help")
install(FILES
    DESTINATION "${GBEX_DOC_DIR}/help")


# Resources
install(FILES
    3rd/ChartNew.js/ChartNew.js
    3rd/ChartNew.js/Add-ins/format.js
    3rd/apexcharts.js/dist/apexcharts.min.js
    resources/ie-polyfill/polyfill.min.js
    resources/ie-polyfill/classlist.min.js
    resources/ie-polyfill/resize-observer.js
    resources/ie-polyfill/findindex.min.js
    resources/ie-polyfill/umd.min.js
    resources/sorttable.js
    resources/jquery.min.js
    resources/home_page.htt
    resources/drop.wav
    resources/cash.wav
    resources/mmex.png
    resources/mmex.svg
    DESTINATION "${GBEX_RES_DIR}")

#Themes & GRM
install(FILES ${THEMEFILES} DESTINATION ${GBEX_RES_DIR_THEMES})
install(FILES ${GRMFILES} DESTINATION ${GBEX_RES_DIR_REPORTS})