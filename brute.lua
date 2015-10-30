-- http://www.asciitable.com/index/asciifull.gif

local rangeString = "45, 48-57, 97-122"

function rangeToList( rangeString )
	rangeString = string.gsub(rangeString, " ", "")
	local rangeList, i = {}, 1
	-- ToDO add a function to easily add it in a for i=1,y loop
	for word in string.gmatch(rangeString, "[^,]%d+") do
		rangeList[i] = tonumber(word)
		
			if rangeList[i] > 0 then
				i = i+1 --proceed
			else --it's an array of IDs 204-207
				local prev, curr = rangeList[i-1], rangeList[i]*-1 --faster than math.abs()
				local step = 1
				if prev > curr then --if the first number is bigger than the second one (e.g. "470-464")
					step = -1 --we need to count downwards
				end
				i = i-1 --trust me. We don't wanna to have the same ID twice
				for x = prev, curr, step do
					rangeList[i] = x
					i = i+1
				end
			end
	end
		
	return rangeList
end

bruteforceChars = rangeToList(rangeString)
print("Current bruteforce dictionary: ")
for k,v in pairs( bruteforceChars ) do io.write(k .. "=" .. string.char(v) .. "\t") end print()

function raiseCharID( id )
	for c = 1, #bruteforceChars do
		if bruteforceChars[ c ] == id then
			local carry = false	-- carry means that the next followed char must be raised as well
			
			if c ~= #bruteforceChars then
				return bruteforceChars[ c+1 ], carry
			else
				carry = true
				return bruteforceChars[ 1 ], carry
			end
		end
	end
end

function raiseChar( char )
	local id, carry = raiseCharID(string.byte( char ))
	return string.char(id), carry
end

function raiseString( str )
	local carry = false
	local currentCharPosition = #str
	
	repeat
		local begin, targetChar, ending = string.sub(str, 1, currentCharPosition - 1), string.sub(str, currentCharPosition, currentCharPosition), string.sub(str, currentCharPosition + 1)
		targetChar, carry = raiseChar( targetChar )
		str = begin .. targetChar .. ending
		if currentCharPosition == 1 then
			if carry then
				str = string.char(bruteforceChars[ 1 ]) .. str
			end
			
			break
		else
			currentCharPosition = currentCharPosition - 1
		end
	until carry == false
	
	return str
end

function bruteforceNextString( lastString, startLength, endLength )
	if not lastString or #lastString == 0 then
		return string.char(bruteforceChars[ 1 ]):rep( startLength )
	end

	--
	
	local nextString = raiseString( lastString )
	
	if #nextString <= endLength then
		return nextString
	else
		return
	end
end

print("Full Syntax: doBruteforce( 'fromString', 'toString', minStringLength, maxStringLength )")
print("Either fromString-toString or minLength, maxLength are optional\n")
function doBruteforce(startString, finalString, startLength, endLength)
	local nextString
	
	if type(startString) == "string" then
		nextString = startString
	else
		print("fromString is not specified! The range will start from an empty string.\n")
		nextString = ""
		os.execute("sleep 3")
	end
	
	if type(finalString) == "string" then
		print("Range set from '".. nextString .."' to '".. finalString .."'\n")
	else
		print("toString is not specified, the range end is now only limited by maxStringLength!\n")
		finalString = nil
		os.execute("sleep 3")
	end
	
	if type(startLength) ~= "number" then
		if type(startString) ~= "string" then
			print("minStringLength is not specified! The bruteforce will start from a single character string\n")
		end
		startLength = 1
	end
	
	if type(endLength) ~= "number" then
		if finalString then
			endLength = #finalString
		else
			print("ERROR: You did not specify maxStringLength nor toString!")
			print("Quitting!")
			os.exit(1)
		end
	end
	
	local blacklist = loadBlacklist()
	local batchList = {}
	local batchSize = 100	-- Amount of parallel CURL instances, e.g. check 24 URLs at once -> 24 cURL instances
	batchLogs = dofile("logging.lua")
	
	repeat
		nextString = bruteforceNextString( nextString, startLength, endLength )
		
		if nextString and blacklist[ nextString ] ~= true then
			-- run curl
			local isValid = validUsername(nextString)
			if isValid then
				batchList[ #batchList + 1] = nextString
				
				if #batchList >= batchSize then
					curlGrab(batchList)
					batchList = {}
				end
				--print("valid: ".. nextString)
			end
			
		end
		
		if type(nextString) == "nil" or (finalString and nextString and nextString == finalString) then
			
			break
		end
		
		--print(nextString, nextString and #nextString)
	until (nextString == nil) or (fileExists("STOP") == true)
	
	if #batchList ~= 0 then
		curlGrab(batchList)
		batchList = {}
	end
	
	
	if fileExists("STOP") == true then
		print("STOP file detected! Quitting...")
	elseif(finalString and nextString and nextString == finalString)
		print("Finished! Reached the finalString: ".. finalString .." (last string processed)")
	else
		print("Looks like we've hit the bruteforce target. Finished! Quitting...")
	end
	
	batchLogs.closeAll()
	os.exit(0)
	return true
end

function validUsername(username)
	if username:sub(1,1):find("%a") then
		local subUsername = username:sub(3)
		if not subUsername:find("[^%w%-]") then
			-- all valid
			return true
		end
	end
end

function curlGrab( usernameList )
	local command = ""
	local usernamesString = ""
	local lastUsername = "-undefined-"
	
	for i = 1, #usernameList do
		local username = usernameList[i]
		command = command .. "curl -I -L --max-time 3.5 --silent --write-out 'user".. username .." %{http_code}\\n' http://home.online.no/~".. usernameList[i] .. "/ & \n"
		usernamesString = usernamesString .. username .. "  "
		
		if i == #usernameList then
			lastUsername = username
		end
	end
	command = command .. "wait"
	
	print("Next up:")
	print(usernamesString)
	local pipe = io.popen(command)
	local serverResponse = pipe:read("*a")
	
	os.execute("sleep 0.1")
	pipe:close()
	
	
	local responseStats = {}	-- collect the statistics instead of printing everything to console
	
	for	username, status_code in serverResponse:gmatch("user(.-) (%d+)") do
		status_code = tonumber(status_code)
		
		responseStats = tableIncrementValue( responseStats, status_code, 1 )
		
		if status_code == 200 then
		
			print("~"..username, status_code, "OK")
			batchLogs.line("200.txt", "~".. username)
			
		elseif status_code == 404 then
		
			--os.execute("echo ~".. username .." >> 404.txt")
			
		elseif status_code == 0 then
		
			batchLogs.line("000.txt", "~".. username)
			
		else
			print("Detected an unexpected response code!")
			os.execute("echo ~".. username .." >> ".. status_code ..".txt")
		end
	end
	
	io.write("Received status codes: ")
	for k, v in pairs( responseStats ) do
		io.write("[".. k .."]: ".. v ..", ")
	end
	io.write("\n")
	
	print("Last checked username: ~".. lastUsername .."\n")
end

function loadBlacklist()
	local blacklist = {}
	local filePath = "01_telenor"
	local file = assert(io.open(filePath, "r"))
	local entryCount = 0
	
	for line in file:lines() do
		if blacklist[ line ] ~= true then
			blacklist[ line ] = true
			entryCount = entryCount + 1
		end
	end
	
	file:close()
	print("Blacklist loaded, ".. entryCount .." entries!")
	os.execute("sleep 2")
	return blacklist
end

-- table, key, amount
function tableIncrementValue( tabl, key, amount )
	local value = tabl[ key ] or 0
	local amount = amount or 1
	
	if value then
		tabl[ key ] = value + amount
		return tabl
	end
end

function fileExists( path )
	local fileHandle = io.open(path, "r")
	
	if fileHandle then
		fileHandle:close()
		return true
	end
	
	return false
end