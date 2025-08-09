# --------- Configuration CPack ---------
# CPack est l’outil de CMake qui permet de créer des paquets d’installation (.deb, .rpm, .zip, etc.)

# Nom du paquet = nom de l’exécutable
set(CPACK_PACKAGE_NAME ${GBEX_EXE})

# Version complète du paquet (ex : 1.7.0-RC.1)
set(CPACK_PACKAGE_VERSION ${GBEX_VERSION_FULL})

# Numéros de version séparés (majeur, mineur, patch)
set(CPACK_PACKAGE_VERSION_MAJOR ${GBEX_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${GBEX_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${GBEX_VERSION_PATCH})

# Contact des développeurs (affiché dans les métadonnées du paquet)
set(CPACK_PACKAGE_CONTACT "Julie Brindejot <julie@gesti-budget.lan>")

# Résumé court de la description
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Logiciel de gestion financière simple à utiliser")

# Description complète
set(CPACK_PACKAGE_DESCRIPTION
    "GestiBudget Ex (GBEX) est un logiciel dérivé Money Manager Ex, open source, multiplateforme et facile à utiliser pour la gestion financière personnelle. 
Il aide principalement à organiser ses finances et à suivre où, quand et comment l'argent est dépensé. 
GBEX inclut toutes les fonctionnalités de base que 90% des utilisateurs recherchent dans une application de finances personnelles. 
Les objectifs de conception sont la simplicité et la convivialité — quelque chose que l’on peut utiliser tous les jours.")

# Icône du paquet
set(CPACK_PACKAGE_ICON "${PROJECT_SOURCE_DIR}/resources/gbex.ico")

# Fichier de licence intégré au paquet
set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/license.txt")

# Fichier README intégré au paquet
set(CPACK_RESOURCE_FILE_README "${PROJECT_SOURCE_DIR}/README.TXT")

# (TODO) Décider si on enlève les symboles de debug des binaires lors de la création du paquet
set(CPACK_STRIP_FILES OFF)

# Spécificités pour les paquets DEB (Debian/Ubuntu)
set(CPACK_DEBIAN_PACKAGE_SECTION misc)                                  # Section "misc" dans l’arborescence Debian
set(CPACK_DEBIAN_PACKAGE_PRIORITY extra)                                # Priorité "extra"
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE https://github.com/gesti-budget/gesti-budget)
set(CPACK_DEBIAN_PACKAGE_REPLACES gesti-budget)                         # Remplace un paquet du même nom
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)                                  # Analyse des dépendances automatiques
set(CPACK_DEBIAN_PACKAGE_RELEASE 1)                                     # Numéro de "release" interne
# set(CPACK_DEBIAN_PACKAGE_DEPENDS wx${wxWidgets_VERSION_MAJOR}.${wxWidgets_VERSION_MINOR}-i18n) # Dépendances (désactivé ici)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)                                 # Nom de fichier généré automatiquement

# Spécificités pour les paquets RPM (Fedora, CentOS, etc.)
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)                                    # Nom de fichier généré automatiquement
set(CPACK_RPM_PACKAGE_LICENSE GPL-2+)                                   # Licence du paquet
set(CPACK_RPM_PACKAGE_URL ${CPACK_DEBIAN_PACKAGE_HOMEPAGE})             # URL du projet
set(CPACK_RPM_PACKAGE_OBSOLETES ${CPACK_DEBIAN_PACKAGE_REPLACES})       # Indique qu’il remplace un ancien paquet
set(CPACK_RPM_PACKAGE_AUTOREQ ON)                                       # Résolution automatique des dépendances
set(CPACK_RPM_PACKAGE_DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION})         # Description
set(CPACK_RPM_PACKAGE_RELEASE_DIST ON)                                  # Inclut la distribution dans le numéro de release

# Exclure certains dossiers standards des fichiers ajoutés automatiquement par RPM
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
    /usr/share/applications
    /usr/share/icons
    /usr/share/icons/hicolor
    /usr/share/icons/hicolor/scalable
    /usr/share/icons/hicolor/scalable/apps)

# (TODO) Possibilité d’inclure un paquet séparé de debug
# set(CPACK_RPM_DEBUGINFO_PACKAGE ON)
# set(CPACK_RPM_DEBUGINFO_FILE_NAME RPM-DEFAULT)


# --- Choix du type de paquet à générer selon l’OS / la distribution ---
if(LINUX)
    # Debian/Ubuntu/Linux Mint/Raspbian → on fabrique un paquet .deb
    if(LINUX_DISTRO STREQUAL "Ubuntu" OR LINUX_DISTRO STREQUAL "Debian" OR LINUX_DISTRO STREQUAL "Linuxmint" OR LINUX_DISTRO STREQUAL "Raspbian")
        set(CPACK_GENERATOR DEB)                                # Générateur CPack = format DEB
        set(CPACK_DEBIAN_PACKAGE_RELEASE "${LINUX_DISTRO_STRING}")  # Suffixe de release (ex: Ubuntu.22.04.jammy)
    # Fedora → paquet .rpm
    elseif(LINUX_DISTRO STREQUAL "Fedora")
        set(CPACK_GENERATOR RPM)
        set(CPACK_RPM_PACKAGE_RELEASE "${LINUX_DISTRO_STRING}") # Suffixe de release RPM (ex: Fedora.40)
    # CentOS → paquet .rpm avec adaptation du champ DIST
    elseif(LINUX_DISTRO STREQUAL "CentOS")
        set(CPACK_GENERATOR RPM)
        string(REGEX REPLACE "\\..*" "" CPACK_RPM_PACKAGE_RELEASE_DIST ${LINUX_DISTRO_REL})  # Extrait la partie majeure (ex: 7, 8)
        set(CPACK_RPM_PACKAGE_RELEASE "${LINUX_DISTRO_STRING}") # Release complète (ex: CentOS.7)
    # openSUSE / SUSE récentes → paquet .rpm, release plus verbeuse
    elseif(LINUX_DISTRO MATCHES "openSUSE" OR (LINUX_DISTRO MATCHES "SUSE" AND LINUX_DISTRO_REL VERSION_GREATER 42))
        set(CPACK_GENERATOR RPM)
        set(CPACK_RPM_PACKAGE_RELEASE "${LINUX_DISTRO_DESCRIPTION}") # Utilise la description (souvent plus lisible)
    # Slackware → archive .txz avec conventions Slack
    elseif(LINUX_DISTRO STREQUAL "Slackware")
        set(CPACK_GENERATOR TXZ)                             # Format Slackware (.txz)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(CPACK_SYSTEM_NAME x86_64)                    # Nom d’archi : 64 bits
        else()
            set(CPACK_SYSTEM_NAME i586)                      # Nom d’archi : 32 bits
        endif()
        # Fichiers de description/installation Slackware
        install(FILES util/slackware-desc
                DESTINATION /install RENAME slack-desc)
        install(PROGRAMS util/slackware-doinst.sh
                DESTINATION /install RENAME doinst.sh)
        # Ajoute un suffixe de release Slackware (ex: x86_64-1_slack14.2)
        set(CPACK_SYSTEM_NAME ${CPACK_SYSTEM_NAME}-1_slack${LINUX_DISTRO_REL})
        set(CPACK_SET_DESTDIR ON)                            # Respect du DESTDIR
        set(CPACK_PACKAGING_INSTALL_PREFIX /usr)             # Préfixe d’install (peut ne pas être pris en compte selon outils)
        set(CMAKE_INSTALL_PREFIX /usr)                       # Aligne le préfixe CMake
        set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)            # Pas de répertoire racine englobant dans l’archive
    # Arch Linux → ici on ne fait rien (un outillage dédié est probablement utilisé ailleurs)
    elseif(LINUX_DISTRO STREQUAL "Arch")
    # Distribution inconnue → avertissement + paquet générique
    else()
        message(WARNING "Distribution Linux inconnue - génération d’un paquet générique.")
    endif()

# macOS → image disque .dmg “glisser-déposer”
elseif(APPLE)
    set(CPACK_GENERATOR DragNDrop)                                           # DMG glisser-déposer
    set(CPACK_DMG_VOLUME_NAME "Gestionnaire Budget Ex")                            # Nom du volume monté
    set(CPACK_DMG_FORMAT UDZO)                                               # Format compressé
    set(CPACK_DMG_BACKGROUND_IMAGE "${PROJECT_SOURCE_DIR}/resources/dmg-background.png") # Fond de la fenêtre
    set(CPACK_DMG_DS_STORE "${PROJECT_SOURCE_DIR}/resources/dmg-DS_Store")   # Mise en page
    set(CPACK_PACKAGE_ICON "${PROJECT_SOURCE_DIR}/resources/gbex-package.icns") # Icône paquet
    set(CPACK_BUNDLE_PLIST "${PROJECT_SOURCE_DIR}/resources/Info.plist")     # Info.plist personnalisé

# Windows → installeur NSIS + archive ZIP
elseif(WIN32)
    # NSIS : https://nsis.sourceforge.net/Main_Page
    set(CPACK_GENERATOR NSIS ZIP)                                            # On fournit NSIS et ZIP
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "Gestionnaire Budget EX")                  # Dossier d’install par défaut
    set(CPACK_PACKAGE_ICON "${PROJECT_SOURCE_DIR}/resources\\\\gbex.ico")    # Icône dans l’installeur
    set(CPACK_NSIS_MUI_ICON "${CPACK_PACKAGE_ICON}")                         # Icône pages NSIS (x86)
    set(CPACK_NSIS_MUI_UNIICON "${CPACK_PACKAGE_ICON}")                      # Icône pages NSIS (Unicode)
    set(CPACK_NSIS_INSTALLED_ICON_NAME "${GBEX_BIN_DIR}\\\\${GBEX_EXE}${CMAKE_EXECUTABLE_SUFFIX}") # Raccourci principal
    set(CPACK_NSIS_MUI_FINISHPAGE_RUN ${GBEX_EXE}${CMAKE_EXECUTABLE_SUFFIX}) # Proposer de lancer à la fin
    set(CPACK_NSIS_URL_INFO_ABOUT ${CPACK_DEBIAN_PACKAGE_HOMEPAGE})          # Lien “À propos”
    set(CPACK_NSIS_CONTACT "${CPACK_PACKAGE_CONTACT}")                       # Contact support
    # Crée/retire le raccourci Menu Démarrer
    set(CPACK_NSIS_CREATE_ICONS_EXTRA
            "CreateShortCut '$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\Gestionnaire Budget EX.lnk' '$INSTDIR\\\\${GBEX_BIN_DIR}\\\\${GBEX_EXE}${CMAKE_EXECUTABLE_SUFFIX}'")
    set(CPACK_NSIS_DELETE_ICONS_EXTRA "Delete '$SMPROGRAMS\\\\$START_MENU\\\\Gestionnaire Budget EX.lnk'")
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)                       # Désinstaller avant réinstaller (propre)
endif()


# --- Cas spécifique : Distribution Linux = Arch Linux ---
if(LINUX_DISTRO STREQUAL "Arch")
    # Définir le préfixe d'installation sur /usr
    set(CMAKE_INSTALL_PREFIX /usr)

    # Déterminer l'architecture CPU cible
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ARCHLINUX_ARCH x86_64)   # 64 bits
    else()
        set(ARCHLINUX_ARCH i686)     # 32 bits
    endif()

    # Remplacer les tirets par des points dans la version pour respecter le format attendu par Arch
    string(REPLACE - . CPACK_PACKAGE_VERSION ${GBEX_VERSION_FULL})

    # Générer le fichier PKGBUILD à partir du modèle util/PKGBUILD.in
    configure_file(util/PKGBUILD.in PKGBUILD @ONLY)

    # Autoriser l'utilisation de la cible réservée "package" (normalement utilisée par CPack)
    cmake_policy(PUSH)
    if(POLICY CMP0037)
        cmake_policy(SET CMP0037 OLD)
    endif()

    # Définir la cible "package" pour construire le paquet Arch avec makepkg
    # Si exécuté en root : changement du propriétaire des fichiers vers "nobody" avant makepkg
    add_custom_target(package
        COMMAND sh -c "if [ `id -u` -eq 0 ]; then chown nobody -R . && runuser nobody -c makepkg; else makepkg; fi"
        VERBATIM)

    cmake_policy(POP)

# --- Cas général : autres distributions / OS ---
else()
    # Correction pour les anciennes versions de CMake (< 3.6) qui ne supportent pas DEB-DEFAULT/RPM-DEFAULT
    if(CMAKE_VERSION VERSION_LESS 3.6)
        if(CPACK_GENERATOR STREQUAL "DEB")
            # Déterminer l'architecture Debian si elle n'est pas définie
            if(NOT CPACK_DEBIAN_PACKAGE_ARCHITECTURE)
                find_program(DPKG_CMD dpkg DOC "Debian packaging tool")
                if(NOT DPKG_CMD)
                    message("CPackDeb: dpkg introuvable dans le PATH, architecture par défaut : i386.")
                    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE i386)
                endif()
                execute_process(COMMAND "${DPKG_CMD}" --print-architecture
                    OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE
                    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
            endif()
            # Construire le nom complet du fichier .deb
            set(CPACK_PACKAGE_FILE_NAME
                "${CPACK_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")

        elseif(CPACK_GENERATOR STREQUAL "RPM")
            # Déterminer l'architecture RPM si elle n'est pas définie
            if(NOT CPACK_RPM_PACKAGE_ARCHITECTURE)
                execute_process(COMMAND uname -m
                    OUTPUT_VARIABLE CPACK_RPM_PACKAGE_ARCHITECTURE
                    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
            endif()
            # Construire le nom complet du fichier .rpm
            set(CPACK_PACKAGE_FILE_NAME
                "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_RPM_PACKAGE_RELEASE}-${CPACK_RPM_PACKAGE_ARCHITECTURE}")
        endif()
    endif()

    # Inclure le module CPack pour générer les paquets
    include(CPack)
endif()
