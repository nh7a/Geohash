# Geohash

This is yet another Geohash library written in Swift.

## Usage
```swift
if let (lat, lon) = Geohash.decode(hash: "u4pruydqqvj") {
  // lat.min == 57.649109959602356
  // lat.max == 57.649111300706863
  // lon.min == 10.407439023256302
  // lon.max == 10.407440364360809
}

let s = Geohash.encode(latitude: 57.64911063015461, longitude: 10.40743969380855, length: 10)
// s == "u4pruydqqv"

let p = Geohash.encode(latitude: 57.64911063015461, longitude: 10.40743969380855, precision: .nineteenMeters)
// p == "u4pruydq"
```

## Neighbors
```swift
Geohash.adjacent(geohash: "u4pruydqqvj", direction: .n)
// "u4pruydqqvm"

Geohash.neighbors(geohash: "u4pruydqqvj")
// ["u4pruydqqvm", "u4pruydqqvn", "u4pruydqquv", "u4pruydqqvh",  // n, e, s, w
//  "u4pruydqqvq", "u4pruydqquy", "u4pruydqqvk", "u4pruydqquu"]  // ne, se, nw, sw
```

## CLLocationCoordinate2D extension
```swift
let l = CLLocationCoordinate2D(geohash: "u4pruydqqvj")
// l.latitude == 57.64911063015461
// l.longitude == 10.407439693808556

let l = CLLocationCoordinate2D(latitude: 57.64911063015461, longitude: 10.40743969380855)
let s = l.geohash(length: 10)
// s == "u4pruydqqv"
```

## Installation

Requires Swift 6.0 (Xcode 16) or newer.

Use Swift Package Manager:

```swift
.package(url: "https://github.com/nh7a/Geohash.git", from: "3.0.0")
```

Or copy [Geohash.swift](https://raw.githubusercontent.com/nh7a/Geohash/main/Sources/Geohash/Geohash.swift) into your project.

## Author

Naoki Hiroshima

## License

MIT. See [LICENSE](LICENSE).
