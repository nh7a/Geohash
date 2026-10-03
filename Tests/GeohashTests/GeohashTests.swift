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

import XCTest
@testable import Geohash

final class GeohashTests: XCTestCase {
    func testDecode() {
        XCTAssertNil(Geohash.decode(hash: "garbage"))
        XCTAssertNil(Geohash.decode(hash: "u$pruydqqvj"))
        // Five invalid characters used to add up to a multiple of 5 bits and slip through.
        XCTAssertNil(Geohash.decode(hash: "aaaaa"))
        XCTAssertNil(Geohash.decode(hash: "u4pruydqqvj" + "aaaaa"))
        XCTAssertNil(Geohash.decode(hash: "U4PRUYDQQVJ"))

        let (lat, lon) = Geohash.decode(hash: "u4pruydqqvj")!
        XCTAssertTrue(lat.min == 57.649109959602356)
        XCTAssertTrue(lat.max == 57.649111300706863)
        XCTAssertTrue(lon.min == 10.407439023256302)
        XCTAssertTrue(lon.max == 10.407440364360809)
    }

    func testEncode() {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        let chars = "u4pruydqqvj"
        for i in 1...chars.count {
            XCTAssertTrue(Geohash.encode(latitude: lat, longitude: lon, length: i) == String(chars.prefix(i)))
        }
    }

    func testEncodeInvalidInput() {
        XCTAssertNil(Geohash.encode(latitude: 0, longitude: 0, length: -1))
        XCTAssertNil(Geohash.encode(latitude: .nan, longitude: 0, length: 5))
        XCTAssertNil(Geohash.encode(latitude: 0, longitude: .nan, length: 5))
        XCTAssertNil(Geohash.encode(latitude: .infinity, longitude: 0, length: 5))
        XCTAssertNil(Geohash.encode(latitude: 90.1, longitude: 0, length: 5))
        XCTAssertNil(Geohash.encode(latitude: 0, longitude: -180.1, length: 5))

        XCTAssertEqual(Geohash.encode(latitude: 0, longitude: 0, length: 0), "")
        XCTAssertNotNil(Geohash.encode(latitude: 90, longitude: 180, length: 5))
        XCTAssertNotNil(Geohash.encode(latitude: -90, longitude: -180, length: 5))
    }

    func testAdjacentInvalidInput() {
        for direction in [Geohash.Direction.n, .e, .s, .w] {
            XCTAssertNil(Geohash.adjacent(geohash: "", direction: direction))
            XCTAssertNil(Geohash.adjacent(geohash: "U4PRUYDQQVJ", direction: direction))
            XCTAssertNil(Geohash.adjacent(geohash: "u4pruydqqva", direction: direction))
            XCTAssertNil(Geohash.adjacent(geohash: "a4pruydqqvj", direction: direction))
        }
        XCTAssertNil(Geohash.neighbors(geohash: ""))
        XCTAssertNil(Geohash.neighbors(geohash: "u4pruydqqva"))
    }

    func testGetAdjacent() {
        let north = Geohash.adjacent(geohash: "u4pruydqqvj", direction: .n)
        let east = Geohash.adjacent(geohash: "u4pruydqqvj", direction: .e)
        let south = Geohash.adjacent(geohash: "u4pruydqqvj", direction: .s)
        let west = Geohash.adjacent(geohash: "u4pruydqqvj", direction: .w)

        XCTAssertEqual(north, "u4pruydqqvm")
        XCTAssertEqual(east, "u4pruydqqvn")
        XCTAssertEqual(south, "u4pruydqquv")
        XCTAssertEqual(west, "u4pruydqqvh")
    }

    func testGetNeighbors() {
        let neighbors = Geohash.neighbors(geohash: "u4pruydqqvj")
        let expectedNeighbors = [
            "u4pruydqqvm", // n
            "u4pruydqqvn", // e
            "u4pruydqquv", // s
            "u4pruydqqvh", // w
            "u4pruydqqvq", // ne
            "u4pruydqquy", // se
            "u4pruydqqvk", // nw
            "u4pruydqquu"  // sw
        ]
        XCTAssertEqual(neighbors, expectedNeighbors)
    }

    static let allTests = [
        ("testDecode", testDecode),
        ("testEncode", testEncode),
        ("testEncodeInvalidInput", testEncodeInvalidInput),
        ("testAdjacentInvalidInput", testAdjacentInvalidInput),
        ("testGetAdjacent", testGetAdjacent),
        ("testGetNeighbors", testGetNeighbors),
    ]
}

#if canImport(CoreLocation)
import CoreLocation

final class GeohashCoreLocationTests: XCTestCase {
    func testCoreLocation() {
        XCTAssertFalse(CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(geohash: "garbage")))

        let c = CLLocationCoordinate2D(geohash: "u4pruydqqvj")
        XCTAssertTrue(CLLocationCoordinate2DIsValid(c))
        XCTAssertTrue(c.geohash(length: 11) == "u4pruydqqvj")
    }

    static let allTests = [
        ("testCoreLocation", testCoreLocation),
    ]
}

#endif
