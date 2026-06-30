<?phpheader("Content-Type: text/html; charset=UTF-8");

$servername = "";
$username   = "";
$password   = "";
$dbname     = "";

$countryMap = [
        // North America
        'United States' => 'us','USA' => 'us','United States of America' => 'us',
        'Canada' => 'ca','Mexico' => 'mx','Cuba' => 'cu',

        // South America
        'Brazil' => 'br','Argentina' => 'ar','Chile' => 'cl','Colombia' => 'co',
        'Peru' => 'pe','Venezuela' => 've','Uruguay' => 'uy','Paraguay' => 'py',
        'Bolivia' => 'bo','Ecuador' => 'ec',

        // Europe (West + Central)
        'United Kingdom' => 'gb','UK' => 'gb','Great Britain' => 'gb','England' => 'gb',
        'France' => 'fr','Germany' => 'de','Italy' => 'it','Spain' => 'es','Portugal' => 'pt',
        'Netherlands' => 'nl','Belgium' => 'be','Switzerland' => 'ch','Austria' => 'at',
        'Ireland' => 'ie','Luxembourg' => 'lu','Monaco' => 'mc','Liechtenstein' => 'li',

        // Scandinavia & Baltics
        'Sweden' => 'se','Norway' => 'no','Denmark' => 'dk','Finland' => 'fi','Iceland' => 'is',
        'Estonia' => 'ee','Latvia' => 'lv','Lithuania' => 'lt',

        // Eastern Europe
        'Poland' => 'pl','Czech Republic' => 'cz','Czechia' => 'cz',
        'Slovakia' => 'sk','Hungary' => 'hu','Romania' => 'ro','Bulgaria' => 'bg',
        'Ukraine' => 'ua','Belarus' => 'by','Moldova' => 'md',

        // Balkan
        'Serbia' => 'rs','Croatia' => 'hr','Bosnia' => 'ba','Bosnia and Herzegovina' => 'ba',
        'Montenegro' => 'me','North Macedonia' => 'mk','Albania' => 'al','Greece' => 'gr',

        // Russia & Caucasus
        'Russia' => 'ru','Georgia' => 'ge','Armenia' => 'am','Azerbaijan' => 'az',

        // Middle East
        'Turkey' => 'tr','Israel' => 'il','Palestine' => 'ps','Lebanon' => 'lb','Jordan' => 'jo',
        'Saudi Arabia' => 'sa','United Arab Emirates' => 'ae','UAE' => 'ae','Qatar' => 'qa',
        'Kuwait' => 'kw','Bahrain' => 'bh','Oman' => 'om','Yemen' => 'ye','Iran' => 'ir','Iraq' => 'iq',

        // Africa
        'Egypt' => 'eg','Algeria' => 'dz','Morocco' => 'ma','Tunisia' => 'tn','Libya' => 'ly',
        'Sudan' => 'sd','Ethiopia' => 'et','Nigeria' => 'ng','Ghana' => 'gh','Ivory Coast' => 'ci',
        'South Africa' => 'za','Kenya' => 'ke','Tanzania' => 'tz','Uganda' => 'ug',

        // Asia
        'India' => 'in','Pakistan' => 'pk','Bangladesh' => 'bd','Sri Lanka' => 'lk','Nepal' => 'np',
        'China' => 'cn','Japan' => 'jp','South Korea' => 'kr','North Korea' => 'kp','Mongolia' => 'mn',
        'Thailand' => 'th','Vietnam' => 'vn','Cambodia' => 'kh','Laos' => 'la','Myanmar' => 'mm',
        'Philippines' => 'ph','Malaysia' => 'my','Singapore' => 'sg','Indonesia' => 'id',

        // Oceania
        'Australia' => 'au','New Zealand' => 'nz','Fiji' => 'fj','Papua New Guinea' => 'pg'
];

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    error_log("Database connection failed: " . $conn->connect_error);
    $players = [];
} else {
    $sql = "SELECT r.name, r.kills, r.hs_kills, r.infections, r.infected, r.deaths, r.score,
                   l.last_country
            FROM zp_rank_system AS r
            LEFT JOIN zp_location_system AS l ON r.name = l.name
            ORDER BY r.score DESC 
            LIMIT 15";
    $result = $conn->query($sql);

    $players = [];
    if ($result && $result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $players[] = $row;
        }
    }
    $conn->close();
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>TOP 15 - ZM.CSELITES.COM</title>
    <style>
        body {
            margin: 0;
            padding: 5px;
            background: #000000;
            color: #FFFFFF;
            font-family: Tahoma, Verdana, Arial;
            font-size: 12px;
            width: 100%;
            box-sizing: border-box;
        }
        .header {
            background: #111111;
            padding: 5px 0;
            text-align: center;
            border-bottom: 2px solid #FF0000;
            margin-bottom: 5px;
        }
        h1 {
            color: #FF0000;
            font-size: 18px;
            margin: 0;
            padding: 3px 0;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: #0A0A0A;
            border: 1px solid #333333;
        }
        th {
            background: #222222;
            color: #00CCFF;
            padding: 6px 4px;
            text-align: center;
            font-size: 12px;
            border-bottom: 1px solid #333333;
            font-weight: bold;
        }
        td {
            padding: 6px 4px;
            text-align: center;
            border-bottom: 1px solid #222222;
            height: 16px;
            font-size: 12px;
        }
        .rank {
            width: 30px;
            font-weight: bold;
            font-size: 13px;
            color: rgba(24, 255, 209, 1);
        }
        .flag {
            width: 24px;
            height: 16px;
        }
        .name {
            text-align: left;
            padding-left: 5px;
            max-width: 160px;
            overflow: hidden;
            white-space: nowrap;
            font-size: 12px;
        }
        .positive { color: #00FF00; font-weight: bold; }
        .negative { color: #FF6666; }
        .highlight { color: #FFCC00; font-weight: bold; }
        .error-message {
            text-align: center;
            padding: 15px;
            color: #FF6666;
            font-size: 14px;
            background: #0A0A0A;
            border: 1px solid #333333;
        }
        tr.row-odd { background: #0F0F0F; }
        tr.row-even { background: #151515; }
        tr.top-1 { background: #332200 !important; border: 1px solid #FFD700; }
        tr.top-2 { background: #222222 !important; border: 1px solid #C0C0C0; }
        tr.top-3 { background: #2A1A00 !important; border: 1px solid #CD7F32; }
        tr.top-1 td.rank { color: #FFD700; font-size: 14px; }
        tr.top-2 td.rank { color: #C0C0C0; font-size: 13px; }
        tr.top-3 td.rank { color: #CD7F32; font-size: 13px; }
    </style>
</head>
<body>
<div class="header">
    <h1>TOP 15 PLAYERS LEADERBOARD</h1>
</div>

<table>
    <tr>
        <th class="rank">#</th>
        <th>Flag</th>
        <th class="name">Player</th>
        <th>Kills</th>
        <th>HS Kills</th>
        <th>Infections</th>
        <th>Infected</th>
        <th>Deaths</th>
        <th>Score</th>
    </tr>
    <?php if (!empty($players)): ?>
        <?php foreach ($players as $index => $player): 
            $rank = $index + 1;
            $rowClass = ($index % 2 == 0) ? 'row-even' : 'row-odd';
            if ($rank <= 3) $rowClass = 'top-' . $rank;

            $countryName = trim($player['last_country']);
            $countryCode = $countryMap[$countryName] ?? strtolower($countryName);

            $flag = ($countryCode && $countryCode != "n/a")
                ? '<img class="flag" src="/test/countries/' . htmlspecialchars($countryCode) . '.png" alt="' . htmlspecialchars($countryName) . '">'
                : '';
        ?>
        <tr class="<?php echo $rowClass; ?>">
            <td class="rank"><?php echo $rank; ?></td>
            <td><?php echo $flag; ?></td>
            <td class="name"><?php echo htmlspecialchars($player['name']); ?></td>
            <td class="positive"><?php echo $player['kills']; ?></td>
            <td class="positive"><?php echo $player['hs_kills']; ?></td>
            <td class="positive"><?php echo $player['infections']; ?></td>
            <td class="negative"><?php echo $player['infected']; ?></td>
            <td class="negative"><?php echo $player['deaths']; ?></td>
            <td class="highlight"><?php echo $player['score']; ?></td>
        </tr>
        <?php endforeach; ?>
    <?php else: ?>
        <tr class="row-odd">
            <td colspan="9" class="error-message">
                Unable to load leaderboard data. Please try again later.
            </td>
        </tr>
    <?php endif; ?>
</table>
</body>
</html>
