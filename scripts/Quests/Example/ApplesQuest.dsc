########################################################################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                     Collect quest Example                                                          |#
#--------------------------------------------------------------------------------------------------------------------------------------#
########################################################################################################################################

#-----------------------------------------------------------------------------------------------------------------#
# COMMANDS:                                                                                                       #
#     - /quests scripts add ApplesQuest#choice : Set NPC script quest                                             #
#     - /quests scripts add ApplesQuest#proxy PROXIMITY : NPC talk when player is near                            #
#                                                                                                                 #
# DESCRIPTION :                                                                                                   #
#   This is a simple collect quest with only one objective.                                                       #
#                                                                                                                 #
#-----------------------------------------------------------------------------------------------------------------#

ApplesWorldEvents:
    type: world
    debug: false
    events:
        # gather some apples ...
        on player picks up apple:
        - if <player.flag[QUESTS.IN_PROGESS_QUESTS].contains[APPLESQUEST].not||true>:
            - stop
        - wait 1
        - narrate format:quest_format "Apples collected: <player.inventory.quantity[i@apple]>/36"

# Quest Data Script
# Always name it "<script ID>QuestData"
ApplesQuestData:
    type: yaml data
    debug: false

    #----------------------------
    #         Display
    #----------------------------

    # Icon in the quest journal
    icon: i@apple

    # title
    title: A friendly fruit

    # Description
    description: Collect some apples

    # Set true to display the quest in the quest journal
    # Set false to display quest as LOCKED (hide title) if player hasn't required conditions
    hide_ifLocked: false

    hide_description: true

    #----------------------------
    #         Conditions
    #----------------------------

    # custom flag (has_flag)
    unlock_flag: ""

    # is the quest repeatable ?
    repeatable: true

    # Cooldown only if repeatable.
    cooldown: 1d

    # Quest only available during this time interval.
    # Must be between 0-24000 (0 -> 6H00 and 14000 -> 20H00).
    # Format: "start-end". Ex: "0-14000"
    available_time: "0-14000"

    #----------------------------
    #         Objectives
    #----------------------------

    # objectives de la quête
    # Doit être une suite de nombre commençant par 1
    objectives:
        1:
            name: Collect apples
            description: Collect 36 apples
            hide: false
            lockDisplay: false
            icon: i@apple

    #----------------------------
    #         Rewards
    #----------------------------

    # Experience win/lose in point (not level)
    experience: 3
    money: 10

# Script ID MUST end with "Quest"
# This script MUST have a data script named "<Script ID>Data"
ApplesQuest:
    type: task
    debug: false
    # Choix qui sont disponibles auprès d'un PNJ
    choice:
        # choice display if player hasn't start the quest
        - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[ApplesQuest].not||true>:
            - narrate format:choice_format "<proc[msgcommand].context[<aqua>Have you some work for me please ?|quest answer ApplesQuest#start <npc>|Click to choose this option]>"
            - stop
        # otherwise, run the objective number script
        - define objectiveNumber "<player.flag[QUESTS.ApplesQuest.CURRENT_OBJECTIVE]||0>"
        - narrate format:choice_format "<proc[msgcommand].context[<aqua>About your apples...|quest answer ApplesQuest#objective_<[objectiveNumber]> <npc>|Click to choose this option]>"

    # When player is near the NPC
    proxy:
        - define activeQuests <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list||li@>
        - if <[activeQuests].contains[ApplesQuest].not||false> && <proc[QuestIsAvailable].context[ApplesQuest|<player>]||false>:
            - narrate format:npc_talk_format "Hey, would you eat very good apples ?"

    # Player havn"t the quest, we display the confirmation
    start:
        - narrate format:npc_talk_format "Maybe. Would you help me to collect some apples ?"
        - wait 3
        - narrate format:player_talk_format "And, what the reward ?"
        - wait 4
        - narrate format:npc_talk_format "Hum... some cash."
        - wait 2
        # Ask for accept quest. Response is catch in ApplesQuest#acceptation script
        - run instantly s@QuestAPI p:acceptation def:ApplesQuest#acceptation  player:<player> npc:<npc>
        - stop

    # Player response to accept quest confirmation
    # Can be "accepted" or "deny"
    acceptation:
        - define answer <[1]>
        - if <[answer]> == "accepted":
            - narrate format:player_talk_format "Oki doki. Let's go."
            # start quest
            - run instantly s@QuestAPI p:start def:ApplesQuest  player:<player>
            - stop
        - else:
            - narrate format:player_talk_format "Another time maybe."
            - wait 3
            - narrate format:npc_talk_format "Ok. And don't forget, to eat apple !"

    # objective 1
    objective_1:
        - narrate format:npc_talk_format "Do you have my apples ?"
        - wait 3
        - if <player.inventory.contains[i@apple].quantity[36].not>:
            - narrate format:npc_talk_format "What ? You don't find any apple ?"
            - wait 3
            - narrate format:quest_format "Collect 36 apples. (<player.inventory.quantity[i@apple]>/36)"
            - stop
        - ^take item:i@apple quantity:36 from:<player.inventory>
        - narrate format:player_talk_format "Take."
        - wait 1
        - narrate format:narration_format "You show your bag to <npc.name>. Full of apples."
        - ^playsound <player.location> sound:ENTITY_ARMORSTAND_PLACE
        - narrate format:npc_talk_format "Thanks <player.name> !"
        - wait 3
        # end of the quest !
        - run instantly s@QuestAPI p:end def:ApplesQuest  player:<player>
        - stop
