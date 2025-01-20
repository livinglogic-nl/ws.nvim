local protocol = require('ws.protocol');

describe('handshake protocol', function()
  it('generates acceptable headers', function()
    local lines = protocol.generateHandshakeLines({
      path = '/devtools/page/C722FAE0E1F172FC04D375618148E1F3',
    });
    local hasLine = function(str)
      for _, value in ipairs(lines) do
        if value == str then return true end
      end
      return false
    end
    assert(hasLine('GET /devtools/page/C722FAE0E1F172FC04D375618148E1F3 HTTP/1.1'));
    assert(hasLine('Upgrade: websocket'));
    assert(hasLine('Connection: Upgrade'));
    assert(hasLine('Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ=='));
    assert(hasLine('Sec-WebSocket-Version: 13'));
  end)

  it('ends every line with a CR-NL', function()
    local str = protocol.generateHandshake({
      path = '/devtools/page/C722FAE0E1F172FC04D375618148E1F3',
    });
    local parts = vim.split(str, '\r\n');
    assert.is_equal(parts[1], 'GET /devtools/page/C722FAE0E1F172FC04D375618148E1F3 HTTP/1.1');
    assert.is_equal(parts[2], 'Upgrade: websocket');
  end)

  it('concludes with a double CR-NL', function()
    local str = protocol.generateHandshake({
      path = '/devtools/page/C722FAE0E1F172FC04D375618148E1F3',
    });
    assert.is_equal(str:sub(str:len() - (4-1)), '\r\n\r\n')
  end)

end)

