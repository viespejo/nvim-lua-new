local s = require("luasnip")

return {
	s.parser.parse_snippet({ trig = "cl", priority = 2000 }, "console.log(${1:msg});$0"),
}
