# ts-manual-import.nvim

Add TS/JS import statement manually in luasnip callbacks, other snippets in lua, any modules, keymaps.

> *! It's still working in development stage.*
<!-- TODO: import video -->

## Installation

Install the plugin with your preferred package manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ "dorage/ts-manual-import.nvim.git" }
```

## Requirements

tree-sitter.nvim

## Configuration

It does not need to setup any extra config.

## Usage

### with [LuaSnip](https://github.com/L3MON4D3/LuaSnip)

``` lua
s(
	{ name = "React: useState", trig = "rehs" },
	fmt(
		[[
	const [<>, use<>] = useState(<>);
		]],
		{ i(1), i(2), i(3) },
		{ delimiters = "<>" }
	),
	{
		callbacks = require("ts-manual-import").luasnip_callback({
			{
				default_modules = {},
				modules = { "useState" },
				source = "react",
			},
		}),
	}
)

-- **The above code is equivalent to the below code**

s(
	{ name = "React: useState", trig = "rehs" },
	fmt(
		[[
	const [<>, use<>] = useState(<>);
		]],
		{ i(1), i(2), i(3) },
		{ delimiters = "<>" }
	),
	{
		callbacks = {
            [event.eneter]=function()
                require("ts-manual-import").import({
                    {
                        default_modules = {},
                        modules = { "useState" },
                            source = "react",
                    }
                })
            end
        },
	}
)
```

### normal usage

``` lua

-- default usage
require("ts-manual-import").import({
	{ default_modules = { "React" }, modules = {}, source = "react" },
	{ default_modules = {}, modules = { "z" }, source = "zod" },
	{ default_modules = {}, modules = { "useState" }, source = "react" },
})

```

## How does it work?

- There has no import statement of the source, Then it would add import statement below the last import statement in the buffer.

### config



### code

``` typescript

```

- There has a import statement of the source, Then it would add modules on the import statement.

- There has a import statement of the source, But module is imported already, then do nothing

- There has multiple import statements of the source, Then it would add modules on the last import statement.

## Todo

- [ ] unit test

## References

It is the first made neovim plugin.

I referenced many parts in [folke](https://github.com/folke)'s plugins.
