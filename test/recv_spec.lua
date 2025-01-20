local protocol = require('ws.protocol');

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

  it('works with fragments', function()
    local ctx = nil;
    local msg;

    local full = '{"message":"test"}';
    local a = full:sub(1, 4);
    local b = full:sub(5, 8);
    local c = full:sub(9);

    local makeMessage = function(isFinal, opCode, payload)
      return protocol.finReservedAndOpCode(isFinal, opCode)
        .. protocol.maskedAndPayloadLength(0, string.len(payload))
        .. payload
    end

    msg = makeMessage(0, 1, a);
    ctx = protocol.parseFrame(msg, ctx);
    assert.is_same(ctx, {
      done = false,
      opCode = 1,
      str = '{"me'
    })


    msg = makeMessage(0, 0, b);
    ctx = protocol.parseFrame(msg, ctx);
    assert.is_same(ctx, {
      done = false,
      opCode = 1,
      str = '{"messag'
    })

    msg = makeMessage(1, 0, c);
    ctx = protocol.parseFrame(msg, ctx);
    assert.is_same(ctx, {
      done = true,
      opCode = 1,
      str = '{"message":"test"}'
    })

    -- msg = protocol.generateSendFrameMessage(b, key, {
    --   isFinal = 0,
    --   opCode = 0,
    --   isMasked = 1,
    -- });
    -- ctx = protocol.parseFrame(msg, ctx);
    --
    -- print(vim.inspect(ctx))
  end)
end)
