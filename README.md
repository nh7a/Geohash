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
```
## CLLocationCoordinate2D extension
```swift
if let l = CLLocationCoordinate2D(geohash: "u4pruydqqvj") {
  // l.latitude == 57.64911063015461
  // l.longitude == 10.407439693808556
}

let l = CLLocationCoordinate2D(latitude: 57.64911063015461, longitude: 10.40743969380855)
let s = l.geohash(length: 10)
// s == u4pruydqqv
````
## Installation

Use Swift Package Manager or copy [Geohash.swift](https://raw.githubusercontent.com/nh7a/Geohash/master/Sources/Geohash/Geohash.swift) into your project.

## Author

Naoki Hiroshima

