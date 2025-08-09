# === Détection de l'environnement Linux (distribution, version, outils) ===
#
# Ce bloc ne s’exécute que si le système cible est Linux.
# Il permet de :
# - Vérifier la présence de certains outils nécessaires (`appstreamcli`, `lsb_release`)
# - Détecter automatiquement la distribution Linux, son nom, sa version, et son nom de code
# - Construire une chaîne descriptive comme "Ubuntu.22.04.jammy"
#
# Ces informations peuvent être utilisées pour :
# - Générer des métadonnées
# - Adapter le build à la distribution
# - Nommer des paquets ou dossiers de build

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")

    # Définition d’un raccourci booléen
    set(LINUX TRUE)

    # Vérifie la présence de `appstreamcli`, requis pour générer les fichiers de métadonnées
    find_program(APPSTREAMCLI appstreamcli
        DOC "outil pour générer les informations de publication (AppStream)")
    if(NOT APPSTREAMCLI)
        message(SEND_ERROR "L’outil appstreamcli est introuvable.")
    endif()

    # --- Tentative de détection de la distribution via lsb_release ---
    find_program(LSB_RELEASE lsb_release
        DOC "outil pour identifier la distribution Linux")

    if(LSB_RELEASE)
        # Nom de la distribution (ex: Ubuntu, Debian)
        execute_process(COMMAND lsb_release -is
            OUTPUT_VARIABLE LINUX_DISTRO
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

        # Nom de code de la distribution (ex: jammy, bookworm)
        execute_process(COMMAND lsb_release -cs
            OUTPUT_VARIABLE LINUX_DISTRO_CODENAME
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

        # Numéro de version de la distribution (ex: 22.04)
        execute_process(COMMAND lsb_release -rs
            OUTPUT_VARIABLE LINUX_DISTRO_REL
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

        # Description longue (ex: "Ubuntu 22.04.1 LTS")
        execute_process(COMMAND lsb_release -ds
            OUTPUT_VARIABLE LINUX_DISTRO_DESCRIPTION
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

        # Nettoyage de la description
        string(REPLACE "\"" "" LINUX_DISTRO_DESCRIPTION "${LINUX_DISTRO_DESCRIPTION}")
        string(REPLACE " " "." LINUX_DISTRO_DESCRIPTION "${LINUX_DISTRO_DESCRIPTION}")

    else()
        # --- Méthodes alternatives si lsb_release est absent ---

        # Slackware : lecture directe d’un fichier système
        if(EXISTS /etc/slackware-version)
            file(STRINGS /etc/slackware-version LINUX_DISTRO LIMIT_COUNT 1)
            if(LINUX_DISTRO MATCHES "^([^.]+) +([0-9.]+)")
                set(LINUX_DISTRO "${CMAKE_MATCH_1}")
                set(LINUX_DISTRO_REL ${CMAKE_MATCH_2})
            endif()

        # Méthode générique via CMake ≥ 3.22 (utilise /etc/os-release)
        elseif(EXISTS /etc/os-release AND ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.22.0")
            cmake_host_system_information(RESULT LINUX_DISTRO QUERY DISTRIB_NAME)
            cmake_host_system_information(RESULT LINUX_DISTRO_REL QUERY DISTRIB_VERSION)

        # Arch Linux
        elseif(EXISTS /etc/arch-release)
            execute_process(COMMAND uname -r
                OUTPUT_VARIABLE LINUX_DISTRO_REL
                OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
            set(LINUX_DISTRO "Arch")

        # Aucune méthode valide trouvée
        else()
            message(SEND_ERROR "Impossible de détecter la distribution : lsb_release est manquant.")
        endif()
    endif()

    # Vérifie que les variables critiques ont bien été détectées
    if(NOT LINUX_DISTRO OR NOT LINUX_DISTRO_REL)
        message(SEND_ERROR "Impossible d’obtenir les informations sur la distribution GNU/Linux.")
    endif()

    # Construit la chaîne globale : ex. Ubuntu.22.04
    set(LINUX_DISTRO_STRING "${LINUX_DISTRO}.${LINUX_DISTRO_REL}")

    # Gestion spéciale du cas "n/a" pour le nom de code
    if(LINUX_DISTRO_CODENAME STREQUAL "n/a")
        if(LINUX_DISTRO STREQUAL "Debian")
            execute_process(COMMAND lsb_release -ds
                OUTPUT_VARIABLE LINUX_DISTRO_CODENAME
                OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
            if(LINUX_DISTRO_CODENAME MATCHES " ([a-z]+)/sid$")
                set(LINUX_DISTRO_CODENAME ${CMAKE_MATCH_1})
            else()
                unset(LINUX_DISTRO_CODENAME)
            endif()
        else()
            unset(LINUX_DISTRO_CODENAME)
        endif()
    endif()

    # Si un nom de code valide est trouvé, on l’ajoute à la chaîne complète
    if(LINUX_DISTRO_CODENAME)
        set(LINUX_DISTRO_STRING "${LINUX_DISTRO_STRING}.${LINUX_DISTRO_CODENAME}")
    endif()

endif()