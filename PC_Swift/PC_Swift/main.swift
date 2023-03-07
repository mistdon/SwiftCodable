//
//  main.swift
//  PC_Swift
//
//  Created by mistdon on 2022/11/4.
//

import Foundation

print("Hello, World!")

enum nationality: String {
    case china, usa, other
}

struct Pet: Decodable {
    /// dog name
    var name: String
    /// dog tag
    var tag: String?
}

struct Person: Decodable {
    @DecodableDefault.EmptyString
    var firstName: String

    @DecodableDefault.EmptyInt
    var age: Int
    
    @DecodableDefault.EmptyDouble
    var height: Double
    
    @DecodableDefault.False
    var femal: Bool
    
    @DecodableDefault.EmptyList
    var pets : [Pet]

    /// 在CodingKeys中移除hands，这样就不会参与decode过程，即使json数据不包含，也能解析成功
    var hands: Int = 2
    
    enum CodingKeys: CodingKey {
        case firstName
        case age
        case height
        case femal
        case pets
    }
}

let json = """
{
    "firstName": "Alice",
    "sons": 10
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
let person = try decoder.decode(Person.self, from: json)

print(person.firstName) // Output: Alice
print(person.age)

