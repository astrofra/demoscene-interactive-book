-- presentation

presentation = {
    {
        -- slide 1 'title'
    },

    {
        -- slide 2 'demoscene'
        {type = action_type.node, ref = "photo0"},
        {type = action_type.svid, ref = "assets_compiled/videos/road-to-valhalla_megadrive.mp4", video_audio_path = "assets_compiled/videos/road-to-valhalla_megadrive.wav",  hide_slide = true,
        title = "Road to Valhalla, par Julien JDM & Resistance (2017 / 4Mo)"},
        {type = action_type.node, ref = "photo1"},
        {type = action_type.node, ref = "photo2"},
        {type = action_type.node, ref = "photo3", zoetrope = {bitmap = "common/image-sequences/caillou_seq.png", 
        uniforms = {uCustom = hg.Vec4(1.150, 1.200, -0.075, 0.000), uFramerate = hg.Vec4(25.0, 0, 0, 0)}}},
        {type = action_type.node, ref = "photo4"},
        {type = action_type.node, ref = "photo5",
        background_func = "SceneCavern", context = "cavern"},
    },

    {
        -- slide 3 'side coding'
        {type = action_type.node, ref = "photo0"},
        {type = action_type.node, ref = "photo1"},
        {type = action_type.node, ref = "photo2"},
        {type = action_type.node, ref = "photo3"},
        {type = action_type.node, ref = "photo4"},
        {type = action_type.node, ref = "photo5"},
    },

    {
        -- slide 4 'demonstration'
        {type = action_type.svid, ref = "assets_compiled/videos/megapole.mp4",  hide_slide = true,
        title = "Megapole, par RedSector Inc. (2015 / 256 Octets)"},
        {type = action_type.svid, ref = "assets_compiled/videos/remnants.mp4",  hide_slide = true,
        title = "Remnants, par Alcatraz (2024 / 256 Octets)"},
        {type = action_type.svid, ref = "assets_compiled/videos/bones-of-civilisation.mp4", video_audio_path = "assets_compiled/videos/bones-of-civilisation.wav", hide_slide = true,
        title = "Bones of civilization, par Fulcrum (2025 / 1Ko)"},
        {type = action_type.svid, ref = "assets_compiled/videos/rau.mp4", video_audio_path = "assets_compiled/videos/rau.wav", hide_slide = true,
        title = "Rau, par Nuance (2025 / 4Ko)"},
        {type = action_type.svid, ref = "assets_compiled/videos/offscreen-colonies.mp4", video_audio_path = "assets_compiled/videos/offscreen-colonies.wav",   hide_slide = true,
        title = "Offscreen Colonies, par Conspiracy (2015 / 64Ko)"},
        {type = action_type.svid, ref = "assets_compiled/videos/brute-concrete.mp4", video_audio_path = "assets_compiled/videos/brute-concrete.wav", hide_slide = true,
        title = "Brute Concrete, par Digital Dynamite & United Force (2025 / 64Ko)"},
        {type = action_type.svid, ref = "assets_compiled/videos/hold-and-modify.mp4", video_audio_path = "assets_compiled/videos/hold-and-modify.wav", hide_slide = true,
        title = "Hold-And-Modify, par CNCD & Fairlight (2015 / 64 Mo)"},
    },

    {
        -- slide 5 'live coding'
        {type = action_type.node, ref = "photo0"},
        {type = action_type.node, ref = "photo1"},
        {type = action_type.node, ref = "photo2"},
        {type = action_type.svid, ref = "assets_compiled/videos/algorave-tracks-arte-short.mp4", video_audio_path = "assets_compiled/videos/algorave-tracks-arte-short.wav", hide_slide = true,
        title = "Algorave : la teuf en open source (2025, Tracks, Arte)"},
    },

    {
        -- slide 6 'Pouet'
        {type = action_type.node, ref = "photo0"},
        {type = action_type.svid, ref = "assets_compiled/videos/pouet.mp4", video_audio_path = "assets_compiled/videos/pouet.wav",  hide_slide = true,
        title = "https://Pouet.net"},
        {type = action_type.svid, ref = "assets_compiled/videos/scene-parties.mp4", hide_slide = true,
        title = "https://files.scene.org/browse/parties/"},
        {type = action_type.svid, ref = "assets_compiled/videos/scene-browse.mp4", hide_slide = true,
        title = "https://files.scene.org/browse/"},
        {type = action_type.svid, ref = "assets_compiled/videos/pouet-submit.mp4", hide_slide = true,
        title = "Submit a demo on Pouet.net"},
        {type = action_type.svid, ref = "assets_compiled/videos/demozoo.mp4", hide_slide = true,
        title = "https://demozoo.org"},

    },

    {
        -- slide 7 'Shadow Party'
    },
}