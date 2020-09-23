![alt tag](http://imgur.com/RteTEoC.png)

# Datafile: Character Management
A plugin that allows factions to manage a character their personal file.

**WIP**

## Tables
These tables are the ones set up in datafile for every player.

**_GenericData**
Basic information about the player: does he have a bol, is the file restricted, what is the Civil Status and when has the player last been seen?
```
_GenericData = {
    bol = {false, ""},
    restricted = {false, ""},
    civilStatus = "";
    lastSeen = "";
};
```

**_Datafile**
This is just a massive table. Every entry is inside. It has information about the category, the text, the date, points (if applicable) and the poster his character name and Steam ID for validation purposes.
```
_Datafile = {
    [k] = {
        category = "", // med, union, civil
        text = "",
        date = "",
        points = "",
        poster = {charName, steamID},
    },
};
```

## Functions

Create a datafile for the player.
```
PLUGIN:CreateDatafile(player);
```

Used in the /Datafile command: decides what to do based upon both players their permissions.
```
PLUGIN:HandleDatafile(player);
```

Update a player their datafile with the new tables.
```
PLUGIN:UpdateDatafile(player, GenericData, Datafile);
```

Add an entry to a player their Datafile.
```
PLUGIN:AddEntry(category, text, date, points, player, poster)
```

Set a player their Civil Status.
```
PLUGIN:SetCivilStatus(player, poster, civilStatus)
```

Scrub a player their datafile.
```
PLUGIN:ClearDatafile(player)
```

Edit an entry of a player their file.
```
PLUGIN:EditEntry(player, entry)
```

Update the last time a player has been seen.
```
PLUGIN:UpdateLastSeen(player, seeer)
```

Put a BOL on the player.
```
PLUGIN:SetBOL(bBOL, text)
```

Make the datafile restricted or not.
```
PLUGIN:SetRestricted(bRestricted, text)
```

## Callbacks

Does the player have a datafile? Returns true if the player has one..
```
PLUGIN:HasDatafile(player);
```

Return _GenericData in table format.
```
PLUGIN:ReturnGenericData(player);
```

Return _Data in table format.
```
PLUGIN:ReturnDatafile(player);
```

Is the player their file restricted? Returns true if it is.
```
PLUGIN:IsRestricted(player);
```

Does the player have a BOL? Return true & the text inside of it if the player has one.
```
PLUGIN:ReturnBOL(player);
```

Is the player in a restricted faction? Return true if yes.
```
PLUGIN:IsRestrictedFaction(player);
```
