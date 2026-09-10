extends RefCounted
# Independent manual/checkpoint slots; retain the previous valid file on failure.
static func write(path:String,data:Dictionary)->Error:
 var absolute:=ProjectSettings.globalize_path(path)
 var result:=DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
 if result!=OK:return result
 var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null:return FileAccess.get_open_error()
 file.store_string(JSON.stringify(data));file.flush()
 result=file.get_error();file.close()
 if result!=OK:return result
 if FileAccess.file_exists(path):
  result=DirAccess.copy_absolute(absolute,absolute+".bak")
  if result!=OK:return result
 return DirAccess.rename_absolute(absolute+".tmp",absolute)

static func checkpoint_path(manual:String)->String:
 return manual.get_basename()+"-checkpoint.json"

static func manual_source(manual:String)->String:
 if FileAccess.file_exists(manual):return manual
 if manual=="user://saves/manual.json" and FileAccess.file_exists("res://savegame.json"):
  return "res://savegame.json"
 return manual
