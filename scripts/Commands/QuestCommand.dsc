########################################################################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                        Quest Commands                                                              |#
#--------------------------------------------------------------------------------------------------------------------------------------#
########################################################################################################################################

#-----------------------------------------------------------------------------------------------------------------#
# DESCRIPTION:                                                                                                    #
#     Commands for Quest system                                                                                   #
#                                                                                                                 #
# COMMANDS:                                                                                                       #
#     /quest                                                                                                      #
#                                                                                                                 #
# PERMISSIONS:                                                                                                    #
#     denizen.quests.admin : administration                                                                       #
#                                                                                                                 #
#-----------------------------------------------------------------------------------------------------------------#

QuestCommand:
    type: command
    debug: false
    name: quest
    aliases:
    - quests
    description: Manage quests
    usage: /quest
    tab complete:
    - if <context.server> stop
    # autocomplet quest name for quest commands
    - if <context.args.size> <= 1 && "<context.raw_args.ends_with[ ].not>":
        - define subcommandToComplete <context.args.last.escaped||null>
        - define subcommands li@list|reload|info|start|status|end|update|reset|resetall|stats|enable|disable|available|npc|scripts
        - define result <[subcommands].filter[starts_with[<[subcommandToComplete]>]]||li@>
        - if <[result].is_empty>:
            - define result <[subcommands].as_list||li@>
    - else if <context.args.size> <= 2:
        - define questToComplete <context.args.last.escaped||null>
        - define result <server.flag[QUESTS.AVAILABLE_QUESTS].filter[starts_with[<[questToComplete]>]]||li@>
        - if <[result].is_empty>:
            - define result <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - else:
        - define result <server.list_online_players.parse[name].filter[starts_with[<context.args.last>]]>
    - determine <[result]||li@>

    script:
    - if <context.args.size> == 0:
        # open the Quest journal
        - run instantly s@QuestAPI displayMainMenu
        - stop

    - inject locally <context.args.get[1]>

    # if no inject
    - narrate format:error_format "Unknown Command."
    - stop

    help:
    - narrate format:narration_format " ---------------- <dark_gray>[HELP]<gray> ---------------- "
    - narrate format:narration_format "- <white>/quest status <&lt>quest<&gt> (player)<gray> to show quest status."
    - narrate format:narration_format "- <white>/quest list <gray> to list all quests."
    - narrate format:narration_format "- <white>/quest reload <gray> to reload all quests."
    - narrate format:narration_format "- <white>/quest info <&lt>quest<&gt><gray> to see infos."
    - narrate format:narration_format "- <white>/quest stats <&lt>quest<&gt><gray> to get quest stats."
    - narrate format:narration_format "- <white>/quest start <&lt>quest<&gt> (player)<gray> to force start quest."
    - narrate format:narration_format "- <white>/quest update <&lt>quest<&gt> <&lt>objective<&gt> (player)<gray> to change the objective."
    - narrate format:narration_format "- <white>/quest end <&lt>quest<&gt> (player)<gray> to force finish quest (no reward)."
    - narrate format:narration_format "- <white>/quest reset <&lt>quest<&gt> (player)<gray> to reset quest."
    - narrate format:narration_format "- <white>/quest resetall (player)<gray> to reset ALL player quest."
    - narrate format:narration_format "- <white>/quest enable/disable <&lt>quest<&gt><gray> to enable/disable quest."
    - narrate format:narration_format "- <white>/quest npc <dark_gray>- <gray>Display NPC infos"
    - narrate format:narration_format "- <white>/quest scripts <dark_gray> - <gray>Display NPC quests"
    - narrate format:narration_format "- <white>/quest scripts add/remove/set <&lt>Quest Script<&gt><dark_gray> - <gray>Add/Remove/Set quest to NPC"
    - narrate format:narration_format " -------------------------------------- "
    - stop

    status:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop

    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest status <&lt>quest<&gt> (player)"
        - stop

    - define questID <context.args.get[2]>

    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop

    - if <context.args.size> > 2:
        - define target <server.match_offline_player[<context.args.get[3]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[3]> not found."
            - stop
    - else:
        - define target <player>

    - define activeQuests <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list||li@>
    - if <[activeQuests].contains[<[questID]>].not>:
        - narrate format:narration_format "<[questID]> is not in progress."
    - else:
        - narrate format:narration_format "Current objective: <player.flag[QUESTS.<[questID]>.CURRENT_OBJECTIVE]||0>"

    - define questDataScript <el@val[<[questID]>Data].as_script||null>
    - if <[questDataScript].yaml_key[repeatable]||false>:
        - if <player.has_flag[quests.<[questID]>.cooldown]>:
            - narrate format:narration_format "Cooldown: <player.flag[quests.<[questID]>.cooldown].expiration.formatted>"
        - narrate format:narration_format "Completed <player.flag[QUESTS.<[questID]>.COMPLETED]||0> times."
    - stop

    list:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].is_empty.not>:
        - narrate "<blue><[quests].size> Quests available: "
    - foreach <[quests]>:
        - define questID <[value]>
        - define questDataScript <el@val[<[questID]>Data].as_script||null>
        - if <[questDataScript]> == null:
            - announce to_console "<red>[ERROR] <&r><[questID]>Data is not a valid script."
            - foreach next
        - narrate format:narration_format "- <proc[msgcommand].context[<dark_gray>[<yellow><[questID]><dark_gray>]<gray> <white><[questDataScript].yaml_key[title]||<red>Pas de titre>|quests info <[questID]>|<&a>Cliquer pour plus de détail]>"
    - stop

    start:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest start <&lt>quest<&gt> (player)""
        - stop

    - define questID <context.args.get[2]>
    # fetch quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop
    # fetch player
    - if <context.args.size> > 2:
        - define target <server.match_offline_player[<context.args.get[3]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[3]> not found."
            - stop
    - else:
        - define target <player>
    - run instantly s@QuestAPI p:start def:<[questID]>  player:<[target]>
    - narrate format:success_format "Quest <[questID]> started for <[target].name>."
    - stop

    update:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - if <context.args.size> < 3:
        - narrate format:error_format "Missing arg. Usage : <white>/quest update <&lt>quest<&gt> <&lt>objective<&gt> (player)"
        - stop

    - define questID <context.args.get[2]>
    # recherche de la quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop

    # recherche du numéro d'objective
    - define objectiveNumber <context.args.get[3].as_int||0>
    - if <[objectiveNumber]> < 1:
        - narrate format:error_format "Objective must be an integer and positive."
        - stop

    # recherche du player
    - if <context.args.size> > 3:
        - define target <server.match_offline_player[<context.args.get[4]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[4]> not found."
            - stop
    - else:
        - define target <player>
    - run instantly s@QuestAPI p:updateObjective def:<[questID]>|<[objectiveNumber]>  player:<[target]>
    - narrate format:success_format "<[target].name> has now objective <[objectiveNumber]> of <[questID]>."
    - stop

    end:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop

    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest end <&lt>quest<&gt> (player)"
        - stop

    - define questID <context.args.get[2]>

    # recherche de la quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop

    # recherche du player
    - if <context.args.size> > 2:
        - define target <server.match_offline_player[<context.args.get[3]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[3]> not found."
            - stop
    - else:
        - define target <player>
    - run instantly s@QuestAPI p:end def:<[questID]>  player:<[target]>
    - narrate format:success_format "Quest <[questID]> finished for <[target].name>."
    - stop

    available:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop

    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest end <&lt>quest<&gt> (player)"
        - stop

    - define questID <context.args.get[2]>

    # recherche de la quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop

    # recherche du player
    - if <context.args.size> > 2:
        - define target <server.match_offline_player[<context.args.get[3]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[3]> not found."
            - stop
    - else:
        - define target <player>

    - narrate "<[questID]> available: <red><proc[QuestIsAvailable].context[<[questID]>|<[target]>].replace[true].with[<green>oui]>"
    - stop

    enable:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest enable <&lt>quest<&gt>"
        - stop

    - define questID <context.args.get[2]>
    # recherche de la quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop
    - flag server QUESTS.<[questID]>.active:true
    - narrate format:success_format "Quest <[questID]> enabled."
    - stop

    disable:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest disable <&lt>quest<&gt> (duration)"
        - stop

    - define questID <context.args.get[2]>
    # recherche de la quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop

    - if <context.args.size> == 3:
        - if <context.args.get[3].as_duration||null> == null:
            - narrate format:error_format "Duration no valid. Usage : <white>/quest disable <&lt>quest<&gt> (duration)"
            - stop
        - flag server QUESTS.<[questID]>.active:false duration:<context.args.get[3]>
        - narrate format:success_format "Quest <[questID]> disabled for <context.args.get[3]>."
    - else:
        - flag server QUESTS.<[questID]>.active:false
        - narrate format:success_format "Quest <[questID]> disabled."
    - stop

    info:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest info <&lt>quest<&gt>"
        - stop

    - define questID <context.args.get[2]>
    # recherche de la quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop
    - define questDataScript <el@val[<[questID]>Data].as_script||null>
    - if <[questDataScript]> == null:
        - announce to_console "<red>[ERROR] <&r><[questID]>Data is not a valid script."
        - stop
    - define questsNeeded <[questDataScript].yaml_key[quests_completed].as_list||li@>
    - define availableTime "<[questDataScript].yaml_key[available_time]||0-24000>"

    - define startTime <[availableTime].split[-].first>
    - define endTime <[availableTime].split[-].get[2]>
    # conversion date minecraft en date H24
    - define hoursStart <[startTime].div[1000].add[6].mod[24].round.pad_left[2].with[0]>
    - define minutesStart <[startTime].mod[1000].mul[60].div[1000].round.pad_left[2].with[0]>
    - define hoursEnd <[endTime].div[1000].add[6].mod[24].round.pad_left[2].with[0]>
    - define minutesEnd <[endTime].mod[1000].mul[60].div[1000].round.pad_left[2].with[0]>

    - define unlockFlag "<[questDataScript].yaml_key[unlock_flag]||none>"
    - if <[unlockFlag].trim.is[==].to[]> || <[unlockFlag]> == none:
        - define unlockFlag "<gray>None"

    - narrate format:narration_format " ----- <yellow>[INFOS OF <[questID]>]<gray> ----- "
    - narrate format:narration_format "Title <&co> <white><[questDataScript].yaml_key[title]||<red>Pas de titre>"
    - narrate format:narration_format "Description <&co> <white><[questDataScript].yaml_key[description]||<red>Pas de description>"
    - narrate format:narration_format "Active <&co> <server.flag[QUESTS.<[questID]>.active]||true>"
    - if <[questsNeeded].is_empty.not>:
        - narrate format:narration_format "Quests requirements <&co>"
        - foreach <[questsNeeded]>:
            - narrate "  - <proc[msgcommand].context[<yellow><[value]>|quests info <[value]>|<&a>Cliquer pour plus de détail]>"
    - else:
        - narrate format:narration_format "Quests requirements <&co> <red>No quest require"
    - narrate format:narration_format "Flags required: <red><[unlockFlag]>"
    - narrate format:narration_format "Hours <&co> <white><[hoursStart]>H<[minutesStart]> <gray>to <white><[hoursEnd]>H<[minutesEnd]>"
    - narrate format:narration_format "Experience reward: <[questDataScript].yaml_key[experience]||<red>0>
    - narrate format:narration_format "Money reward: <[questDataScript].yaml_key[money]||<red>0>
    - narrate format:narration_format " -------------------------------------- "
    - stop

    stats:
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - if <context.args.size> < 2:
        - narrate format:error_format "Missing arg. Usage : <white>/quest stats <&lt>quest<&gt> (player)"
        - stop

    - define questID <context.args.get[2]>
    # recherche de la quest
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop
    # recherche du player
    - if <context.args.size> > 2:
        - define target <server.match_offline_player[<context.args.get[3]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[3]> not found."
            - stop
    - else:
        - narrate format:narration_format " ----- <dark_gray>[STATS OF <[questID]>]<gray> ----- "
        - narrate format:narration_format "- Quest started <white><server.flag[quests.stats.<[questID]>.start].round||0> <gray>times."
        - narrate format:narration_format "- Quest finished <white><server.flag[quests.stats.<[questID]>.end].round||0> <gray>times."
        - narrate format:narration_format " -------------------------------------- "
    - stop

    reset:
    - if <context.args.size> < 2:
        - inject locally resetall
        - stop
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    - define questID <context.args.get[2]>
    - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].as_list||li@>
    - if <[quests].contains[<[questID]>].not>:
        - narrate format:error_format "Quest <[questID]> not found."
        - stop
    - if <context.args.size> > 2:
        - define target <server.match_offline_player[<context.args.get[3]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[3]> not found."
            - stop
    - else:
        - define target <player>
    - flag <[target]> quests.<[questID]>:!
    - flag <[target]> quests.COMPLETED_QUESTS:<-:<[questID]>
    - flag <[target]> QUESTS.IN_PROGESS_QUESTS:<-:<[questID]>
    - narrate format:success_format "Quest <[questID]> reset for <[target].name>."
    - stop

    resetall:
    - if <context.args.size> > 1:
        - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
            - narrate format:error_format "You don't have the permission to use this command on another player."
            - stop
        - define target <server.match_offline_player[<context.args.get[2]>]||null>
        - if <[target]> == null:
            - narrate format:error_format "Player <context.args.get[2]> not found."
            - stop
    - else:
        - define target <player>
    - if <player.has_flag[resetAll.confirm].not||true>:
        - narrate format:error_format "ATTENTION"
        - narrate "You will reset ALL quests for <[target].name>."
        - narrate "This change can't be undone. This player will restart from zero."
        - narrate format:error_format "Tape this command again to confirm."
        - wait 1
        - flag <player> resetAll.confirm duration:2m
        - stop
    - flag <player> resetAll.confirm:!
    # clear all quests
    - flag <[target]> quests:!
    - if <[target]> == <player>:
        - narrate format:success_format "Quests reset."
    - else:
        - narrate format:success_format "All quests of <[target].name> are reset."
    - stop

    answer:
    - if <player.has_flag[quests.answer.spam]> && <player.is_op.not> && <player.has_permission[denizen.quests.admin].not>:
        - announce to_console "[Quest Answer] <player.name> spam !"
        - narrate format:warning_format "Thanks to not spam."
        - stop
    - flag player quests.answer.spam:true duration:6s
    # An choice answer. Format: /quest answer <script(#path)> <npc> (args).
    # Ex: /quest answer LuciusBlacksmithChoice <n@485> menacer
    - if <context.args.size> < 3:
        - announce to_console "<red>[ERROR] <&r>[Quest Answer] Not enough args. Usage: /quest <&lt>answer<&gt> <&lt>script#(path)<&gt> <&lt>npc<&gt> (args)."
        - narrate format:error_format "An error occurs. Please contact admin for support."
        - stop
    - define npc <context.args.get[3]||none>
    - if <[npc]> != none && <[npc].is_npc.not>:
        - announce to_console "<red>[ERROR] <&r>[Quest Answer] <[npc]> must be an valid NPC."
        - narrate format:error_format "An error occurs. Please contact admin for support.."
        - stop
    # ensure player is near (10 blocks) the npc
    - if <[npc]> != none && <player.location.find.npcs.within[10].contains[<[npc]>].not>:
        - narrate format:narration_format "You are to far from <green><[npc].name||<red>inconnu><gray>."
        - stop
    - define anwserScript "<context.args.get[2].split[#].get[1]>"
    - define path "<context.args.get[2].split[#].get[2]||script>"
    - if <server.list_scripts.contains[s@<[anwserScript]>]>:
        # Call the answer script whit player and npc attached. Use <[raw_context]> to get context list args
        - if <[npc]> != none:
            # with NPC linked
            - run <[anwserScript]> path:<[path]> instantly  context:<context.args.get[4].to[<context.args.size>]||none> player:<player> npc:<[npc]>
        - else:
            # without NPC
            - run <[anwserScript]> path:<[path]> instantly  context:<context.args.get[4].to[<context.args.size>]||none> player:<player>
    - else:
        - announce to_console "<red>[ERROR] <&r>[Quest Answer] Script <[anwserScript]> not found !"
    - stop

    reload:
    - if <player.is_player||false>:
        - narrate format:warning_format "Reloading quests ..."
    - if <player.is_player||false> && <player.has_permission[denizen.quests.admin].not> && <player.is_op.not>:
        - narrate format:error_format "You don't have the permission to use this command."
        - stop
    # Add quests to server quest list
    - define questScripts <server.list_scripts.filter[ends_with[Quest]]>
    - flag server QUESTS.AVAILABLE_QUESTS:!
    - foreach <[questScripts]> as:questID:
        - define dataScript <[questID]>Data
        # Script can be on form "script#path" or "script"
        - define script <[dataScript].as_script||none>
        - if <[script]> == none:
            - announce to_console "<red>[Quester] <[questID]> has not quest data script."
            - foreach next
        - flag server QUESTS.AVAILABLE_QUESTS:->:<[questID].substring[3]>
    - if <player.is_player||false>:
        - narrate format:warning_format "<proc[msgcommand].context[<gold><[questScripts].size> quests rechargées.|quests list|<&a>Cliquer pour lister les quests]>"
    - stop

    npc:
    - define npcSel <player.selected_npc||null>
    - execute as_op "npc sel"
    - wait 1t
    - define npcSel <player.selected_npc||null>
    - if <[npcSel]> == null:
        - narrate format:error_format "No NPC selected."
        - stop
    - narrate "<blue>--- <white><[npcSel].name||<[npcSel]>> <blue>---"
    - if <[npcSel].script> != s@quester:
        - narrate "<gold>Quests: <red>this NPC is not a Quester. <proc[msgcommand].context[<white><&gt> change it <&lt>|npc assignment --set quester|<&a>Click here to add Quester assignment]>"
    - else:
        - define questsClick <[npcSel].flag[QUESTS.SCRIPTS.CLICK].as_list.deduplicate||li@>
        - define questsProxi <[npcSel].flag[QUESTS.SCRIPTS.PROXIMITY].as_list.deduplicate||li@>
        - define questsDeath <[npcSel].flag[QUESTS.SCRIPTS.DEATH].as_list.deduplicate||li@>
        - define questsScriptCount "<[questsClick].size.add[<[questsProxi].size.add[<[questsDeath].size>]>]>"
        - narrate "<proc[msgcommand].context[<gold>Quests count|quests scripts|<&a>Click to list NPC quests]><gold>: <gray><[questsScriptCount]>"

    - narrate "<gold>Sentinel: <gray><[npcSel].has_trait[sentinel]||false>"
    - narrate "<gold>Loyalty (reputation): "
    - foreach <[npcSel].flag[reputations.affiliations].as_list||li@Aucune>:
      - narrate "- <gray><[value]>"
    - stop

    scripts:
    - define npcSel <player.selected_npc||null>
    - define triggerAvailables li@CLICK|PROXIMITY|DEATH
    - if <[npcSel]> == null:
        - execute as_op "npc sel"
        - wait 1t
        - define npcSel <player.selected_npc||null>

    - if <context.args.size> == 1:
        - narrate "<blue>--- <white>Scripts of <[npcSel].name> <blue>---"
        # show scripts
        - define scripts "<[npcSel].flag[QUESTS.SCRIPTS.CLICK].as_list||li@<red>Aucun Script>"
        - narrate "<gold>Scripts CLICK:"
        - foreach <[scripts]>:
            - narrate "<dark_gray>- <gray><[value]>"

        - define scripts "<[npcSel].flag[QUESTS.SCRIPTS.DEATH].as_list||li@<red>Aucun Script>"
        - narrate "<gold>Scripts DEATH:"
        - foreach <[scripts]>:
            - narrate "<dark_gray>- <gray><[value]>"

        - define scripts "<[npcSel].flag[QUESTS.SCRIPTS.PROXIMITY].as_list||li@<red>Aucun Script>"
        - narrate "<gold>Scripts PROXIMITY:"
        - foreach <[scripts]>:
            - narrate "<dark_gray>- <gray><[value]>"

    #==============================
    #     ADD SCRIPT
    #==============================
    - else if <context.args.get[2]> == "add":
        - if <context.args.size> < 3:
            - narrate format:error_format "You must enter the script to add. Ex: <white>/npcq scripts add <&lt>MyGreatQuest<&gt>"
            - stop

        - define questScript <context.args.get[3]>
        - define trigger <context.args.get[4]||CLICK>
        - if <[triggerAvailables].contains[<[trigger]>].not:
            - narrate format:error_format "The trigger <white><[trigger]><red> is not valid. Available triggers: <white><[triggerAvailables].formatted>"
            - stop

        - if <npc.script> != s@quester:
            - execute as_player "npc assignment --set quester"
            - narrate "<gold>Quests: <white>this NPC is now a Quester."

        # Script can be on form "script#path" or "script"
        - define scriptName "s@<[questScript].split[#].get[1]>"
        - define script <[scriptName].as_script||none>
        - define path "<[questScript].split[#].get[2]||script>"
        - if <[script].yaml_key[<[path]>]||none> == none:
            - announce to_console "<red>[Quester] <[scriptName]> with the path <[path]> is not a valid denizen script. Npc: <npc.name> [<npc.id>]"
            - if <player.is_op>:
                - narrate format:error_format "<[scriptName]> with the path <[path]> is not a valid denizen script."
            - stop

        # add script to npc script list
        - if <npc.flag[QUESTS.SCRIPTS.<[trigger]>].contains[<[questScript]>].not||true>:
            - flag npc QUESTS.SCRIPTS.<[trigger]>:->:<[questScript]>
            - narrate format:success_format "Script <[trigger]> <white><[questScript]><green> added !"
            # ensure NPC has the trigger enabled
            - if <[trigger]> == CLICK && <npc.has_trigger[click].not>:
                - trigger name:click state:true
            - if <[trigger]> == PROXIMITY && <npc.has_trigger[proximity].not>:
                - trigger name:proximity state:true cooldown:5 radius:5
            - else if <[trigger]> == DEATH && <npc.has_trigger[death].not>:
                - trigger name:death state:true
        - else:
            - narrate format:warning_format "<npc.name> already have script <[trigger]> <white><[questScript]>"

    #==============================
    #     DELETE SCRIPT
    #==============================
    - else if <context.args.get[2]> == "remove":
        - if <context.args.size> < 3:
            - narrate format:error_format "You must enter the script name. Ex: <white>/npcq scripts remove <&lt>WeirdQuest<&gt>"
            - stop

        - define questScript <context.args.get[3]>
        - define trigger <context.args.get[4]||CLICK>
        # remove script to npc script list
        - if <npc.flag[QUESTS.SCRIPTS.<[trigger]>].contains[<[questScript]>].not>:
            - narrate format:warning_format "<npc.name> doesn't have the script <[trigger]> <white><[questScript]>"
        - else:
            - flag npc QUESTS.SCRIPTS.<[trigger]>:<-:<[questScript]>
            - narrate format:success_format "Script <[trigger]> <white><[questScript]><green> removed !"

    - else if <context.args.get[2]> == "set":
        - if <context.args.size> < 3:
            - narrate format:error_format "You must precise at least one script to set. Ex: <white>/npcq scripts set <&lt>GreatQuest|OptionalQuest<&gt>"
            - stop

        - define trigger <context.args.get[4]||CLICK>
        - if <[triggerAvailables].contains[<[trigger]>].not:
            - narrate format:error_format "The trigger <white><[trigger]><red> is not valid. Available triggers: <white><[triggerAvailables].formatted>"
            - stop

        - foreach "li@<context.args.get[3]>":
            - define questScript <[value]>
            # add script to npc script list
            - flag npc QUESTS.SCRIPTS.<[trigger]>:->:<[questScript]>
            - narrate "<gold>Script <[trigger]> <white><[questScript]><gold> added !"
    - stop