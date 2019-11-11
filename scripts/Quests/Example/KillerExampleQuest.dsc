########################################################################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                        Kill: Example                                                               |#
#--------------------------------------------------------------------------------------------------------------------------------------#
########################################################################################################################################

#-----------------------------------------------------------------------------------------------------------------#
# COMMANDS:                                                                                                       #
#     - /quests scripts add KillerExampleQuest#choice : Set quester script                                        #
#     - /quests scripts add KillerExampleQuest#target DEATH: Set the target's death script                        #
#                                                                                                                 #
# DESCRIPTION :                                                                                                   #
#   the player must kill "The Target" NPC and get back his head to NPC quester                                    #
#-----------------------------------------------------------------------------------------------------------------#


TheTargetHead:
    debug: false
    type: item
    material: i@player_head[skull_skin=cfeab1be-cc58-4550-8349-16622e4644f9|eyJ0aW1lc3RhbXAiOjE1MzY0MTA3NDc3MTQsInByb2ZpbGVJZCI6ImNmZWFiMWJlY2M1ODQ1NTA4MzQ5MTY2MjJlNDY0NGY5IiwicHJvZmlsZU5hbWUiOiJiYWtvYmEiLCJzaWduYXR1cmVSZXF1aXJlZCI6dHJ1ZSwidGV4dHVyZXMiOnsiU0tJTiI6eyJ1cmwiOiJodHRwOi8vdGV4dHVyZXMubWluZWNyYWZ0Lm5ldC90ZXh0dXJlL2ZlNDgzNmQyODk5MmYyOWQ4ZmRlNTBhZWExNzEzMWQ0YjU0NWQ2ZGZiODFlNmIyM2UwNjI5NGVmZjM1ZjRiYzkiLCJtZXRhZGF0YSI6eyJtb2RlbCI6InNsaW0ifX19fQ]
    display name: <red>Target Head
    lore:
    - <gray>Someone would be happy
    - <gray>to known his death
    - <green>Quest Item
    - <green><italic>Linked
    # if true, player can't drop it
    bind: true

# Quest Data Script
KillerExampleQuestData:
  type: yaml data
  debug: false

  #----------------------------
  #         Display
  #----------------------------

  icon: i@iron_sword

  title: "Contract: TheTarget"

  description: Get the Target Head

  hide_ifLocked: false

  hide_description: false

  #----------------------------
  #         Conditions
  #----------------------------

  unlock_flag: ""

  # completed quests (all quests must be completed)
  quests_completed:
    - APPLESQUEST
    - FARMERQUEST

  repeatable: false
  cooldown: ""

  available_time: "0-14000"

  #----------------------------
  #         Objectives
  #----------------------------

  objectives:
    1:
      name: Get back the Target Head
      description: Kill and get back the target head
      hide: false
      lockDisplay: false

  #----------------------------
  #         Rewards
  #----------------------------

  experience: 2
  money: 50

KillerExampleQuest:
  type: task
  debug: false
  target:
  - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[KillerExampleQuest]||false> && <player.inventory.contains[TheTargetHead].not>:
    - drop TheTargetHead <context.entity.location> qty:1

  choice:
  - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[<script.name>].not||true>:
      - narrate format:choice_format "<proc[msgcommand].context[<aqua>Contract<&co> KillerExample|quest answer <script.name>#start <npc>|Cliquez pour choisir cette option]>"
      - stop
  
  - define objectiveNumber "<player.flag[QUESTS.<script.name>.CURRENT_OBJECTIVE]||0>"
  - narrate format:choice_format "<proc[msgcommand].context[<aqua>Contract<&co> KillerExample|quest answer <script.name>#objective_<[objectiveNumber]> <npc>|Cliquez pour choisir cette option]>"

  start:
  - narrate format:npc_talk_format "Are you man hunter ?"
  - wait 2
  - narrate format:npc_talk_format "Yeah, wanna help ?"
  - wait 6
  - narrate format:player_talk_format "Sure. Who is my target ?"
  - wait 4
  - narrate format:npc_talk_format "It's <green>Target<yellow>. He's somewhere near the forest."
  - wait 2
  - run instantly s@QuestAPI p:acceptation def:<script.name>#acceptation  player:<player> npc:<npc>
  - stop

  acceptation:
  - define answer <[1]>
  - define activesQuests <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list||li@>
  
  - if <[answer]> == "accepted":
      - narrate format:player_talk_format "I will back with his head."
      - run instantly s@QuestAPI p:start def:<script.name>  player:<player>
      - stop
  - else:
      - narrate format:player_talk_format "Another time. Maybe."
    
  objective_1:
  - narrate format:npc_talk_format "You're living ! What's a surprise."
  - wait 3
  - if <player.inventory.contains[i@TheTargetHead].quantity[1].not>:
      - narrate format:npc_talk_format "Not found isn't it?"
      - wait 3
      - narrate format:npc_talk_format "He's hard to find. Try looking near the forest."
      - wait 6
      - narrate format:quest_format "Get the Target Head."
      - stop
  
  - ^take item:i@TheTargetHead quantity:1 from:<player.inventory>
  - narrate format:player_talk_format "He won't be a problem anymore for anyone."
  - wait 4
  - ^playsound <player.location> sound:ENTITY_ARMORSTAND_PLACE
  - narrate format:npc_talk_format "Thanks <player.name> !"
  - wait 4
  - narrate format:npc_talk_format "Come back often for new contracts."
  - wait 7
  - narrate format:player_talk_format "My pleasure."
  - wait 3
  - run instantly s@QuestAPI p:end def:<script.name>  player:<player>
  - stop
