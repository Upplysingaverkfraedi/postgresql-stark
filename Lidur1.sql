--- Liður 1
-- Skrifið SQL fyrirspurn sem finnur samsvörun á milli ríkja í Game of Thrones heiminum (úr atlas.kingdoms) og húsum (úr got.houses) út frá því hvaða hús tilheyra hvaða ríki.
-- Sýna öll ríki og öll hús, líka þau sem eru ekki með samsvörun. Upsertið möppunina í töfluna stark.tables_mapping með dálkunum kingdom_id, house_id.

-- Sýna öll ríki og öll hús
WITH KingdomHouseMapping AS (
    -- Left join: Sýnir öll ríki og samsvörun ef hún er til, annars NULL fyrir hús.
    SELECT
        k.gid AS kingdom_id,
        h.id AS house_id,
        k.name AS kingdom_name,
        h.name AS house_name
    FROM
        atlas.kingdoms k
    LEFT JOIN
        got.houses h
    ON
        k.name ILIKE h.region  -- Samsvörun milli ríkjanöfn og svæðis húsa

    UNION

    -- Right join: Sýnir öll hús og samsvörun ef hún er til, annars NULL fyrir ríki.
    SELECT
        k.gid AS kingdom_id,
        h.id AS house_id,
        k.name AS kingdom_name,
        h.name AS house_name
    FROM
        atlas.kingdoms k
    RIGHT JOIN
        got.houses h
    ON
        k.name ILIKE h.region
)
-- Sýnir öll ríki og öll hús:
SELECT
    kingdom_name,
    house_name
FROM
    KingdomHouseMapping
ORDER BY
    kingdom_name, house_name;

-- Liður 2
    -- Skrifið SQL fyrirspurn með CTE sem finnur samsvörun á milli staða og húsa. Hér er markmiðið að finna gagntæka vörpun (one-to-one mapping), þar sem hver staður úr atlas.locations mappast á nákvæmlega eitt hús úr got.houses.
-- Upsertið niðurstöður fyrir allan heiminn í töfluna stark.tables_mapping með dálkunum house_id, location_id.
-- Sýnið svo niðurstöður fyrir Norðrið.

-- CTE til að finna samsvörun á milli staða og húsa:
WITH LocationHouseMapping AS (
    SELECT
        l.gid AS location_id,
        h.id AS house_id,
        l.name AS location_name,
        h.name AS house_name,
        l.summary
    FROM atlas.locations l
    LEFT JOIN got.houses h
    ON l.name ILIKE '%' || h.name || '%'
    OR l.summary ILIKE '%' || h.name || '%'
    OR h.name ILIKE '%' || split_part(l.summary, ' ', array_length(string_to_array(l.summary, ' '), 1)) || '%'
)

-- Setja niðurstöðurnar inn í Stark töfluna:
INSERT INTO stark.tables_mapping (house_id, location_id)
SELECT house_id, location_id
FROM LocationHouseMapping
WHERE house_id IS NOT NULL  -- Vera viss um að house_id sé ekki NULL
AND location_id IS NOT NULL  -- Vera viss um að location_id sé ekki NULL
AND NOT EXISTS (  -- Setja ekki inn duplicates
    SELECT 1
    FROM stark.tables_mapping tm
    WHERE tm.house_id = LocationHouseMapping.house_id
    OR tm.location_id = LocationHouseMapping.location_id
);

-- Sýna niðurstöður fyrir Norðrið:
SELECT *
FROM stark.tables_mapping tm
JOIN got.houses h ON tm.house_id = h.id
WHERE h.region = 'The North';

-- Liður 3
-- Skrifið SQL fyrirspurn með CTE sem finnur stærstu ættir allra norðanmanna
-- (þ.e. persónur sem eru hliðhollar húsinu The North).
-- Einskorðið ykkur við ættir sem hafa fleiri en 5 hliðholla meðlimi.
-- Úttakið ætti að vera raðað eftir fjölda meðlima (stærstu fyrst) og í stafrófsröð.

-- Sýnir fjölskyldunöfn og fjölda meðlima
WITH SwornFamilies AS (
    -- Finna allar persónur sem eru hliðhollar húsum í The North
    SELECT
        h.id AS house_id,
        unnest(h.sworn_members) AS member_id  -- Brýtur sworn_members array niður í stakar raðir
    FROM
        got.houses h
    WHERE
        h.region = 'The North'  -- Sía til að fá aðeins hús í The North
),
CharacterDetails AS (
    -- Finna nafn og fjölskyldunafn persóna
    SELECT
        c.id AS character_id,
        c.name,
        split_part(c.name, ' ', array_length(string_to_array(c.name, ' '), 1)) AS family_name  -- Nær í fjölskyldunafn
    FROM
        got.characters c
),
FamilyCount AS (
    -- Tengja sworn members við character details og telja meðlimi
    SELECT
        cd.family_name,
        COUNT(cd.character_id) AS member_count
    FROM
        SwornFamilies sf
    JOIN
        CharacterDetails cd
    ON
        sf.member_id = cd.character_id
    GROUP BY
        cd.family_name
    HAVING
        COUNT(cd.character_id) > 5  -- Síum út ættir sem hafa fleiri en 5 meðlimi
)
-- Lokaúttak: Velja ættir með fleiri en 5 meðlimi og raða þeim
SELECT
    family_name,
    member_count
FROM
    FamilyCount
ORDER BY
    member_count DESC,  -- Raða eftir fjölda meðlima (stærstu ættir fyrst)
    family_name ASC;    -- Ef jafn fjöldi meðlima, raða eftir nafni

