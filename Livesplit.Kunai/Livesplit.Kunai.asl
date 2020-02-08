state("Kunai") {}

startup {
    refreshRate = 0.5;

    settings.Add("weapons", false, "Weapons");
    settings.Add("bosses", false, "Bosses");
    settings.Add("events", false, "Events");
    settings.Add("scenes", false, "Scenes (split at first enter)");
    settings.Add("perks", false, "Perks");
    settings.Add("upgrades", false, "Upgrades");

    settings.CurrentDefaultParent = "weapons";
    settings.Add("weapon_1", false, "Katana");
    settings.Add("weapon_64", false, "Right Kunai");
    settings.Add("weapon_32", false, "Left Kunai");
    settings.Add("weapon_4", false, "Shuriken");
    settings.Add("weapon_8", false, "SMGs");
    settings.Add("weapon_16", false, "Rocket Launcher");

    settings.CurrentDefaultParent = "bosses";
    settings.Add("event_4", false, "The Garbage Collector");
    settings.Add("event_16", false, "The Guardian");
    settings.Add("event_32", false, "The Deprecator");
    settings.Add("event_64", false, "Furious Ferro");
    settings.Add("event_128", false, "Zensei");
    settings.Add("event_lemonkus", false, "Lemonkus (test)");
    
    settings.CurrentDefaultParent = "events";
    settings.Add("event_8", false, "Resistance Camp Destroyed");
    settings.Add("event_4096", false, "Cave Collapsed");
    settings.Add("event_8192", false, "Lava Flow Enabled");
    settings.Add("event_16384", false, "Joined Church Of Skebin");
    settings.Add("event_1024", false, "Got Captured");
    settings.Add("event_2048", false, "Got Weapons Back");
    settings.Add("event_256", false, "Escaped From Prison");
    settings.Add("event_1", false, "Picked Up Air Base Core");
    settings.Add("event_2", false, "Delivered Air Base Core");
    settings.Add("event_32768", false, "Flew To Mars");
    settings.Add("event_512", false, "Completed Dream Sequence");

    settings.CurrentDefaultParent = "scenes";
    settings.Add("scene_Factory", false, "Haunted Factory");
    settings.Add("scene_Forest", false, "Quantum Forest");
    //Battlecruiser Y4R?
    settings.Add("scene_Desert", false, "Artificial Desert");
    //Shuriken Shrine
    settings.Add("scene_Subway", false, "Abandoned Subnet");
    settings.Add("scene_Caves", false, "Crypto Mines");
    settings.Add("scene_ZenMountains", false, "Zen Mountains");
    settings.Add("scene_City", false, "Robopolis");
    settings.Add("scene_AirBase", false, "SSD Floatanic");
    settings.Add("scene_Mars", false, "0b101010");

    settings.CurrentDefaultParent = "perks";
    settings.Add("upgrade_32", false, "Map");
    settings.Add("upgrade_2", false, "Extra Jump");
    settings.Add("upgrade_4", false, "Dash");
    settings.Add("upgrade_1024", false, "Soulbound (obtained when?)");
    settings.Add("upgrade_1", false, "Focus Chip (???)");
    settings.Add("upgrade_8", false, "Zen Mode Chip (???)");
    settings.Add("upgrade_2097152", false, "Cellular Network (???)");
    // settings.Add("upgrade_8388608", false, "GodMode");

    settings.CurrentDefaultParent = "upgrades";
    settings.Add("upgrade_16", false, "(Featured) Solar Panel");
    settings.Add("upgrade_64", false, "(Featured) Coin Magnet");
    settings.Add("upgrade_256", false, "(Katana) Charge Attack");
    settings.Add("upgrade_512", false, "(Katana) Attunement");
    settings.Add("upgrade_4096", false, "(Kunai) Slingshot");
    settings.Add("upgrade_8192", false, "(Shuriken) Lightning Strike");
    settings.Add("upgrade_16384", false, "(Shuriken) Steady Ground");
    settings.Add("upgrade_32768", false, "(SMGs) Shotgun Blast");
    settings.Add("upgrade_65536", false, "(SMGs) Clip Size");
    settings.Add("upgrade_131072", false, "(SMGs) Precision");
    settings.Add("upgrade_262144", false, "(Rocket Launcher) Missile Barrage");
    settings.Add("upgrade_524288", false, "(Rocket Launcher) Rocket Jump");
    settings.Add("upgrade_1048576", false, "(Rocket Launcher) Recoil Reduction");
    settings.Add("upgrade_4194304", false, "(Dream) Exploit");

    vars.visitedScenes = new HashSet<string>();

    vars.ResetVars = (EventHandler)((s, e) => {
        vars.visitedScenes = new HashSet<string>();
    });
    timer.OnStart += vars.ResetVars;

    vars.scanLoadingScreen = new SigScanTarget(0x8, "55 8B EC 83 EC 28 8B 05 ?? ?? ?? ?? 89 04 24");
    vars.scanGameState = new SigScanTarget(0x24, "55 8B EC 83 EC 28 C7 04 24 ?? ?? ?? ?? 8B C0 E8 ?? ?? ?? ?? 89 45 FC 89 04 24 90 E8 ?? ?? ?? ?? 8B 4D FC B8 ?? ?? ?? ?? 89 08 C9 C3");
    vars.scanPlayerSystem = new SigScanTarget(0x1, "BA ?? ?? ?? ?? 8B C0 E8 ???????? 8B 40 0C 89 45 CC");
    vars.scanLevelSystem = new SigScanTarget(0x6, "85 C0 74 06 8B 1D");
}

init {
    IntPtr ptrLoadingScreen = IntPtr.Zero;
    IntPtr ptrGameState = IntPtr.Zero;
    IntPtr ptrPlayerSystem = IntPtr.Zero;
    IntPtr ptrLevelSystem = IntPtr.Zero;

    print("[Autosplitter] Scanning memory");
    foreach (var page in game.MemoryPages()) {
        var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

        if(ptrLoadingScreen == IntPtr.Zero && (ptrLoadingScreen = scanner.Scan(vars.scanLoadingScreen)) != IntPtr.Zero)
            print("[Autosplitter] LoadingScreen Found : " + ptrLoadingScreen.ToString("X"));

        if(ptrGameState == IntPtr.Zero) {
            foreach (IntPtr ptr in scanner.ScanAll(vars.scanGameState)) {
                if(game.ReadValue<float>(game.ReadPointer(game.ReadPointer(ptr))+0x4C) != 25.42f)
                    continue;

                ptrGameState = ptr;
                print("[Autosplitter] GameState Found : " + ptrGameState.ToString("X"));
                break;
            }
        }

        if(ptrPlayerSystem == IntPtr.Zero && (ptrPlayerSystem = scanner.Scan(vars.scanPlayerSystem)) != IntPtr.Zero)
            print("[Autosplitter] PlayerSystem Found : " + ptrPlayerSystem.ToString("X"));

        if(ptrLevelSystem == IntPtr.Zero && (ptrLevelSystem = scanner.Scan(vars.scanLevelSystem)) != IntPtr.Zero)
            print("[Autosplitter] LevelSystem Found : " + ptrLevelSystem.ToString("X"));

        if(ptrLoadingScreen != IntPtr.Zero && ptrGameState != IntPtr.Zero && ptrPlayerSystem != IntPtr.Zero && ptrLevelSystem != IntPtr.Zero)
            break;
    }

    if(ptrLoadingScreen == IntPtr.Zero || ptrGameState == IntPtr.Zero || ptrPlayerSystem == IntPtr.Zero || ptrLevelSystem == IntPtr.Zero)
        throw new Exception("[Autosplitter] Can't find signature");
    
    vars.watchers = new MemoryWatcherList() {
        (vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(ptrLoadingScreen, 0x0, 0x20))),

        (vars.playtime = new MemoryWatcher<float>(new DeepPointer(ptrGameState, 0x0, 0x44))),
        (vars.weapons = new MemoryWatcher<int>(new DeepPointer(ptrGameState, 0x0, 0x50))),
        (vars.upgrades = new MemoryWatcher<int>(new DeepPointer(ptrGameState, 0x0, 0x54))),
        (vars.worldEvents = new MemoryWatcher<int>(new DeepPointer(ptrGameState, 0x0, 0x68))),

        (vars.controlsDisableStack = new MemoryWatcher<int>(new DeepPointer(ptrPlayerSystem, 0x24, 0x4, 0x0, 0x0C, 0x10, 0xCC))),
        
        (vars.actToLoad = new StringWatcher(new DeepPointer(ptrLevelSystem, 0x0, 0xC), 64))
    };

    refreshRate = 200/3d;
}

start {
    return !vars.isLoading.Old && vars.isLoading.Current && vars.playtime.Current == 0;
}

update {
    vars.watchers.UpdateAll(game);
}

split {
    if(vars.weapons.Changed) {
        return settings["weapon_"+(vars.weapons.Current-vars.weapons.Old)];
    }

    if(vars.worldEvents.Changed) {
        return settings["event_"+(vars.worldEvents.Current-vars.worldEvents.Old)];
    }

    if(vars.controlsDisableStack.Old == 1 && vars.controlsDisableStack.Current == 2 && vars.actToLoad.Current.Equals("Mars")) {
        return settings["event_lemonkus"];
    }

    if(vars.actToLoad.Changed && vars.visitedScenes.Add(vars.actToLoad.Current)) {
        return settings["scene_"+vars.actToLoad.Current];
    }

    if(vars.upgrades.Changed) {
        return settings["upgrade_"+(vars.upgrades.Current-vars.upgrades.Old)];
    }
}

isLoading {
    return vars.isLoading.Current;
}

shutdown {
    timer.OnStart -= vars.ResetVars;
}