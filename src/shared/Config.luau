return {
    Version = "1.0.0",
    Title = "NERO CHAOS PARTY",
    Tagline = "ALLES GEHT SCHIEF!",
    MaxPlayers = 16,
    MinimumPlayers = 1, -- Solo testing and quiet servers; intended for 2–16.
    Intermission = 15,
    VotingTime = 12,
    ResultsTime = 8,
    ChaosInterval = 18,
    AutoSaveSeconds = 45,
    SessionLeaseSeconds = 180,
    DataStoreName = "NeroChaosParty_v1",
    StudioPersistence = false, -- Separate Studio store when enabled; never uses production data.
    OwnerUserIds = {}, -- Add your numeric Roblox UserId. User-owned place creator is also owner.
    VipUserIds = {}, -- Optional social lounge access; no paid benefit or gameplay advantage.
    Audio = {
        Bounce = "rbxasset://sounds/electronicpingshort.wav",
        Fall = "rbxasset://sounds/uuhhh.mp3",
        Chicken = "rbxasset://sounds/electronicpingshort.wav",
        Duck = "rbxasset://sounds/electronicpingshort.wav",
        Horn = "rbxasset://sounds/electronicpingshort.wav",
        Victory = "rbxasset://sounds/electronicpingshort.wav",
        Countdown = "rbxasset://sounds/electronicpingshort.wav",
        Explosion = "rbxasset://sounds/impact_water.mp3",
        LevelUp = "rbxasset://sounds/electronicpingshort.wav",
        Music = "", -- Original WAVs in assets/audio: upload and insert your permitted asset IDs.
    },
}
