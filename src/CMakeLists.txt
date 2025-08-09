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

# === Inclusion du module pour vérifier la compatibilité des options du compilateur C++ ===
include(CheckCXXCompilerFlag)


# Ajoutez une source à l'exécutable de ce projet.
add_executable (${GBEX_EXE} "gesti-budget.cpp" "gesti-budget.h")

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET ${GBEX_EXE} PROPERTY CXX_STANDARD 20)
endif()