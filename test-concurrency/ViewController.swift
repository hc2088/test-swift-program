//
//  ViewController.swift
//  test-concurrency
//
//  Created by huchu on 2025/8/3.
//
import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建按钮
        let testButton = UIButton(type: .system)
        testButton.setTitle("测试 Actor", for: .normal)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testButton)
        
        // 约束按钮居中显示
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 120),
            testButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // 按钮点击事件
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
    }
    
    @objc private func testButtonTapped() {
        
        for i in 1...100 {
            
//            Task {
//                await testBankAccountConcurrency(name: "withTaskGroup-\(i)")
//            }
//            
//            
//            Task {
//                await testBankAccountConcurrency2(name: "async let-\(i)")
//            }
//            
            DispatchQueue.global().async {
              
                testError(name:"gcd-\(i)")
            }
            
//            DispatchQueue.global().async {
//                testSafeBankAccountConcurrency(name: "普通 class + GCD-\(i)")
//            }
//            
            
        }
    }
    
}
