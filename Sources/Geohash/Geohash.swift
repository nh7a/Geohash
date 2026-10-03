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

#if canImport(CoreLocation)
import CoreLocation
#endif

public enum Geohash {
    public static func decode(hash: String) -> (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))? {
        // For example: hash = u4pruydqqvj

        let chunks = hash.compactMap { bitmap[$0] }
        guard chunks.count == hash.count else { return nil }
        let bits = chunks.joined(separator: "")
        // bits = 1101000100101011011111010111100110010110101101101110001

        let (lat, lon) = bits.enumerated().reduce(into: ([Character](), [Character]())) {
            if $1.0 % 2 == 0 {
                $0.1.append($1.1)
            } else {
                $0.0.append($1.1)
            }
        }
        // lat = [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0]
        // lon = [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1]

        func combiner(array a: (min: Double, max: Double), value: Character) -> (Double, Double) {
            let mean = (a.min + a.max) / 2
            return value == "1" ? (mean, a.max) : (a.min, mean)
        }

        let latRange = lat.reduce((-90.0, 90.0), combiner)
        // latRange = (57.649109959602356, 57.649111300706863)

        let lonRange = lon.reduce((-180.0, 180.0), combiner)
        // lonRange = (10.407439023256302, 10.407440364360809)

        return (latRange, lonRange)
    }

    /// Returns `nil` if `length` is negative or the coordinate is NaN or out of range.
    public static func encode(latitude: Double, longitude: Double, length: Int) -> String? {
        guard length >= 0,
              (-90.0...90.0).contains(latitude),
              (-180.0...180.0).contains(longitude) else { return nil }
        // For example: (latitude, longitude) = (57.6491106301546, 10.4074396938086)

        func combiner(array a: inout (min: Double, max: Double, array: [String]), value: Double) {
            let mean = (a.min + a.max) / 2
            if value < mean {
                a.max = mean
                a.array.append("0")
            } else {
                a.min = mean
                a.array.append("1")
            }
        }

        let lat = Array(repeating: latitude, count: length * 5).reduce(into: (min: -90.0, max: 90.0, array: [String]()), combiner)
        // lat = (57.64911063015461, 57.649110630154766, [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,0,...])

        let lon = Array(repeating: longitude, count: length * 5).reduce(into: (min: -180.0, max: 180.0, array: [String]()), combiner)
        // lon = (10.407439693808236, 10.407439693808556, [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1,0,1,..])

        let latlon = lon.2.enumerated().flatMap { [$1, lat.2[$0]] }
        // latlon - [1,1,0,1,0,0,0,1,0,0,1,0,1,0,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,...]

        let bits = latlon.enumerated().reduce(into: [String]()) {
            if $1.0 % 5 > 0 {
                $0[$0.count - 1] += $1.1
            } else {
                $0.append($1.1)
            }
        }
        //  bits: [11010,00100,10101,10111,11010,11110,01100,10110,10110,11011,10001,10010,10101,...]

        let arr = bits.compactMap { charmap[$0] }
        // arr: [u,4,p,r,u,y,d,q,q,v,j,k,p,b,...]

        return String(arr.prefix(length))
    }

    // MARK: Private

    private static let base32 = "0123456789bcdefghjkmnpqrstuvwxyz"

    private static let bitmap = base32
        .enumerated()
        .map {
            ($1, String(integer: $0, radix: 2, padding: 5))
        }
        .reduce(into: [Character: String]()) {
            $0[$1.0] = $1.1
        }

    private static let charmap = bitmap
        .reduce(into: [String: Character]()) {
            $0[$1.1] = $1.0
        }
}

#if canImport(CoreLocation)

// MARK: - CLLocationCoordinate2D

public extension CLLocationCoordinate2D {
    init(geohash: String) {
        if let (lat, lon) = Geohash.decode(hash: geohash) {
            self = CLLocationCoordinate2DMake((lat.min + lat.max) / 2, (lon.min + lon.max) / 2)
        } else {
            self = kCLLocationCoordinate2DInvalid
        }
    }

    func geohash(length: Int) -> String? {
        return Geohash.encode(latitude: latitude, longitude: longitude, length: length)
    }

    func geohash(precision: Geohash.Precision) -> String? {
        return geohash(length: precision.rawValue)
    }
}

#endif

public extension Geohash {
    enum Direction: String, Sendable {
        case n, e, s, w

        var neighbor: [String] {
            switch self {
            case .n:
                return ["p0r21436x8zb9dcf5h7kjnmqesgutwvy", "bc01fg45238967deuvhjyznpkmstqrwx"]
            case .e:
                return ["bc01fg45238967deuvhjyznpkmstqrwx", "p0r21436x8zb9dcf5h7kjnmqesgutwvy"]
            case .s:
                return ["14365h7k9dcfesgujnmqp0r2twvyx8zb", "238967debc01fg45kmstqrwxuvhjyznp"]
            case .w:
                return ["238967debc01fg45kmstqrwxuvhjyznp", "14365h7k9dcfesgujnmqp0r2twvyx8zb"]
            }
        }

        var border: [String] {
            switch self {
            case .n:
                return ["prxz", "bcfguvyz"]
            case .e:
                return ["bcfguvyz", "prxz"]
            case .s:
                return ["028b", "0145hjnp"]
            case .w:
                return ["0145hjnp", "028b"]
            }
        }
    }

    /// Returns `nil` if `geohash` is not a valid geohash.
    static func adjacent(geohash: String, direction: Direction) -> String? {
        guard isValid(geohash) else { return nil }
        return _adjacent(geohash: geohash, direction: direction)
    }

    /// Returns `nil` if `geohash` is not a valid geohash.
    static func neighbors(geohash: String) -> [String]? {
        guard isValid(geohash) else { return nil }

        let n = _adjacent(geohash: geohash, direction: .n)
        let e = _adjacent(geohash: geohash, direction: .e)
        let s = _adjacent(geohash: geohash, direction: .s)
        let w = _adjacent(geohash: geohash, direction: .w)

        return [
            n, e, s, w,
            _adjacent(geohash: n, direction: .e), // ne
            _adjacent(geohash: s, direction: .e), // se
            _adjacent(geohash: n, direction: .w), // nw
            _adjacent(geohash: s, direction: .w) // sw
        ]
    }

    /// A valid geohash is non-empty and made only of characters from the base32 alphabet.
    private static func isValid(_ geohash: String) -> Bool {
        !geohash.isEmpty && geohash.allSatisfy { bitmap[$0] != nil }
    }

    // The caller must have checked that `geohash` is valid.
    private static func _adjacent(geohash: String, direction: Direction) -> String {
        let lastChar = geohash.last!
        var parent = String(geohash.dropLast())
        let type = geohash.count % 2

        // Check for edge-cases which don't share common prefix
        if direction.border[type].contains(lastChar), !parent.isEmpty {
            parent = _adjacent(geohash: parent, direction: direction)
        }

        // Append letter for direction to parent
        let charIndex = direction.neighbor[type].distance(of: lastChar)!

        return parent + String(base32[charIndex])
    }
}

// MARK: Extensions
public extension Geohash {
    enum Precision: Int, Sendable {
        case twentyFiveHundredKilometers = 1    // ±2500 km
        case sixHundredThirtyKilometers         // ±630 km
        case seventyEightKilometers             // ±78 km
        case twentyKilometers                   // ±20 km
        case twentyFourHundredMeters            // ±2.4 km
        case sixHundredTenMeters                // ±0.61 km
        case seventySixMeters                   // ±0.076 km
        case nineteenMeters                     // ±0.019 km
        case twoHundredFourtyCentimeters        // ±0.0024 km
        case sixtyCentimeters                   // ±0.00060 km
        case seventyFourMillimeters             // ±0.000074 km
    }

    static func encode(latitude: Double, longitude: Double, precision: Precision) -> String? {
        return encode(latitude: latitude, longitude: longitude, length: precision.rawValue)
    }
}

private extension String {
    init(integer n: Int, radix: Int, padding: Int) {
        let s = String(n, radix: radix)
        let pad = (padding - s.count % padding) % padding
        self = Array(repeating: "0", count: pad).joined(separator: "") + s
    }
}

private extension StringProtocol {
    func distance(of element: Element) -> Int? { firstIndex(of: element)?.distance(in: self) }

    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

private extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}

private extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(to: self) }
}
