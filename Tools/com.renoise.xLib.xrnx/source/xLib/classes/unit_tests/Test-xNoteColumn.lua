--[[ 

  Testcase for xNoteColumn

--]]

_xlib_tests:insert({
name = "xNoteColumn",
fn = function()

  require (_xlibroot.."xNoteColumn")
  require (_xlibroot.."xLinePattern")

  print(">>> xNoteColumn: starting unit-test...")

  -- note string/value converter

	assert(xNoteColumn.note_string_to_value("C-0") == 0)
	assert(xNoteColumn.note_value_to_string(0) == "C-0")

	assert(xNoteColumn.note_string_to_value("C-4") == 48)
	assert(xNoteColumn.note_value_to_string(48) == "C-4")

	assert(xNoteColumn.note_string_to_value("C-9") == 108)
	assert(xNoteColumn.note_value_to_string(108) == "C-9")

	assert(xNoteColumn.note_string_to_value("C#9") == 109)
	assert(xNoteColumn.note_value_to_string(109) == "C#9")

	assert(xNoteColumn.note_string_to_value("D-9") == 110)
	assert(xNoteColumn.note_value_to_string(110) == "D-9")

	assert(xNoteColumn.note_string_to_value("D#9") == 111)
	assert(xNoteColumn.note_value_to_string(111) == "D#9")

	assert(xNoteColumn.note_string_to_value("E-9") == 112)
	assert(xNoteColumn.note_value_to_string(112) == "E-9")

	assert(xNoteColumn.note_string_to_value("F-9") == 113)
	assert(xNoteColumn.note_value_to_string(113) == "F-9")

	assert(xNoteColumn.note_string_to_value("F#9") == 114)
	assert(xNoteColumn.note_value_to_string(114) == "F#9")

	assert(xNoteColumn.note_string_to_value("G-9") == 115)
	assert(xNoteColumn.note_value_to_string(115) == "G-9")

	assert(xNoteColumn.note_string_to_value("G#9") == 116)
	assert(xNoteColumn.note_value_to_string(116) == "G#9")

	assert(xNoteColumn.note_string_to_value("A-9") == 117)
	assert(xNoteColumn.note_value_to_string(117) == "A-9")

	assert(xNoteColumn.note_string_to_value("A#9") == 118)
	assert(xNoteColumn.note_value_to_string(118) == "A#9")

	assert(xNoteColumn.note_string_to_value("B-9") == 119)
	assert(xNoteColumn.note_value_to_string(119) == "B-9")

	assert(xNoteColumn.note_string_to_value("OFF") == 120)
	assert(xNoteColumn.note_value_to_string(120) == "OFF")

	assert(xNoteColumn.note_string_to_value("---") == 121)
	assert(xNoteColumn.note_value_to_string(121) == "---")

  -- vol/pan converter

	assert(xNoteColumn.column_string_to_value("00") == 0x00)
	assert(xNoteColumn.column_value_to_string(0x00) == "00")

	assert(xNoteColumn.column_string_to_value("1B") == 0x1B,xNoteColumn.column_string_to_value("1B"))
	assert(xNoteColumn.column_value_to_string(0x1B) == "1B")

	assert(xNoteColumn.column_string_to_value("40") == 0x40)
	assert(xNoteColumn.column_value_to_string(0x40) == "40")

	assert(xNoteColumn.column_string_to_value("7F") == 0x7F)
	assert(xNoteColumn.column_value_to_string(0x7F) == "7F")

	assert(xNoteColumn.column_string_to_value("80") == 0x80)
	assert(xNoteColumn.column_value_to_string(0x80) == "80")

	assert(xNoteColumn.column_string_to_value("C8") == 0x00000C08)
	assert(xNoteColumn.column_value_to_string(0x00000C08) == "C8")

	assert(xNoteColumn.column_string_to_value("I4") == 0x00001204)
	assert(xNoteColumn.column_value_to_string(0x00001204) == "I4")

	assert(xNoteColumn.column_string_to_value("G5") == 0x00001005)
	assert(xNoteColumn.column_value_to_string(0x00001005) == "G5")

	assert(xNoteColumn.column_string_to_value("..",xLinePattern.EMPTY_VALUE) == 255)
	assert(xNoteColumn.column_value_to_string(xLinePattern.EMPTY_VALUE,"..") == "..")

	assert(xNoteColumn.column_string_to_value("..",0) == 0)
	assert(xNoteColumn.column_value_to_string(0) == "00")

	assert(xNoteColumn.column_string_to_value("80") == 128)
	assert(xNoteColumn.column_value_to_string(128) == "80")


  -- test with instance 

  local xnotecol = xNoteColumn({
    note_value = 48,
    instrument_value = 1,
    volume_value = 0x80,
    panning_value = 0x40,
    delay_value = 0,
  })
  assert(xnotecol.note_string == "C-4")
  assert(xnotecol.instrument_string == "01")
  assert(xnotecol.volume_string == "80")
  assert(xnotecol.panning_string == "40")
  assert(xnotecol.delay_string == "00")

  local xnotecol = xNoteColumn({
    note_string = "C-5",
    instrument_string = "01",
    volume_string = "..",
    panning_string = "I4",
    delay_string = 0xFF,
  })
  assert(xnotecol.note_value == 60)
  assert(xnotecol.instrument_value == 1)
  assert(xnotecol.volume_value == 0xFF)
  assert(xnotecol.panning_value == 4612)
  assert(xnotecol.delay_value == 255)

  print(">>> xNoteColumn: OK - passed all tests")

end
})
