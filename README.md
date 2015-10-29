###How to start the script in shell:
cd into the same directory as brute.lua
Launch the Lua shell by typing "lua"
Then enter this code:
```lua
dofile("brute.lua")
doBruteforce( <fromString> , <toString>, <fromStringLength>, <toStringLength>)
```

Installation:
You need cURL and Lua5.1 to be installed

Settings:
You can change the amount of parallel cURL instances by changing "batchSize = 24" on line (currently) 96

doBruteforce() is a function with following arguments:
1) fromString: is the string to start from
2) toString: this will be the last string of the current bruteforce job. The Lua shell will automatically quit.
3) fromStringLength:	if fromString is not specified, it will start with N characters and work it's way upwards until hitting toString or toStringLength
4) toStringLength:	the bruteforce job will stop when the bruteforce string reaches this length

What it does:
The scripts goes through all possible usernames in http://home.online.no/~<USERNAME>/ and saves server's responses into files.
200.txt	= usernames that do exists
404.txt	= usernames do not exists
000.txt = usernames most probably do not exist, cURL timeout (the server response takes up to 8 seconds for 404's, while it's instant for 200's)

01_telenor is currently the list with known usernames that will not be bruteforced.