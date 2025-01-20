# ws.nvim
Basic websocket support in neovim. In only 160 lines of code 🎉

`ws://` only for the moment... 🤷

But can for example be used to communicate with Chrome using the devtools protocol.
You would have to start Chrome with `--remote-debugging-port=9222` or some other port number.

## Why?
I had trouble finding a **simple** solution that works.

Most solutions depend on lua-rocks or interface for example with a built Rust library.

Neovim actually provides a TCP client so it should be possible in plain lua.

## TODO
- [ ] neovim documentation

# Install
Use your favourite package manager. For example

```lua
Plug 'livinglogic-nl/ws.nvim';
```

# Usage
```lua

local ws =  require('ws');
  ws.connect({
    url = 'ws://127.0.01:9222/devtools/page/C722F...E1F3',
    onOpen = function(client)
      client.send(
        vim.fn.json_encode({
          id = 1,
          method = 'Runtime.evaluate',
          params = {
            expression = 'console.log(new Date)',
          }
        })
      )
    end,
    onData = function(client, data)
        local obj = vim.fn.json_decode(data);
        client.close()
    end,
  })


```

## Test

Uses [busted](https://lunarmodules.github.io/busted/) for testing. Installs by using `luarocks --lua-version=5.1 install vusted` then runs `vusted ./test`
for your test cases. `vusted` is a wrapper of Busted especially for testing Neovim plugins.

Create test cases in the `test` folder. Busted expects files in this directory to be named `foo_spec.lua`, with `_spec` as a suffix before the `.lua` file extension. For more usage details please check
[busted usage](https://lunarmodules.github.io/busted/)

## License MIT
