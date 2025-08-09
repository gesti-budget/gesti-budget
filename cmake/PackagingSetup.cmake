# === Définition d'une fonction utilitaire pour créer une archive zip ===
# Utilise la commande CMake -E tar avec --format=zip.
# - output_file : chemin de sortie du fichier zip
# - input_files : liste des fichiers à zipper (relatif à working_dir)
# - working_dir : répertoire dans lequel la commande est exécutée

function(create_zip output_file input_files working_dir)
    add_custom_command(
        COMMAND ${CMAKE_COMMAND} -E tar "cf" "${output_file}" --format=zip -- ${input_files}
        WORKING_DIRECTORY "${working_dir}"
        OUTPUT  "${output_file}"
        DEPENDS ${input_files}
        COMMENT "Zipping to ${output_file}."
    )
endfunction()

# === Macro pour récupérer tous les sous-dossiers d’un répertoire donné ===
# Résultat retourné dans une variable passée par nom (simule un "return").

macro(GETSUBDIRS result curdir)
  file(GLOB children RELATIVE ${curdir} ${curdir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${curdir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()
  set(${result} ${dirlist})
endmacro()

# === Génération des fichiers .mmextheme depuis les sous-dossiers de system-themes/ ===

# Récupère tous les sous-dossiers dans themes/system-themes/
GETSUBDIRS(THEMESDIR "${PROJECT_SOURCE_DIR}/themes/system-themes/")

# Pour chaque thème, créer un fichier .mmextheme en zippant son contenu
foreach(THEMENAME ${THEMESDIR})
    message(FATAL_ERROR "Revenir dans cette partie.")
    file(GLOB THEME_DEFAULT_FILES "${PROJECT_SOURCE_DIR}/themes/system-themes/${THEMENAME}/*")
    create_zip("${CMAKE_CURRENT_BINARY_DIR}/${THEMENAME}.mmextheme" "${THEME_DEFAULT_FILES}" "${PROJECT_SOURCE_DIR}/themes/system-themes/${THEMENAME}/")
    list(APPEND THEMEFILES "${CMAKE_CURRENT_BINARY_DIR}/${THEMENAME}.mmextheme")
endforeach()

# Crée une cible appelée "generate_theme_files" qui dépend de tous les fichiers .mmextheme
# Elle est ajoutée à la construction globale (ALL)
add_custom_target(generate_theme_files ALL DEPENDS ${THEMEFILES})

# === Génération des fichiers .grm (rapports) à partir de general-reports/packages/ ===

# Récupère les groupes de rapports (dossiers dans general-reports/packages/)
GETSUBDIRS(GRMGROUPDIR "${PROJECT_SOURCE_DIR}/general-reports/packages/")

# Pour chaque groupe de rapport...
foreach(GRMGROUP ${GRMGROUPDIR})
    message(FATAL_ERROR "Revenir dans cette partie.")

    # ...on récupère les sous-rapports à l’intérieur du groupe
    GETSUBDIRS(GRMDIR "${PROJECT_SOURCE_DIR}/general-reports/packages/${GRMGROUP}/")

    # Pour chaque rapport, on zippe les fichiers nécessaires dans un .grm
    foreach(GRMNAME ${GRMDIR})
        set(GRM_DEFAULT_FILES
            "${PROJECT_SOURCE_DIR}/general-reports/packages/${GRMGROUP}/${GRMNAME}/description.txt"
            "${PROJECT_SOURCE_DIR}/general-reports/packages/${GRMGROUP}/${GRMNAME}/luacontent.lua"
            "${PROJECT_SOURCE_DIR}/general-reports/packages/${GRMGROUP}/${GRMNAME}/sqlcontent.sql"
            "${PROJECT_SOURCE_DIR}/general-reports/packages/${GRMGROUP}/${GRMNAME}/template.htt"
        )

        create_zip("${CMAKE_CURRENT_BINARY_DIR}/${GRMGROUP}-${GRMNAME}.grm" "${GRM_DEFAULT_FILES}" "${PROJECT_SOURCE_DIR}/general-reports/packages/${GRMGROUP}/${GRMNAME}/")
        list(APPEND GRMFILES "${CMAKE_CURRENT_BINARY_DIR}/${GRMGROUP}-${GRMNAME}.grm")
    endforeach()
endforeach()

# Crée une cible appelée "generate_grm_files" qui dépend de tous les fichiers .grm
add_custom_target(generate_grm_files ALL DEPENDS ${GRMFILES})
