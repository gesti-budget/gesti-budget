# === Récupération des informations Git pour inclusion dans versions.h ===
#
# Ce bloc utilise `git` pour extraire automatiquement :
# - le nom de la branche courante
# - le hash abrégé du dernier commit
# - la date du dernier commit
#
# Ces informations seront ensuite utilisées pour générer un fichier `versions.h`
# contenant les métadonnées de version du dépôt actuel.

# Assure-toi que Git est disponible sur le système
find_package(Git REQUIRED)

# Récupère le nom de la branche courante (ex: "main", "develop")
execute_process(
    COMMAND ${GIT_EXECUTABLE} symbolic-ref --short -q HEAD
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_BRANCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    TIMEOUT 4
    ERROR_QUIET
)

# Récupère le hash abrégé du dernier commit (ex: "a1b2c3d")
execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 --format=%h
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_COMMIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    TIMEOUT 4
    ERROR_QUIET
)

# Récupère la date du dernier commit (format court : YYYY-MM-DD)
execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 --format=%cd --date=short
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_COMMIT_DATE
    OUTPUT_STRIP_TRAILING_WHITESPACE
    TIMEOUT 4
    ERROR_QUIET
)