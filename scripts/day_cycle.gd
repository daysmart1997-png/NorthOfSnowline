extends RefCounted

# One clock: elapsed gameplay seconds also drive weather, needs and fire fuel.
# 24 real minutes per day; a 120-second rest advances two in-world hours.
const DAY_SECONDS := 1440.0
const START_HOUR := 9.0

static func hour(elapsed: float) -> float:
	return fposmod(START_HOUR + elapsed * 24.0 / DAY_SECONDS, 24.0)

static func day(elapsed: float) -> int:
	return int(floor((START_HOUR + elapsed * 24.0 / DAY_SECONDS) / 24.0)) + 1

static func clock_text(elapsed: float) -> String:
	# Work in whole game minutes: converting through fractional hours can turn
	# 00:10 into 00:09 through floating point rounding at midnight.
	var minutes := posmod(int(floor(elapsed)) + int(START_HOUR * 60.0), 1440)
	return "%02d:%02d" % [minutes / 60, minutes % 60]

static func phase(elapsed: float) -> String:
	var h := hour(elapsed)
	if h < 5.5 or h >= 19.0: return "夜晚"
	if h < 7.0: return "晨光"
	if h < 16.5: return "白昼"
	return "暮色"

static func daylight(elapsed: float) -> float:
	var elevation := sin((hour(elapsed) - 6.0) * TAU / 24.0)
	return smoothstep(-0.15, 0.4, elevation)

static func cold(elapsed: float) -> float:
	return 1.0 - daylight(elapsed)

static func sun_direction(elapsed: float) -> Vector3:
	var angle := (hour(elapsed) - 6.0) * TAU / 24.0
	# A tilted arc avoids a vertical singularity while carrying shadows east/west.
	return Vector3(cos(angle), sin(angle) * 0.85, 0.42).normalized()

static func sun_strength(elapsed: float) -> float:
	return smoothstep(0.0, 0.3, sun_direction(elapsed).y)

static func sunset_tint(elapsed: float) -> float:
	return (1.0 - smoothstep(0.1, 0.65, absf(sun_direction(elapsed).y))) * daylight(elapsed)
