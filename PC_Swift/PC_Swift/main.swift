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

    @DecodableDefault.EmptyString
    var lastName: String

    @DecodableDefault.EmptyInt
    var age: Int
    
    @DecodableDefault.EmptyDouble
    var height: Double
    
    @DecodableDefault.False
    var femal: Bool
    
    var sons: Int
    
    @DecodableDefault.EmptyList
    var pets : [Pet]
    
    @DecodableDefault.EmptyString
    var familtName: String
    
    enum CodingKeys: CodingKey {
        case firstName
        case lastName
        case age
        case height
        case femal
        case sons
        case pets
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._firstName = try container.decode(DecodableDefault.EmptyString.self, forKey: .firstName)
        self._lastName = try container.decode(DecodableDefault.EmptyString.self, forKey: .lastName)
        self._age = try container.decode(DecodableDefault.EmptyInt.self, forKey: .age)
        self._height = try container.decode(DecodableDefault.EmptyDouble.self, forKey: .height)
        self._femal = try container.decode(DecodableDefault.False.self, forKey: .femal)
        self.sons = try container.decode(Int.self, forKey: .sons)
        self._pets = try container.decode(DecodableDefault.Wrapper<DecodableDefault.Sources.EmptyList<[Pet]>>.self, forKey: .pets)
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
print(person.lastName) // Output: Doe
print(person.sons)
print(person.age)

