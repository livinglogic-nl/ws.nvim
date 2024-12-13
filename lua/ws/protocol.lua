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
    opcode = 1,
    isFinal = 1,
    isMasked = 1,
  }
end

M.finReservedAndOpcode = function(isFinal, opcode)
   return string.char( bit.lshift(isFinal, 7) + opcode );
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
  -- local bit = require('bit');
  local masked = '';
  for i=1,string.len(payload) do
    local char = payload:sub(i,i);
    local b = string.byte(char);
    local mi = ((i-1) % 4) + 1;
    masked = masked .. string.char( bit.bxor(b, key[mi]));
  end
  return masked
end

M.generateSendFrameMessage = function(payload)
  local key = M.generateKey();
  local info = M.generateSendFrameInfo();
  return
    M.finReservedAndOpcode(info.isFinal, info.opcode)
    .. M.maskedAndPayloadLength(info.isMasked, string.len(payload))
    .. string.char(key[1], key[2], key[3], key[4])
    .. M.mask(payload, key)
end

return M;
