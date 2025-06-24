# Hooking Overview

This document provides a quick reference for developers on how the injector loads the patched server module and the hook DLLs. The diagram summarizes the process and the main functions each hook intercepts.

```mermaid
flowchart TD
    subgraph Game Launch
        start["start_game_* .bat"] --> injector["injector.exe"]
    end

    subgraph Injector
        injector --> loadServer["Load server.dll"]
        injector --> loadHooks["Inject hook DLLs"]
        injector --> resume["Resume process (if newly created)"]
    end

    subgraph Hook DLLs
        loadHooks --> wsHook["hook_ws2_32.dll"]
        loadHooks --> k32Hook["hook_kernel32.dll"]
        loadHooks --> srvHook["hook_server.dll"]
    end

    subgraph wsHookDetails["hook_ws2_32.dll"]
        wsHook --> dllAttachWs["DLL_PROCESS_ATTACH"]
        dllAttachWs --> minhookInitWs["MH_Initialize()"]
        dllAttachWs --> hookRecvSend["Hook recv/send"]
        hookRecvSend --> runRecv["hook_recv: swallows WSAEWOULDBLOCK"]
        hookRecvSend --> runSend["hook_send: retries WSAEWOULDBLOCK"]
    end

    subgraph k32HookDetails["hook_kernel32.dll"]
        k32Hook --> dllAttachK32["DLL_PROCESS_ATTACH"]
        dllAttachK32 --> minhookInitK32["MH_Initialize()"]
        dllAttachK32 --> hookTick["Hook GetTickCount"]
    end

    subgraph srvHookDetails["hook_server.dll"]
        srvHook --> dllAttachSrv["DLL_PROCESS_ATTACH"]
        dllAttachSrv --> minhookInitSrv["MH_Initialize()"]
        dllAttachSrv --> hookF3720["Hook function @0x3720"]
    end
```

The injector first loads `server.dll`, then injects each hook DLL. During `DLL_PROCESS_ATTACH`, every hook uses MinHook to intercept the respective functions. See the source files in `src/` for the implementation details.
