########################################################################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------#
#|                                                            Sleep                                                                   |#
#|                                             Skip the night if x% player sleeping                                                   |#
#--------------------------------------------------------------------------------------------------------------------------------------#
########################################################################################################################################

SleepWorldEvents:
    type: world
    debug: true
    speed: 0
    events:
        on player enters bed:
        - if <player.location.world.name> != world:
            - queue clear
        - flag player sleeping:true
        - define allPlayersCount <world[world].players.size||1>
        - define sleepingPlayersCount <world[world].players.filter[has_flag[sleeping]].size||0>
        - define sleepingPlayersPercent <[sleepingPlayersCount].mul_int[100].div_int[<[allPlayersCount]>]>
        - narrate "<player.display_name> dort paisiblement. <[sleepingPlayersCount]>/<[allPlayersCount]> (<[sleepingPlayersPercent]>%)" targets:<world[world].players>
        # Here, 50% player are needed to skip the night
        - if <[sleepingPlayersPercent]> >= 50 && <[allPlayersCount]> != 1:
            - wait 5s
            - narrate "Le jour se lève..." targets:<world[world].players>
            - time 0t

        on player leaves bed:
        - flag player sleeping:!
