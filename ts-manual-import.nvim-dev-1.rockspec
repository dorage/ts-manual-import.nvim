package = "ts-manual-import.nvim"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   detailed = "Add TS/JS import statement manually in luasnip callbacks, other snippets in lua, any modules, keymaps.",
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      ["ts-manual-import"] = "lua/ts-manual-import.lua",
      ["ts-manual-import.import"] = "lua/ts-manual-import/import.lua",
      ["ts-manual-import.init"] = "lua/ts-manual-import/init.lua",
      ["ts-manual-import.util"] = "lua/ts-manual-import/util.lua"
   },
   copy_directories = {
      "doc"
   }
}
