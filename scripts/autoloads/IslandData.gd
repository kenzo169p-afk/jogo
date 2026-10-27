extends Node

# IslandData.gd - Global balance table, 10 anime islands, passives table, level/XP formulas.
# Compliant with Godot 4.x - Compatibility renderer.

const MAX_LEVEL = 250
const LEVEL_DAMAGE_BONUS_PER_LEVEL = 0.014 # +1.4% damage per level above 1

const RARITY_COMMON = "Comum"
const RARITY_RARE = "Raro"
const RARITY_EPIC = "Épico"
const RARITY_LEGENDARY = "Lendário"
const RARITY_MYTHIC = "Mítico"

const RARITY_CHANCES = {
	RARITY_COMMON: 0.60,
	RARITY_RARE: 0.25,
	RARITY_EPIC: 0.10,
	RARITY_LEGENDARY: 0.045,
	RARITY_MYTHIC: 0.005
}

const RARITY_COLORS = {
	RARITY_COMMON: Color(0.75, 0.75, 0.75),
	RARITY_RARE: Color(0.2, 0.65, 1.0),
	RARITY_EPIC: Color(0.75, 0.2, 0.95),
	RARITY_LEGENDARY: Color(1.0, 0.75, 0.1),
	RARITY_MYTHIC: Color(1.0, 0.15, 0.25)
}

# --- PASSIVES DATABASE & REROLL ODDS ---
# Odds: Comum 50%, Raro 30%, Épico 13%, Lendário 6%, Mítico 1%
const PASSIVE_TIER_ODDS = {
	RARITY_COMMON: 0.50,
	RARITY_RARE: 0.30,
	RARITY_EPIC: 0.13,
	RARITY_LEGENDARY: 0.06,
	RARITY_MYTHIC: 0.01
}

const PASSIVES: Dictionary = {
	"none": {
		"id": "none",
		"name": "Nenhuma",
		"rarity": "Nenhuma",
		"dps_mult": 1.0,
		"atk_speed_mult": 1.0,
		"coin_bonus": 0.0,
		"xp_bonus": 0.0,
		"description": "Sem efeitos adicionais"
	},
	"ataque_1": {
		"id": "ataque_1",
		"name": "Ataque I",
		"rarity": RARITY_COMMON,
		"dps_mult": 1.10, # +10% Dano
		"atk_speed_mult": 1.0,
		"coin_bonus": 0.0,
		"xp_bonus": 0.0,
		"description": "+10% Dano"
	},
	"agilidade_1": {
		"id": "agilidade_1",
		"name": "Agilidade I",
		"rarity": RARITY_COMMON,
		"dps_mult": 1.0,
		"atk_speed_mult": 1.10, # +10% Vel. Ataque
		"coin_bonus": 0.0,
		"xp_bonus": 0.0,
		"description": "+10% Vel. de Ataque"
	},
	"ataque_2": {
		"id": "ataque_2",
		"name": "Ataque II",
		"rarity": RARITY_RARE,
		"dps_mult": 1.25, # +25% Dano
		"atk_speed_mult": 1.0,
		"coin_bonus": 0.0,
		"xp_bonus": 0.0,
		"description": "+25% Dano"
	},
	"magnata_1": {
		"id": "magnata_1",
		"name": "Magnata I",
		"rarity": RARITY_RARE,
		"dps_mult": 1.0,
		"atk_speed_mult": 1.0,
		"coin_bonus": 0.35, # +35% Moedas
		"xp_bonus": 0.0,
		"description": "+35% Moedas ganhas"
	},
	"guerreiro_feroz": {
		"id": "guerreiro_feroz",
		"name": "Guerreiro Feroz",
		"rarity": RARITY_EPIC,
		"dps_mult": 1.60, # +60% Dano
		"atk_speed_mult": 1.0,
		"coin_bonus": 0.0,
		"xp_bonus": 0.0,
		"description": "+60% Dano"
	},
	"estudioso": {
		"id": "estudioso",
		"name": "Estudioso",
		"rarity": RARITY_EPIC,
		"dps_mult": 1.0,
		"atk_speed_mult": 1.0,
		"coin_bonus": 0.0,
		"xp_bonus": 0.75, # +75% XP
		"description": "+75% XP ganho por abate"
	},
	"destruidor": {
		"id": "destruidor",
		"name": "Destruidor",
		"rarity": RARITY_LEGENDARY,
		"dps_mult": 2.30, # +130% Dano
		"atk_speed_mult": 1.0,
		"coin_bonus": 0.0,
		"xp_bonus": 0.0,
		"description": "+130% Dano"
	},
	"divindade_celestial": {
		"id": "divindade_celestial",
		"name": "Divindade Celestial",
		"rarity": RARITY_MYTHIC,
		"dps_mult": 4.00, # +300% Dano
		"atk_speed_mult": 1.40, # +40% Vel. Ataque
		"coin_bonus": 1.00, # +100% Moedas
		"xp_bonus": 0.0,
		"description": "+300% Dano, +40% Vel. Ataque, +100% Moedas"
	}
}

# --- THE 10 ANIME ISLANDS TABLE (Updated with Boss HP, 2x Drops, Reroll Costs, XP and Single Unified Currency) ---
const CURRENCY_ID = "coins"
const CURRENCY_NAME = "Moedas"

const ISLANDS: Dictionary = {
	1: {
		"id": 1,
		"name": "Vila da Folha (Naruto)",
		"anime": "Naruto",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Ninja Renegado",
		"mob_hp": 100,
		"mob_drop": 20, # Dobro do anterior (10 -> 20)
		"mob_xp": 15,
		"boss_name": "Chefe Madara Uchiha",
		"boss_hp": 1000,
		"boss_drop": 100, # 5x mais moedas (20 -> 100)
		"boss_xp": 75,   # 5x mob xp
		"capsule_cost": 100,
		"reroll_cost": 50,
		"unlock_cost": 0,
		"unlock_currency_id": "",
		"unlock_currency_name": "Gratuito",
		"world_position": Vector3(0, 0, 0),
		"ground_color": Color(0.28, 0.55, 0.28),
		"fighters": {
			RARITY_COMMON: {"name": "Clone de Naruto", "dps": 25, "mesh_color": Color(0.95, 0.45, 0.05)},
			RARITY_RARE: {"name": "Sasuke Genin", "dps": 65, "mesh_color": Color(0.18, 0.3, 0.55)},
			RARITY_EPIC: {"name": "Kakashi do Sharingan", "dps": 160, "mesh_color": Color(0.4, 0.5, 0.6)},
			RARITY_LEGENDARY: {"name": "Itachi Akatsuki", "dps": 420, "mesh_color": Color(0.75, 0.1, 0.1)},
			RARITY_MYTHIC: {"name": "Naruto Modo Sábio", "dps": 1250, "mesh_color": Color(1.0, 0.75, 0.0)}
		}
	},
	2: {
		"id": 2,
		"name": "Reino de Liones (Nanatsu no Taizai)",
		"anime": "Nanatsu no Taizai",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Cavaleiro Sagrado Rebelde",
		"mob_hp": 500,
		"mob_drop": 120, # Dobro (60 -> 120)
		"mob_xp": 50,
		"boss_name": "Chefe Rei Demônio",
		"boss_hp": 5000,
		"boss_drop": 600, # 5x mais moedas (120 -> 600)
		"boss_xp": 250,   # 5x mob xp
		"capsule_cost": 600,
		"reroll_cost": 300,
		"unlock_cost": 1000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -500),
		"ground_color": Color(0.25, 0.45, 0.35),
		"fighters": {
			RARITY_COMMON: {"name": "Diane Gigante", "dps": 130, "mesh_color": Color(0.7, 0.45, 0.2)},
			RARITY_RARE: {"name": "Ban da Ganância", "dps": 320, "mesh_color": Color(0.75, 0.2, 0.2)},
			RARITY_EPIC: {"name": "King Rei das Fadas", "dps": 800, "mesh_color": Color(0.2, 0.7, 0.4)},
			RARITY_LEGENDARY: {"name": "Meliodas Dragão da Fúria", "dps": 2200, "mesh_color": Color(0.55, 0.25, 0.7)},
			RARITY_MYTHIC: {"name": "Escanor O Todo-Poderoso", "dps": 6500, "mesh_color": Color(1.0, 0.65, 0.1)}
		}
	},
	3: {
		"id": 3,
		"name": "Região dos Treinadores (Pokémon)",
		"anime": "Pokémon",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Membro da Equipe Rocket",
		"mob_hp": 2500,
		"mob_drop": 700, # Dobro (350 -> 700)
		"mob_xp": 180,
		"boss_name": "Chefe Mewtwo Armadurado",
		"boss_hp": 25000,
		"boss_drop": 3500, # 5x mais moedas (700 -> 3500)
		"boss_xp": 900,   # 5x mob xp
		"capsule_cost": 3500,
		"reroll_cost": 1750,
		"unlock_cost": 5000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -1000),
		"ground_color": Color(0.35, 0.65, 0.25),
		"fighters": {
			RARITY_COMMON: {"name": "Pikachu Trovão", "dps": 700, "mesh_color": Color(0.95, 0.8, 0.1)},
			RARITY_RARE: {"name": "Charizard Chamas", "dps": 1750, "mesh_color": Color(0.9, 0.45, 0.15)},
			RARITY_EPIC: {"name": "Lucario da Aura", "dps": 4400, "mesh_color": Color(0.15, 0.5, 0.75)},
			RARITY_LEGENDARY: {"name": "Mewtwo Psíquico", "dps": 12000, "mesh_color": Color(0.65, 0.35, 0.75)},
			RARITY_MYTHIC: {"name": "Rayquaza Celestial", "dps": 35000, "mesh_color": Color(0.18, 0.8, 0.45)}
		}
	},
	4: {
		"id": 4,
		"name": "Grande Rota (One Piece)",
		"anime": "One Piece",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Marujo da Marinha",
		"mob_hp": 12000,
		"mob_drop": 4000, # Dobro (2000 -> 4000)
		"mob_xp": 600,
		"boss_name": "Chefe Kaido Rei das Feras",
		"boss_hp": 120000,
		"boss_drop": 20000, # 5x mais moedas (4000 -> 20000)
		"boss_xp": 3000,   # 5x mob xp
		"capsule_cost": 20000,
		"reroll_cost": 10000,
		"unlock_cost": 25000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -1500),
		"ground_color": Color(0.82, 0.72, 0.45),
		"fighters": {
			RARITY_COMMON: {"name": "Usopp Deus Atirador", "dps": 3500, "mesh_color": Color(0.85, 0.7, 0.2)},
			RARITY_RARE: {"name": "Sanji Perna Negra", "dps": 8500, "mesh_color": Color(0.18, 0.22, 0.3)},
			RARITY_EPIC: {"name": "Zoro Três Espadas", "dps": 22000, "mesh_color": Color(0.1, 0.55, 0.25)},
			RARITY_LEGENDARY: {"name": "Luffy Gear 4 Snakeman", "dps": 58000, "mesh_color": Color(0.9, 0.15, 0.15)},
			RARITY_MYTHIC: {"name": "Luffy Gear 5 Deus do Sol", "dps": 170000, "mesh_color": Color(0.98, 0.98, 1.0)}
		}
	},
	5: {
		"id": 5,
		"name": "Academia U.A. (Boku no Hero)",
		"anime": "Boku no Hero",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Nomu Guerreiro",
		"mob_hp": 60000,
		"mob_drop": 24000, # Dobro (12000 -> 24000)
		"mob_xp": 2200,
		"boss_name": "Chefe All For One",
		"boss_hp": 600000,
		"boss_drop": 120000, # 5x mais moedas (24000 -> 120000)
		"boss_xp": 11000,   # 5x mob xp
		"capsule_cost": 120000,
		"reroll_cost": 60000,
		"unlock_cost": 150000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -2000),
		"ground_color": Color(0.38, 0.44, 0.5),
		"fighters": {
			RARITY_COMMON: {"name": "Deku Full Cowl", "dps": 18000, "mesh_color": Color(0.15, 0.75, 0.5)},
			RARITY_RARE: {"name": "Bakugo Explosão Total", "dps": 45000, "mesh_color": Color(0.85, 0.35, 0.05)},
			RARITY_EPIC: {"name": "Todoroki Fogo e Gelo", "dps": 110000, "mesh_color": Color(0.2, 0.6, 0.85)},
			RARITY_LEGENDARY: {"name": "Endeavor Chamas Infernais", "dps": 300000, "mesh_color": Color(0.8, 0.15, 0.15)},
			RARITY_MYTHIC: {"name": "All Might Símbolo da Paz", "dps": 900000, "mesh_color": Color(1.0, 0.8, 0.1)}
		}
	},
	6: {
		"id": 6,
		"name": "Estádio Egoísta (Blue Lock)",
		"anime": "Blue Lock",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Zagueiro Holográfico",
		"mob_hp": 300000,
		"mob_drop": 140000, # Dobro (70000 -> 140000)
		"mob_xp": 8500,
		"boss_name": "Chefe Noel Noa - Atacante Mundial",
		"boss_hp": 3000000,
		"boss_drop": 700000, # 5x mais moedas (140000 -> 700000)
		"boss_xp": 42500,    # 5x mob xp
		"capsule_cost": 700000,
		"reroll_cost": 350000,
		"unlock_cost": 900000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -2500),
		"ground_color": Color(0.12, 0.32, 0.52),
		"fighters": {
			RARITY_COMMON: {"name": "Bachira Monstro do Drible", "dps": 90000, "mesh_color": Color(0.95, 0.6, 0.1)},
			RARITY_RARE: {"name": "Chigiri Pantera Veloz", "dps": 220000, "mesh_color": Color(0.9, 0.15, 0.45)},
			RARITY_EPIC: {"name": "Barou O Rei do Campo", "dps": 550000, "mesh_color": Color(0.5, 0.1, 0.3)},
			RARITY_LEGENDARY: {"name": "Nagi Gênio do Domínio", "dps": 1500000, "mesh_color": Color(0.8, 0.82, 0.85)},
			RARITY_MYTHIC: {"name": "Isagi Metavisão Máxima", "dps": 4500000, "mesh_color": Color(0.0, 1.0, 0.55)}
		}
	},
	7: {
		"id": 7,
		"name": "Ringue Kamogawa (Hajime no Ippo)",
		"anime": "Hajime no Ippo",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Boxeador Rank 1",
		"mob_hp": 1500000,
		"mob_drop": 800000, # Dobro (400000 -> 800000)
		"mob_xp": 35000,
		"boss_name": "Chefe Ricardo Martinez Invicto",
		"boss_hp": 15000000,
		"boss_drop": 4000000, # 5x mais moedas (800000 -> 4000000)
		"boss_xp": 175000,   # 5x mob xp
		"capsule_cost": 4000000,
		"reroll_cost": 2000000,
		"unlock_cost": 5000000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -3000),
		"ground_color": Color(0.58, 0.45, 0.32),
		"fighters": {
			RARITY_COMMON: {"name": "Aoki Golpe Duplo", "dps": 450000, "mesh_color": Color(0.85, 0.45, 0.15)},
			RARITY_RARE: {"name": "Kimura Dragão Branco", "dps": 1100000, "mesh_color": Color(0.2, 0.45, 0.7)},
			RARITY_EPIC: {"name": "Sendo Tigre de Naniwa", "dps": 2800000, "mesh_color": Color(0.8, 0.3, 0.1)},
			RARITY_LEGENDARY: {"name": "Takamura Campeão Mundial", "dps": 7500000, "mesh_color": Color(1.0, 0.75, 0.15)},
			RARITY_MYTHIC: {"name": "Ippo Dempsey Roll Supremo", "dps": 22000000, "mesh_color": Color(0.1, 0.8, 0.9)}
		}
	},
	8: {
		"id": 8,
		"name": "Planeta Namekusei (Dragon Ball Z)",
		"anime": "Dragon Ball Z",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Soldado de Elite do Freeza",
		"mob_hp": 8000000,
		"mob_drop": 5000000, # Dobro (2500000 -> 5000000)
		"mob_xp": 150000,
		"boss_name": "Chefe Imperador Freeza 100%",
		"boss_hp": 80000000,
		"boss_drop": 25000000, # 5x mais moedas (5000000 -> 25000000)
		"boss_xp": 750000,    # 5x mob xp
		"capsule_cost": 25000000,
		"reroll_cost": 12500000,
		"unlock_cost": 30000000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -3500),
		"ground_color": Color(0.28, 0.52, 0.42),
		"fighters": {
			RARITY_COMMON: {"name": "Piccolo Guerreiro Namek", "dps": 2500000, "mesh_color": Color(0.2, 0.7, 0.4)},
			RARITY_RARE: {"name": "Vegeta Príncipe Saiyajin", "dps": 6000000, "mesh_color": Color(0.15, 0.25, 0.65)},
			RARITY_EPIC: {"name": "Trunks Espada do Futuro", "dps": 15000000, "mesh_color": Color(0.35, 0.2, 0.5)},
			RARITY_LEGENDARY: {"name": "Gohan Super Saiyajin 2", "dps": 40000000, "mesh_color": Color(0.95, 0.85, 0.2)},
			RARITY_MYTHIC: {"name": "Goku Super Saiyajin Lendário", "dps": 120000000, "mesh_color": Color(1.0, 0.65, 0.05)}
		}
	},
	9: {
		"id": 9,
		"name": "Mundo dos Stands (JoJo's Bizarre Adventure)",
		"anime": "JoJo's Bizarre Adventure",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Usuário de Stand Inimigo",
		"mob_hp": 45000000,
		"mob_drop": 30000000, # Dobro (15000000 -> 30000000)
		"mob_xp": 700000,
		"boss_name": "Chefe DIO Brando Over Heaven",
		"boss_hp": 450000000,
		"boss_drop": 150000000, # 5x mais moedas (30000000 -> 150000000)
		"boss_xp": 3500000,    # 5x mob xp
		"capsule_cost": 150000000,
		"reroll_cost": 75000000,
		"unlock_cost": 200000000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -4000),
		"ground_color": Color(0.35, 0.2, 0.4),
		"fighters": {
			RARITY_COMMON: {"name": "Polnareff & Silver Chariot", "dps": 14000000, "mesh_color": Color(0.75, 0.78, 0.82)},
			RARITY_RARE: {"name": "Josuke & Crazy Diamond", "dps": 35000000, "mesh_color": Color(0.95, 0.4, 0.55)},
			RARITY_EPIC: {"name": "DIO & The World", "dps": 90000000, "mesh_color": Color(0.95, 0.8, 0.15)},
			RARITY_LEGENDARY: {"name": "Jotaro & Star Platinum", "dps": 230000000, "mesh_color": Color(0.4, 0.3, 0.85)},
			RARITY_MYTHIC: {"name": "Giorno Gold Experience Requiem", "dps": 700000000, "mesh_color": Color(1.0, 0.9, 0.4)}
		}
	},
	10: {
		"id": 10,
		"name": "Torneio do Poder (Dragon Ball Super)",
		"anime": "Dragon Ball Super",
		"currency_id": CURRENCY_ID,
		"currency_name": CURRENCY_NAME,
		"mob_name": "Guerreiro do Multiverso",
		"mob_hp": 300000000,
		"mob_drop": 200000000, # Dobro (100000000 -> 200000000)
		"mob_xp": 3500000,
		"boss_name": "Chefe Jiren Poder Supremo",
		"boss_hp": 3000000000,
		"boss_drop": 1000000000, # 5x mais moedas (200000000 -> 1000000000)
		"boss_xp": 17500000,    # 5x mob xp
		"capsule_cost": 1000000000,
		"reroll_cost": 500000000,
		"unlock_cost": 1500000000,
		"unlock_currency_id": CURRENCY_ID,
		"unlock_currency_name": CURRENCY_NAME,
		"world_position": Vector3(0, 0, -4500),
		"ground_color": Color(0.15, 0.2, 0.32),
		"fighters": {
			RARITY_COMMON: {"name": "Goku Super Saiyajin Deus", "dps": 90000000, "mesh_color": Color(0.95, 0.2, 0.2)},
			RARITY_RARE: {"name": "Vegeta Super Saiyajin Blue", "dps": 220000000, "mesh_color": Color(0.1, 0.7, 0.95)},
			RARITY_EPIC: {"name": "Gogeta Blue Cósmico", "dps": 600000000, "mesh_color": Color(0.4, 0.3, 0.9)},
			RARITY_LEGENDARY: {"name": "Jiren O Inabalável", "dps": 1600000000, "mesh_color": Color(0.9, 0.15, 0.1)},
			RARITY_MYTHIC: {"name": "Goku Instinto Superior Completo", "dps": 5000000000, "mesh_color": Color(1.0, 1.0, 1.0)}
		}
	}
}

static func get_island(island_id: int) -> Dictionary:
	if ISLANDS.has(island_id):
		return ISLANDS[island_id]
	return ISLANDS[1]

# --- XP & LEVEL FORMULAS ---
static func get_xp_needed(level: int) -> int:
	if level >= MAX_LEVEL:
		return 999999999
	return int(100.0 * pow(1.035, float(level - 1)) + float(level * 50))

static func calculate_fighter_dps(base_dps: float, level: int, passive_id: String) -> float:
	var level_mult: float = 1.0 + (float(level - 1) * LEVEL_DAMAGE_BONUS_PER_LEVEL)
	var p_info = PASSIVES.get(passive_id, PASSIVES["none"])
	var passive_mult: float = float(p_info.get("dps_mult", 1.0))
	return base_dps * level_mult * passive_mult

static func calculate_fighter_atk_speed(passive_id: String) -> float:
	var p_info = PASSIVES.get(passive_id, PASSIVES["none"])
	return float(p_info.get("atk_speed_mult", 1.0))

static func get_passive_info(passive_id: String) -> Dictionary:
	return PASSIVES.get(passive_id, PASSIVES["none"])

# Rolls a random passive based on tier probabilities
static func roll_random_passive() -> String:
	var roll = randf()
	var tier = RARITY_COMMON
	
	if roll < PASSIVE_TIER_ODDS[RARITY_MYTHIC]: # 1%
		tier = RARITY_MYTHIC
	elif roll < PASSIVE_TIER_ODDS[RARITY_MYTHIC] + PASSIVE_TIER_ODDS[RARITY_LEGENDARY]: # 1% + 6% = 7%
		tier = RARITY_LEGENDARY
	elif roll < PASSIVE_TIER_ODDS[RARITY_MYTHIC] + PASSIVE_TIER_ODDS[RARITY_LEGENDARY] + PASSIVE_TIER_ODDS[RARITY_EPIC]: # 7% + 13% = 20%
		tier = RARITY_EPIC
	elif roll < PASSIVE_TIER_ODDS[RARITY_MYTHIC] + PASSIVE_TIER_ODDS[RARITY_LEGENDARY] + PASSIVE_TIER_ODDS[RARITY_EPIC] + PASSIVE_TIER_ODDS[RARITY_RARE]: # 20% + 30% = 50%
		tier = RARITY_RARE
	else:
		tier = RARITY_COMMON
		
	# Select from matching tier
	var candidates: Array = []
	for pid in PASSIVES:
		if pid == "none":
			continue
		if PASSIVES[pid]["rarity"] == tier:
			candidates.append(pid)
			
	if not candidates.is_empty():
		return candidates[randi() % candidates.size()]
	return "ataque_1"

static func format_number(val: float) -> String:
	if val >= 1_000_000_000_000.0:
		return "%.2fT" % (val / 1_000_000_000_000.0)
	elif val >= 1_000_000_000.0:
		return "%.2fB" % (val / 1_000_000_000.0)
	elif val >= 1_000_000.0:
		return "%.2fM" % (val / 1_000_000.0)
	elif val >= 1_000.0:
		return "%.1fK" % (val / 1_000.0)
	else:
		return str(int(val))

static func format_time(seconds: float) -> String:
	var total_sec = int(max(0.0, seconds))
	var hours = total_sec / 3600
	var minutes = (total_sec % 3600) / 60
	var secs = total_sec % 60
	if hours > 0:
		return "%dh %02dm" % [hours, minutes]
	else:
		return "%02dm %02ds" % [minutes, secs]

# --- TABELA GLOBAL DE CONQUISTAS ---
# 1. Tempo Jogado (1h, 2h, 5h, 10h, 24h, 48h, 72h, 100h) -> +0.25% Sorte nos giros da ilha
# 2. Dinheiro Coletado (10, 100, 1.000, 100.000, 10.000.000, 100.000.000.000.000) -> +0.25% Moedas por mob/chefe morto
# 3. Inimigos Mortos (1, 10, 50, 100, 200, 500, 1.000, 2.000) -> +0.25% Dano em qualquer inimigo
# 4. Giros de Personagem (10, 100, 1.000, 5.000, 10.000) -> +0.25% Sorte nos giros da ilha
const ACHIEVEMENTS: Array = [
	# 1. TEMPO JOGADO (+0.25% de sorte nos giros de personagens da ilha)
	{
		"id": "time_1",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Aventureiro Iniciante I",
		"description": "Jogue por 1 hora",
		"target": 3600.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "time_2",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Aventureiro Focado II",
		"description": "Jogue por 2 horas",
		"target": 7200.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "time_5",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Guerreiro Dedicado III",
		"description": "Jogue por 5 horas",
		"target": 18000.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "time_10",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Lutador Experiente IV",
		"description": "Jogue por 10 horas",
		"target": 36000.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "time_24",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Dia Completo V",
		"description": "Jogue por 24 horas",
		"target": 86400.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "time_48",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Veterano do Anime VI",
		"description": "Jogue por 48 horas",
		"target": 172800.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "time_72",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Mestre Incansável VII",
		"description": "Jogue por 72 horas",
		"target": 259200.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "time_100",
		"category": "time",
		"category_name": "Tempo Jogado",
		"icon": "⏳",
		"title": "Lenda Suprema VIII",
		"description": "Jogue por 100 horas",
		"target": 360000.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},

	# 2. DINHEIRO COLETADO (+0.25% de moedas a mais por inimigo/chefe morto)
	{
		"id": "coins_10",
		"category": "coins",
		"category_name": "Dinheiro Coletado",
		"icon": "🪙",
		"title": "Primeiros Tostões I",
		"description": "Colete 10 moedas",
		"target": 10.0,
		"reward_type": "coins",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Moedas de Mobs/Chefes"
	},
	{
		"id": "coins_100",
		"category": "coins",
		"category_name": "Dinheiro Coletado",
		"icon": "🪙",
		"title": "Bolsos Cheios II",
		"description": "Colete 100 moedas",
		"target": 100.0,
		"reward_type": "coins",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Moedas de Mobs/Chefes"
	},
	{
		"id": "coins_1000",
		"category": "coins",
		"category_name": "Dinheiro Coletado",
		"icon": "🪙",
		"title": "Pequena Fortuna III",
		"description": "Colete 1.000 moedas",
		"target": 1000.0,
		"reward_type": "coins",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Moedas de Mobs/Chefes"
	},
	{
		"id": "coins_100000",
		"category": "coins",
		"category_name": "Dinheiro Coletado",
		"icon": "🪙",
		"title": "Cofre de Ouro IV",
		"description": "Colete 100.000 moedas",
		"target": 100000.0,
		"reward_type": "coins",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Moedas de Mobs/Chefes"
	},
	{
		"id": "coins_10000000",
		"category": "coins",
		"category_name": "Dinheiro Coletado",
		"icon": "🪙",
		"title": "Magnata Multimilionário V",
		"description": "Colete 10.000.000 moedas",
		"target": 10000000.0,
		"reward_type": "coins",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Moedas de Mobs/Chefes"
	},
	{
		"id": "coins_100000000000000",
		"category": "coins",
		"category_name": "Dinheiro Coletado",
		"icon": "🪙",
		"title": "Lorde Trilionário VI",
		"description": "Colete 100.000.000.000.000 moedas",
		"target": 100000000000000.0,
		"reward_type": "coins",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Moedas de Mobs/Chefes"
	},

	# 3. INIMIGO MORTO (CHEFE OU INIMIGO COMUM) (+0.25% de dano em qualquer inimigo)
	{
		"id": "kills_1",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Primeiro Sangue I",
		"description": "Derrote 1 inimigo ou chefe",
		"target": 1.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},
	{
		"id": "kills_10",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Guerreiro Emergente II",
		"description": "Derrote 10 inimigos ou chefes",
		"target": 10.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},
	{
		"id": "kills_50",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Caçador Hábil III",
		"description": "Derrote 50 inimigos ou chefes",
		"target": 50.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},
	{
		"id": "kills_100",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Centurião dos Campos IV",
		"description": "Derrote 100 inimigos ou chefes",
		"target": 100.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},
	{
		"id": "kills_200",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Destruidor da Vanguarda V",
		"description": "Derrote 200 inimigos ou chefes",
		"target": 200.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},
	{
		"id": "kills_500",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Exterminador Implacável VI",
		"description": "Derrote 500 inimigos ou chefes",
		"target": 500.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},
	{
		"id": "kills_1000",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Lenda das Batalhas VII",
		"description": "Derrote 1.000 inimigos ou chefes",
		"target": 1000.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},
	{
		"id": "kills_2000",
		"category": "enemies",
		"category_name": "Inimigos Derrotados",
		"icon": "⚔️",
		"title": "Conquistador Supremo VIII",
		"description": "Derrote 2.000 inimigos ou chefes",
		"target": 2000.0,
		"reward_type": "damage",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Dano em Qualquer Inimigo"
	},

	# 4. GIRO DE PERSONAGEM (+0.25% de sorte nos giros de personagens da ilha)
	{
		"id": "spins_10",
		"category": "spins",
		"category_name": "Giros de Personagem",
		"icon": "🎰",
		"title": "Colecionador Iniciante I",
		"description": "Gire personagens da ilha 10 vezes",
		"target": 10.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "spins_100",
		"category": "spins",
		"category_name": "Giros de Personagem",
		"icon": "🎰",
		"title": "Invocador Confiante II",
		"description": "Gire personagens da ilha 100 vezes",
		"target": 100.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "spins_1000",
		"category": "spins",
		"category_name": "Giros de Personagem",
		"icon": "🎰",
		"title": "Mestre Invocador III",
		"description": "Gire personagens da ilha 1.000 vezes",
		"target": 1000.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "spins_5000",
		"category": "spins",
		"category_name": "Giros de Personagem",
		"icon": "🎰",
		"title": "Senhor dos Destinos IV",
		"description": "Gire personagens da ilha 5.000 vezes",
		"target": 5000.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	},
	{
		"id": "spins_10000",
		"category": "spins",
		"category_name": "Giros de Personagem",
		"icon": "🎰",
		"title": "Divindade dos Giros V",
		"description": "Gire personagens da ilha 10.000 vezes",
		"target": 10000.0,
		"reward_type": "luck",
		"reward_val": 0.0025,
		"reward_text": "+0.25% Sorte na Ilha"
	}
]
