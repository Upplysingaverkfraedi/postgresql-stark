# Game of Thrones með PostgreSQL

## Gögn

Gögnin fyrir þetta verkefni koma frá tveimur uppruna:

1. [**Ice and Fire API**](https://anapioficeandfire.com/) - Gögn frá skáldsöguheiminum *Game of
   Thrones* (schema: `got`) sem hægt er að nálgast með API köllum á vefþjónustu eftir Joakim Skoog.
2. **Game of Maps** - Gögn um kortlagningu og staðsetningar í heimi GoT (schema: `atlas`) eftir
   Patrick Triest.

### Sjö konungsríkin

GoT heimurinn er skiptur í mörg konungsríki og svæði. Oft er rætt um hin sjö konungsríki (*the
seven kingdoms*):

1. Konungsríki Norðursins (Kingdom of the North) – Stjórnað frá _Winterfell_ af Stark ættinni.
2. Konungsríki Fjallanna og Dalsins (Kingdom of the Mountain and the Vale) – Stjórnað frá
   _Eyrie_ af Arryn ættinni.
3. Konungsríki Eyjanna og Fljótanna (Kingdom of the Isles and the Riverlands) – Sögulega sameinað
   ríki _Iron Islands_ og _Riverdale_, en nú skipt í:
    - Járneyjar (Iron Islands) – Stjórnað frá _Pyke_ af Greyjoy ættinni.
    - Árdalið (Riverlands) – Stjórnað frá _Riverrun_ af Tully ættinni.
4. Konungsríki Klapparinnar (Kingdom of the Rock) – Stjórnað frá _Casterly Rock_ af Lannister
   ættinni (líka þekkt sem
   Vesturlönd).
5. Konungsríki Stormlandanna (Kingdom of the Stormlands) – Stjórnað frá _Storm's End_ af Baratheon
   ættinni.
6. Konungsríki Frónsins (Kingdom of the Reach) – Stjórnað frá _Highgarden_  af Tyrell ættinni.
7. Furstadæmi Dorne (Principality of Dorne) – Stjórnað frá _Sunspear_ af Martell ættinni.

### Viðbótarhéruð (utan sjö konungsríkin)

Þrátt fyrir að nafnið _sjö konungsríki_ haldist, eru fleiri stór svæði í Westeros:

- Krúnulöndin (The Crownlands) – Stjórnað frá _King's Landing_, beint undir valdi Járntrónunnar.
- Vesturlöndin (The Westerlands) – Stjórnað af House Lannister (sem hluti af Kingdom of the Rock).
- Árdalið (The Riverlands) – Sérstakt hérað stjórnað af House Tully.
- Járneyjar (The Iron Islands) – Stjórnað af House Greyjoy (áður hluti af Kingdom of the Isles and
  Rivers).
- Stormlöndin (The Stormlands) – Stjórnað af House Baratheon.

### PostgreSQL tenging
Gagnagrunnurinn er hýstur á Railway og er aðgengilegur með eftirfarandi tengingarupplýsingum:

Host: junction.proxy.rlwy.net
Port: 55303
Database: railway
Username: teymisnafn
Password: uppgefið í Canvas

Notið IDE til að tengjast PostgreSQL gagnagrunninum með þessum tengingarupplýsingum. 

## Hluti 1: Ættir og landsvæði í Norður konungsríkinu

1. Skrifuð er SQL fyrirspurn sem finnur samsvörun á milli **ríkja** í *Game of Thrones* heiminum
   (úr `atlas.kingdoms`) og **húsum** (úr `got.houses`) út frá því hvaða hús tilheyra hvaða
   ríki. Sýnd eru öll ríki og öll hús, líka þau sem eru ekki með samsvörun.
    - Mappan er upsertuð í töfluna `<teymi>.tables_mapping` með dálkunum `kingdom_id`, `house_id`.
2. Skrifuð er SQL fyrirspurn með CTE sem finnur samsvörun á milli staða og húsa. Hér er markmiðið að
   finna **gagntæka vörpun** (one-to-one mapping), þar sem hver staður úr `atlas.locations` mappast
   á nákvæmlega eitt hús úr `got.houses`.
    - Niðurstöður fyrir allan heiminn eru upsertaðar í töfluna `<teymi>.tables_mapping` með dálkunum
      `house_id`, `location_id`.
    - Sýndar eru niðurstöður fyrir Norðrið. 
3. Skrifuð er SQL fyrirspurn með CTE sem finnur stærstu ættir allra norðanmanna (þ.e. persónur sem eru
   hliðhollar húsinu *The North*). Aðeins eru notaðar ættir sem hafa fleiri en 5 hliðholla
   meðlimi í úttakinu. Úttakið er raðað eftir fjölda meðlima (stærstu fyrst) og í stafrófsröð.


## Hluti 2: Aðalpersónur í Krúnuleikum

Búið er til PostgreSQL view sem heitir `lausn.v_pov_characters_human_readable` með CTE sem
inniheldur allar POV-persónur (Point of View) úr *A Song of Ice and Fire* bókunum ásamt eftirfarandi
upplýsingum: 

1. Nafn með titil (ef fleiri en einn, þá er fyrsti valinn) sem `full_name`, kyn (`gender` sem er
   annaðhvort `M` eða `F`), nafn foreldra (`father` og `mother`) og maka (`spouse`)
   persónunnar.
2. Fæðingar- og dánarár (`born` og `died`) sem gefin eru í formatinu AC eða BC eru gefin sem heiltölur: 
    - AC árin verða jákvæðar tölur (t.d. 299 AC verður 299).
    - BC árin verða neikvæðar tölur (t.d. 3 BC verður -3).
3. Aldur persónunnar (`age`), reiknaður út frá fæðingarárinu `born` og dánarárinu `died`.
   Ef dánarár er ekki til staðar (persónan er enn á lífi), er aldurinn reiknaður út frá 300 AC.
4. Gefið er til kynna hvort persónan sé enn á lífi eða ekki (með `alive` flag og er tvíundarbreyta).
5. Lista yfir bókaheiti sem persónan kemur fyrir í, í réttri röð eftir útgáfuárum.

Búið til SQL **SELECT skipun** sem sýnir upplýsingar fyrir allar POV-persónur úr viewinu og
raðið eftir þeim sem eru enn á lífi, svo eftir aldri í lækkandi röð.

