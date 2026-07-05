//
//  linked_list_test.cpp
//  nowcoder_practice
//
//  Created by huchu on 2026/6/29.
//

#include <stdio.h>
#include <iostream>
#include <initializer_list>
#include <sstream>
#include <string>

#include <set>
#include <unordered_set>



using namespace std;

struct ListNode {
    int val;
    ListNode* next;
    ListNode(int x) : val(x), next(nullptr) {}
};



class Solution {
public:
    
    ListNode* reverseList(ListNode* head) {
        if (head == nullptr) {
            return nullptr;
        }
        ListNode *previous = nullptr;
        ListNode *current = head;
        
        while (current != nullptr) {
            
            ListNode *next = current->next;
            
            
            current->next = previous;
            
            previous = current;
            
            current = next;
            
            
        }
        return previous;
        
    }
    
    void printNode(ListNode* head) {
        ListNode* p = head;
        bool isFirst = true;
        
        while (p != nullptr) {
            if (!isFirst) {
                cout << ",";
            }
            cout << p->val;
            isFirst = false;
            p = p->next;
        }
        cout << "\n";
    }
};

void testLinkedList() {
    ListNode* tail = nullptr;
    ListNode* head = nullptr;
    
    cout << "请输入整数（用逗号分隔，回车结束）：";
    string input;
    getline(cin, input);//用getline读取一整行,从cin标准输入，读取一行内容到input
    
    //stringstream inputStream(input); //直接初始化，stringstream inputStream = stringstream(input);
    //还有一种写法：
    stringstream inputStream{input};
    string item;
    while (getline(inputStream, item, ',')) { //getline，从inputStream 读取内容，保存到item，遇到,字符停止,逗号会被读取掉，不会放进item
        stringstream itemStream(item);//创建一个名为itemStream的stringstream类型的对象，把item放进去
        
        
        int number = 0;
        char extra = '\0';
        
        // item 必须包含且只包含一个整数，前后可以有空格。
        if (!(itemStream >> number) || (itemStream >> extra)) {
            cout << "忽略无效内容：" << item << "\n";
            continue;
        }
        
        ListNode* node = new ListNode(number);
        if (head == nullptr) {
            head = node;
            tail = node;
        } else {
            tail->next = node;
            tail = node;
        }
    }
    
    Solution solution;
    solution.printNode(head);
    ListNode *newList = solution.reverseList(head);
    solution.printNode(newList);
    
    
    
    // 逐个释放用 new 创建的节点。
    while (newList != nullptr) {
        ListNode* next = newList->next;
        delete newList;
        newList = next;
    }
}


void testLinkedList2() {
    ListNode* head = nullptr;
    ListNode* tail = nullptr;
    
    // 依次使用 1、2、3、4、5 创建并连接链表节点。
    //创建一个轻量对象，用于查看编译器生成的只读元素列表
    //int values[] = {1, 2, 3};
    for (int value : {1, 2, 3, 4, 5}) {
        ListNode* node = new ListNode(value);
        
        if (head == nullptr) {
            head = node;
            tail = node;
        } else {
            tail->next = node;
            tail = node;
        }
    }
    
    Solution solution;
    solution.printNode(head);
    
    ListNode *newList = solution.reverseList(head);
    solution.printNode(newList);
    
    
    
    
    // 逐个释放用 new 创建的节点。
    while (newList != nullptr) {
        ListNode* next = newList->next;
        delete newList;
        newList = next;
    }
}




class Solution2 {
public:
    
    ListNode* ReverseList(ListNode* head) {
        ListNode *previous = nullptr;
        ListNode *current = head;
        while (current != nullptr) {
            ListNode *next =  current->next;
            current->next = previous;
            previous = current;
            current = next;
        }
        return previous;
    }
    void printNode(ListNode *head){
        while (head!=nullptr) {
            printf("%d,",head->val);
            head =  head->next;
        }
        printf("\n");
    }
    
};


void testLinkedList3 (){
    ListNode* head = nullptr;
    ListNode* last = nullptr;
    for (int a : {
        1, 2, 3,4,5
    }) {
        if (last == nullptr) {
            last = new ListNode(a);
            head = last;
            head->next = nullptr;
        } else {
            last->next = new ListNode(a);
            last = last->next;
        }
        
    }
    
    Solution2 *s = new Solution2();
    s->printNode(head);
    ListNode *newList = s->ReverseList(head);
    s->printNode(newList);
    
}




class Solution3 {
public:
    
    ListNode* Merge(ListNode* pHead1,ListNode *pHead2) {
        
        /// 一个临时的“固定起点”，让链表头节点和普通节点使用完全相同的连接逻辑
        ListNode node = ListNode(0);//先创建一个节点。
        ListNode *last = &node; //先来一个指针
        
        
        while  (pHead1 != nullptr && pHead2 != nullptr) {
            
            if (pHead1->val <= pHead2->val) {
                last->next = pHead1;
                pHead1 = pHead1->next;
                
            } else {
                last->next = pHead2;
                pHead2 = pHead2->next;
            }
            last = last->next;
            
        }
        
        // 某个链表还有剩余节点， 直接链接 到末尾
        if (pHead1 != nullptr) {
            last->next = pHead1;
        } else {
            last->next = pHead2;
        }
        
        return  node.next;//这就是第一个节点
    }
    
    void printNode(ListNode *head){
        while (head!=nullptr) {
            printf("%d,",head->val);
            head =  head->next;
        }
        printf("\n");
    }
    
    ListNode *createList(initializer_list<int> values ) {
        ListNode* head = nullptr;
        ListNode* last = nullptr;
        
        for (int a : values) {
            if (last == nullptr) {
                last = new ListNode(a);
                head = last;
                head->next = nullptr;
            } else {
                last->next = new ListNode(a);
                last = last->next;
            }
            
        }
        return head;
    }
    
    void deleteList(ListNode *&head){
        while (head != nullptr) {
            ListNode *next = head->next;
            delete head;
            head = next;
        }
    }
    
};


void testMerge () {
    Solution3 *solution = new Solution3();
    ListNode* head1 = solution->createList({1, 2, 3, 4, 5});
    ListNode* head2 = solution->createList({1, 2, 3, 4, 5});
    solution->printNode(head1);
    solution->printNode(head2);
    ListNode *newList = solution->Merge(head1, head2);
    solution->printNode(newList);
    
    
}


class Solution4 {
    
    
public:
    
    //最长不重复字串长度
    int lengthOfLongestSubstring(string s) {
        
        unordered_set<char> values;//已初始化为空集合
        
        int maxLength = 0;
        int maxStart = 0;
        
        for (int i = 0, j = 0; i < s.length(); i++ ) {
            
            
            
            //abca
            //abcb
            //abcc
            while(values.contains(s[i])) {
            //while(values.count(s[i]) > 0) {
                
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
    
    
    
    
    //给定一个未排序的整数数组 nums ，找出数字连续的最长序列
    //（不要求序列元素在原数组中连续）的长度。
    int longestConsecutive(const vector<int>& nums) {
        
        //先去重
        unordered_set<int> values(nums.begin(), nums.end());
        
        //{1,0,1}， {1,0}
        
        //set:平衡二叉树，自动排序，去重
        //unordered_set: 哈希表,顺序不确定，去重，O(1)
        //set<int> values(nums.begin(), nums.end());
        
        int maxLength =  0 ;
        for(int value: values) {//values里面是无序的，去重的集合。
            //{1,0}
            
            //value-1 存在，说明，value不是序列起点
            
            
            if(values.contains(value-1)) {
                continue;
            }
            
            int current = value;//锚点 当前值
            int currentLenght = 1;///本次value为锚点，先假定只有锚点value，当前长度为1
            
            //找连续的序列，如果连续的数字存在 就一直找
            while (values.contains(current+1)) {//1
                current++;//这里直接加+1，因为这样判断是不是连续的
                currentLenght++;//一直更新长度
            }
            
            
            maxLength = max(maxLength, currentLenght);
            
            
            
        }
        
        
        cout << "最长连续序列: " << maxLength << "\n";
        return maxLength;
    }
    
    
    
    
    //找到s中所有 p的异位词
    //滑动窗口
    vector<int> findAnagrams(string s, string p) {
        
        
        vector<int> result;
        
        
        if(p.empty()||s.size() < p.size()) {
            return result;
        }
        
        int windowLength = static_cast<int>(p.size());
        
        
        //必须要初始化长度， 不然没办法下标操作
        vector<int> need(26, 0);///用来存放的， 26个字符，出现的次数
        vector<int> window(26, 0); /// 26个字符出现的次数
        
        for (char c: p) {
            //统计p中每个字符出现的次数
            need[c - 'a']++;/// 这是目标，转化成26个字母对应的数组，这个是关键创意
        }
        
        for (int i = 0; i < s.size(); i++) {///
            window[s[i] - 'a']++;//窗口，这个就是当前找到的窗口，这个窗口一直动态变化的
            
            
            if (i >= windowLength) {//这里一定要包括大于 而不仅仅是等于
                
                window[s[i-windowLength] - 'a']--;
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
    string longestPalindrome(string s) {

        if(s.empty()){
            return "";
        }
        
        int n = static_cast<int>(s.size());
        int i = 0 ;
        
        int length = 1;
        
        //遍历每一个可能的中心
        for (int center = 0; center < n; center++) {
            
            //offset表示两种中心， 0: aba，1:abba
            //检查奇数回文
            //检查偶数回文
            //左右字符相同，就继续向外扩展
            //记录遇到的最长回文
            for(int offset = 0; offset<=1;offset++){
                 //offset=0： 奇数长度
                //center=1:偶数长度 abba
                int left = center; // 0
                int right = center+offset; //1
                
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
    
};


void testLongestSubstring(){
    
    Solution4 *solution = new Solution4();
    
    printf("%d\n",solution->lengthOfLongestSubstring("abc"));
    printf("%d\n",solution->lengthOfLongestSubstring("abcabcbb"));
    printf("%d\n",solution->lengthOfLongestSubstring("bbbbb"));
    printf("%d\n",solution->lengthOfLongestSubstring("abcdabcde"));
    printf("%d\n",solution->lengthOfLongestSubstring("aaaabcdef"));
    
    
    vector<int> nums = {1,0,2};
    
    solution->longestConsecutive(nums);
    
    
    solution->findAnagrams("abcabcaefg", "abc");
    solution->longestPalindrome("abccbadabcaefg");
}
