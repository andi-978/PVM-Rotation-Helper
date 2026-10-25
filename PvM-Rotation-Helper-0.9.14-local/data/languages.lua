-- Language resources and accepted localized key aliases; no executable logic.
-- Own existing plugin labels/parser facts, centralized for English code style.
return {
    labels = { de = "Deutsch", en = "English", fr = "Français", ["pt-BR"] = "Português" },
    keyModifiers = { ["shift"] = 1, ["umschalt"] = 1, ["maj"] = 1,
        ["ctrl"] = 2, ["control"] = 2, ["strg"] = 2, ["alt"] = 4 },
    keySymbols = { ["-"] = "MINUS", ["="] = "EQUALS", [","] = "COMMA", ["."] = "FULLSTOP",
        ["["] = "LEFT_BRACKET", ["]"] = "RIGHT_BRACKET", [";"] = "SEMICOLON", ["'"] = "APOSTROPHE",
        ["#"] = "HASH", ["/"] = "SLASH", ["\\"] = "BACKSLASH", ["space"] = "SPACE", ["espace"] = "SPACE",
        ["leertaste"] = "SPACE", ["espaco"] = "SPACE", ["barradeespaco"] = "SPACE" },
}
