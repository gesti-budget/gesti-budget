#include <windows.h>
#include <string>
#include <vector>

static std::wstring ExeDir()
{
    wchar_t buf[MAX_PATH];
    DWORD n = GetModuleFileNameW(nullptr, buf, MAX_PATH);
    std::wstring path(buf, n);
    size_t pos = path.find_last_of(L"\\/");
    return (pos == std::wstring::npos) ? L"." : path.substr(0, pos);
}

static bool TryLoadAnyWxDllInFolder(const std::wstring& folder)
{
    WIN32_FIND_DATAW fd;
    HANDLE h = FindFirstFileW((folder + L"\\wx*.dll").c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) return false;
    bool ok = false;
    do {
        HMODULE lib = LoadLibraryW((folder + L"\\" + fd.cFileName).c_str());
        if (lib) { FreeLibrary(lib); ok = true; break; }
    } while (FindNextFileW(h, &fd));
    FindClose(h);
    return ok;
}

static bool TryLoadCommonWxNamesFromPATH()
{
    // Noms fréquents (varient selon la build wx) — on tente quelques possibilités usuelles.
    const std::wstring candidates[] = {
        L"wxmsw341u_core.dll", L"wxbase341u.dll",     // wx 3.2/3.1+ empaquetages récents
        L"wxmsw32u_core_vc_custom.dll", L"wxbase32u_vc_custom.dll" // builds VC “custom”
    };
    for (const auto& name : candidates) {
        if (HMODULE lib = LoadLibraryW(name.c_str())) {
            FreeLibrary(lib);
            return true;
        }
    }
    return false;
}

static bool IsWxWidgetsAvailable()
{
    // 1) Regarder d’abord à côté de l’exécutable
    if (TryLoadAnyWxDllInFolder(ExeDir()))
        return true;
    // 2) Sinon, tenter quelques noms usuels via le PATH
    return TryLoadCommonWxNamesFromPATH();
}

int WINAPI wWinMain(
    _In_     HINSTANCE hInstance,
    _In_opt_ HINSTANCE hPrevInstance,
    _In_     PWSTR     lpCmdLine,
    _In_     int       nCmdShow)
{
    (void)hInstance; (void)hPrevInstance; (void)lpCmdLine; (void)nCmdShow;
    const bool ok = IsWxWidgetsAvailable();
    MessageBoxW(
        nullptr,
        ok
        ? L"wxWidgets semble disponible (au moins une DLL wx* a pu être chargée)."
        : L"wxWidgets introuvable.\nPlace les DLLs wx* dans le dossier de l’exécutable ou ajoute-les au PATH.",
        L"Probe wxWidgets",
        ok ? (MB_OK | MB_ICONINFORMATION) : (MB_OK | MB_ICONERROR)
    );
    return ok ? 0 : 1;
}
