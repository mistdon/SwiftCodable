# SwiftCodable
## Codble

Codable 协议在 Swift4.0 开始被引入，目标是取代现有的 NSCoding 协议，它对结构体，枚举和类都支持。Codable 的引入简化了JSON 和 Swift 类型之间相互转换的难度，能够把 JSON 这种弱类型数据转换成代码中使用的强类型数据。

Codable 是 Encodable 和 Decodable 两个协议的组合：
```swift
public typealias Codable = Decodable & Encodable
```

Encodable 协议定义了一个方法：
```swift
public protocol Encodable {
    func encode(to encoder: Encoder) throws
} 
```
如数据遵守这个协议，并且数据中所有成员都是 encodable，编译器会自动生成相关实现。 如不可编码，需自定义，自己实现。

Decodable 协议定义了一个初始化函数：
```swift
public protocol Decodable {
    init(from decoder: Decoder) throws
}
```
跟 Encodable 一样，编译器也会自动为你生成相关的实现，前提是所有成员属性都是 Decodable 的。

由于 Swift 标准库中的类型，比如 String，Int，Double 和 Foundation 框架中 Data，Date，URL 都是默认支持 Codable 协议的，所以只需声明支持协议即可。
我们不必同时遵循 Decodable、Encodable 协议，比如项目中只需获取网络数据解析为 Swift 类型，只需遵循 Decodable 协议就行了。我们要根据需要有选择的遵循 Decodable、Encodable 协议。

### 解码、编码过程
简单了解 Codable 后，我们先看看怎么使用的，看下面例子：
```swift
struct Person: Codable {
    let name: String
    let age: Int
}

//解码 JSON 数据
let json = #" {"name":"Tom", "age": 2} "#
let person = try JSONDecoder().decode(Person.self, from: json.data(using: .utf8)!)
print(person) //Person(name: "Tom", age: 2)

//编码导出为 JSON 数据
let data0 = try? JSONEncoder().encode(person)
let dataObject = try? JSONSerialization.jsonObject(with: data0!, options: [])
print(dataObject ?? "nil") //{ age = 2; name = Tom; }

let data1 = try? JSONSerialization.data(withJSONObject: ["name": person.name, "age": person.age], options: [])
print(String(data: data1!, encoding: .utf8)!) //{"name":"Tom","age":2}
```

上面的例子实现了从 JSON 数据解码到 Swift 中的数据，以及编码导出 JSON 数据，Person 中成员变量是遵循 Codable 协议的，所以编译器会自动生成相关的代码来实现编码、解码，我们只需调用 decode()、encode() 相关函数即可。
那么 Codable 是怎么实现呢？在编译代码时根据类型的属性，自动生成了一个 CodingKeys 的枚举类型定义，这个枚举需要包含需要编码或解码的属性字段，CodingKeys 枚举的 case 名称应该与类型中对应属性的名称相匹配。然后再给每一个声明实现 Codable 协议的类型自动生成 init(from:) 和 encode(to:) 两个函数的具体实现，最终完成了整个协议的实现。

### 字段匹配的问题
有时后端接口返回的数据命名规则和前端不一致，可能后端返回下划线命名法，而一般我们使用驼峰命名法，所以在字段映射的时候就需要修改一下。使用 CodingKeys 指定一个明确的映射。
```swift
struct Person: Codable {
    let firstName: String
    let age: Int
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case age
    }
}

// {"first_name":"Tom", "age": 2 }
```

如果数据类型中的属性只有部分需要从 JSON 中解析获取，或者 JSON 中数据字段较多只需解析一部分，这是可以重写 CodingKeys 枚举值中仅列出需要解析的字段即可。
```swift
struct Person: Codable {
    let firstName: String
    let age: Int
    var additionalInfo: String?
    var addressInfo: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case age
    }
}
```

### 字段类型匹配的问题

Codble不支持自动转换类型，解析类型必须和数据类型一致，比如Int -> Int, String -> String,

否则会报 **DecodingError typeMismatch** 的错误

### 嵌套类型
Swift 数据中属性可能是，嵌套的对象类型、数组或者字典类型，只要其中的每个元素都遵循 Codable 协议，那么整体数据类型就遵循 Codable 协议。
```json
{
    "family_name":"101",
    "persons":[
          {
             "name": "小明",
             "age": 1
          },
          {
             "name": "小红",
             "age": 1
          }
    ]
}
```

```swift
struct Person: Codable {
    let name: String
    let age: Int
}

struct Family: Codable {
    let familyName: String
    let persons: [Person]
}

let family = try JSONDecoder().decode(Family.self, from: json.data(using: .utf8)!)
print(family)
```

### 空值字段问题
有时后端接口返回的数据可能有值，也可能只是返回空值，如何处理？
```json
{
    "familyName":"101",
    "person1": {
        "name": "小明",
        "age": 1
    },
    "person2": {},
    "person3": null
}
```
这时需要把属性设置为可选的，当返回为空对象或 null 时，解析为 nil。
```swift
struct Person: Codable {
    var name: String?
    var age: Int?
}
struct Family: Codable {
    let familyName: String
    var person1: Person?
    var person2: Person?
    var person3: Person?
}
```

###  枚举值
在后端返回的数据中，有的字段是确定的几种类别，我们希望转换成枚举类型，方便使用。例如性别数据：
```json
{
    "name": "小明",
    "age": 1,
    "gender": "male"
}
```

```swift
enum Gender: String, Codable {
    case male
    case female
}
struct Person: Codable {
    var name: String?
    var age: Int?
    var gender: Gender?
}
```
枚举类型要默认支持 Codable 协议，需要声明为具有原始值的形式，并且原始值的类型需要支持 Codable 协议。上面例子使用字符串作为枚举类型的原始值，每个枚举成员的隐式原始值为该枚举成员的名称。如果对应的数据为整数的话，枚举可声明为：
```swift
enum Gender: Int, Codable {
    case male = 1
    case female = 2
}
```
## Default value
以上是Codable的基础用法，但是有一个场景，Codabe不支持，就是默认值。
```swift
struct Article: Decodable {
    var title: String
    var body: String
    var isFeatured: Bool = false // This value isn't used when decoding
}
```
当一个属性，后端返回可能为空的时候，我们必须用Optional，否则可能解析失败。但是我们也想使用var的默认值，该怎么做的？这时候就需要用到PropertyWrapped。
```swift
@propertyWrapper
struct DecodableBool {
    var wrappedValue = false
}
```
比如在上面的例子中，我们可以使用一个DecodableBool包装器来实现默认值*false*

然后利用Decoable的扩展（不覆盖类型的成员初始化器）来解析
```swift
extension DecodableBool: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Bool.self)
    }
}
```
然后利用 ** KeyedDecodingContainer ** 解码的重载扩展类型来完成DecodableBool。这样，只会在值存在的琴况下继续解码给定的键。否则将返回包装器的空实例。
```swift
extension KeyedDecodingContainer {
    func decode(_ type: DecodableBool.Type,
                forKey key: Key) throws -> DecodableBool {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}
```
然后在使用的时候只需要添加即可
```swift
struct Article: Decodable {
    var title: String
    var body: String
    @DecodableBool var isFeatured: Bool
}
```
最后给出适用于所有类型的扩展
```swift
protocol DecodableDefaultSource {
    associatedtype Value: Decodable
    static var defaultValue: Value { get }
}

/// 使用空枚举，使得其不能被初始化，以便当作纯包装器
enum DecodableDefault {}

extension DecodableDefault {
    @propertyWrapper
    struct Wrapper<Source: DecodableDefaultSource> {
        typealias Value = Source.Value
        var wrappedValue = Source.defaultValue
    }
}

extension DecodableDefault.Wrapper: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Value.self)
    }
}

extension KeyedDecodingContainer {
    func decode<T>(_ type: DecodableDefault.Wrapper<T>.Type,
                   forKey key: Key) throws -> DecodableDefault.Wrapper<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}

extension DecodableDefault {
    typealias Source = DecodableDefaultSource
    typealias List = Decodable & ExpressibleByArrayLiteral
    typealias Map = Decodable & ExpressibleByDictionaryLiteral

    enum Sources {
        enum True: Source {
            static var defaultValue: Bool { true }
        }

        enum False: Source {
            static var defaultValue: Bool { false }
        }

        enum EmptyString: Source {
            static var defaultValue: String { "" }
        }
        
        enum EmptyInt: Source {
            static var defaultValue: Int  { 0 }
        }
        
        enum EmptyDouble: Source {
            static var defaultValue: Double { 0.0 }
        }
        
        enum EmptyList<T: List>: Source {
            static var defaultValue: T { [] }
        }

        enum EmptyMap<T: Map>: Source {
            static var defaultValue: T { [:] }
        }
    }
}

extension DecodableDefault {
    typealias True = Wrapper<Sources.True>
    typealias False = Wrapper<Sources.False>
    typealias EmptyString = Wrapper<Sources.EmptyString>
    typealias EmptyInt = Wrapper<Sources.EmptyInt>
    typealias EmptyDouble = Wrapper<Sources.EmptyDouble>
    typealias EmptyList<T: List> = Wrapper<Sources.EmptyList<T>>
    typealias EmptyMap<T: Map> = Wrapper<Sources.EmptyMap<T>>
}
```

### 注意事项：

1、Codable不能把Int自动转为Bool，比如JSON中value是int，class/strtuc中为bool，就会报错: Expected to decode Bool but found a number instead.

2、Coding没有默认值的概念，要么是必选，要么是可选。必选的话JSON必须包含，否则会报错，建议让所有参数都是可选。

参考链接：https://www.swiftbysundell.com/tips/default-decoding-values/
