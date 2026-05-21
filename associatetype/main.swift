//
//  main.swift
//  associatetype
//
//  Created by huchu on 2025/8/8.
//

import Foundation

print("Hello, World!")


protocol DataSource {
    
    func load() -> String
}


class Aclass:DataSource{
    func load() -> String {
        return "123123"
    }
}


let a: DataSource = Aclass()

print(a.load())


//let b: DataSource = DataSource()
//
//print(b.load())



protocol DataSource2 {
    associatedtype DataType
    func load() -> DataType
}




class Aclass2:DataSource2{
    func load() -> String {
        return "123123"
    }
}

let a2: any DataSource2 = Aclass2()

print(a2.load())




class DataSource3<T> {
    func load() -> T {
        fatalError("Subclasses must override this method")
    }
}



class StringSource: DataSource3<String> {
    override func load() -> String {
        return "Hello"
    }
}

class IntSource: DataSource3<Int> {
    override func load() -> Int {
        return 42
    }
}


let stringSource = StringSource()
print(stringSource.load())  // Hello

let intSource = IntSource()
print(intSource.load())




func printData<T>(from source: DataSource3<T>) {
    print(source.load())
}

printData(from: StringSource())  // Hello
printData(from: IntSource())




protocol DataSource4 {
    associatedtype Data
    func load() -> Data
}


//let source: DataSource4

//类型擦除封装类
class AnyDataSource<T>: DataSource4 {
    private let _load: () -> T
    
    
    
        //类型擦除封装类
        //where DS.Data == T
    init<DS: DataSource4>(_ dataSource: DS) where DS.Data == T {
        self._load = dataSource.load
    }
    
    func load() -> T {
        return _load()
    }
}

struct StringSource4: DataSource4 {
    func load() -> String {
        return "Hello from StringSource"
    }
}

struct IntSource4: DataSource4 {
    func load() -> Int {
        return 100
    }
}


let stringSource4 = AnyDataSource(StringSource4())
let intSource4 = AnyDataSource(IntSource4())

print(stringSource4.load())  // 输出: Hello from StringSource
print(intSource4.load())     // 输出: 100
