--
-- Created by IntelliJ IDEA.
-- User: 20362
-- Date: 2020/11/7
-- Time: 22:12
-- To change this template use File | Settings | File Templates.
--
local t = {'a', 'b', 'c'}
t[2] = 'B'
t['foo'] = 'Bar'
local s = t[3]..t[2]..t[1]..t['foo']..#t
