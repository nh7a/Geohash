// The MIT License (MIT)
//
// Copyright (c) 2016 Naoki Hiroshima
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

import Foundation

class Geohash {
    static func decode(hash: String) -> (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))? {
        // For example: hash = u4pruydqqvj
        
        let bits = hash.characters.map { bitmap[$0] ?? "?" }.joinWithSeparator("")
        guard bits.characters.count % 5 == 0 else { return nil }
        // bits = 1101000100101011011111010111100110010110101101101110001
        
        let (lat, lon) = bits.characters.enumerate().reduce(([Character](),[Character]())) {
            var result = $0
            if $1.0 % 2 == 0 {
                result.1.append($1.1)
            } else {
                result.0.append($1.1)
            }
            return result
        }
        // lat = [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0]
        // lon = [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1]

        func combiner(a: (min: Double, max: Double), value: Character) -> (Double, Double) {
            let mean = (a.min + a.max) / 2
            return value == "1" ? (mean, a.max) : (a.min, mean)
        }
        
        let latRange = lat.reduce((-90.0, 90.0), combine: combiner)
        // latRange = (57.649109959602356, 57.649111300706863)
        
        let lonRange = lon.reduce((-180.0, 180.0), combine: combiner)
        // lonRange = (10.407439023256302, 10.407440364360809)
        
        return (latRange, lonRange)
    }
    
    static func encode(latitude latitude: Double, longitude: Double, length: Int) -> String {
        // For example: (latitude, longitude) = (57.6491106301546, 10.4074396938086)
        
        func combiner(a: (min: Double, max: Double, array: [String]), value: Double) -> (Double, Double, [String]) {
            let mean = (a.min + a.max) / 2
            if value < mean {
                return (a.min, mean, a.array + "0")
            } else {
                return (mean, a.max, a.array + "1")
            }
        }
        
        let lat = Array(count: length*5, repeatedValue: latitude).reduce((-90.0, 90.0, [String]()), combine: combiner)
        // lat = (57.64911063015461, 57.649110630154766, [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,0,...])
        
        let lon = Array(count: length*5, repeatedValue: longitude).reduce((-180.0, 180.0, [String]()), combine: combiner)
        // lon = (10.407439693808236, 10.407439693808556, [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1,0,1,..])
        
        let latlon = lon.2.enumerate().flatMap { [$1, lat.2[$0]] }
        // latlon - [1,1,0,1,0,0,0,1,0,0,1,0,1,0,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,...]
        
        let bits = latlon.enumerate().reduce([String]()) { $1.0 % 5 > 0 ? $0 << $1.1 : $0 + $1.1 }
        //  bits: [11010,00100,10101,10111,11010,11110,01100,10110,10110,11011,10001,10010,10101,...]
        
        let arr = bits.flatMap { charmap[$0] }
        // arr: [u,4,p,r,u,y,d,q,q,v,j,k,p,b,...]
        
        return String(arr.prefix(length))
    }
    
    // MARK: Private
    
    private static let bitmap = "0123456789bcdefghjkmnpqrstuvwxyz".characters.enumerate()
        .map {
            ($1, String($0, radix: 2, padding: 5))
        }
        .reduce([Character:String]()) {
            var dict = $0
            dict[$1.0] = $1.1
            return dict
    }

    private static let charmap = bitmap
        .reduce([String:Character]()) {
            var dict = $0
            dict[$1.1] = $1.0
            return dict
    }
}

private extension String {
    init(_ n: Int, radix: Int, padding: Int) {
        let s = String(n, radix: radix)
        let pad = (padding - s.characters.count % padding) % padding
        self = Array(count: pad, repeatedValue: "0").joinWithSeparator("") + s
    }
}

private func + (left: Array<String>, right: String) -> Array<String> {
    var arr = left
    arr.append(right)
    return arr
}

private func << (left: Array<String>, right: String) -> Array<String> {
    var arr = left
    var s = arr.popLast()!
    s += right
    arr.append(s)
    return arr
}

#if os(OSX) || os(iOS)

// MARK: - CLLocationCoordinate2D

import CoreLocation

extension CLLocationCoordinate2D {
    init?(geohash: String) {
        guard let (lat, lon) = Geohash.decode(geohash) else { return nil }
        self = CLLocationCoordinate2DMake((lat.min + lat.max) / 2, (lon.min + lon.max) / 2)
    }
    
    func geohash(length: Int) -> String {
        return Geohash.encode(latitude: latitude, longitude: longitude, length: length)
    }
}

#endif
