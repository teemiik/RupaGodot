extends GutTest

func before_all():
	I18N.init()

func test_known_key_resolves():
	assert_eq(I18N.get_s("app_name"), "Rupa")

func test_missing_key_falls_back_to_key():
	assert_eq(I18N.get_s("___does_not_exist___"), "___does_not_exist___")

func test_fmt_substitutes_placeholder():
	var s = I18N.fmt("result_time", "00:30")
	assert_true(s.find("00:30") >= 0, "fmt injects the argument into the template")
