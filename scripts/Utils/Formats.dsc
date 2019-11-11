#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                        Formats Script                                                              |#
#--------------------------------------------------------------------------------------------------------------------------------------#

npc_talk_format:
    type: format
    debug: false
    format: "<green><npc.name><white><&co> <yellow><text>"

unknow_npc_talk_format:
    type: format
    debug: false
    format: "<green>Unknown<white><&co> <yellow><text>"

player_talk_format:
    type: format
    debug: false
    format: "<green>You<white><&co> <white><text>"
    
other_player_talk_format:
    type: format
    debug: false
    format: "<green><player.name><white><&co> <white><text>"

# use for clickable choices
# ex: <proc[msgChat].context[<aqua>No. Go to hell !|no|Deny the job]>
#     <proc[msgChat].context[<aqua>Yes. I was looking for some work !|yes|Accept the job]>
choice_format:
    type: format
    debug: false
    format: "<aqua>► <text>"

# Use it for narration (off voice)
# Use it for commands output
narration_format:
    type: format
    debug: false
    format: "<gray><text>"

# Use it for HINT
hint_format:
    type: format
    debug: false
    format: "<white><&lb>hint<&rb><gray> <text>"

# Use it when action is denied
# Use it when error occurs
error_format:
    type: format
    debug: false
    format: "<gray>[<red>!<gray>]<red> <text>"

# Use it for warning
warning_format:
    type: format
    debug: false
    format: "<gray>[<gold>!<gray>]<gold> <text>"

# Use it when command is successful
success_format:
    type: format
    debug: false
    format: "<gray>[<green>v<gray>]<green> <text>"

# Used by Quest to display quest info (like objectives)
quest_format:
  type: format
  debug: false
  format: "<yellow><&lb>QUEST<&rb><white> <text>"
