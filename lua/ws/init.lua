local uv = vim.uv;
local protocol = require('ws.protocol');

local M = {}

M.connect = function(params)
  local log = function() end

  if params.silent == nil then
    log = function(str)
      print('ws.nvim: ' .. str);
    end
  end

  local domain, path = params.url:match('//([^/]*)(.+)');
  local ip, port = domain:match('([^:]+):([0-9]+)');

  local handshakeMessage = protocol.generateHandshake({ path = path });
  local handshakeComplete = false;

  local client = {}
  local tcp = uv.new_tcp()
  client.tcp = tcp;
  client.send = function(payload)
    tcp:write(protocol.generateSendFrameMessage(payload));
  end

  client.close = function()
    tcp:close(function()
      log('closed')
    end);
  end

  tcp:connect(ip, port, function (err)
    if err then
      log('error' .. err);
    end
    log('closed');
  end)

  tcp:read_start(function(_, chunk)
    vim.schedule(function()
      if handshakeComplete then
        local result = chunk:sub(3);
        params.onData(client, result);
        return
      end
      log('connected');
      handshakeComplete = true;
      params.onOpen(client);
    end);
  end)

  tcp:write(handshakeMessage);
  return client;
end

return M;
