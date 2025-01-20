local protocol = require('ws.protocol');

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
    assert.is_equal(info.opCode, 1);
  end)

  it('correctly packs the final and opCode', function()
    local packed = protocol.finReservedAndOpCode(1,1);

    -- 1000 0001 = (128+1)
    -- ^final  ^opCode
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

