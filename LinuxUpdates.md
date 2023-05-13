# Updates Need to Run on Linux

2023 May 12, to revisit after WWDC.

## Still TODO
ServerSideEvents engine not implemented on Linux b/c currently uses the `URLSession.bytes(for)` async convenience function and I don't need it for phase 1 of my posts-only bot. References to it wrapped in `#if !os(Linux)` checks. 

## Misc Headers
File headers where necessary.

### Networking
Used by Linux to load URLRequest, etc. 

 ```Swift
 #if canImport(FoundationNetworking)
import FoundationNetworking
#endif
```
### UTTypes
Used by AppleOS b/c they have it. 

```Swift
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
```

Linux version has a cludge file to handle JUST what I use types for wrapped in `#if !canImport(UniformTypeIdentifiers)`


## Extensions

- `Date`: only `func ISO8601Format() -> String`, not needed for `APITizer`, used in `TrunkLine`
- `FileIO`: mostly URL problems
    -  `initializer URL(filePath: filePath)` is still `URL(fileURLWithPath: filePath)`
    - .appending(component: folderName) doesn't exist
- `URLSession`: add async convenience inits, with the exclusion of bytes (TODO if not added after WWDC)

## Glue Implementations

### UTType

UTType library doesn't not exist on Linux. Wrote BARE MINUM hard coded make it work for image file detection. 


## Actually... that's an Improvement

In `POSTEncoders` discovered new-to-me non-objectiveC way to detect Optional<Any> == nil for `func makeDictionary(from itemToEncode:Any) -> [String:String]?`. Both ways are here, only the new way got moved to `APITizer`. 

