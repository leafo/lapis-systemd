
inifile = require "inifile"

prepare_ini = (tuples) ->
  structure = {}
  order = {}

  for section in *tuples
    section_name = section[1]
    structure[section_name] or={}

    section_order = for i=2,#section
      {key, value} = section[i]
      structure[section_name][key] = value
      key

    section_order.name = section_name
    table.insert order, section_order

  setmetatable structure, {
    __inifile: {
      sectionorder: order
      comments: {}
    }
  }

inifile.save "test.ini", prepare_ini {
  {"hello", {"what", "world"} }
  {"yeah", {"one", "two"}, {"three", "four"}, {"dad", 22}}
}



