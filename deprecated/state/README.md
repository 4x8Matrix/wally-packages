# State

> ⚠️ - this resource has been deprecated, to use the latest version of this resource, please use the last known version of wally - previous to the current.

Deprecated - Imho, state was a layer ontop of a generic, instance, or value which introduced overhead developers just don't really need. 

State introduced a higher learning curve to the codebases it was involved in - and overall tried to add compliexity where it was not wanted - just be simple, simplicity isn't bad.

If you need something like state - i'd suggest checking out one of the many state libraries on wally. But i'd suggest you take a step back and really consider how this may effect you, and your team later down the line.

---

To make things simpler, i'd suggest you use try using ObjectValue, NumberValue, StringValue, Vector3Value, so on.. they implement the same logic, albeit as a Roblox instance.