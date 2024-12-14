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

describe('send frame protocol', function()
  it('generates a random key every time', function()
    local str1 = table.concat(protocol.generateKey(), '');
    local str2 = table.concat(protocol.generateKey(), '');
    assert.is_not_equal(str1,str2);

  end)
  it('Generates send frame info', function()
    local info = protocol.generateSendFrameInfo();
    assert.is_equal(info.isFinal, 1);
    assert.is_equal(info.isMasked, 1);
    assert.is_equal(info.opcode, 1);
  end)

  it('correctly packs the final and opcode', function()
    local packed = protocol.finReservedAndOpcode(1,1);

    -- 1000 0001 = (128+1)
    -- ^final  ^opcode
    assert.is_equal(string.byte(packed:sub(1,1)), 129);
  end)

  it('correctly packs isMasked flag and payload length 124', function()
    assert.is_equal(string.byte( (protocol.maskedAndPayloadLength(1,124)):sub(1,1)), 252);
  end);

  it('correctly packs isMasked flag and payload length 125', function()
    assert.is_equal(string.byte( (protocol.maskedAndPayloadLength(1,125)):sub(1,1)), 253);
  end);

  it('correctly packs isMasked flag and payload length 126', function()
    local result = protocol.maskedAndPayloadLength(1,126);
    assert.is_equal(1 + 2, string.len(result));
    assert.is_equal(result, string.char(254, 0, 126));
  end)

  it('correctly packs isMasked flag and payload length 65535', function()
    local result = protocol.maskedAndPayloadLength(1,65535);
    assert.is_equal(1 + 2, string.len(result));
    assert.is_equal(result, string.char(254, 255, 255));
  end);

  it('correctly packs isMasked flag and payload length 65536', function()
    local result = protocol.maskedAndPayloadLength(1,65536);
    assert.is_equal(1 + 8, string.len(result));
    assert.is_equal(result, string.char(255, 0, 0, 0, 0, 0, 1, 0, 0));
  end);

  it('correctly packs isMasked flag and payload length 65537', function()
    local result = protocol.maskedAndPayloadLength(1,65537);
    assert.is_equal(1 + 8, string.len(result));
    assert.is_equal(result, string.char(255, 0, 0, 0, 0, 0, 1, 0, 1));
  end);

  it('masks the payload with the key', function()
    assert.is_equal( protocol.mask('abcd', { 0,0,0,0 }), 'abcd');
    assert.is_equal( protocol.mask('abcd', { 0,0,0,1 }), 'abce');
    assert.is_equal( protocol.mask('abcdefgh', { 0,0,0,1 }), 'abceefgi');
  end);
end)

describe('receive frame protocol', function()
  it('correctly determines length and offset when length < 126', function ()
    local message = string.char(129, 125);
    local len,offset = protocol.getPayloadLengthAndOffset(message)
    assert.is_equal(len, 125);
    assert.is_equal(offset, 3);
  end)

  it('correctly determines length and offset when length < 65536', function ()
    local message = string.char(129, 126, 0xFF, 0xFF);
    local len,offset = protocol.getPayloadLengthAndOffset(message)
    assert.is_equal(len, 65535);
    assert.is_equal(offset, 5);
  end)

  it('correctly determines length and offset when length >= 65536', function ()
    local message = string.char(129, 127, 0,0,0,0,0,1,0,0 );
    local len,offset = protocol.getPayloadLengthAndOffset(message)
    assert.is_equal(len, 65536);
    assert.is_equal(offset, 10);
  end)
end)
