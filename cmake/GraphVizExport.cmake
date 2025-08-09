# === Export de la structure du projet au format Graphviz ===
# Écrit un fichier de configuration utilisé par :
#   cmake --graphviz=graph.dot
# Pour générer une visualisation des dépendances entre targets.


# === Configuration pour l’export Graphviz des dépendances CMake ===
#
# Ce fichier de configuration est automatiquement écrit dans le dossier de build.
# Il permet de contrôler le comportement de la commande :
#
#   cmake --graphviz=graph.dot
#
# Et d’ensuite générer un graphe visuel avec Graphviz :
#
#   dot -Tpng graph.dot -o graph.png
#
# 🔍 Utile pour :
# - visualiser les dépendances entre les targets
# - repérer les cycles ou redondances
# - documenter l’architecture du projet

file(WRITE "${CMAKE_BINARY_DIR}/CMakeGraphVizOptions.cmake" "
    # Nom du graphe principal affiché
    set(GRAPHVIZ_GRAPH_NAME \"GBEX build dependency graph\")

    # Ne pas générer un graphe séparé pour chaque target
    set(GRAPHVIZ_GENERATE_PER_TARGET FALSE)

    # Ne pas afficher les dépendances inverses (qui dépend de qui)
    set(GRAPHVIZ_GENERATE_DEPENDERS FALSE)
")
