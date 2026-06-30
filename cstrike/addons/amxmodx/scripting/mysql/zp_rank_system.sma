#include <amxmodx>
#include <amxmisc>
#include <chr_engine>
#include <hamsandwich>
#include <zombie_plague>
#include <sqlx>

#pragma semicolon 1

#define PLUGIN "[ZP] Rank System"
#define VERSION "1.0"
#define AUTHOR "DadoDz"

native is_user_logged(id);
native is_user_registered(id);

new Handle:g_SqlTuple, g_Error[512];

enum _:STATS
{
    NAME[32],
    KILLS,
    HS_KILLS,
    INFECTIONS,
    INFECTED,
    DEATHS,
    SCORE,
    HOURS_PLAYED
}

new g_playerstats[33][STATS];
new g_hitgroup[33];
new Float:g_fStartTime[33];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    MySql_Init();

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");

    register_clcmd("say /rank", "RankCMD");
    register_clcmd("say /hoursplayed", "HoursPlayedCMD");
    register_clcmd("say /top15", "Top15CMD");

    set_task(60.0, "UpdateHours", 0, "", 0, "", 1);
}

public MySql_Init()
{
    g_SqlTuple = SQL_MakeDbTuple("", "", "", ""); //

    new ErrorCode, Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error));

    if (SqlConnection == Empty_Handle)
        set_fail_state(g_Error);
    else
        log_amx("aLL NiCE");

    new Handle:Queries;
    Queries = SQL_PrepareQuery(SqlConnection, 
            "CREATE TABLE IF NOT EXISTS `zp_rank_system` ( \
            `name` VARCHAR(32) NOT NULL PRIMARY KEY, \
            `kills` INT NOT NULL DEFAULT 0, \
            `hs_kills` INT NOT NULL DEFAULT 0, \
            `infections` INT NOT NULL DEFAULT 0, \
            `infected` INT NOT NULL DEFAULT 0, \
            `deaths` INT NOT NULL DEFAULT 0, \
            `score` INT NOT NULL DEFAULT 0, \
            `hours_played` INT NOT NULL DEFAULT 0 \
        )"
    );

    if(!SQL_Execute(Queries))
    {
        SQL_QueryError(Queries,g_Error,charsmax(g_Error));
        set_fail_state(g_Error);
    }

    SQL_FreeHandle(Queries);
    SQL_FreeHandle(SqlConnection);
}

public plugin_natives()
{
    register_native("SaveRank", "SaveRank", 1);
    register_native("LoadRank", "LoadRank", 1);
}

public plugin_end() SQL_FreeHandle(g_SqlTuple);

public client_putinserver(id)
{
    get_user_name(id, g_playerstats[id][NAME], charsmax(g_playerstats[][NAME]));
    g_hitgroup[id] = 0;

    g_playerstats[id][KILLS] = 0;
    g_playerstats[id][HS_KILLS] = 0;
    g_playerstats[id][INFECTIONS] = 0;
    g_playerstats[id][INFECTED] = 0;
    g_playerstats[id][DEATHS] = 0;
    g_playerstats[id][SCORE] = 0;
    g_playerstats[id][HOURS_PLAYED] = 0;

    if (is_user_connected(id) && is_user_registered(id) && is_user_logged(id))
        g_fStartTime[id] = get_gametime(); // store start time in seconds
}

public client_disconnected(id)
{
    g_hitgroup[id] = 0;
    SaveRank(id);

    if(is_user_registered(id) && is_user_logged(id))
    {
        new Float:seconds_played = get_gametime() - g_fStartTime[id];
        new minutes_played = seconds_played / 60.0;
        if(minutes_played > 0)
        {
            new szQuery[256];
            format(szQuery, charsmax(szQuery), "UPDATE `zp_rank_system` SET `hours_played` = `hours_played` + %d WHERE `name` = '%s';", minutes_played, g_playerstats[id][NAME]);
            SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szQuery);
        }
    }

    g_playerstats[id][KILLS] = 0;
    g_playerstats[id][HS_KILLS] = 0;
    g_playerstats[id][INFECTIONS] = 0;
    g_playerstats[id][INFECTED] = 0;
    g_playerstats[id][DEATHS] = 0;
    g_playerstats[id][SCORE] = 0;
    g_playerstats[id][HOURS_PLAYED] = 0;
}

public SaveRank(id)
{
    if (!is_user_connected(id))
        return;
        
    new szTemp[512];

    if (is_user_registered(id) && is_user_logged(id))
    {
        format(szTemp, charsmax(szTemp), "UPDATE `zp_rank_system` SET `kills` = '%d' , `hs_kills` = '%d' , `infections` = '%d' , `infected` = '%d' , `deaths` = '%d' , `score` = '%d' , `hours_played` = '%d' WHERE `zp_rank_system`.`name` = '%s';", 
        g_playerstats[id][KILLS], g_playerstats[id][HS_KILLS], g_playerstats[id][INFECTIONS], g_playerstats[id][INFECTED], g_playerstats[id][DEATHS], g_playerstats[id][SCORE], g_playerstats[id][HOURS_PLAYED], g_playerstats[id][NAME]);
    }

    SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
}

public LoadRank(id)
{
    if (!is_user_connected(id)) 
        return;

    new szTemp[256];

    new Data[1];
    Data[0] = id;

    format(szTemp, charsmax(szTemp), "SELECT * FROM `zp_rank_system` WHERE (`zp_rank_system`.`name` = '%s')", g_playerstats[id][NAME]);
    SQL_ThreadQuery(g_SqlTuple, "LoadPlayer_Handle", szTemp, Data, 1);
}

public LoadPlayer_Handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
    if (FailState == TQUERY_CONNECT_FAILED)
        log_amx("LoadPlayer - Could not connect to SQL database. [%d] %s", Errcode, Error);
    else if (FailState == TQUERY_QUERY_FAILED)
        log_amx("LoadPlayer - Query failed. [%d] %s", Errcode, Error);

    new id = Data[0];

    if(SQL_NumResults(Query) < 1)
    {
        new szTemp[512];
        format(szTemp,charsmax(szTemp), "INSERT INTO `zp_rank_system` ( `name` , `kills` , `hs_kills` , `infections` , `infected` , `deaths` , `score` , `hours_played`) VALUES ('%s' , '0' , '0' , '0' , '0' , '0' , '0', '0');", g_playerstats[id][NAME]);
        SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);

        g_playerstats[id][KILLS] = 0;
        g_playerstats[id][HS_KILLS] = 0;
        g_playerstats[id][INFECTIONS] = 0;
        g_playerstats[id][INFECTED] = 0;
        g_playerstats[id][DEATHS] = 0;
        g_playerstats[id][SCORE] = 0;
        g_playerstats[id][HOURS_PLAYED] = 0;
    }
    else
    {
        if (is_user_registered(id) && is_user_logged(id))
        {
            g_playerstats[id][KILLS] = SQL_ReadResult(Query, 1);
            g_playerstats[id][HS_KILLS] = SQL_ReadResult(Query, 2);
            g_playerstats[id][INFECTIONS] = SQL_ReadResult(Query, 3);
            g_playerstats[id][INFECTED] = SQL_ReadResult(Query, 4);
            g_playerstats[id][DEATHS] = SQL_ReadResult(Query, 5);
            g_playerstats[id][SCORE] = SQL_ReadResult(Query, 6);
            g_playerstats[id][HOURS_PLAYED] = SQL_ReadResult(Query, 7);
        }
    }

    return PLUGIN_HANDLED;
}

public IgnoreHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
    SQL_FreeHandle(Query);
    return PLUGIN_HANDLED;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
    if(attacker == victim) 
        return PLUGIN_HANDLED;

    if(is_user_connected(victim) && is_user_registered(victim) && is_user_logged(victim))
    {
        g_playerstats[victim][DEATHS]++;
        NewScore(victim);
    }

    if(is_user_connected(attacker) && is_user_registered(attacker) && is_user_logged(attacker))
    {
        if(g_hitgroup[attacker] == HIT_HEAD)
            g_playerstats[attacker][HS_KILLS]++;
        else
            g_playerstats[attacker][KILLS]++;

        NewScore(attacker);
    }

    return PLUGIN_HANDLED;
}

public zp_user_infected_post(id, infector)
{
    if (id != infector) 
    {
        if (is_user_connected(infector) && is_user_registered(infector) && is_user_logged(infector))
        {
            g_playerstats[infector][INFECTIONS]++;
            NewScore(infector);
        }
        
        if (is_user_connected(id) && is_user_registered(id) && is_user_logged(id) && infector > 0)
        {
            g_playerstats[id][INFECTED]++;
            NewScore(id);
        }
    }

    return PLUGIN_HANDLED;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
    if (victim == attacker || !is_user_connected(attacker))
        return HAM_IGNORED;

    g_hitgroup[attacker] = get_tr2(tracehandle, TR_iHitgroup);
    return HAM_IGNORED;
}

public NewScore(id)
{
    if (is_user_registered(id) && is_user_logged(id))
    {
        g_playerstats[id][SCORE] = 0;

        g_playerstats[id][SCORE] += g_playerstats[id][KILLS] * 2;
        g_playerstats[id][SCORE] += g_playerstats[id][HS_KILLS] * 3;
        g_playerstats[id][SCORE] += g_playerstats[id][INFECTIONS] * 1;
        g_playerstats[id][SCORE] -= g_playerstats[id][DEATHS];
        g_playerstats[id][SCORE] -= g_playerstats[id][INFECTED];

        if (g_playerstats[id][SCORE] < 0)
            g_playerstats[id][SCORE] = 0;

        SaveRank(id);
    }
}

public RankCMD(id)
{
    if(!is_user_connected(id) || !is_user_registered(id) || !is_user_logged(id))
        return PLUGIN_HANDLED;

    new szQuery[256];
    format(szQuery, charsmax(szQuery), "SELECT name, kills, hs_kills, infections, infected, deaths, score FROM zp_rank_system ORDER BY score DESC;");

    new Data[1];
    Data[0] = id;

    SQL_ThreadQuery(g_SqlTuple, "Rank_Handle", szQuery, Data, 1);

    return PLUGIN_HANDLED;
}

public Rank_Handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
    new id = Data[0];
    new total_players = SQL_NumResults(Query);

    if(total_players < 1)
    {
        client_print(id, print_chat, "No registered players found.");
        return PLUGIN_HANDLED;
    }

    new player_rank = 1;
    new name[32], kills, hs, infections, infected, deaths, score;
    
    SQL_Rewind(Query);
    for(new i = 0; i < total_players; i++)
    {
        SQL_ReadResult(Query, 0, name, charsmax(name)); // name
        kills = SQL_ReadResult(Query, 1);
        hs = SQL_ReadResult(Query, 2);
        infections = SQL_ReadResult(Query, 3);
        infected = SQL_ReadResult(Query, 4);
        deaths = SQL_ReadResult(Query, 5);
        score = SQL_ReadResult(Query, 6);

        if(equali(name, g_playerstats[id][NAME]))
            break;

        player_rank++;
        SQL_NextRow(Query);
    }

    client_print_color(id, 0, "^x04[^x01ZP^x04]^x01 Rank:^x03 %d/%d^x04 -^x01 Kills: %d^x04 |^x01 HS: %d^x04 |^x01 Infections: %d^x04 |^x01 Infected: %d^x04 |^x01 Deaths: %d",
    player_rank, total_players, kills, hs, infections, infected, deaths, score);

    return PLUGIN_HANDLED;
}

public HoursPlayedCMD(id)
{
    if (!is_user_connected(id) || !is_user_registered(id) || !is_user_logged(id))
        return PLUGIN_HANDLED;

    new szQuery[256];
    format(szQuery, charsmax(szQuery),
        "SELECT `hours_played` FROM `zp_rank_system` WHERE `name` = '%s';",
        g_playerstats[id][NAME]);

    new Data[1];
    Data[0] = id;

    SQL_ThreadQuery(g_SqlTuple, "HoursPlayed_Handle", szQuery, Data, 1);
    return PLUGIN_HANDLED;
}

public HoursPlayed_Handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
    new id = Data[0];

    if (FailState != TQUERY_SUCCESS)
    {
        client_print(id, print_chat, "Failed to get hours played.");
        return PLUGIN_HANDLED;
    }

    if (SQL_NumResults(Query) < 1)
    {
        client_print(id, print_chat, "No data found.");
        return PLUGIN_HANDLED;
    }

    new played_minutes = SQL_ReadResult(Query, 0);
    g_playerstats[id][HOURS_PLAYED] = played_minutes;

    new hours = played_minutes / 60;
    new minutes = played_minutes % 60;

    client_print_color(id, 0, "^x04[^x01ZP^x04]^x01 You have played^x03 %d hours^x01 and^x03 %d minutes^x01.", hours, minutes);
    return PLUGIN_HANDLED;
}

public UpdateHours()
{
    new Float:time, Float:seconds_played;
    new szQuery[256];

    for(new id = 1; id <= MAX_PLAYERS; id++)
    {
        if(is_user_connected(id) && is_user_registered(id) && is_user_logged(id))
        {
            time = get_gametime();
            seconds_played = time - g_fStartTime[id];

            if(seconds_played >= 60.0)
            {
                new minutes_played = floatround(seconds_played / 60.0);

                format(szQuery, charsmax(szQuery), 
                    "UPDATE `zp_rank_system` SET `hours_played` = `hours_played` + %d WHERE `name` = '%s';", 
                    minutes_played, g_playerstats[id][NAME]);

                SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szQuery);
                g_fStartTime[id] = time;
            }
        }
    }
}

public Top15CMD(id)
{
    show_motd(id, "http://------.com/website/index.php", "TOP PLAYERS LEADERBOARD");
    return PLUGIN_HANDLED;
}
