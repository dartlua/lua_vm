function newYinYinMonster ()
    local count = 'yin '
    return function () -- anonymous function
        count = count..count
        return count..'bo'
    end
end

c1 = newYinYinMonster()
print(c1())
print(c1())

c2 = newYinYinMonster()
print(c2())
print(c1())
print(c2())