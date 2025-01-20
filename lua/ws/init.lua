local uv = vim.uv;
local protocol = require('ws.protocol');

local M = {}

M.connect = function(params)
  local domain, path = params.url:match('//([^/]*)(.+)');
  local ip, port = domain:match('([^:]+):([0-9]+)');

  local handshakeMessage = protocol.generateHandshake({ path = path });
  local handshakeComplete = false;

  local client = {}
  local tcp = uv.new_tcp()
  client.tcp = tcp;
  client.send = function(payload)
    local key = protocol.generateKey();
    local info = protocol.generateSendFrameInfo();
    tcp:write(protocol.generateSendFrameMessage(payload, key, info));
  end

  client.close = function()
    tcp:close(function()
    end);
  end

  tcp:connect(ip, port, function (err)
    if err then
      vim.schedule_wrap(function()
        vim.notify(err, vim.log.levels.ERROR);
      end)
    end
  end)

  local ctx = nil;
  tcp:read_start(function(_, chunk)
    if chunk == nil then
      client.close();
      return
    end
    vim.schedule(function()
      if handshakeComplete then
        ctx = protocol.parseFrame(chunk, ctx)
        if ctx.done then
          params.onData(client, ctx.str);
          ctx = nil;
        end
        return
      end
      handshakeComplete = true;
      params.onOpen(client);
    end);
  end)

  tcp:write(handshakeMessage);
  return client;
end

return M;
