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

# --- Recherche et vérification de la présence de gettext ---
find_package(Gettext REQUIRED)  
# → Cherche la bibliothèque et les outils gettext (obligatoire, sinon erreur de configuration).

# --- Si la version gettext n’a pas encore été récupérée ---
if(NOT GETTEXT_VERSION_STRING)
    # Récupère la version en exécutant la commande `msgmerge --version`
    execute_process(COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --version
        OUTPUT_VARIABLE m_version                        # Sauvegarde la sortie dans m_version
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)    # Supprime espaces/retours inutiles

    # Récupère le nom complet de l’exécutable et son nom sans extension
    get_filename_component(m_name ${GETTEXT_MSGMERGE_EXECUTABLE} NAME)
    get_filename_component(m_namewe ${GETTEXT_MSGMERGE_EXECUTABLE} NAME_WE)

    # Utilise une regex pour extraire uniquement le numéro de version
    if(m_version MATCHES "^(${m_name}|${m_namewe}) \\([^\\)]*\\) ([0-9\\.]+[^ \n]*)")
        set(GETTEXT_VERSION_STRING "${CMAKE_MATCH_2}")
    endif()

    # Nettoyage des variables temporaires
    unset(m_version)
    unset(m_name)
    unset(m_namewe)
endif()

# Sauvegarde la version détectée dans le cache interne de CMake
set(GETTEXT_VERSION_STRING "${GETTEXT_VERSION_STRING}"
    CACHE INTERNAL "gettext version detected")


# --- Recherche de tous les fichiers .po (traductions) ---
file(GLOB POFiles RELATIVE "${CMAKE_CURRENT_BINARY_DIR}" *.po)

# --- Pour chaque fichier .po trouvé ---
foreach(POFile ${POFiles})
    # Récupère le nom du fichier sans extension
    get_filename_component(CurrentFile "${POFile}" NAME_WE)

    # Ignore le fichier "common.po" (traité séparément plus bas)
    if(CurrentFile MATCHES "common")
        continue()
    endif()

    # Copie le fichier .po vers le dossier build/po
    file(COPY ${CurrentFile}.po DESTINATION ${CMAKE_BINARY_DIR}/po)

    # Génère le fichier .mo (binaire compilé de traduction) à partir du .po
    add_custom_command(
        OUTPUT ${CurrentFile}.mo
        COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -v --statistics -o ${CurrentFile}.mo ${CMAKE_BINARY_DIR}/po/${CurrentFile}.po
        COMMENT ""
        MAIN_DEPENDENCY "${POFile}")

    # --- Détermine le dossier d’installation des .mo selon la plateforme ---
    # Référence : chemins standards wxWidgets
    if(APPLE)
        set(MODir ${GBEX_EXE}.app/Contents/Resources/${CurrentFile}.lproj)  # macOS
    elseif(WIN32)
        set(MODir bin/${CurrentFile})                                        # Windows
    else()
        set(MODir share/${GBEX_EXE}/${CurrentFile})                          # Linux / Unix
        # set(MODir share/locale/${CurrentFile}/LC_MESSAGES)  # Chemin alternatif (commenté)
    endif()

    # Installation du .mo avec renommage en nom de l’exécutable
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${CurrentFile}.mo"
        DESTINATION ${MODir}
        RENAME ${GBEX_EXE}.mo)

    # Ajoute le .mo à la liste pour la cible "Translations"
    list(APPEND MOFiles "${CMAKE_CURRENT_BINARY_DIR}/${CurrentFile}.mo")
endforeach()


# --- Gestion spéciale du fichier "common.po" ---
# (traductions communes à toutes les langues, mises dans en_US)
file(COPY "common.po" DESTINATION ${CMAKE_BINARY_DIR}/po)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/po/common.mo
    COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -v --statistics -o ${CMAKE_CURRENT_BINARY_DIR}/po/common.mo ${CMAKE_CURRENT_BINARY_DIR}/po/common.po
    COMMENT ""
    MAIN_DEPENDENCY common.po
)

# Chemin de destination du common.mo selon la plateforme
if(APPLE)
    set(MODir ${GBEX_EXE}.app/Contents/Resources/en_US.lproj)
elseif(WIN32)
    set(MODir bin/en_US)
else()
    set(MODir share/${GBEX_EXE}/en_US)
endif()

# Installe le fichier common.mo
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/common.mo"
        DESTINATION ${MODir})

# Ajoute à la liste des fichiers générés
list(APPEND MOFiles "${CMAKE_CURRENT_BINARY_DIR}/common.mo")


# --- Cible globale "Translations" ---
# Cette cible régénère toutes les traductions .mo
add_custom_target(Translations ALL DEPENDS ${MOFiles}
    COMMENT "Generated translations")



message(WARNING "Passage dans le Dossier PO....")