//
//  test1.swift
//  test-swift-program
//
//  Created by v-huchu on 2025/4/13.
//

import Foundation

public class AClass{
    var name:String
    init(name: String) {
        self.name = name
    }
    func asa(){
        AClass3(name: "1231")
        print("asdfasf")
        
        
        let a4 = AClass4(name: "asdfasdf")
        a4.name2
        a4.name
        
        //private不能访问的
        //name3' is inaccessible due to 'private' protection level
        //a4.name3
    }
}

internal class AClass2{
    var name:String
    init(name: String) {
        self.name = name
    }
}


fileprivate class AClass3{
    var name:String
    init(name: String) {
        self.name = name
    }
}


private class AClass4{
    var name:String
    fileprivate var name2:String
    private var name3:String
    
    init(name: String) {
        self.name = name
        self.name2 = name
        self.name3 = name
    }
}




public enum Student13 {
    
    //枚举名字，类型
    case Name(String)
    
    //枚举名字，类型
    case Mark(Int,Int,Int)
}
 
var studDetails13 = Student13.Name("Swift")
var studMarks13 = Student13.Mark(98,97,95)


func test(){
    
   switch studMarks13 {
       //枚举名字+类型
   case .Name(let studName):
       print("学生名: \(studName).")
       
       //枚举名字+；类型
   case .Mark(let Mark1, let Mark2, let Mark3):
       print("学生成绩: \(Mark1),\(Mark2),\(Mark3)")
   }

}


