# 📌 En résumé
# Objectif : S’assurer que RapidJSON est disponible pour le projet.
# 
# Méthode :
# 
# Essaye d’abord avec le mode CONFIG (qui recherche un RapidJSONConfig.cmake).
# 
# Si échec, essaye la méthode classique (FindRapidJSON.cmake).
# 
# Si toujours échec, pointe vers une copie locale dans rapidjson/include.
# 
# Résultat :
# 
# Crée une cible RapidJSON que les autres parties du projet peuvent 
# lier avec target_link_libraries(...).
#
# Ajoute les bons include paths en tant que headers système 
# pour éviter les avertissements de compilation dans ce code tiers.


# Recherche la bibliothèque RapidJSON version ≥ 1.1 via une configuration CMake (CONFIG)
find_package(RapidJSON 1.1 QUIET CONFIG)

# Si non trouvée avec CONFIG, tente la recherche classique (FindRapidJSON.cmake ou modules standards)
if(NOT RapidJSON_FOUND)
    find_package(RapidJSON 1.1 QUIET)
endif()

# Si toujours introuvable, on définit manuellement le chemin vers une version embarquée du projet
if(NOT RapidJSON_FOUND)
    set(RAPIDJSON_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/rapidjson/include")
endif()

# Affiche dans la sortie CMake le chemin trouvé/utilisé
message(STATUS "Found RapidJSON: ${RAPIDJSON_INCLUDE_DIRS}")

# Crée une bibliothèque INTERFACE pour RapidJSON (pas de compilation, juste une collection de propriétés)
add_library(RapidJSON INTERFACE)

# Ajoute les répertoires d'inclusion à cette cible
# SYSTEM → les inclut comme "system headers" pour éviter les warnings
# BUILD_INTERFACE → ne les ajoute que lors de la compilation dans ce projet (pas pour les installés ailleurs)
target_include_directories(RapidJSON SYSTEM INTERFACE
    $<BUILD_INTERFACE:${RAPIDJSON_INCLUDE_DIRS}>)
