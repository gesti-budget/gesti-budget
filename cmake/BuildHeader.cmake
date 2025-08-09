# Le fichier build.h sera généré dans ${PROJECT_BINARY_DIR}/generated/src
# à partir du template src/build.h.in. Il contient :
# - la version complète
# - la date/heure de compilation (via __DATE__ et __TIME__)

# === Génération de build.h depuis un template CMake ===
#
# Le fichier `src/build.h.in` contient des variables à substituer automatiquement.
# CMake génère un fichier `build.h` dans le dossier de génération (build)
# en injectant la valeur actuelle de la version complète (avec suffixe instable éventuel).
#
# Avantages :
# - Ne modifie pas les sources (build.h est généré hors de src/)
# - Ne régénère le fichier que si son contenu change
# - Compatible avec les bonnes pratiques de génération hors-sources

configure_file(
    ${PROJECT_SOURCE_DIR}/src/build.h.in      # Fichier modèle
    ${PROJECT_SOURCE_DIR}/src/build.h         # Fichier de sortie
    @ONLY                                     # Ne remplace que les variables @...@
)
