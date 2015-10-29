###What it does:
The scripts goes through all possible usernames (called bruteforcing) in http://home.online.no/~<USERNAME>/ and saves server's responses into files.

_200.txt_ = usernames that do exists

_404.txt_ = usernames do not exists

_000.txt_ = usernames most probably do not exist, cURL timeout (the server response takes up to 8 seconds for 404's, while it's instant for 200's)


###Installation:
You need cURL and Lua5.1 to be installed

###How to start the script from a shell:
```cd``` into the same directory as brute.lua

Launch the Lua shell by typing "lua"

Then enter this code:
```lua
dofile("brute.lua")
doBruteforce( <fromString> , <toString>, <fromStringLength>, <toStringLength>)
```

###Settings:
You can change the amount of parallel cURL instances by changing "batchSize = 24" on line 96

#####doBruteforce() is a function with following arguments:
1) ```fromString```: defines the beginning of range (the string itself is non-included)

2) ```toString```: defines the end of the range (the string itself is included). The Lua shell will automatically quit upon reaching it.

3) ```fromStringLength```: if ```fromString``` is not specified, it will start with N characters and work it's way upwards until hitting ```toString``` or ```toStringLength```

4) ```toStringLength```: the bruteforce job will stop when the string reaches this length. This limit overrides ```toString```



01_telenor is currently the list with known usernames that will not be bruteforced.

https://github.com/VADemon/telenor-brute/issues/1 is the current list with allocated ranges.