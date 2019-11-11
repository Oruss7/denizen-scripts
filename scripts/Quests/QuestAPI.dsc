########################################################################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                          Quests API                                                                |#
#--------------------------------------------------------------------------------------------------------------------------------------#
########################################################################################################################################

#-----------------------------------------------------------------------------------------------------------------#
# DESCRIPTION:                                                                                                    #
#     Quest Manager                                                                                               #
#       - multi-quest support                                                                                     #
#       - quest availability conditions:                                                                          #
#           - quests done                                                                                         #
#           - time (in-game)                                                                                      #
#           - repeatable / repeat cooldown                                                                        #
#           - a flag                                                                                              #
#      Work with OBJECTIVES. Each objectives progress are saved and displayed in quest journal                    #
#                                                                                                                 #
# COMMANDS:                                                                                                       #
#     /quest                                                                                                      #
#     /quest answer                                                                                               #
#                                                                                                                 #
# PERMISSIONS:                                                                                                    #
#   - denizen.quests.admin: admin for quests                                                                      #
#-----------------------------------------------------------------------------------------------------------------#

Quest_Config:
    type: yaml data

    # Max quest active. Disable quest accept if player reach it.
    maximum_actives: 6

    # the default cooldown before repeat a quest
    # if none are set to quest data script
    defaultCooldown: 1m

QuestJournal:
    type: item
    material: i@book
    debug: false
    display name: <yellow>Quest Journal
    lore:
        - <gray>My precious quest book
        - <yellow>Quest item
        - <green><italic>Bound to you
    # if true, player cant drop it
    bind: true

# Call this proc: <proc[EntityCanSeeOtherEntity].context[<npc>|<player>]>
# Return true if the entity can see the other entity
EntityCanSeeOtherEntity:
    type: procedure
    debug: false
    definitions: entity|target
    script:
    # is_sneaking only supported by NPCs and players. Other entities are true by default.
    # Player is visible if he have an item in hand
    - if <[entity].can_see[<[target]>].not> || ( <[target].has_effect[invisibility]||false> && <[target].item_in_hand||i@air> == i@air && <[target].is_sneaking||true> ):
        - determine false
    - determine true
    

# Assignment Script for Quester NPCs
Quester:
    type: assignment
    debug: false
    actions:
        on assignment:
            - inject locally init instantly
        on click:
            - run instantly Quester p:handle def:click player:<player> npc:<npc>
        on enter proximity:
            - run instantly Quester p:handle def:proximity player:<player> npc:<npc>
        on death:
            - run instantly Quester p:handle def:death player:<player> npc:<npc>

    # handle trigger on NPC
    handle:
    - define trigger <[1]>
    # le script du NPC peut ne pas exister
    - define npcScript "<npc.name.replace_text[ ].with[_].as_script||none>"

    - if <[trigger]> == "click" && <proc[EntityCanSeeOtherEntity].context[<npc>|<player>].not>:
        # le NPC n'as pas vu le joueur
        - random:
            - narrate format:npc_talk_format "Qui est là?"
            - narrate format:npc_talk_format "Il y a quelqu'un ?"
            - narrate format:npc_talk_format "Quelque chose a bougé non ?!"
        - stop

    # NPC customs Scripts
    - if <[npcScript]> != none && <[trigger]> == "click":
        - if <[npcScript].yaml_key[welcome]||none> != none:
            - inject instantly <[npcScript]> path:welcome player:<player> npc:<npc>
        - wait 1t
        - if <[npcScript].yaml_key[presentation_choice]||none> != none:
            - inject instantly <[npcScript]> path:presentation_choice player:<player> npc:<npc>

    # NPC quests
    - define triggerScript <npc.flag[QUESTS.SCRIPTS.<[trigger]>].as_list.deduplicate||li@>
    # List player's options. Depends on the availability of quests.
    - foreach <[triggerScript]>:
        # Script can be on form "script:path" or "script"
        - define scriptName "s@<[value].split[#].get[1]>"
        - define script <[scriptName].as_script||none>
        - define path "<[value].split[#].get[2]||script>"
        - if <[script].yaml_key[<[path]>]||none> == none:
            - announce to_console "<red>[Quester] <[scriptName]> with the path <[path]> is not a valid denizen script. Npc: <npc.name> [<npc.id>]"
            - if <player.is_op>:
                - narrate format:error_format "<[scriptName]> with the path <[path]> is not a valid denizen script."
            - foreach next

        - if <[trigger]> == DEATH || "<proc[QuestIsAvailable].context[<[script].name>|<player>]>" == available || <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[<[script].name>]||false>:
            - if <[trigger]> == PROXIMITY:
                - playeffect effect:happy_villager at:<npc.location.add[0,2.5,0]> quantity:10 data:0 offset:0.0 targets:<player>

            # available
            - run instantly <[script]> p:<[path]> def:<[triggerScript]> player:<player> npc:<npc>

    - determine passively cancelled

QuestAPI:
    type: world
    debug: false
    events:
        on reload scripts:
        # reload quests
        - inject QuestCommand path:reload

        # Handle player inventory clicks
        # Possible Inventory Notable Name:
        # - Quest_MainMenu_<player.name>
        # - Quest_View_<Available/Current/Completed>_<player.name>
        # - Quest_Objectives_<player.name>
        on player clicks in inventory:
        - if <context.inventory.notable_name.split[_].get[1]||null> != quest:
            - stop
        - if <context.slot_type> == OUTSIDE || <context.item> == i@air:
            - stop
        - determine passively cancelled
        - inject locally p:inventoryClick_<context.inventory.notable_name.split[_].get[2]>

        on player closes inventory:
        - if <context.inventory.notable_name.split[_].get[1]||null> != quest stop
        - note remove as:<context.inventory.notable_name>

        on player right clicks with QuestJournal:
        - run instantly s@QuestAPI displayMainMenu

    # Display accept/deny choice for quest start
    # define questAcceptationScript (s@)
    # player must be linked
    acceptation:
    - define questAcceptationScriptFull <[1]>
    - define questScript <[questAcceptationScriptFull].split[#].get[1]>

    # check if player already doing this quest
    - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[<[questScript]>]||false>:
        - narrate format:error_format "You already doing this quest."
        - stop

    # if script is a valid quest script, we check if player have the maximum actives quests
    - if <server.flag[QUESTS.AVAILABLE_QUESTS].as_list.contains[<[questScript]>]||false> && <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.deduplicate.size||0> >= <s@Quest_Config.yaml_key[maximum_actives]>:
        - narrate format:error_format "You must have only <s@Quest_Config.yaml_key[maximum_actives]> quests actives."
        - stop

    - narrate "<gold>---------------------------------------------"
    - narrate "<&sp.pad_left[24]><yellow> Accept quest ?"
    - narrate "<&sp.pad_left[26]><proc[msgCommand].context[<green>► Yes|quest answer <[questAcceptationScriptFull]> <npc> accepted|Accept this quest]> <gold>/ <proc[msgCommand].context[<red>► No|quest answer <[questAcceptationScriptFull]> <npc> deny|Deny this quest]>"
    - narrate "<gold>---------------------------------------------"
    - playsound <player> sound:BLOCK_METAL_PRESSUREPLATE_CLICK_OFF

    # define questID (string)
    start:
    - define questID <[1]>
    - define activeQuests <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list||li@>
    - if <[activeQuests].contains[<[questID]>]>:
        - announce to_console "<player> is already doing <[questID]> quest."
    - else:
        - flag <player> QUESTS.IN_PROGESS_QUESTS:->:<[questID]>
    - define questDataScript <el@val[<[questID]>Data].as_script||null>

    - if <[questDataScript]> == null:
        - announce to_console "<red>[ERROR] <&r><[questID]>Data is not a valid script."
        - stop

    - if <[questDataScript].yaml_key[hide].not||true>:
        - define questTitle "<[questDataScript].yaml_key[title]||>"
        - title "title:<yellow>New Quest" "subtitle:<white><[questTitle]||>"

    - wait 2
    - flag <player> QUESTS.<[questID]>.CURRENT_OBJECTIVE:0
    - flag server quests.stats.<[questID]>.start:++
    - run instantly s@QuestAPI p:updateObjective def:<[questID]>|1  player:<player>

    # define questID (string)
    end:
    - define questID <[1]>
    - define questDataScript <el@val[<[questID]>Data].as_script||null>
    - if <[questDataScript]> == null:
        - announce to_console "<red>[ERROR] <&r><[questID]>Data is not a valid script."
        - stop

    # display to player
    - if <[questDataScript].yaml_key[hide].not||true>:
        - define questTitle "<[questDataScript].yaml_key[title]||>"
        - title "title:<yellow>Quest completed" "subtitle:<white><[questTitle]>"
        - ^playsound <player> sound:ENTITY_PLAYER_LEVELUP

    # quest flags
    - flag <player> QUESTS.<[questID]>.CURRENT_OBJECTIVE:!
    - flag <player> QUESTS.<[questID]>.OBJECTIVES:!
    - if <player.flag[QUESTS.COMPLETED_QUESTS].as_list||li@> !contains <[questID]>:
        - flag <player> QUESTS.COMPLETED_QUESTS:->:<[questID]>
        - flag server quests.stats.<[questID]>.end:++
    - flag <player> QUESTS.<[questID]>.COMPLETED:++
    - flag <player> QUESTS.IN_PROGESS_QUESTS:<-:<[questID]>

    # repeat & cooldown
    - if <[questDataScript].yaml_key[repeatable]||false>:
        - define defaultCooldown <s@Quest_Config.yaml_key[defaultCooldown]>
        - define cooldown <[questDataScript].yaml_key[cooldown]||<[defaultDuration]>>
        - if <[cooldown]> == '':
            - announce to_console "<red>[ERROR] <&r><[questID]> cooldown is not a valid cooldown."
            # force to defaultCooldown
            - define cooldown <[defaultDuration]>
        - flag <player> QUESTS.<[questID]>.COOLDOWN:true duration:<[cooldown]>

    # rewards
    - define exp <[questDataScript].yaml_key[experience]||0>
    - define money <[questDataScript].yaml_key[money]||0>

    - experience give <[exp]>
    - money give quantity:<[money]>

    - if <[questDataScript].yaml_key[hide].not||true>:
        - narrate "<gold>---------------- <yellow>Quest finished<gold> ---------------"
        - narrate "<yellow> Name: <white><[questDataScript].yaml_key[title]||<red>???>"
        - if <[exp]> < 0:
            - narrate "<yellow> Experience: <red> <[exp]>"
        - else if <[exp]> > 0:
            - narrate "<yellow> Experience: <dark_green>+ <[exp]>"
        - if <[money]> > 0:
            - narrate "<yellow> Money: <dark_green>+ <[money].as_money>"

    # define questID (string)
    # define objective (int)
    updateObjective:
    - define questID <[1]>
    - define newObjective <[2]>
    - define questDataScript <el@val[<[questID]>Data].as_script||null>
    - if <[questDataScript]> == null:
        - announce to_console "<red>[ERROR] <&r><[questID]>Data is not a valid script."
        - stop
    # ensure player have the previous objectif
    - if <player.flag[QUESTS.<[questID]>.CURRENT_OBJECTIVE].add_int[1]> != <[newObjective]>:
        - announce to_console "Player <player.name> haven't the previous objective. Cancel."
        - stop

    - define objectiveDesc "<[questDataScript].yaml_key[objectives.<[newObjective]>.description]||<red>???>"
    - if <[questDataScript].yaml_key[hide].not||true>:
        - narrate format:quest_format "<[objectiveDesc]>"
        - ^playsound <player> sound:ENTITY_EXPERIENCE_ORB_PICKUP

    - flag <player> QUESTS.<[questID]>.CURRENT_OBJECTIVE:<[newObjective]>
    - run CompassNavigatorEvents path:showLocation "def:<[questID]>|<[newObjective]>"

    inventoryClick_MainMenu:
    - if <context.raw_slot> > 9 stop

    - if <context.item.scriptname.split[_].get[2]||null> == button:
        - define GUI QuestMainMenu_<player.name>
        - inject <context.item.scriptname.as_script>
        - stop

    inventoryClick_view:
    - if <context.raw_slot> > 36 stop

    - if <context.item.nbt[questID]||null> != null:
        - if <context.item.display.strip_color> == UNAVAILABLE || <context.inventory.notable_name.split[_].get[3]> != Current:
            - stop
        - define objectif <context.item.nbt[obj]||null>
        - define questID <context.item.nbt[questID]||null>
        - if <[objectif]> != null:
            - run CompassNavigatorEvents path:showLocation "def:<[questID]>|<[objectif]>"
        - stop

    - if <context.item.scriptname.split[_].get[2]||null> == button:
        - define GUI Quest_View_<player.name>
        - define menuType Overview
        - inject <context.item.scriptname.as_script>

    inventoryClick_Objectives:
    - if <context.raw_slot> > 36 stop

    - if <context.item.scriptname.split[_].get[2]||null> == button:
        - define GUI Quest_Objectives_<player.name>
        - define menuType Objectives
        - inject <context.item.scriptname.as_script>

    displayMainMenu:
    - define questMainInventory Quest_MainMenu_<player.name>
    - note "in@generic[title=<yellow>Quest Journal;size=9]" as:<[questMainInventory]>
    - inventory add d:in@<[questMainInventory]> o:i@Quest_Button_QuestsAvailable slot:1
    - inventory add d:in@<[questMainInventory]> o:i@Quest_Button_QuestCurrent slot:2
    - inventory add d:in@<[questMainInventory]> o:i@Quest_Button_QuestsCompleted slot:3
    - inventory add d:in@<[questMainInventory]> o:i@Quest_Button_Close slot:9
    - inventory open d:in@<[questMainInventory]>

    displayView:
    # view can be: current, availables or completed
    - define view <[2]>

    - if <[view]> == "completed":
        - define questViewInventory Quest_View_Completed_<player.name>
        - note "in@generic[title=<yellow>Quests completed;size=36]" as:<[questViewInventory]>
        - define quests <player.flag[QUESTS.COMPLETED_QUESTS].as_list.deduplicate.exclude[<player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.deduplicate||li@>]||li@>
    - else if <[view]> == "current":
        - define questViewInventory Quest_View_Current_<player.name>
        - note "in@generic[title=<yellow>Quests in progress;size=36]" as:<[questViewInventory]>
        - define quests <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.deduplicate||li@>
    - else if <[view]> == "available":
        - define questViewInventory Quest_View_Available_<player.name>
        - note "in@generic[title=<yellow>Quests availables;size=36]" as:<[questViewInventory]>
        - define quests <server.flag[QUESTS.AVAILABLE_QUESTS].exclude[<player.flag[QUESTS.COMPLETED_QUESTS]||li@>].exclude[<player.flag[QUESTS.IN_PROGESS_QUESTS]||li@>].as_list.deduplicate>

    - define hr "<yellow>--------------------"
    - foreach <[quests]> as:questID:
        - define questDataScript <el@val[<[questID]>Data].as_script||null>
        # false = quest is diplayed as UNAVAILABLE otherwise it's no displayed
        - define isHidden <[questDataScript].yaml_key[hide_ifLocked]||false>
        - define isAlwaysHidden <[questDataScript].yaml_key[hide]||false>

        # never show hidden quests
        - if <[isAlwaysHidden]>:
            - define quests <[quests].exclude[<[questID]>]>

        - define isComplete false
        - if <player.flag[QUESTS.<[questID]>.CURRENT_OBJECTIVE].strip_color||null> == "COMPLETED":
            - define isComplete true

    - define page <[1]||1>
    - define countPages <[quests].size.div[27].round_up>
    - if <[page]> > <[countPages]>:
        - define page <[countPages]>
    
    - define highNumber <[page].mul[27]>
    - define lowNumber <[highNumber].sub[26]>

    - foreach <[quests].get[<[lowNumber]>].to[<[highNumber]>]||li@> as:questID:
        - define slot <[loop_index]>
        - define questDataScript "<el@val[<[questID]>Data].as_script||null>"
        - define isHidden <[questDataScript].yaml_key[hide_ifLocked]||false>
        # quests UNAVAILABLEs
        - if <[view]> == "available" && <proc[QuestIsAvailable].context[<[questID]>|<player>].not>:
            - adjust <[questDataScript].yaml_key[icon].simple||i@book> display_name:<red>UNAVAILABLE save:lockItem
            - adjust <entry[lockItem].result> flags:HIDE_ATTRIBUTES|HIDE_DESTROYS|HIDE_ENCHANTS|HIDE_PLACED_ON|HIDE_POTION_EFFECTS|HIDE_UNBREAKABLE save:lockItemClean
            - inventory add "d:in@<[questViewInventory]>" o:<entry[lockItemClean].result> slot:<[slot]>
            - foreach next
        # quests cachées
        - if <[view]> == "available" && <[isHidden]>:
            - adjust <[questDataScript].yaml_key[icon].simple||i@book> display_name:<red>HIDDEN save:lockItem
            - adjust <entry[lockItem].result> flags:HIDE_ATTRIBUTES|HIDE_DESTROYS|HIDE_ENCHANTS|HIDE_PLACED_ON|HIDE_POTION_EFFECTS|HIDE_UNBREAKABLE save:lockItemClean
            - inventory add "d:in@<[questViewInventory]>" o:<entry[lockItemClean].result> slot:<[slot]>
            - foreach next

        - define titleString "<gold><[questDataScript].yaml_key[title]||<red>???>"
        - define titleLines "<proc[lineWrap].context[<[titleString]>|20]>"
        - define title "<gold><[titleLines].get[1]||null>"
        - define titleLong li@
        - foreach <[titleLines].remove[1]>:
            - define titleLong "<[titleLong].include[<[value]>]>"

        - define progress <player.flag[QUESTS.<[questID]>.CURRENT_OBJECTIVE]||null>
        - if <[progress]> != null && <[progress]> != 'COMPLETED':
            - define objString "<[questDataScript].yaml_key[objectives.<[progress]>.description]||li@>"
            - define objLines "<proc[lineWrap].context[<[objString]>|20]>"
            - define obj li@
            - foreach <[objLines]>:
                - define obj "<[obj].include[<white><&sp.pad_left[2]><[value]>]>"
            - define lore "<[titleLong].separated_by[|]>|<[hr]>|<gold> |<[obj].separated_by[|]>"
        - else:
            - define lore "<[titleLong].separated_by[|]>|<[hr]>|<white> "
            # time completed
            - define timesCompleted <player.flag[QUESTS.<[questID]>.COMPLETED]||0>
            - if <[timesCompleted]> > 0:
                - define lore "<[lore]>|<gold>Finish <&co> <white><[timesCompleted]> times"
            # if quest is available (repeated quests)
            - define repeatable "<[questDataScript].yaml_key[repeatable]||false>"
            - if <[repeatable]> && <player.has_flag[quests.<[questID]>.cooldown].not>:
                - define lore "<[lore]>|<green><&sp.pad_left[10]>Available"
        

        - define item "<[questDataScript].yaml_key[icon].as_item.simple||barrier>[display_name=<[title]>;lore=<[lore]>;flags=HIDE_ATTRIBUTES|HIDE_DESTROYS|HIDE_ENCHANTS|HIDE_PLACED_ON|HIDE_POTION_EFFECTS|HIDE_UNBREAKABLE;nbt=li@questID/<[questID]>|obj/<[progress]||0>]"
        - inventory add d:in@<[questViewInventory]> o:<[item]> slot:<[slot]>
    
    - if <[countPages]> > 1:
        - if <[page]> != 1:
            - inventory add d:in@<[questViewInventory]> o:i@Quest_Button_PreviousPage[nbt=page/<[page].sub[1]>] slot:34
        - if <[page]> < <[countPages]>:
            - inventory add d:in@<[questViewInventory]> o:i@Quest_Button_NextPage[nbt=page/<[page].add[1]>] slot:35
    - inventory add d:in@<[questViewInventory]> o:i@Quest_Button_QuestMenu slot:35
    - inventory add d:in@<[questViewInventory]> o:i@Quest_Button_Close slot:36
    - inventory open d:in@<[questViewInventory]>

    displayObjectives:
    - define questID <[1]>
    - define questObjectivesInventory Quest_Objectives_<player.name>
    - note in@generic[title=<yellow>Objectifs;size=18] as:<[questObjectivesInventory]>
    - define hr <yellow>--------------------

    - define questDataScript <el@val[<[questID]>Data].as_script||null>
    - define progress <player.flag[QUESTS.<[questID]>.CURRENT_OBJECTIVE]||0>
    - define objectives "<[questDataScript].list_keys[objectives]||li@>"
    - if <[progress]> == COMPLETED:
        - define progress <[objectives].size>
    
    - foreach <[objectives]>:
        - define obj <[value]>
        - define isHidden <[questDataScript].yaml_key[objectives.<[obj]>.hide]||false>
        - if <[isHidden]> && <[progress].is[MATCHES].to[NUMBER]>:
            - if <[obj]> > <[progress]>:
                - define objectives "<[objectives].exclude[<[obj]>]>"
            
    - define page <[page]||1>
    - define countPages <[objectives].size.div[9].round_up>
    - if <[page]> > <[countPages]>:
        - define page <[countPages]>
    
    - define highNumber <[page].mul[9]>
    - define lowNumber <[highNumber].sub[8]>

    - foreach <[objectives].alphanumeric.get[<[lowNumber]>].to[<[highNumber]>]||li@>:
        - define slot <[loop_index]>
        - define obj <[value]>
        - define isLocked <[questDataScript].yaml_key[objectives.<[obj]>.lockDisplay]||false>
        - define icon <[questDataScript].yaml_key[objectives.<[obj]>.icon]||i@paper>
        - if <[isLocked]> && <[progress]> < <[obj]>:
            - inventory add d:in@<[questObjectivesInventory]> o:<[icon]>[display_name=<red>UNAVAILABLE;flags=HIDE_ATTRIBUTES|HIDE_DESTROYS|HIDE_ENCHANTS|HIDE_PLACED_ON|HIDE_POTION_EFFECTS|HIDE_UNBREAKABLE] slot:<[slot]>
            - foreach next
        
        - define nameString "<gold><[questDataScript].yaml_key[objectives.<[obj]>.name]||li@>"
        - define nameLines "<proc[lineWrap].context[<[nameString]>|20]>"
        - define name "<[nameLines].get[1]>"
        - define nameLong li@
        - foreach <[nameLines].remove[1]>:
            - define nameLong "<[nameLong].include[<gold><[value]>]>"
        
        - define descString "<[questDataScript].yaml_key[objectives.<[obj]>.description]||li@>"
        - define descLines "<proc[lineWrap].context[<[descString]>|20]>"
        - define desc li@
        - foreach <[descLines]>:
            - define desc "<[desc].include[<gray><&sp.pad_left[2]><[value]>]>"
        
        - define lore "<[nameLong].separated_by[|]>|<[hr]>|<white>|<[desc].separated_by[|]>"
        - inventory add d:in@<[questObjectivesInventory]> o:<[icon]>[display_name=<[name]>;lore=<[lore]>;flags=HIDE_ATTRIBUTES|HIDE_DESTROYS|HIDE_ENCHANTS|HIDE_PLACED_ON|HIDE_POTION_EFFECTS|HIDE_UNBREAKABLE] slot:<[slot]>
    
    - if <[countPages]> > 1:
        - if <[page]> != 1:
            - inventory add d:in@<[questObjectivesInventory]> o:i@Quest_Button_PreviousPage[nbt=page/<[page].sub[1]>] slot:14
        
        - if <[page]> < <[countPages]>:
            - inventory add d:in@<[questObjectivesInventory]> o:i@Quest_Button_NextPage[nbt=page/<[page].add[1]>] slot:15

    - inventory add d:in@<[questObjectivesInventory]> o:i@Quest_Button_QuestCurrent slot:16
    - inventory add d:in@<[questObjectivesInventory]> o:i@Quest_Button_QuestMenu slot:17
    - inventory add d:in@<[questObjectivesInventory]> o:i@Quest_Button_Close slot:18
    - inventory open d:in@<[questObjectivesInventory]>

Quest_Button_QuestsAvailable:
    type: item
    material: i@book
    debug: false
    display name: <white>Quests available
    lore:
    - "<yellow>---------------"
    script:
    - inventory close
    - note remove as:<[GUI]>
    - run instantly s@QuestAPI p:displayView def:1|available

Quest_Button_QuestCurrent:
    type: item
    material: i@book[flags=li@HIDE_ENCHANTS]
    debug: false
    display name: <white>Quests in progress
    lore:
    - "<yellow>---------------"
    enchantments:
    - DAMAGE_ALL
    script:
    - inventory close
    - note remove as:<[GUI]>
    - run instantly s@QuestAPI p:displayView def:1|current

Quest_Button_QuestsCompleted:
    type: item
    material: i@bookshelf
    debug: false
    display name: <white>Quests completed
    lore:
    - "<yellow>---------------"
    script:
    - inventory close
    - note remove as:<[GUI]>
    - run instantly s@QuestAPI p:displayView def:1|completed

Quest_Button_QuestMenu:
    type: item
    material: i@paper
    debug: false
    display name: <white>Quests Menu
    script:
    - inventory close
    - note remove as:<[GUI]>
    - run instantly s@QuestAPI p:displayMainMenu def:1

Quest_Button_Close:
    type: item
    material: i@barrier
    debug: false
    display name: <white>Close
    script:
    - inventory close
    - note remove as:<[GUI]>

Quest_Button_NextPage:
    type: item
    material: i@player_head[skull_skin=6754c1a4-746b-45ad-ac39-5763b8e20c3a|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNmNiMGNiZTFjOWQ3YTFiMmQ2MWRmNDVjNmQyOWE3NzRjYzU2NGUyZWI5YTliNzU2ZmNmOWUxMzM0ZTM3MSJ9fX0=]
    debug: false
    display name: <white>Next Page
    script:
    - inventory close
    - note remove as:<[GUI]>
    - run instantly s@QuestAPI p:display_<[menu_type]> def:<context.item.nbt[page]>

Quest_Button_PreviousPage:
    type: item
    material: i@player_head[skull_skin=3c648c2b-e09a-4016-b470-17af45c5169a|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNmE2ZGI2YjZkMTJiYjRkYzc2ODJhOTZiM2I5MzNlN2EyOTUxZDM1NzE4NzkxOGU4YmVkYzY1ZGU5ZDc5NiJ9fX0=]
    debug: false
    display name: <white>Previous Page
    script:
    - inventory close
    - note remove as:<[GUI]>
    - run instantly s@QuestAPI p:display_<[menu_type]> def:<context.item.nbt[page]>

# Call this proc: <proc[QuestIsAvailable].context[<[questScript]|<player>>]>
# Return available if quest available, string contening error otherwise
QuestIsAvailable:
    type: procedure
    debug: true
    script:
        - define questScript <[1]>
        - define player <[2]>
        - define questDataScript <el@val[<[questScript]>Data].as_script||null>

        # quest not recognize
        - if <[questDataScript]> == null:
            - announce to_console "<red>[ERROR] QuestIsAvailable: <[questScript]>Data not found."
            - determine "questNotRecognize"

        # quest disabled by admin
        - if <server.flag[QUESTS.<[questScript]>.active].not||false>:
            - determine "questDisabledByAdmin"

        # already in progress
        - if <[player].flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[<[questScript]>]||false>:
            - determine "inProgressQuest"
        
        # unlocked flag
        - define unlockFlag "<[questDataScript].yaml_key[unlock_flag]||>"
        - if <[unlockFlag].trim.is[==].to[].not> && <[player].has_flag[<[unlockFlag]>].not>:
            # not available yet
            - determine "playerHaveNotUnlockFlag"

        - define questsCompleted <[player].flag[QUESTS.COMPLETED_QUESTS].as_list.deduplicate||li@>
        # unlocked quest completed
        - define unlockQuestsCompleted <[questDataScript].yaml_key[quests_completed].as_list||li@>
        - if <[questsCompleted].contains_all[<[unlockQuestsCompleted]>].not>:
            # not available yet
            - determine "questsCompleted"

        # time
        - define availableTime "<[questDataScript].yaml_key[available_time]||0-24000>"
        - if <[availableTime].trim.is[==].to[].not>:
            - if <[player].location.world.time> < <[availableTime].split[-].get[1]> || <[player].location.world.time> > <[availableTime].split[-].get[2]>:
                # not available yet
                - determine "availableTime"
        # repeatable & cooldown
        - define repeatable "<[questDataScript].yaml_key[repeatable]||false>"
        # not repeatable
        - if <[repeatable].not> && <[questsCompleted].contains[<[questScript]>]>:
            # not repeatable
            - determine "notRepeatable"

        # have the cooldown
        - if <[repeatable]> && <[player].has_flag[QUESTS.<[questScript]>.COOLDOWN]>:
            # not repeatable yet
            - determine "repeatableCooldown"
        
        - determine "available"
