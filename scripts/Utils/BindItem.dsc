########################################################################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                          Bind Item                                                                 |#
#--------------------------------------------------------------------------------------------------------------------------------------#
########################################################################################################################################

#-----------------------------------------------------------------------------------------------------------------#
# DESCRIPTION:                                                                                                    #
#                                                                                                                 #
#           Add the propertie "bind: true" to an item script to bind the player with it                           #
#           Player can't throw it or drag it to inventory                                                         #
#           Example:                                                                                              #
#                    QuestJournal:                                                                                #
#                      type: item                                                                                 #
#                      material: i@book                                                                           #
#                      debug: false                                                                               #
#                      display name: <yellow>Quest Journal                                                        #
#                      # if true, player cant drop it                                                             #
#                      bind: true                                                                                 #
#                                                                                                                 #
# PERMISSIONS:                                                                                                    #
#                                                                                                                 #
#-----------------------------------------------------------------------------------------------------------------#

BindItem_Listener:
  type: world
  debug: false
  events:
    on player drops item:
    - if <context.item.scriptname.as_script.yaml_key[bind]||false> && <player.gamemode> != CREATIVE:
        - narrate format:error_format "this item is Bound to you."
        - playsound <player> sound:ENTITY_VILLAGER_NO
        - determine CANCELLED
    
    on player drags item:
    - if <context.item.scriptname.as_script.yaml_key[bind]||false> && <context.raw_slots.filter[is[less].than[<context.inventory.size>]].size.is[more].than[0]> && <player.gamemode> != CREATIVE:
        - narrate format:error_format "this item is Bound to you."
        - playsound <player> sound:ENTITY_VILLAGER_NO
        - determine CANCELLED
    
    on player clicks in inventory:
    - if <context.action.is[==].to[NOTHING]> stop
    - if <context.action.starts_with[DROP].and[<context.cursor_item.scriptname.as_script.yaml_key[bind].or[<context.item.scriptname.as_script.yaml_key[bind]||false>]||false>]||false> && <player.gamemode> != CREATIVE:
        - narrate format:error_format "this item is Bound to you."
        - playsound <player> sound:ENTITY_VILLAGER_NO
        - determine CANCELLED
    
    - if <context.item.scriptname.as_script.yaml_key[bind]||false> && <player.gamemode> != CREATIVE:
        - if <context.action.starts_with[DROP]>:
            - narrate format:error_format "this item is Bound to you."
            - playsound <player> sound:ENTITY_VILLAGER_NO
            - determine CANCELLED
        
        - if <context.action.is[==].to[MOVE_TO_OTHER_INVENTORY]> && <context.inventory.inventory_type.is[!=].to[CRAFTING]> && <player.gamemode> != CREATIVE:
            - narrate format:error_format "this item is Bound to you."
            - playsound <player> sound:ENTITY_VILLAGER_NO
            - determine CANCELLED
        
      
    - if <context.cursor_item.scriptname.as_script.yaml_key[bind]||false>:
        - if <context.action.starts_with[DROP]> || <context.raw_slot.is[or_less].than[<context.inventory.size>]> && <player.gamemode> != CREATIVE:
            - narrate format:error_format "this item is Bound to you."
            - playsound <player> sound:ENTITY_VILLAGER_NO
            - determine passively CANCELLED
            - inventory update d:<player.inventory>
            - stop
        
      
    - if <context.action.is[==].to[HOTBAR_SWAP]>:
        - if <player.inventory.slot[<context.hotbar_button>].scriptname.as_script.yaml_key[bind]||false> && <context.raw_slot.is[or_less].than[<context.inventory.size>]> && <player.gamemode> != CREATIVE:
            - narrate format:error_format "this item is Bound to you."
            - playsound <player> sound:ENTITY_VILLAGER_NO
            - determine CANCELLED
        
    
    on item recipe formed:
    - if <context.recipe.parse[scriptname].filter[scriptname.as_script.yaml_key[bind]].size.is[more].than[0]> && <player.gamemode> != CREATIVE:
        - narrate format:error_format "this item is Bound to you."
        - playsound <player> sound:ENTITY_VILLAGER_NO
        - determine CANCELLED
    
    on player death:
    - determine <context.drops.exclude[<context.drops.filter[scriptname.as_script.yaml_key[bind]]>]>

