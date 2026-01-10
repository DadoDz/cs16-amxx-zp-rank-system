#include <amxmodx>
#include <amxmisc>
#include <chr_engine>
#include <hamsandwich>
#include <fvault> 
#include <zombie_plague>

#define PLUGIN "[ZP] Rank System"
#define VERSION "1.0"
#define AUTHOR "DadoDz"

enum _:STATS
{
    NAME[32],
    KILLS,
    HS_KILLS,
    INFECTIONS,
    INFECTED,
    DEATHS,
    SCORE
}

new g_playerstats[33][STATS];
new g_hitgroup[33];
new g_bLoaded[33];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");

    register_clcmd("say /rank", "RankCMD");
    register_clcmd("say /top15", "TopCMD");
}

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

    LoadRank(id);
}

public client_disconnected(id)
{
    g_hitgroup[id] = 0;
    SaveRank(id);
    g_bLoaded[id] = false;

    g_playerstats[id][KILLS] = 0;
    g_playerstats[id][HS_KILLS] = 0;
    g_playerstats[id][INFECTIONS] = 0;
    g_playerstats[id][INFECTED] = 0;
    g_playerstats[id][DEATHS] = 0;
    g_playerstats[id][SCORE] = 0;
}

public SaveRank(id)
{
    if(!is_user_connected(id) || !g_bLoaded[id]) 
        return;

    static szDataHolder[128];
    formatex(szDataHolder, charsmax(szDataHolder), "%i#%i#%i#%i#%i#%i", g_playerstats[id][KILLS], g_playerstats[id][HS_KILLS], 
                                                                        g_playerstats[id][INFECTIONS], g_playerstats[id][INFECTED], 
                                                                        g_playerstats[id][DEATHS], g_playerstats[id][SCORE]);
    fvault_set_data("zp63_rank_system", g_playerstats[id][NAME], szDataHolder);
}

public LoadRank(id)
{
    if(!is_user_connected(id) || !g_playerstats[id][NAME][0])
        return;

    static szDataHolder[128], szKills[10], szHS[10], szInfections[10], szInfected[10], szDeaths[10], szScore[10];

    if(fvault_get_data("zp63_rank_system", g_playerstats[id][NAME], szDataHolder, charsmax(szDataHolder)))
    {
        replace_string(szDataHolder, charsmax(szDataHolder), "#", " ");
        parse(szDataHolder, szKills, charsmax(szKills), szHS, charsmax(szHS), szInfections, charsmax(szInfections),
              szInfected, charsmax(szInfected), szDeaths, charsmax(szDeaths), szScore, charsmax(szScore));

        g_playerstats[id][KILLS] = str_to_num(szKills);
        g_playerstats[id][HS_KILLS] = str_to_num(szHS);
        g_playerstats[id][INFECTIONS] = str_to_num(szInfections);
        g_playerstats[id][INFECTED] = str_to_num(szInfected);
        g_playerstats[id][DEATHS] = str_to_num(szDeaths);
        g_playerstats[id][SCORE] = str_to_num(szScore);
    }
    else
    {
        g_playerstats[id][KILLS] = 0;
        g_playerstats[id][HS_KILLS] = 0;
        g_playerstats[id][INFECTIONS] = 0;
        g_playerstats[id][INFECTED] = 0;
        g_playerstats[id][DEATHS] = 0;
        g_playerstats[id][SCORE] = 0;

        SaveRank(id);
    }

    g_bLoaded[id] = true;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
    if(attacker == victim) 
        return PLUGIN_HANDLED;

    if(is_user_connected(victim))
    {
        g_playerstats[victim][DEATHS]++;
        NewScore(victim);
    }

    if(is_user_connected(attacker))
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
        if (is_user_connected(infector))
        {
            g_playerstats[infector][INFECTIONS]++;
            NewScore(infector);
        }
        
        if (is_user_connected(id) && infector > 0)
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

public RankCMD(id)
{
    if (!is_user_connected(id) || !g_bLoaded[id])
        return PLUGIN_HANDLED;

    new Array:keys = ArrayCreate(64);
    new Array:datas = ArrayCreate(128);
    new Array:timestamps = ArrayCreate(1);

    new total = fvault_load("zp63_rank_system", keys, datas, timestamps);

    if (total < 1)
    {
        client_print_color(id, 0, "^x04[^x01ZP^x04]^x01 No registered players found.");
        goto CLEANUP;
    }

    new my_score = g_playerstats[id][SCORE];
    new rank = 1;

    static data[128];
    static szKills[8], szHS[8], szInf[8], szInfd[8], szDeaths[8], szScore[8];

    for (new i = 0; i < total; i++)
    {
        ArrayGetString(datas, i, data, charsmax(data));
        replace_string(data, charsmax(data), "#", " ");
        parse(data, szKills, charsmax(szKills), szHS, charsmax(szHS), szInf, charsmax(szInf), szInfd, charsmax(szInfd), szDeaths, charsmax(szDeaths),szScore, charsmax(szScore));

        if (str_to_num(szScore) > my_score)
            rank++;
    }

    client_print_color(id, 0, "^x04[^x01ZP^x04]^x01 Rank:^x03 %d/%d^x04 -^x01 Kills:^x03 %d^x04 -^x01 HS:^x03 %d^x04 -^x01 Infections:^x03 %d^x04 -^x01 Infected:^x03 %d^x04 -^x01 Deaths:^x03 %d^x04 -^x01 Score:^x03 %d",
        rank, total, g_playerstats[id][KILLS], g_playerstats[id][HS_KILLS], g_playerstats[id][INFECTIONS], g_playerstats[id][INFECTED], g_playerstats[id][DEATHS], g_playerstats[id][SCORE]);

CLEANUP:
    ArrayDestroy(keys);
    ArrayDestroy(datas);
    ArrayDestroy(timestamps);

    return PLUGIN_HANDLED;
}

public TopCMD(id)
{
    if (!is_user_connected(id))
        return PLUGIN_HANDLED;

    new Array:keys = ArrayCreate(64);
    new Array:datas = ArrayCreate(128);
    new Array:timestamps = ArrayCreate(1);

    new total = fvault_load("zp63_rank_system", keys, datas, timestamps);

    if (total < 1)
    {
        show_motd(id, "<body style='background:#000;color:#fff;text-align:center;'><br><br>No ranked players found.</body>", "TOP 15");
        goto CLEANUP;
    }

    static row1[128], row2[128];
    static sK[8], sHS[8], sInf[8], sInfd[8], sD[8], sScore1[8], sScore2[8];

    for (new i = 0; i < total - 1; i++)
    {
        for (new j = i + 1; j < total; j++)
        {
            ArrayGetString(datas, i, row1, charsmax(row1));
            ArrayGetString(datas, j, row2, charsmax(row2));
            replace_string(row1, charsmax(row1), "#", " ");
            replace_string(row2, charsmax(row2), "#", " ");

            parse(row1, sK, charsmax(sK), sHS, charsmax(sHS), sInf, charsmax(sInf), sInfd, charsmax(sInfd), sD, charsmax(sD), sScore1, charsmax(sScore1));
            parse(row2, sK, charsmax(sK), sHS, charsmax(sHS), sInf, charsmax(sInf), sInfd, charsmax(sInfd), sD, charsmax(sD), sScore2, charsmax(sScore2));

            if (str_to_num(sScore2) > str_to_num(sScore1))
            {
                ArraySwap(datas, i, j);
                ArraySwap(keys, i, j);
            }
        }
    }

    new szMotd[4096], len;
    new name[32], data[128];

    static szKills[8], szHS[8], szInf[8], szInfected[8], szDeaths[8], szScore[8];

    len += formatex(szMotd[len], charsmax(szMotd) - len, "<body style='background:#000;color:#fff;font-family:Verdana,Tahoma;font-size:13px;margin:0;'>\ <center><pre>");
    len += formatex(szMotd[len], charsmax(szMotd) - len, "%2s %-18.18s %6s %3s %11s %9s %7s %6s^n", "#", "Nick", "Kills", "HS", "Infections", "Infected", "Deaths", "Score");
    len += formatex(szMotd[len], charsmax(szMotd) - len, "--------------------------------------------------------^n");

    new limit = (total < 15) ? total : 15;

    for (new i = 0; i < limit; i++)
    {
        ArrayGetString(keys, i, name, charsmax(name));
        ArrayGetString(datas, i, data, charsmax(data));
        replace_string(data, charsmax(data), "#", " ");

        parse(data, szKills, charsmax(szKills), szHS, charsmax(szHS), szInf, charsmax(szInf), szInfected, charsmax(szInfected), szDeaths, charsmax(szDeaths), szScore, charsmax(szScore));

        replace_all(name, charsmax(name), "<", "[");
        replace_all(name, charsmax(name), ">", "]");

        len += formatex(szMotd[len], charsmax(szMotd) - len, "%2d %-18.18s %6d %3d %11d %9d %7d %6d^n", 
        i + 1, name, str_to_num(szKills), str_to_num(szHS), str_to_num(szInf), str_to_num(szInfected), str_to_num(szDeaths), str_to_num(szScore));
    }

    len += formatex(szMotd[len], charsmax(szMotd) - len, "</pre></center></body>");
    show_motd(id, szMotd, "Top 15");

CLEANUP:
    ArrayDestroy(keys);
    ArrayDestroy(datas);
    ArrayDestroy(timestamps);

    return PLUGIN_HANDLED;
}
