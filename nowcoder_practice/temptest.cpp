//
//  temptest.cpp
//  nowcoder_practice
//
//  Created by huchu on 2026/7/10.
//

#include <stdio.h>

#include <algorithm>
#include <iostream>
#include <string>
#include <unordered_set>
#include <vector>

using namespace std;

string addString(string s1, string s2) {
    
    string result;
    
    int carray = 0;

    int i = static_cast<int>(s1.size()-1);//从后面迭代,个位开始加
    int j = static_cast<int>(s2.size()-1);
    
    
    while (i >=0 || j >= 0 || carray!= 0) {
        
        int sum = carray;//把上一轮地位上的求和得到的进位带过来
        
        
        if( i >=0 ) {//取第一个数
            sum += s1[i] - '0';
            
        }
        if(j >=0) {
            sum += s2[j] - '0';
        }
        
        carray = sum/10;//算出进位
        
        result.push_back((sum%10)+'0');
        
    }
    
    std::reverse(result.begin(), result.end());
    
    return result;
}
 
