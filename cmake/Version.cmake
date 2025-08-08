# ---------------------------------------------------------------------------
# GBEX utilise la gestion de version sémantique. Réf. : http://semver.org
#
# VERSION DU PROJET – Format : MAJEUR.MINEUR.CORRECTIF-INSTABLE
# Mettez à jour la version du projet comme suit :
# 1. MAJEUR : lorsqu’il y a des changements incompatibles dans l’API.
# 2. MINEUR : lors de l’ajout de fonctionnalités de manière rétrocompatible.
# 3. CORRECTIF : pour les corrections de bugs rétrocompatibles.
# 4. INSTABLE = alpha, alpha.1, beta, beta.4, rc, rc.3
#    - utilisé comme suffixe additionnel de version ; ne doit PAS être défini pour une version stable.

# En définissant la version de l'application ici, CMake transférera les valeurs
# des variables vers les noms de variables correspondants dans les fichiers suivants :
# ./src/build.h
# ./resources/GBEX.rc
# ---------------------------------------------------------------------------

SET(GBEX_VERSION_ALPHA -1)   # Version alpha désactivée
SET(GBEX_VERSION_BETA -1)    # Version bêta désactivée
SET(GBEX_VERSION_RC -1)      # Version candidate (Release Candidate) désactivée

# ---------------------------------------------------------------------------
# Si le fichier NEWS existe :
# 1. Extraire toutes les lignes commençant par "Version ".
# 2. Supprimer le préfixe "Version " pour ne garder que les numéros de version.
# 3. Récupérer la première version (en supposant que la plus récente est en haut).
# Sinon, afficher un message d'avertissement.
# ---------------------------------------------------------------------------
if(EXISTS "${CMAKE_SOURCE_DIR}/NEWS")
    file(STRINGS NEWS NEWS_VERSION_LINES REGEX "^Version .*")
    string(REPLACE "Version " "" GBEX_VERSIONS "${NEWS_VERSION_LINES}")
    list(GET GBEX_VERSIONS 0 LATEST_GBEX_VERSION)
else()
    message(SEND_ERROR "Le fichier NEWS est introuvable. Impossible de récupérer la version automatiquement.")
endif()

# ---------------------------------------------------------------------------
# Analyse la chaîne de version extraite (LATEST_GBEX_VERSION) pour déterminer
# s’il s’agit d’une version instable (Alpha, Beta, RC) ou stable.
# En cas de version instable, on extrait aussi le numéro associé (ex: "Beta 2").
# Les variables GBEX_VERSION_ALPHA / BETA / RC sont alors définies selon le cas.
# ---------------------------------------------------------------------------

if(LATEST_GBEX_VERSION MATCHES "^([0-9]+)(\\.[0-9]+)(\\.[0-9]+) (Alpha|Beta|RC)( [0-9]+)?$")
    # Cas d’une version Alpha, Beta ou RC avec ou sans numéro (ex: "1.6.3 Beta 2")
    
    if(LATEST_GBEX_VERSION MATCHES ".* [0-9]+$")
        # Si un numéro suit le suffixe (ex: "Beta 2"), on l'extrait
        string(REGEX REPLACE "^.* " "" RELEASE_VERSION "${LATEST_GBEX_VERSION}")
    else()
        # Sinon on considère que c’est la première itération (ex: "Beta" → 0)
        set(RELEASE_VERSION 0)
    endif()

    # Détection du type de version et assignation à la variable appropriée
    if(LATEST_GBEX_VERSION MATCHES ".* Alpha( [0-9]+)?$")
        message(STATUS "Build type: Alpha")
        set(GBEX_VERSION_ALPHA ${RELEASE_VERSION})
    elseif(LATEST_GBEX_VERSION MATCHES ".* Beta( [0-9]+)?$")
        message(STATUS "Build type: Beta")
        set(GBEX_VERSION_BETA ${RELEASE_VERSION})
    elseif(LATEST_GBEX_VERSION MATCHES ".* RC( [0-9]+)?$")
        message(STATUS "Build type: RC")
        set(GBEX_VERSION_RC ${RELEASE_VERSION})
    else()
        # Type inconnu : message d’erreur bloquant
        message(SEND_ERROR "Invalid version string: \"${LATEST_GBEX_VERSION}\"")
    endif()

elseif(LATEST_GBEX_VERSION MATCHES "^([0-9]+)(\\.[0-9]+)(\\.[0-9]+)$")
    # Cas d’une version stable sans suffixe (ex: "1.6.3")
    message(STATUS "Build type: Stable")

else()
    # Format invalide : message d’erreur bloquant
    message(SEND_ERROR "Invalid version string: \"${LATEST_GBEX_VERSION}\"")
endif()

# Supprime tout ce qui suit un espace (ex: "1.6.3 Beta 2" → "1.6.3")
string(REGEX REPLACE " .*$" "" GBEX_VERSION "${LATEST_GBEX_VERSION}")

# === Construction de la chaîne de version complète (stable + instable) ===
#
# Ce bloc assemble la version complète du projet GBEX, en prenant en compte :
# - le numéro de version stable (ex: 1.6.3)
# - le suffixe instable éventuel (Alpha, Beta, RC, avec ou sans numéro)
#
# Résultat final (GBEX_VERSION_FULL) : par exemple "1.6.3-Beta.2"
# Cette version est ensuite transmise à la directive `project()`.

# Vérifie quelle version instable est définie (Alpha, Beta ou RC)
if(GBEX_VERSION_ALPHA EQUAL 0)
    set(GBEX_VERSION_UNSTABLE Alpha)
elseif(GBEX_VERSION_ALPHA GREATER 0)
    set(GBEX_VERSION_UNSTABLE Alpha.${GBEX_VERSION_ALPHA})
elseif(GBEX_VERSION_BETA EQUAL 0)
    set(GBEX_VERSION_UNSTABLE Beta)
elseif(GBEX_VERSION_BETA GREATER 0)
    set(GBEX_VERSION_UNSTABLE Beta.${GBEX_VERSION_BETA})
elseif(GBEX_VERSION_RC EQUAL 0)
    set(GBEX_VERSION_UNSTABLE RC)
elseif(GBEX_VERSION_RC GREATER 0)
    set(GBEX_VERSION_UNSTABLE RC.${GBEX_VERSION_RC})
endif()

# Par défaut, la version complète = version stable uniquement
set(GBEX_VERSION_WITH_UNSTABLE ${GBEX_VERSION})

# Si une version instable est définie, on l'ajoute au format "-Suffix"
if(GBEX_VERSION_UNSTABLE)
    set(GBEX_VERSION_WITH_UNSTABLE "${GBEX_VERSION}-${GBEX_VERSION_UNSTABLE}")
endif()

# Chaîne finale complète de version
set(GBEX_VERSION_FULL ${GBEX_VERSION_WITH_UNSTABLE})