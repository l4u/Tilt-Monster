module(..., package.seeall)

function escape (str)
	if str then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^0-9a-zA-Z ])", -- locale independent
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
	end
	return str
end

function encode( t )
	local s = ""
	for k,v in pairs( t ) do
		s = s .. "&" .. escape(k) .. "=" .. escape(v)
	end
	return string.sub(s, 2)		-- remove first `&'
end

function unescape( s )
	s = string.gsub(s, "+", " ")
	s = string.gsub(s, "%%(%x%x)", function (h)
				return string.char(tonumber(h, 16))
			end)
	return s
end

function decode( s )
	local result = {}
	for name, value in string.gfind(s, "([^&=]+)=([^&=]+)") do
		name = unescape(name)
		value = unescape(value)
		result[name] = value
	end
	return result
end
