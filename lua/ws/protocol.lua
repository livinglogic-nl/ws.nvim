local M = {}

M.generateHandshake = function(opt)
  return table.concat(M.generateHandshakeLines(opt), '\r\n');
end

M.generateHandshakeLines = function(opt)
  return {
    'GET ' .. opt.path .. ' HTTP/1.1',
    'Upgrade: websocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==',
    'Sec-WebSocket-Version: 13',
    '',
    '',
  };
end

M.generateKey = function()
  return {
    math.random(0,255),
    math.random(0,255),
    math.random(0,255),
    math.random(0,255),
  }
end

M.generateSendFrameInfo = function()
  return {
    opCode = 1,
    isFinal = 1,
    isMasked = 1,
  }
end

M.finReservedAndOpCode = function(isFinal, opCode)
   return string.char( bit.lshift(isFinal, 7) + opCode );
end

M.maskedAndPayloadLength = function(isMasked, payloadLength)
  local maskBit = bit.lshift(isMasked, 7);
  if payloadLength > 125 then
    if payloadLength < 65536 then
      local big = bit.rshift(payloadLength, 8);
      local small = bit.band(payloadLength, 0xFF);
      return string.char(maskBit + 126, big, small);
    end

    local remain = payloadLength;
    local bytes = { maskBit + 127 }
    local i=9;
    while i > 1 do
      local val = 0;
      if remain > 0 then
        val = bit.band(remain, 0xFF);
        remain = bit.rshift(remain, 8);
      end
      bytes[i] = val;
      i = i - 1;
    end
    return table.concat( vim.tbl_map(function(byte) return string.char(byte) end, bytes), '');
  end
  return string.char(maskBit + payloadLength);
end

M.mask = function(payload, key)
  local masked = '';
  for i=1,string.len(payload) do
    local char = payload:sub(i,i);
    local b = string.byte(char);
    local mi = ((i-1) % 4) + 1;
    masked = masked .. string.char( bit.bxor(b, key[mi]));
  end
  return masked
end

M.generateSendFrameMessage = function(payload, key, info)
  return
    M.finReservedAndOpCode(info.isFinal, info.opCode)
    .. M.maskedAndPayloadLength(info.isMasked, string.len(payload))
    .. string.char(key[1], key[2], key[3], key[4])
    .. M.mask(payload, key)
end

M.getPayloadLengthAndOffset = function(msg)
  local payloadLength = string.byte(msg, 2, 2);
  if payloadLength < 126 then return payloadLength, 3 end
  if payloadLength < 127 then
    -- real length is in next 2 bytes
    local big = string.byte(msg,3,3);
    local small = string.byte(msg,4,4);
    return (bit.lshift(big, 8) + small), 5
  end

  -- real length is in next 8 bytes
  local sum = 0;
  local shiftSize = 56;
  for i=3,10 do
    local b = string.byte(msg, i,i);
    if b > 0 then
      sum  = sum + bit.lshift(b, shiftSize);
    end
    shiftSize = shiftSize - 8;
  end
  return sum, 10
end


M.parseFrame = function(chunk, ctx)
  local finReservedAndOpCode = string.byte(chunk, 1, 1);
  local isFinal = bit.band(finReservedAndOpCode, bit.lshift(1, 7)) > 0;
  local opCode = bit.band( finReservedAndOpCode, 0x7F );
  if opCode > 1 then
    return error('unsupported opCode: ' .. opCode)
  end

  local payloadLength, payloadOffset = M.getPayloadLengthAndOffset(chunk);
  local chars = {}
  for i=payloadOffset,payloadOffset+payloadLength-1 do
    table.insert(chars, chunk:sub(i,i));
  end

  local str = table.concat(chars,'')
  if ctx then
    opCode = ctx.opCode
    str = ctx.str .. str
  end
  return {
    opCode = opCode,
    done = isFinal,
    str = str,
  }
end

return M;
