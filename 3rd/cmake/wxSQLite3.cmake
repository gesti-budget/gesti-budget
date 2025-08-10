# --- Recherche via pkg-config ---
find_package(PkgConfig)  # Tente de trouver l’outil pkg-config (Linux?)
if(PkgConfig_FOUND)
    # Recherche du module wxSQLite3 via pkg-config (plusieurs noms possibles selon la version/distribution)
    PKG_SEARCH_MODULE(wxSQLite3 QUIET wxsqlite3-3.0 wxsqlite3 wxsqlite>=3)
endif()

# --- Si wxSQLite3 est trouvé via pkg-config ---
if(wxSQLite3_FOUND)
    message(STATUS "Found wxSQLite3: ${wxSQLite3_LIBRARIES} (found version \"${wxSQLite3_VERSION}\")")

    # Test de la présence du support "CODEC" (chiffrement des bases SQLite)
    # On écrit un petit code source temporaire qui inclut <wx/wxsqlite3opt.h>
    file(WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/WXSQLITE3_HAVE_CODEC.c"
        "#include <wx/wxsqlite3opt.h>\n#if !WXSQLITE3_HAVE_CODEC\n#error\n#endif\n\nint main(int argc, char** argv)\n{\n  (void)argv;\n  (void)argc;\n  return 0;\n}\n")

    # On tente de compiler ce code pour vérifier la présence de WXSQLITE3_HAVE_CODEC
    try_compile(WXSQLITE3_HAVE_CODEC ${CMAKE_BINARY_DIR}
        "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/WXSQLITE3_HAVE_CODEC.c"
        CMAKE_FLAGS "-DINCLUDE_DIRECTORIES:STRING=${wxSQLite3_INCLUDE_DIRS}")
    set(WXSQLITE3_HAVE_CODEC ${WXSQLITE3_HAVE_CODEC} CACHE INTERNAL "Have symbol ${SYMBOL}")

    # Si la lib supporte le CODEC ou si on a activé l’option d’encryptage optionnelle
    if(WXSQLITE3_HAVE_CODEC OR MMEX_ENCRYPTION_OPTIONAL)
        add_library(wxSQLite3 INTERFACE)
        target_include_directories(wxSQLite3 SYSTEM INTERFACE ${wxSQLite3_INCLUDE_DIRS})
        target_link_libraries(wxSQLite3 INTERFACE ${wxSQLite3_LIBRARIES} wxWidgets)
        target_compile_options(wxSQLite3 INTERFACE ${wxSQLite3_CFLAGS})
    else()
        message(WARNING "wxSQLite3 found does not support database encryption - compiling from sources")
    endif()
endif()

# --- Si wxSQLite3 n’est pas trouvé ou n’a pas de CODEC ---
if(NOT wxSQLite3_FOUND OR NOT (WXSQLITE3_HAVE_CODEC OR GBEX_ENCRYPTION_OPTIONAL))
    set(WXSQLITE3_HAVE_CODEC ON)

    # Lire la version de wxSQLite3 depuis wxsqlite3_version.h
    file(STRINGS wxsqlite3/include/wx/wxsqlite3_version.h
        wxSQLite3_VERSION LIMIT_COUNT 1
            REGEX "#define WXSQLITE3_VERSION_STRING[\t ]+\"[^\"]+ [0-9.]+\"")
    string(REGEX REPLACE ".+\"[^\"]+ ([0-9.]+)\".*" \\1 wxSQLite3_VERSION ${wxSQLite3_VERSION})


    # Compilation locale de SQLite3 modifié (sqlite3mc_amalgamation.c)
    add_library(SQLite3 STATIC EXCLUDE_FROM_ALL wxsqlite3/src/sqlite3mc_amalgamation.c)
    target_include_directories(SQLite3 SYSTEM PUBLIC wxsqlite3/src)

        # Sous Linux, vérifier la présence de la lib dl (pour dlopen)
    if(LINUX)
        include(CheckLibraryExists)
        CHECK_LIBRARY_EXISTS(${CMAKE_DL_LIBS} dlopen "" HAVE_DLOPEN)
        if(NOT HAVE_DLOPEN)
            message(SEND_ERROR "Could not find required dl library.")
        endif()
        target_link_libraries(SQLite3 PRIVATE ${CMAKE_DL_LIBS})
    endif()

    # Compilation locale de wxSQLite3 (en se basant sur wxsqlite3.cpp)
    add_library(wxSQLite3 STATIC EXCLUDE_FROM_ALL wxsqlite3/src/wxsqlite3.cpp)
    target_include_directories(wxSQLite3 SYSTEM PUBLIC wxsqlite3/include)
    target_link_libraries(wxSQLite3 PUBLIC wxWidgets SQLite3)

    # Définition de macros pour SQLite3 compilé
    target_compile_definitions(SQLite3
        PRIVATE
            NOPCH
            SQLITE_CORE
            SQLITE_ENABLE_FTS5
            SQLITE_ENABLE_EXTFUNC
            SQLITE_ENABLE_COLUMN_METADATA
            SQLITE_ENABLE_JSON1
            HAVE_ACOSH
            HAVE_ASINH
            HAVE_ATANH
            HAVE_ISBLANK
        PUBLIC
            SQLITE_HAS_CODEC
            CODEC_TYPE=CODEC_TYPE_AES128
            WXSQLITE3_USE_SQLCIPHER_LEGACY)


    # Définition de macros pour wxSQLite3 compilé
    target_compile_definitions(wxSQLite3
        PUBLIC
            WXSQLITE3_HAVE_CODEC
            WXSQLITE3_HAVE_METADATA
            WXSQLITE3_USER_AUTHENTICATION)

    # --- Gestion de la compatibilité C++11 ---
    if(";${CMAKE_CXX_COMPILE_FEATURES};" MATCHES ";cxx_std_11;")
        target_compile_features(wxSQLite3 PRIVATE cxx_std_11)
    elseif(";${CMAKE_CXX_COMPILE_FEATURES};" MATCHES ";cxx_range_for;")
        target_compile_features(wxSQLite3 PRIVATE cxx_range_for)
    else()
        include(CheckCXXCompilerFlag)
        CHECK_CXX_COMPILER_FLAG("-std=gnu++11" COMPILER_SUPPORTS_GXX11)
        CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
        CHECK_CXX_COMPILER_FLAG("-std=gnu++0x" COMPILER_SUPPORTS_GXX0X)
        CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
        if(COMPILER_SUPPORTS_GXX11)
            target_compile_options(wxSQLite3 PRIVATE -std=gnu++11)
        elseif(COMPILER_SUPPORTS_CXX11)
            target_compile_options(wxSQLite3 PRIVATE -std=c++11)
        elseif(COMPILER_SUPPORTS_GXX0X)
            target_compile_options(wxSQLite3 PRIVATE -std=gnu++0x)
        elseif(COMPILER_SUPPORTS_CXX0X)
            target_compile_options(wxSQLite3 PRIVATE -std=c++0x)
        else()
            message(SEND_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support.")
        endif()
    endif()

    # --- Gestion de la compatibilité C99 (pour SQLite3) ---
    if(NOT MSVC) # MSVC n’exige pas C99 pour les extensions de sécurité wxSQLite3
        if(NOT ";aarch64;arm;arm64;armv8b;armv8l;" MATCHES ";${CMAKE_HOST_SYSTEM_PROCESSOR};")
            set (CMAKE_C_FLAGS "-msse4.2 -maes") # Optimisations CPU pour x86
        endif()
        if(";${CMAKE_C_COMPILE_FEATURES};" MATCHES ";c_std_99;")
            target_compile_features(SQLite3 PRIVATE c_std_99)
        elseif(";${CMAKE_C_COMPILE_FEATURES};" MATCHES ";c_restrict;")
            target_compile_features(SQLite3 PRIVATE c_restrict)
        else()
            include(CheckCCompilerFlag)
            CHECK_C_COMPILER_FLAG("-std=c99" COMPILER_SUPPORTS_C99)
            if(COMPILER_SUPPORTS_C99)
                target_compile_options(SQLite3 PRIVATE -std=c99)
            else()
                message(SEND_ERROR "The compiler ${CMAKE_C_COMPILER} has no C99 support.")
            endif()
        endif()
    endif()
    message(STATUS "wxSQLite3_VERSION = ${wxSQLite3_VERSION}")
endif()