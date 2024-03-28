Ardour Tools and Stuff
======================

Tips
----

- Print messages appear in the log: Window --> Log.

- For testing, the scratch buffer can be used: Window --> Scripting.


Get routes
----------

```
local routes = Session:get_routes()

print('Number of routes: ' .. tostring(routes:size()))
```

Loop over routes and print their names:
```
for i,route in ipairs(routes:table()) do
	print('    - ' .. tostring(i) .. ' ' .. route:name())
end
```

List processors plugins of all routes:
```
for i,route in ipairs(routes:table()) do
	print('    - ' .. tostring(i) .. ' ' .. route:name())
	local ip = 0
	while true do
	    -- For all types of processors, including built-in processors,
	    -- use nth_processor() instead
		p = route:nth_plugin(ip) 
		if p:isnil() then
			break
		end
		if not p:isnil() then
			print('        - ' .. p:name())
		end
		ip = + 1
	end
end
```
