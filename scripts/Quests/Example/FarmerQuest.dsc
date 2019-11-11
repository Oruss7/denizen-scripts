########################################################################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                 Multi-Objective quest example                                                      |#
#--------------------------------------------------------------------------------------------------------------------------------------#
########################################################################################################################################

#-----------------------------------------------------------------------------------------------------------------#
# COMMANDS:                                                                                                       #
#     - /quests scripts add farmerquest#farmer_choice : the farmer                                                #
#     - /quests scripts add farmerquest#proxy PROXIMITY : the farmer proxy dialog                                 #
#     - /quests scripts add farmerquest#farmerWoman_choice : farmer's wife                                        #
#     - /quests scripts add farmerquest#leatherWorker_choice : leather worker script                              #
#                                                                                                                 #
# DESCRIPTION :                                                                                                   #
#     An example of multi-objective quest with 2 NPC. Please bring back the farmer cow.                           #
#                                                                                                                 #
#-----------------------------------------------------------------------------------------------------------------#

FarmerQuestCow:
  type: entity
  entity_type: e@cow
  custom_name: Ada the Ayrshire
  custom_name_visible: true
  has_ai: true
  age: adult

FarmerQuestLeash:
  type: item
  debug: false
  material: i@leash
  display name: <yellow>Ada the Ayrshire lead
  lore:
  - <green>Quest item
  - <green><italic>Linked
  # if true, player can't drop it
  bind: true


#-----------------------------------------------------------------#
#                                                                 #
#                           EVENTS                                #
#                                                                 #
#-----------------------------------------------------------------#

FarmerQuestEvents:
  type: world
  debug: false
  events:
    on reload scripts:
    # create notable cuboids if not exist
    - define cuboids <FarmerQuestData.list_keys[cuboids]||li@>
    - foreach <[cuboids]> as:cuboid:
      - note <s@FarmerQuestData.yaml_key[cuboids.<[cuboid]>]> as:<[cuboid]>

    on player enters farmerquest_cow:
    - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[farmerquest].not||true>:
      - stop
    
    - define objectiveNumber <player.flag[QUESTS.farmerquest.CURRENT_OBJECTIVE]||0>

    # objective 2 && si le joueur n'a pas déjà une vache vivante
    - if <[objectiveNumber]> == "2" && <player.flag[QUESTS.FARMERQUEST.COW].as_entity.is_living.not||true>:
      # spawn la vache dans l cuboid dès que le joueur rentre dedans et se
      # trouve au deuxième objectif de la quête
      - narrate format:narration_format "Find Ada the Ayrshire."
      - define randomLocation <cu@farmerquest_cow.spawnable_blocks.random>
      - spawn e@FarmerQuestCow <[randomLocation]> save:spawned_entities
      - define cow <entry[spawned_entities].spawned_entities.first||li@>
      - playsound <[cow].location> sound:ENTITY_COW_AMBIENT
      - flag <player> QUESTS.FARMERQUEST.COW:<[cow]>
      
    on player leashes entity:
    # not the player's cow
    - if <context.entity> != <player.flag[QUESTS.FARMERQUEST.COW]>:
      - stop

    # No reapetable quest
    - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[farmerquest].not||true>:
      - stop

    # objective 2 required
    - if <player.flag[QUESTS.farmerquest.CURRENT_OBJECTIVE]||0> != 2:
      - stop

    - run instantly s@QuestAPI p:updateObjective def:farmerquest|3  player:<player>

#-----------------------------------------------------------------#
#                                                                 #
#                           QUEST                                 #
#                                                                 #
#-----------------------------------------------------------------#

FarmerQuestData:
  type: yaml data
  debug: false

  icon: i@leash

  #----------------------------
  #         Conditions
  #----------------------------

  repeatable: false

  cooldown: ""

  hide_ifLocked: false

  hide_description: true

  title: The farmer's missing cow

  description: Bring back the farme's cow

#----------------------------------------------------------------------

  experience: 1
  reputations: li@

  objectives:
    1:
      name: Find the farme's wife
      description: Find the farme's wife
      hide: false
      lockDisplay: false

    2:
      name: Locate the cow
      description: Locate the cow (enter the farmerquest_cow cuboid)
      hide: false
      lockDisplay: false

    3:
      name: Bring back the cow
      description: Bring back the cow to the farm (in the farmerquest_enclosure cuboid)
      hide: false
      lockDisplay: false
        
    4:
      name: Talk to the leather worker
      description: Ask an armor to the leather worker
      hide: false
      lockDisplay: false

  #----------------------------------------------------------------------
  # custom cuboids for this quest
  cuboids:
    farmerquest_cow: cu@123,65,186,delerorn|164,67,214,world
    farmerquest_enclosure: cu@61,64,-3,delerorn|75,69,26,world

FarmerQuest:
  type: task
  debug: false

  #-----------------------------------------------------------------#
  # Farmer scripts                                                  #
  #-----------------------------------------------------------------#

  farmer_choice:
  - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[<script.name>].not||true>:
    - narrate format:choice_format "<proc[msgcommand].context[<aqua>Hello. How can I help you ?|quest answer <script.name>#farmer_start <npc>|Click to choose this option]>"
    - stop
  
  - define objectiveNumber "<player.flag[QUESTS.<script.name>.CURRENT_OBJECTIVE]||0>"
  - narrate format:choice_format "<proc[msgcommand].context[<aqua>About your cow|quest answer <script.name>#farmer_objective_<[objectiveNumber]> <npc>|Click to choose this option]>"

  proxy:
  - define activeQuests <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list||li@>
  - if <[activeQuests].contains[<script.name>].not||false> && <proc[QuestIsAvailable].context[<script.name>|<player>]||false>:
    - narrate format:npc_talk_format "Oh no... my deer ..."
    
    
  # quest start
  farmer_start:
  - narrate format:npc_talk_format "I lost my cow: <green>Ada the Ayrshire<yellow>."
  - wait 3
  - narrate format:npc_talk_format "Business is hard... If i don't find it, how am I going to get out ?"
  - wait 4
  - narrate format:npc_talk_format "You seems be resourceful. Help me to find it please !"
  - wait 3
  - run instantly s@QuestAPI p:acceptation def:<script.name>#farmer_acceptation  player:<player> npc:<npc>
  - stop

  # player accept or deny
  farmer_acceptation:
  - define answer <[1]>
  - if <[answer]> == "accepted":
    - narrate format:player_talk_format "Ok, but where search ?"
    - wait 5
    - narrate format:npc_talk_format "Talk to my wife, she now where my cow like to go."
    - wait 3
    - run instantly s@QuestAPI p:start def:<script.name>  player:<player>
    - stop
  - else:
    - narrate format:player_talk_format "No, I does'nt have time."
    - wait 3
    - narrate format:npc_talk_format "..."

  farmer_objective_1:
  - narrate format:npc_talk_format "Talk to my wife, she knowns something."
  - stop

  farmer_objective_2:
  - narrate format:npc_talk_format "Have you seen my cow ?"
  - stop
    
  farmer_objective_3:
  - narrate format:npc_talk_format "<green>Ada the Ayrshire<yellow>, you're back and safe !"
  - wait 3
  - narrate format:npc_talk_format "Can you bring it to the farm ?"
  - stop
    
  #-----------------------------------------------------------------#
  # Farmer's wife                                                   #
  #-----------------------------------------------------------------#

  farmerWoman_choice:
  # player doesn't have the quest
  - if <player.flag[QUESTS.IN_PROGESS_QUESTS].as_list.contains[<script.name>].not||true>:
    - narrate format:npc_talk_format "Hello, What a nice day !"
    - stop
  
  - define objectiveNumber "<player.flag[QUESTS.<script.name>.CURRENT_OBJECTIVE]||0>"
  - narrate format:choice_format "<proc[msgcommand].context[<aqua>About your cow|quest answer <script.name>#farmerWoman_objective_<[objectiveNumber]> <npc>|Click to choose this option]>"

  # objectif 1 second Farmer
  farmerWoman_objective_1:
  - narrate format:player_talk_format "Hi lady, your husband send my to find your missing cow, <green>Ada the Ayrshire<white>."
  - wait 4
  - narrate format:npc_talk_format "Hello <player.name>. thanks !"
  - wait 3
  - narrate format:npc_talk_format "She was here and an instant after, gone. The door was open and the cow missing !"
  - wait 5
  - narrate format:player_talk_format "Where can she be?"
  - wait 3
  - narrate format:npc_talk_format "She love the forest, in the nord."
  - wait 3
  - narrate format:player_talk_format "Ok, i will bring back your cow."
  - wait 3
  - narrate format:npc_talk_format "Thank. You need this."
  - wait 3
  - give i@FarmerQuestLeash
  - narrate format:narration_format "You got <i@FarmerQuestLeash.display>"
  - run instantly s@QuestAPI p:updateObjective def:<script.name>|2  player:<player>
  - stop

  farmerWoman_objective_3:
  - define entities <cu@farmerquest_enclosure.list_living_entities||li@>
  - foreach <[entities]> as:entity:
    - if <[entity]> != <player.flag[QUESTS.FARMERQUEST.COW]>:
      - foreach next
    
    - narrate format:npc_talk_format "Thank for bring back <green>Ada the Ayrshire<yellow>."
    - wait 3
    - run <s@FarmerQuestRemoveCow> def:<[entity]>
    - take leash
    - narrate format:npc_talk_format "Take this as reward."
    - wait 2
    - give item:leather qty:19
    - wait 2
    - narrate format:npc_talk_format "Talk to the leather worker. He will help you if you're say my name."
    - wait 5
    - run instantly s@QuestAPI p:updateObjective def:<script.name>|4  player:<player>
    - remove <player.flag[QUESTS.FARMERQUEST.COW].as_entity>
    - stop
  
    - narrate format:npc_talk_format "Bring back the cow in the farm (in the farmerquest_enclosure cuboid)."


  #-----------------------------------------------------------------#
  # Leather worker                                                  #
  #-----------------------------------------------------------------#
    
  leatherWorker_choice:
  - if <player.flag[QUESTS.<script.name>.CURRENT_OBJECTIVE]||0> == 4:
    - narrate format:choice_format "<proc[msgcommand].context[<aqua>Craft leather armor|quest answer <script.name>#leatherWorker_objective_4 <npc>|Click to choose this option]>"
    
    
  leatherWorker_objective_4:
  - narrate format:player_talk_format "Hi, <green>the farmer<white> send me."
  - wait 2
  - narrate format:npc_talk_format "I have a debt to him. Tell me, what can i do for you ?"
  - wait 5
  - narrate format:player_talk_format "I have some leather, and need an armor."
  - wait 6
  - narrate format:player_talk_format "But i have any tool, or skin in this domain..."
  - wait 3
  - narrate format:npc_talk_format "Give it to me, I will craft you a nice armor."
  - wait 3
  - narrate format:player_talk_format "Thank."
  - wait 3
  - if <player.inventory.contains[i@leather].quantity[19].not>:
    - narrate format:npc_talk_format "You doesn't have enought."
    - wait 3
    - narrate format:player_talk_format "My bad, i will come back."
    - wait 3
    - narrate format:quest_format "Get 19 leather and talk to the leather worker. (<player.inventory.quantity[i@leather]>/19)"
    - stop
  
  - ^take item:i@leather quantity:19 from:<player.inventory>
  - narrate format:player_talk_format "Take."
  - wait 1
  - ^playsound <player.location> sound:ENTITY_ARMORSTAND_PLACE
  - narrate format:npc_talk_format "Very well, wait a minute, it will not take long time."
  - wait 2s
  - playsound <npc.location> sound:BLOCK_ANVIL_USE
  - wait 3s
  - give Leather_Helmet
  - wait 2s
  - playsound <npc.location> sound:BLOCK_ANVIL_USE
  - wait 3s
  - give Leather_Chestplate
  - wait 1s
  - playsound <npc.location> sound:BLOCK_ANVIL_USE
  - wait 2s
  - give Leather_Leggings
  - wait 1s
  - playsound <npc.location> sound:BLOCK_ANVIL_USE
  - wait 2s
  - give Leather_Boots
  - wait 1
  - narrate format:npc_talk_format "And voila."
  - wait 2
  - narrate format:player_talk_format "Thanks."
  - wait 2
  - narrate format:npc_talk_format "It's nothing, friend's friends are my friends too."
  
  # quest end !
  - run instantly s@QuestAPI p:end def:<script.name>  player:<player>
