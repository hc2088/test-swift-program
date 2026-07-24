//
//  string_algorithms.cpp
//  nowcoder_practice
//
//  字符串相关算法复习
//

#include <stdio.h>
#include <algorithm>
#include <iostream>
#include <string>
#include <unordered_set>
#include <vector>

using namespace std;

// ============================================================
// 字符串题：滑动窗口、回文、大数相加
// ============================================================

//最长不重复字串长度

//lengthOfLongestSubstring 的时间复杂度是：
//O(n)
//n 是字符串长度。
//你这个算法是滑动窗口：
//for (int i = 0, j = 0; i < s.length(); i++) {
//    while (values.contains(s[i])) {
//        values.erase(s[j]);
//        j++;
//    }
//
//    values.insert(s[i]);
//}
//看起来有一层 for，里面还有一层 while，但整体不是 O(n^2)。
//原因是：
//i 只会从左到右走一遍
//j 也只会从左到右走一遍
//每个字符最多：
//被 i 加入窗口一次
//被 j 移出窗口一次
//所以总操作次数最多大约是 2n，复杂度去掉常数就是：
//O(n)
//比如：
//s = "abcabcbb"
//i 负责不断扩展右边界，j 负责在遇到重复字符时收缩左边界。
//j 不会回头，所以不会重复扫描整个字符串。
//空间复杂度是：
//O(k)
//k 是字符集大小。比如只考虑 ASCII 字符，最多就是 O(128)，可以看作 O(1)；如果按一般字符串长度算，最坏是 O(n)，因为窗口里可能存下很多不重复字符。
int lengthOfLongestSubstring(string s) {

    unordered_set<char> values;//已初始化为空集合

    int maxLength = 0;
    int maxStart = 0;

    for (int i = 0, j = 0; i < s.length(); i++ ) {
        
        //abca
        //abcb
        //abcc
        while(values.contains(s[i])) {

            values.erase(s[j]);//删除最左边
            j++;//左边右移
        }

        values.insert(s[i]);

        int currentLength = i - j + 1;

        if (currentLength > maxLength ) {
            maxLength = currentLength;
            maxStart = j;
        }

    }

    string longest = s.substr(maxStart, maxLength);
    cout << "最长子串: " << longest << "\n";
    cout << "最长长度: " << maxLength << "\n";

    return maxLength;


}

//找到字符串中所有字母异位词
//找到s中所有 p的异位词
//滑动窗口
//
//给定两个字符串 s 和 p，找到 s 中所有 p 的 异位词 的子串，返回这些子串的起始索引。不考虑答案输出的顺序。
//
// 
//
//示例 1:
//
//输入: s = "cbaebabacd", p = "abc"
//输出: [0,6]
//解释:
//起始索引等于 0 的子串是 "cba", 它是 "abc" 的异位词。
//起始索引等于 6 的子串是 "bac", 它是 "abc" 的异位词。
// 示例 2:
//
//输入: s = "abab", p = "ab"
//输出: [0,1,2]
//解释:
//起始索引等于 0 的子串是 "ab", 它是 "ab" 的异位词。
//起始索引等于 1 的子串是 "ba", 它是 "ab" 的异位词。
//起始索引等于 2 的子串是 "ab", 它是 "ab" 的异位词。
//
//提示:
//
//1 <= s.length, p.length <= 3 * 10^4
//s 和 p 仅包含小写字母



//findAnagrams 的时间复杂度是：
//O(n)
//其中 n 是字符串 s 的长度。
//原因是主循环只遍历 s 一遍：
//for (int i = 0; i < s.size(); i++)
//每次循环做几件事：
//window[s[i] - 'a']++;
//右边字符进窗口，O(1)。
//window[s[i - windowLength] - 'a']--;
//左边字符出窗口，O(1)。
//window == need
//这里比较两个长度为 26 的数组，时间是 O(26)，因为只比较 26 个小写字母。26 是常数，所以看作 O(1)。
//所以整体是：
//O(n * 26) = O(n)
//空间复杂度是：
//O(1)
//因为 need 和 window 都是固定长度 26：
//vector<int> need(26, 0);
//vector<int> window(26, 0);
//不管 s 多长，这两个数组大小都不变。
//如果把返回结果 result 也算进去，最坏情况下可能存很多下标，空间是：
//O(n)
//但算法额外辅助空间是 O(1)。

//滑动窗口 + 哈希计数
vector<int> findAnagrams(string s, string p) {


    vector<int> result;


    if(p.empty()||s.size() < p.size()) {
        return result;
    }

    int windowLength = static_cast<int>(p.size());


    //必须要初始化长度，不然没办法下标操作
    vector<int> need(26, 0);///用来存放的，26个字符，出现的次数， 26个字符因为是26个英文字母，只包含小写字母
    vector<int> window(26, 0); /// 26个字符出现的次数

    //
    for (char c: p) {
        //统计p中每个字符出现的次数
        //用-'a'是为了找到下标
        need[c - 'a']++;/// 这是目标，转化成26个字母对应的数组，这个是关键创意
    }

        //abcabcaefg abc
    for (int i = 0; i < s.size(); i++) {///
        window[s[i] - 'a']++;//窗口，这个就是当前找到的窗口，这个窗口一直动态变化的


        if (i >= windowLength) {//这里一定要包括大于 而不仅仅是等于

            window[s[i-windowLength] - 'a']--;//把左边的字符移除当前窗口
        }



        //两个向量直接比较 是否相等，相等就值相同，这应该是vector向量的操作符实现的
        if(i + 1 >= windowLength && window == need) {
            int start = i - windowLength + 1;
            result.push_back(start);//

        }
    }


    for (int a : result) {
        printf("%d,",a);
    }
    printf("\n");
    return result;


}


//最长回文子串
//给你一个字符串 s，找到 s 中最长的 回文 子串。
//
// 
//
//示例 1：
//
//输入：s = "babad"
//输出："bab"
//解释："aba" 同样是符合题意的答案。


//示例 2：
//
//输入：s = "cbbd"
//输出："bb"


//longestPalindrome 这个算法的时间复杂度是：
//O(n^2)
//n 是字符串长度。

//你的写法是 中心扩展法：

//外层：
//for (int center = 0; center < n; center++)
//会枚举每一个字符作为中心，一共 n 次。
//内层：
//for (int offset = 0; offset <= 1; offset++)
//是为了处理两种回文中心：
//offset = 0：奇数长度回文，比如 aba
//offset = 1：偶数长度回文，比如 abba
//这个内层固定只跑 2 次，所以是常数，不影响复杂度。
//关键是：
//while (left >= 0 && right < n && s[left] == s[right])


//每个中心最坏情况下可能向两边扩展 O(n) 次。
//比如：
//s = "aaaaa"
//每个位置往外扩都能扩很远。


//所以整体就是：
//n 个中心 * 每个中心最多扩展 n 次 = O(n^2)


//空间复杂度是：
//O(1)

string longestPalindrome(string s) {

    if(s.empty()){
        return "";
    }

    int n = static_cast<int>(s.size());
    int i = 0 ;

    int length = 1;

    //遍历每一个可能的中心
    for (int center = 0; center < n; center++) { //n次

        //offset表示两种中心，0: aba，1:abba
        //检查奇数回文： offet：0
        //检查偶数回文： offset：1
        //左右字符相同，就继续向外扩展
        //记录遇到的最长回文
        for(int offset = 0; offset<=1;offset++){
            //offset=0：奇数长度
            //center=1:偶数长度 abba
            int left = center;
            //  当offset是0时，left=center，right=center， 奇数长度，每次都用center为中心
            //  当offset是1时，left=center，right=center+1
            int right = center+offset;

            //left>=0 左边不要越界
            //right<n 右边不要越界
            //offset=0：第一次while循环: 比较当前自己中间数，然后才是，左边和右边比较
            //左边和右边相等
            while (left>=0&&right<n&&s[left]==s[right]) {
                int currentLenght = right-left+1;//1 先记录1个
                if(currentLenght>length){
                    i = left;
                    length = currentLenght;
                }
                left--;//左边再往左移
                right++;//右边再往右移
            }
        }
    }

    string result = s.substr(i, length);
    cout << "最长回文字串：" << result << endl;
    return result;
}

void testStringSlidingWindowAndPalindrome(){


    printf("%d\n", lengthOfLongestSubstring("abc"));
    printf("%d\n", lengthOfLongestSubstring("abcabcbb"));
    printf("%d\n", lengthOfLongestSubstring("bbbbb"));
    printf("%d\n", lengthOfLongestSubstring("abcdabcde"));
    printf("%d\n", lengthOfLongestSubstring("aaaabcdef"));

    findAnagrams("abcabcaefg", "abc");
    longestPalindrome("abccbadabcaefg");
}


//addStrings 的时间复杂度是：
//O(max(m, n))
//其中：
//m = s1 的长度
//n = s2 的长度
//原因是它从两个字符串的末尾开始逐位相加：
//while (i >= 0 || j >= 0 || carray != 0)
//每一轮最多处理 s1 的一位和 s2 的一位，所以循环次数大约等于较长字符串的长度，最后如果还有进位，最多再多一次。
//比如：
//"999" + "1"
//会多处理一个进位，得到：
//"1000"
//但这个多出来的 1 是常数级，不影响复杂度。
//另外最后有一句：
//reverse(result.begin(), result.end());
//它也会遍历一次结果字符串，长度最多是：
//max(m, n) + 1
//所以总时间是：
//O(max(m, n)) + O(max(m, n)) = O(max(m, n))
//空间复杂度是：
//O(max(m, n))
//因为要创建一个结果字符串 result，长度最多比两个字符串中较长的那个多一位。
string addStrings(string s1, string s2) {
    //核心思想：从右往左逐位相加，用 carry 保存进位，把每一位结果先放进字符串，最后反转。
    string result;


    int i = static_cast<int>(s1.size()) - 1;

    //把size_t类型转化成int类型
    int j = static_cast<int>(s2.size()) - 1;

    int carray = 0;

    
    while (i >= 0 || j >= 0 || carray != 0) {
        int sum = carray;

        if(i >= 0) {
            sum += s1[i] - '0';//把字符串转化成int
            i--;
        }
        if(j >= 0) {
            sum += s2[j] - '0';//把字符串转化成int
            j--;
        }
        carray = sum/10;

        result.push_back((sum % 10) + '0');//把数字转化成字符串
    }

    std::reverse(result.begin(), result.end());
    return result;
}




void testAddStringsBigNumber(){

    cout << addStrings("123", "1111") << endl;
    cout << addStrings("", "") << endl;
    cout << addStrings("", "1111") << endl;

}
