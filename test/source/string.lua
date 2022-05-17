print(string.gsub("aaaa","a","z",3))
print(string.find("Hello Lua user", "Lua", 1))
print(string.reverse("Lua"))
print(string.format("the value is:%d",4))
print(string.char(97,98,99,100))
print(string.rep("abcd",2))
print(string.match("I have 2 questions for you.", "%d+ %a+"))

for word in string.gmatch("Hello Lua user", "%a+") do print(word) end