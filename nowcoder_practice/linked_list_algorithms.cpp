//
//  linked_list_algorithms.cpp
//  nowcoder_practice
//
//  Created by huchu on 2026/6/29.
//

#include <stdio.h>
#include <algorithm>
#include <iostream>
#include <initializer_list>
#include <sstream>
#include <string>
#include <vector>

#include <set>
#include <unordered_set>

using namespace std;

// ============================================================
// 基础结构
// ============================================================

struct ListNode {
    int val;
    ListNode* next;
    ListNode(int x) : val(x), next(nullptr) {}
};

// ============================================================
// 链表工具函数：创建、打印、释放
// ============================================================

// vector<int> 向量容器，整型动态数组
ListNode *buildList(vector<int> nums) {

    ListNode dummy(0);//借助一个虚拟节点
    ListNode *current = &dummy;

    for (int num : nums) {
        //尾插法
        current->next = new ListNode(num);
        current = current->next;
    }

    return dummy.next;
}


ListNode *buildList2(vector<int> nums) {
    ListNode *head = nullptr;//需要一个指针永远指向头
    ListNode *last = nullptr;//需要一个指针迭代
    for (int num: nums) {
        ListNode *node = new ListNode(num);
        if(head == nullptr) {//第一个节点
            head = node;
            last = head;
        }else {//迭代
            last->next = node;
            last = last->next;
        }
    }
    return head;//返回这个头
}


void printNode(ListNode *list) {
    string str;
    cout << "[";
    while (list!=nullptr) {
        cout << list->val;
        if(list->next!=nullptr){
            cout << ",";
        }
        list=list->next;
    }
    cout << "]" << endl;
}


void deleteList(ListNode *node){

    // 逐个释放用 new 创建的节点。
    while (node != nullptr) {
        ListNode* next = node->next;
        delete node;
        node = next;
    }
}

// ============================================================
// 链表题：两数相加
// ============================================================

ListNode *addTwoNumbers(ListNode *l1, ListNode *l2) {

    ListNode dummy(0);//先搞一个新链表

    //0
    ListNode *current = &dummy;



    int carry = 0;//再来一个终止条件

    //如果carry不等于0，仍然需要继续执行一次循环，此时有可能l1和l2已经迭代结束了。比如119+119，高位9+9=18,仍然需要进位1，所以这种情况需要创建一个新节点。
    while (l1 != nullptr || l2 != nullptr || carry != 0) {
        int sum = carry;//这个是当前位 求和

        if (l1!=nullptr) {
            sum += l1->val; //先从链表拿一位 计算
            l1 = l1->next;
        }

        if (l2!=nullptr) {
            sum += l2->val; //先从链表拿一位 计算
            l2 = l2->next;
        }

        carry = sum / 10; //看一下要不要进位，例如 8+9=17，这里只要1，这个进位需要带到下一轮的计算中


        // 这里是尾插法
        //新节点，给当前节点下一个节点
        current->next = new ListNode(sum % 10); //这里只要超过10位数后的个位数，例如 8+9=17，这里只要7



        current = current->next; //把当前节点指向新节点


    }
    return dummy.next;


}


void testAddTwoNumbers(){



    ListNode *l1 =  buildList({1,2,3});
    ListNode *l2 =   buildList({4,5,6,7});

    printNode(addTwoNumbers(l1, l2));

    ListNode* l5 =  buildList({9, 9, 9, 9, 9, 9, 9});
    ListNode* l6 =  buildList({9, 9, 9, 9});

    printNode(addTwoNumbers(l5, l6));

}

// ============================================================
// 链表题：合并两个有序链表
// ============================================================


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

    // 某个链表还有剩余节点，直接链接到末尾
    if (pHead1 != nullptr) {
        last->next = pHead1;
    } else {
        last->next = pHead2;
    }

    return  node.next;//这就是第一个节点
}




void testMergeSortedLists() {

    ListNode* head1 = buildList({1, 2, 3, 4, 5});
    ListNode* head2 = buildList({1, 2, 3, 4, 5});
    printNode(head1);
    printNode(head2);
    ListNode *newList = Merge(head1, head2);
    printNode(newList);
}

// ============================================================
// 链表题：倒数第 k 个节点
// ============================================================

//单向链表，求最后第k个节点


//时间复杂度是O(n)
//n是链表节点数量。
//用了快按指针，让fast走k步
//然后fast和slow一起往后走，直到fast到链表末尾。
//虽然有两个循环，但不是O(k*n),而是加起来：
//k+(n-k)=n
//因为fast总共最多从头走到尾一次。
//所以整体是O(n)
//空间复杂度是O(1)
//因为只用了两个指针fast和slow
//没有使用数组、栈、哈希表等额外空间
ListNode *findKthFromEnd(ListNode *head, int k) {
    //如果是链表头指针是空指针，或者k的位置 为小于等于0，则为非法的，直接返回空
    if (head == nullptr || k <= 0) {
        return nullptr;;

    }

    ListNode *fast = head;
    ListNode *slow = head;
    //1,2,3,4,5 找倒数第2个
    //fast，走2步，找到3，
    //slow还在1

    //fast走到4，slow到2
    //fast到5，slow到3
    //fast到null，slow到4

    //这里为什么fast走到null时，slow就是倒数第k个节点呢？
    //核心思想：先让 fast 领先 slow k 步；
    //当 fast 到终点，slow 离终点就刚好 k 步，因此 slow 是倒数第 k 个。

    //第一次for 循环，找到 顺序 第k 个节点
    
    // k-1次循环
    for (int i = 0; i < k; i++) {
        if (fast == nullptr) {

            //快指针跑完了，那么k超过长度了，直接返回空
            return nullptr;
        }

        fast = fast->next;
    }


    //这样fast 和 slow 一直保持着相差 k 步。
    //当fast到终点时，仍然是相差k步，所以是倒数第k步
    //n-(k-1)次循环
    while (fast != nullptr) {
        fast = fast->next; //继续让fast往后跑，一直跑到末尾
        slow = slow->next;//slow仍然是从表头往后挪
    }

    return slow;

}


void testFindKthFromEndNode() {

    ListNode *list = buildList({1,2,3,4,5,6});
    ListNode *find = findKthFromEnd(list, 5);

    if(find!=nullptr) {

        cout << find->val << endl;
    } else {

        cout << "Not Found" << endl;
    }



}

// ============================================================
// 链表题：删除倒数第 n 个节点
// ============================================================

//删除末尾的第n个节点
ListNode* removeNthFromEnd(ListNode* head, int n) {

    ListNode *fast = head;
    ListNode *slow = head;

    if(head == nullptr || n <= 0) {//n小于等于0时，参数不合法直接返回
        return head;
    }

    for(int i = 0 ; i < n ; i ++) {

        if(fast == nullptr){
            return head;//n大于链表长度，参数不合法，直接返回
        }
        fast = fast->next; //先让fast和slow相差n步
    }

    if (fast == nullptr) {//说明要删除的是头节点
        ListNode *newHead = head->next;
        delete head;
        return newHead;
    }



    while (fast->next != nullptr) {//技巧，这里需要用fast->next来判断，而不用fast指针判断，目的是找到目标位置的前面一个节点
        fast = fast->next;//fast继续往后挪
        slow = slow->next;//slow也往后挪，直到fast到结束了，slow正好就是倒数第n个了
    }

    //这里已经找到目标位置了，就是slow指向的位置，现在删除slow的位置，把前面和后面的连起来。

    ListNode *deleteNode = slow->next;
    slow->next = slow->next->next;
    delete deleteNode;

    return head;
}

 

void testRemoveNthNodeFromEnd(){
    {
        ListNode *list = buildList({1,2,3,4,5});
        printNode(list);


        ListNode *newList = removeNthFromEnd(list, 200);
        printNode(newList);
    }

    {
        ListNode *list = buildList({1});
        printNode(list);


        ListNode *newList = removeNthFromEnd(list, 1);
        printNode(newList);
    }

    {
        ListNode *list = buildList({1,2});
        printNode(list);


        ListNode *newList = removeNthFromEnd(list, 1);
        printNode(newList);
    }

}

// ============================================================
// 链表题：反转链表
// ============================================================

ListNode* reverseList(ListNode* head) {

    ListNode *previous = nullptr;

    ListNode *current = head;


    while (current != nullptr) {

        ListNode *next =  current->next;//先保存下一个节点

        current->next = previous;//把当前节点下一个节点改成新的下一个节点，第一个节点 下一个节点是null，第二个节点下一个节点是上一个节点

        previous = current;//保存新的上一个节点

        current = next;//继续把当前链表右移下一个节点
    }

    return previous;
}


// ============================================================
// 链表题：反转指定区间
// ============================================================

//反转第left到right之间的节点
ListNode* reverseBetween(ListNode* head, int left, int right) {

    if (head == nullptr || left == right) {
        return head;//不用反转，直接返回
    }
    // 1，2，3，4，5，6，  left:3，right:5
    // before指向2， start指向3
    ListNode* before = nullptr;
    ListNode* start = head;

    for (int i = 1; i < left; i++) {
        before = start;//这里是保存需要反转开始位置的前一个位置
        start = start->next;//start就是开始反转的位置，因为start是从head开始，所以移动left-1次就到left对应位置了
    }

    ListNode* previous = nullptr;
    ListNode* current = start;//从这里开始反转

    for (int i = left; i <= right; i++) {//这里用<=right，表示需要跑right-left+1次，left=3，right=5，需要跑3次，正好就是3，4，5 遍历这三个节点
        ListNode* next = current->next;//先保存下一个节点

        current->next = previous;//先把第一个反转的节点指向上一个节点，第一个反转的节点，下一个节点是nullptr
        previous = current;//这里保存已经反转好的上一个节点
        current = next;//往后移动，继续反转剩余节点
    }
    //上面for循环反转后，只有第一个节点的next指针仍然还是nullptr
    //1，2，
    //5，4，3， nullptr
    //6

    start->next = current;//这里需要把反转后的最后一个节点的next指向，就是把3这个节点的next改成 6

    if (before != nullptr) {//
        before->next = previous; //previous=5，
        //1，2，5，4，3，
        return head;
    } else {
        //表示从第一个节点开始反转
        // 1，2，3，4，5，6 left=1，right=5
        return previous;
    }
}


ListNode *findKEnd(ListNode *head, int k) {
    
    if(head == nullptr || k<=0) {
        return nullptr;
    }
    ListNode *fast = head;
    ListNode *slow = head;
    
    //先拉开k距离
    for (int i=0; i< k ; i++) {
        if(fast ==nullptr){
            return nullptr;
        }
        fast = fast->next;
    }
    //继续迭代
    while (fast!=nullptr) {
        fast =fast->next;
        slow=slow->next;
    }
    return slow;
}
