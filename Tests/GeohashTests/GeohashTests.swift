// The MIT License (MIT)
//
// Copyright (c) 2019 Naoki Hiroshima
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Testing
@testable import Geohash

struct GeohashTests {
    @Test(arguments: [
        "garbage",
        "u$pruydqqvj",
        // Five invalid characters used to add up to a multiple of 5 bits and slip through.
        "aaaaa",
        "u4pruydqqvjaaaaa",
        "U4PRUYDQQVJ",
    ])
    func decodeInvalid(hash: String) {
        #expect(Geohash.decode(hash: hash) == nil)
    }

    @Test func decode() throws {
        let (lat, lon) = try #require(Geohash.decode(hash: "u4pruydqqvj"))
        #expect(lat.min == 57.649109959602356)
        #expect(lat.max == 57.649111300706863)
        #expect(lon.min == 10.407439023256302)
        #expect(lon.max == 10.407440364360809)
    }

    @Test(arguments: 1...11)
    func encode(length: Int) {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        #expect(Geohash.encode(latitude: lat, longitude: lon, length: length) == String("u4pruydqqvj".prefix(length)))
    }

    @Test(arguments: [
        (0.0, 0.0, -1),
        (.nan, 0.0, 5),
        (0.0, .nan, 5),
        (.infinity, 0.0, 5),
        (90.1, 0.0, 5),
        (0.0, -180.1, 5),
    ])
    func encodeInvalid(latitude: Double, longitude: Double, length: Int) {
        #expect(Geohash.encode(latitude: latitude, longitude: longitude, length: length) == nil)
    }

    @Test func encodeBoundaries() {
        #expect(Geohash.encode(latitude: 0, longitude: 0, length: 0) == "")
        #expect(Geohash.encode(latitude: 90, longitude: 180, length: 5) != nil)
        #expect(Geohash.encode(latitude: -90, longitude: -180, length: 5) != nil)
    }

    @Test(arguments: [Geohash.Direction.n, .e, .s, .w], ["", "U4PRUYDQQVJ", "u4pruydqqva", "a4pruydqqvj"])
    func adjacentInvalid(direction: Geohash.Direction, hash: String) {
        #expect(Geohash.adjacent(geohash: hash, direction: direction) == nil)
    }

    @Test(arguments: ["", "U4PRUYDQQVJ", "u4pruydqqva", "a4pruydqqvj"])
    func neighborsInvalid(hash: String) {
        #expect(Geohash.neighbors(geohash: hash) == nil)
    }

    @Test(arguments: [
        (Geohash.Direction.n, "u4pruydqqvm"),
        (.e, "u4pruydqqvn"),
        (.s, "u4pruydqquv"),
        (.w, "u4pruydqqvh"),
    ])
    func adjacent(direction: Geohash.Direction, expected: String) {
        #expect(Geohash.adjacent(geohash: "u4pruydqqvj", direction: direction) == expected)
    }

    @Test func adjacentAtPoles() throws {
        let north = try #require(Geohash.encode(latitude: 90, longitude: 10, length: 6))
        let south = try #require(Geohash.encode(latitude: -90, longitude: 10, length: 6))

        #expect(Geohash.adjacent(geohash: north, direction: .n) == nil)
        #expect(Geohash.adjacent(geohash: south, direction: .s) == nil)
        #expect(Geohash.adjacent(geohash: north, direction: .s) != nil)
        #expect(Geohash.adjacent(geohash: south, direction: .n) != nil)
        #expect(Geohash.adjacent(geohash: north, direction: .e) != nil)
        #expect(Geohash.adjacent(geohash: south, direction: .w) != nil)
        #expect(Geohash.neighbors(geohash: north) == nil)
        #expect(Geohash.neighbors(geohash: south) == nil)
    }

    @Test(arguments: ["z", "b", "zz", "bp", "zzzzzz"])
    func adjacentAtPolesAnyLength(hash: String) {
        // All of these are in the top row of the world.
        #expect(Geohash.adjacent(geohash: hash, direction: .n) == nil)
    }

    @Test(arguments: ["0", "1", "00", "08", "000000"])
    func adjacentAtSouthPoleAnyLength(hash: String) {
        // All of these are in the bottom row of the world.
        #expect(Geohash.adjacent(geohash: hash, direction: .s) == nil)
    }

    @Test func adjacentWrapsAroundAntimeridian() throws {
        let east = try #require(Geohash.encode(latitude: 10, longitude: 179.99999, length: 6))
        let west = try #require(Geohash.encode(latitude: 10, longitude: -179.99999, length: 6))

        let wrappedEast = try #require(Geohash.adjacent(geohash: east, direction: .e))
        let wrappedWest = try #require(Geohash.adjacent(geohash: west, direction: .w))
        #expect(try #require(Geohash.decode(hash: wrappedEast)).longitude.min == -180)
        #expect(try #require(Geohash.decode(hash: wrappedWest)).longitude.max == 180)
        #expect(Geohash.neighbors(geohash: east) != nil)
    }

    @Test func neighbors() {
        let expected = [
            "u4pruydqqvm", // n
            "u4pruydqqvn", // e
            "u4pruydqquv", // s
            "u4pruydqqvh", // w
            "u4pruydqqvq", // ne
            "u4pruydqquy", // se
            "u4pruydqqvk", // nw
            "u4pruydqquu"  // sw
        ]
        #expect(Geohash.neighbors(geohash: "u4pruydqqvj") == expected)
    }
}

#if canImport(CoreLocation)
import CoreLocation

struct GeohashCoreLocationTests {
    @Test func coreLocation() {
        #expect(!CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(geohash: "garbage")))

        let c = CLLocationCoordinate2D(geohash: "u4pruydqqvj")
        #expect(CLLocationCoordinate2DIsValid(c))
        #expect(c.geohash(length: 11) == "u4pruydqqvj")
    }
}

#endif
