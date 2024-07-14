# ts-manual-import.nvim

Add TS/JS import statement manually in luasnip callbacks, other snippets in lua, any modules, keymaps.

<!-- TODO: import video -->

## Installation

Install the plugin with your preferred package manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ "dorage/ts-manual-import.nvim.git" }
```

## Requirements

[tree-sitter.nvim](https://github.com/nvim-treesitter/nvim-treesitter)

``` lua
require("nvim-treesitter.configs").setup({
    ensure_installed = {
        "javascript",
        "typescript",
        "tsx",
    },
    sync_install = true,
})
```

## Configuration

It does not need to setup.

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
	{ defalut = "React", modules = {}, source = "react" },
	{ modules = { "z" }, source = "zod" },
	{ modules = { "useState" }, source = "react" },
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

- [v] unit test
- [ ] Support `import type ...` statement in Typescript

## References

It is the first made neovim plugin.

This plugin has been constructed based on [nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template).

I referenced many parts in [folke](https://github.com/folke)'s plugins.
