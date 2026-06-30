#include <amxmodx>
#include <sqlx>
#include <geoip>

#define PLUGIN  "[ZP] Location System"
#define VERSION "1.0"
#define AUTHOR  "DadoDz"

new Handle:g_SqlTuple, g_Error[512];
new g_playername[33][32], g_playercountry[33][64], g_playercity[33][64], g_playersteamid[33][64], g_playerip[33][32];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    MySql_Init();
}

public plugin_end() SQL_FreeHandle(g_SqlTuple);

public MySql_Init()
{
    g_SqlTuple = SQL_MakeDbTuple("", "", "", "");

    new ErrorCode, Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error));

    if (SqlConnection == Empty_Handle)
        set_fail_state(g_Error);
    else
        log_amx("MySQL Connected successfully!");

    new Handle:Query;
    Query = SQL_PrepareQuery(SqlConnection,
        "CREATE TABLE IF NOT EXISTS `zp_location_system` ( \
        `name` VARCHAR(32) NOT NULL PRIMARY KEY, \
        `last_country` VARCHAR(64) NOT NULL DEFAULT 'N/A', \
        `last_city` VARCHAR(64) NOT NULL DEFAULT 'N/A', \
        `last_steamid` VARCHAR(64) NOT NULL DEFAULT 'N/A', \
        `last_ip` VARCHAR(32) NOT NULL DEFAULT 'N/A' \
    )"
    );

    if(!SQL_Execute(Query))
    {
        SQL_QueryError(Query, g_Error, charsmax(g_Error));
        set_fail_state(g_Error);
    }

    SQL_FreeHandle(Query);
    SQL_FreeHandle(SqlConnection);
}

public client_putinserver(id)
{
    if (!is_user_connected(id))
        return;

    get_user_name(id, g_playername[id], charsmax(g_playername[]));
    get_user_ip(id, g_playerip[id], charsmax(g_playerip[]), 1);
    get_user_authid(id, g_playersteamid[id], charsmax(g_playersteamid[]));
    geoip_country(g_playerip[id], g_playercountry[id], charsmax(g_playercountry[]));
    geoip_city(g_playerip[id], g_playercity[id], charsmax(g_playercity[]));

    if (containi(g_playercountry[id], "err") != -1)
        copy(g_playercountry[id], charsmax(g_playercountry[]), "N/A");
    if (!g_playercity[id][0])
        copy(g_playercity[id], charsmax(g_playercity[]), "N/A");

    new szQuery[256], Data[1];
    Data[0] = id;

    format(szQuery, charsmax(szQuery), "SELECT `last_country`, `last_city`, `last_steamid`, `last_ip` FROM `zp_location_system` WHERE `name` = '%s';", g_playername[id]);
    SQL_ThreadQuery(g_SqlTuple, "LoadPlayer_Handle", szQuery, Data, 1);
}

public LoadPlayer_Handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
    new id = Data[0];

    if (FailState == TQUERY_CONNECT_FAILED)
    {
        log_amx("SQL Connection failed! [%d] %s", Errcode, Error);
        return;
    }
    else if (FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("SQL Query failed! [%d] %s", Errcode, Error);
        return;
    }

    if(SQL_NumResults(Query) < 1)
    {
        new szInsert[600];
        format(szInsert, charsmax(szInsert), "INSERT INTO `zp_location_system` (`name`, `last_country`, `last_city`, `last_steamid`, `last_ip`) VALUES ('%s','%s','%s','%s','%s');", g_playername[id], g_playercountry[id], g_playercity[id], g_playersteamid[id], g_playerip[id]);
        SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szInsert);

        log_amx("[Location] Inserted new player: %s (%s, %s, %s, %s)", g_playername[id], g_playercountry[id], g_playercity[id], g_playersteamid[id], g_playerip[id]);
    }
    else
    {
        new szDBCountry[64], szDBCity[64], szDBSteam[64], szDBIP[32];
        SQL_ReadResult(Query, 0, szDBCountry, charsmax(szDBCountry));
        SQL_ReadResult(Query, 1, szDBCity, charsmax(szDBCity));
        SQL_ReadResult(Query, 2, szDBSteam, charsmax(szDBSteam));
        SQL_ReadResult(Query, 3, szDBIP, charsmax(szDBIP));

        if (!equal(szDBCountry, g_playercountry[id]) || !equal(szDBCity, g_playercity[id]) || !equal(szDBSteam, g_playersteamid[id]) || !equal(szDBIP, g_playerip[id]))
        {
            new szUpdate[600];
            format(szUpdate, charsmax(szUpdate), "UPDATE `zp_location_system` SET `last_country`='%s', `last_city`='%s', `last_steamid`='%s', `last_ip`='%s' WHERE `name`='%s';", g_playercountry[id], g_playercity[id], g_playersteamid[id], g_playerip[id], g_playername[id]);
            SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szUpdate);

            log_amx("[Location] Updated player %s → (%s, %s, %s, %s)", g_playername[id], g_playercountry[id], g_playercity[id], g_playersteamid[id], g_playerip[id]);
        }
        else
            log_amx("[Location] %s already up-to-date", g_playername[id]);
    }
}

public IgnoreHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
    SQL_FreeHandle(Query);
    return PLUGIN_HANDLED;
}
