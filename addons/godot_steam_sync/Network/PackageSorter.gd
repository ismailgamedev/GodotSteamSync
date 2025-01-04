class_name PackageSorter 
static func compare(a: Dictionary, b: Dictionary) -> int:
	if a["TS"] < b["TS"]:
		return -1
	elif a["TS"] > b["TS"]:
		return 1
	return 0
