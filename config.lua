Config = {}

Config.npc = {
	coords = vec4(-321.5673, -1545.6829, 30.0202, 352.2139),
	renderDistance = 30,
	model = "a_f_m_beach_01"
}

Config.truck = {
	model = "trash",
	coords = vec4(-327.5529, -1524.7357, 26.5360, 269.3373)
}
Config.Routes = {
	-- vec3(539.3947, -1648.8604, 27.4926)
	-- vec4(-325.6136, -1518.5925, 27.5393, 8.3812), --test lokalizacja
	vec4(-159.4840, -878.2471, 28.2491, 290.9088),
	vec4(-34.1446, -398.4838, 38.6045, 263.1521),
	vec4(147.8934, -291.0820, 45.3034, 157.1042),
	vec4(178.5788, 54.2797, 82.6236, 2.4044),
	vec4(-943.1977, 312.8254, 70.3519, 184.0779),
	vec4(-1458.5796, -176.5494, 47.8165, 41.4431),
	vec4(869.3641, -2122.3179, 29.5600, 85.2887),
}

Config.models = {
	bag = "p_binbag_01_s",
	bins = {
		"hei_heist_kit_bin_01",
		"prop_bin_01a",
		"prop_bin_02a",
		"prop_bin_05a",
		"prop_bin_08open",
		"prop_bin_07d",
		"prop_bin_14a",
		"prop_cs_bin_01_skinned"
	}
}

Config.endCoords = vec4(-340.9601, -1558.7915, 25.2302, 221.1289)

Config.payout = {
	min = 100,
	max = 200
}

Config.bags = {
	min = 3,
	max = 5
}

Config.maxCourses = 4
