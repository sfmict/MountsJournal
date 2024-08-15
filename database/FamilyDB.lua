local _, ns = ...


ns.familyDB = {
	["Amphibian"] = {
		["Crawgs"] = 100,
		["Toads"] = 101,
	},
	["Arachnids"] = {
		["Blood Ticks"] = 200,
		["Scorpions"] = 201,
		["Spiders"] = 202,
		["Undercrawlers"] = 203,
	},
	["Bats"] = 300,
	["Birds"] = {
		["Albatross"] = 400,
		["Chickens"] = 401,
		["Cranes"] = 402,
		["Crows"] = 403,
		["Dread Ravens"] = 404,
		["Eagle"] = 405,
		["Hawkstriders"] = 406,
		["Mechanical Birds"] = 407,
		["Owl"] = 408,
		["Owlbear"] = 409,
		["Pandaren Phoenixes"] = 410,
		["Parrots"] = 411,
		["Peafowl"] = 412,
		["Phoenixes"] = 413,
		["Raptora"] = 414,
		["Roc"] = 415,
		["Tallstriders"] = 416,
		["Talonbirds"] = 417,
		["Vultures"] = 418,
	},
	["Bovids"] = {
		["Clefthooves"] = 500,
		["Goats"] = 501,
		["Rams"] = 502,
		["Ruinstriders"] = 503,
		["Talbuks"] = 504,
		["Tauralus"] = 505,
		["Yaks"] = 506,
	},
	["Carnivorans"] = {
		["Bears"] = 600,
		["Foxes"] = 601,
		["Gargon"] = 602,
		["Hounds"] = 603,
		["Hyenas"] = 604,
		["Ottuk"] = 605,
		["Quilen"] = 606,
		["Vulpin"] = 607,
	},
	["Cats"] = {
		["Bipedal Cat"] = 700,
		["Dreamsaber"] = 701,
		["Lions"] = 702,
		["Manasabers"] = 703,
		["Mechanical Cats"] = 704,
		["Others"] = 705,
		["Sabers"] = 706,
		["Stone Cats"] = 707,
		["Tigers"] = 708,
		["Lynx"] = 709,
	},
	["Crabs"] = 800,
	["Demons"] = {
		["Demonic Hounds"] = 900,
		["Demonic Steeds"] = 901,
		["Felsabers"] = 902,
		["Infernals"] = 903,
		["Ur'zul"] = 904,
	},
	["Devourer"] = {
		["Animite"] = 1000,
		["Gorger"] = 1001,
		["Mauler"] = 1002,
	},
	["Dinosaurs"] = {
		["Brutosaurs"] = 1100,
		["Direhorns"] = 1101,
		["Falcosaurs"] = 1102,
		["Pterrordaxes"] = 1103,
		["Raptors"] = 1104,
	},
	["Dragonhawks"] = 1200,
	["Drakes"] = {
		["Cloud Serpents"] = 1300,
		["Drakes"] = 1301,
		["Grand Drakes"] = 1302,
		["Nether Drakes"] = 1303,
		["Others"] = 1304,
		["Proto-Drakes"] = 1305,
		["Stone Drakes"] = 1306,
		["Undead Drakes"] = 1307,
		["Wind Drakes"] = 1308,
	},
	["Elementals"] = {
		["Core Hounds"] = 1400,
		["Others"] = 1401,
		["Phoenixes"] = 1402,
		["Sabers"] = 1403,
		["Sporebat"] = 1404,
		["Stone Drakes"] = 1405,
		["Wind Drakes"] = 1406,
	},
	["Feathermanes"] = {
		["Gryphons"] = 1500,
		["Hippogryphs"] = 1501,
		["Larion"] = 1502,
		["Wolfhawks"] = 1503,
		["Wyverns"] = 1504,
	},
	["Fish"] = {
		["Fish"] = 1600,
		["Seahorses"] = 1601,
		["Stingrays"] = 1602,
	},
	["Gargoyle"] = 1700,
	["Horses"] = {
		["Chargers"] = 1800,
		["Demonic Steeds"] = 1801,
		["Flying Steeds"] = 1802,
		["Horned Steeds"] = 1803,
		["Mechanical Steeds"] = 1804,
		["Mountain Horses"] = 1805,
		["Steeds"] = 1806,
		["Undead Steeds"] = 1807,
	},
	["Humanoids"] = {
		["Gorger"] = 1900,
		["Gronnlings"] = 1901,
		["Murloc"] = 1902,
		["Others"] = 1903,
		["Yetis"] = 1904,
	},
	["Insects"] = {
		["Animite"] = 2000,
		["Aqir Flyers"] = 2001,
		["Beetle"] = 2002,
		["Flies"] = 2003,
		["Gorm"] = 2004,
		["Krolusks"] = 2005,
		["Moth"] = 2006,
		["Others"] = 2007,
		["Silithids"] = 2008,
		["Wasp"] = 2009,
		["Water Striders"] = 2010,
		["Skyrazor"] = 2011,
		["Skyflayer"] = 2012,
		["Bees"] = 2013,
	},
	["Jellyfish"] = 2100,
	["Mollusc"] = {
		["Slug"] = 2200,
		["Snail"] = 2201,
	},
	["Rays"] = {
		["Fathom Rays"] = 2300,
		["Mana Rays"] = 2301,
		["Nether Rays"] = 2302,
		["Stingrays"] = 2303,
	},
	["Razorwing"] = 2400,
	["Reptiles"] = {
		["Armoredon"] = 2500,
		["Basilisks"] = 2501,
		["Crocolisks"] = 2502,
		["Kodos"] = 2503,
		["Mushan"] = 2504,
		["N'Zoth Serpents"] = 2505,
		["Others"] = 2506,
		["Sea Serpents"] = 2507,
		["Shardhides"] = 2508,
		["Snapdragons"] = 2509,
		["Thunder Lizard"] = 2510,
		["Turtles"] = 2511,
	},
	["Rodent"] = {
		["Rabbit"] = 2600,
		["Rats"] = 2601,
		["Mudnose"] = 2602,
	},
	["Rylaks"] = 2700,
	["Ungulates"] = {
		["Alpacas"] = 2800,
		["Boars"] = 2801,
		["Camels"] = 2802,
		["Cervid"] = 2803,
		["Elekks"] = 2804,
		["Mammoths"] = 2805,
		["Moose"] = 2806,
		["Ox"] = 2807,
		["Rhinos"] = 2808,
		["Riverbeasts"] = 2809,
		["Stag"] = 2810,
	},
	["Vehicles"] = {
		["Airplanes"] = 2900,
		["Airships"] = 2901,
		["Assault Wagons"] = 2902,
		["Book"] = 2903,
		["Broom"] = 2904,
		["Carpets"] = 2905,
		["Discs"] = 2906,
		["Gyrocopters"] = 2907,
		["Hands"] = 2908,
		["Hovercraft"] = 2909,
		["Jet Aerial Units"] = 2910,
		["Kites"] = 2911,
		["Mecha-suits"] = 2912,
		["Mechanical Animals"] = 2913,
		["Mechanostriders"] = 2914,
		["Motorcycles"] = 2915,
		["Rockets"] = 2916,
		["Seat"] = 2917,
		["Spider Tanks"] = 2918,
		["Surfboard"] = 2919
	},
	["Vombata"] = 3000,
	["Wolves"] = {
		["Dire Wolves"] = 3100,
		["Lupine"] = 3101,
		["Undead Wolves"] = 3102,
		["War Wolves"] = 3103,
		["Wilderlings"] = 3104,
		["Wolves"] = 3105,
	},
	["rest"] = 0,
}