# go-tester.nvim

Forget about opening tmux or another terminal instance to run your file/package tests.

## What is go-tester? 
Go tester is a way to avoid the context switching in running a test suite in your golang project.<br>
As soon as you run the command, you can begin to fix all from tests to actual source code, just for the tests to be re-run as soon as you save the files you are coding in.

![Imgur](https://imgur.com/gOOQOBV.gif)

## Special thanks
[tjdevries](https://github.com/tjdevries) who inspired this plugin to be created.
For more information about how it works in practical applications watch [This Video](http://youtube.com/watch?v=cf72gMBrsI0)

## Getting started
### Required Dependecies
* [nvim 0.8.0](https://github.com/neovim/neovim/releases/tag/v0.8.0) or higher
* [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

## How to install it

Using [vim-plug](https://github.com/junegunn/vim-plug)
```viml
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nachonievag/go-tester.nvim'
``` 

Using [dein](https://github.com/Shougo/dein.vim)
```viml
call dein#add('nvim-treesitter/nvim-treesitter')
call dein#add('nachonievag/go-tester.nvim')
``` 

Using [Packer](https://github.com/wbthomason/packer.nvim)
```lua
use {
  'nachonievag/go-tester.nvim',
  requires = { {'nvim-treesitter/nvim-treesitter'} }
}
``` 

## Configurations
You can specify the several flags to execute the go test command.<br>
As it is today the defined command to execute is:<br>
`go test $exec_path -v -json`<br>
This flags are mandatory for the plugin to work, yet you could add the ones you need at will.
```lua
use {
  "nachonievag/go-tester.nvim",
  requires = "nvim-treesitter/nvim-treesitter",
  config = function()
    require("go-tester").setup({ flags = { "-failfast", "-race", "-cover" } })
  end
}
``` 
In this case, we shall see as the user command is executed, that the command executed is:
`go test $exec_path -v -json -failfast -race -cover`<br>



## Commands
| Commands                   | Description                                                                                 |
|----------------------------|---------------------------------------------------------------------------------------------|
|  `GoTestFileOnSave`        | Test current buffer on save.                                                                |
|  `GoTestPackageOnSave`     | Test package where current buffer is located.                                               |
|  `GoTestLineDiag`          | After having diagnostics executed, show in split the results of a test.                     |
