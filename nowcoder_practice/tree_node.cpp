//
//  tree_node.cpp
//  nowcoder_practice
//
//  Created by huchu on 2026/7/8.
//

#include <iostream>
#include <vector>
#include <queue>
#include <algorithm>
using namespace std;

struct TreeNode {
    
    int val;
    TreeNode *left;
    TreeNode *right;
    
    TreeNode():val(0), left(nullptr),right(nullptr){
        
    }
    
    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
    
    TreeNode(int x, TreeNode* left, TreeNode* right)
    : val(x), left(left), right(right) {}
};



TreeNode *buildTree(vector<int> nums) {
    
    if(nums.empty()){
        return  nullptr;
    }
    
    vector<TreeNode *>nodes;//生命一个数组里面放的是node节点
    
    for (int num :nums) {
        nodes.push_back(new TreeNode(num));
    }
    
    
    for (int i=0; i<nums.size(); i++) {
        
        //2个2个取
        int leftIndex = 2*i+1;
        int rightIndex = 2*i+2;
        
        if (leftIndex < nums.size()) {
            nodes[i]->left = nodes[leftIndex];
        }
        if (rightIndex<nums.size()) {
            nodes[i]->right = nodes[rightIndex];
        }
    }
    return nodes[0];
}

void printTree(TreeNode *root) {
    
    if(root==nullptr){
        cout << "[]" <<endl;
        return;
    }
    
    // 记住下一批要打印的节点，并保证它们按从左到右、从上到下的顺序被处理
    queue<TreeNode*> q;//来一个队列
    q.push(root);//放进去第一个root
    
    vector<int> result;
    
    while (!q.empty()) {
        
        TreeNode* node = q.front();//保存一下当前层
        //先取出
        q.pop();
        //当前层待打印的
        result.push_back(node->val);
        
        
        //左边继续放进去
        if (node->left != nullptr) {
            q.push(node->left);
        }
        //右边继续放进去
        if (node->right != nullptr) {
            q.push(node->right);
        }
    }
    
    cout << "[";
    
    for (int i = 0; i < result.size(); i++) {
        cout << result[i];
        
        if (i != result.size() - 1) {
            cout << ",";
        }
    }
    
    cout << "]" << endl;
    
    
    
    
}
TreeNode* invertTree(TreeNode* root) {
    if (root == nullptr) {
        return nullptr;//递归的终止条件
    }
    //先直接对本次进行操作反转
    TreeNode* temp = root->left;
    root->left = root->right;
    root->right = temp;
    
    //然后继续递归 下一层，左边和右边节点，继续反转
    invertTree(root->left);
    invertTree(root->right);
    
    return root;
}
//void testTreeNode() {
//    TreeNode* root = buildTree({4, 2, 7, 1, 3, 6, 9});
//    printTree(root);
//    TreeNode* newRoot = invertTree(root);
//
//    printTree(newRoot); // [4,7,2,9,6,3,1]
//
//
//}




string tree2str(TreeNode *root) {
    
    if (root == nullptr) {
        return "";
    }
    
    string val = to_string(root->val);
    
    if (root->left==nullptr&&root->right==nullptr) {
        return val;
    }
    
    if (root->left != nullptr) {
        return val + "(" + tree2str(root->left) + ")";
    }
    
    if (root->right != nullptr) {
        return val + "()" + "(" + tree2str(root->right) + ")";
    }

    return val + "(" + tree2str(root->left) + ")" + "(" + tree2str(root->right) + ")" ;
}


//string tree2str(TreeNode *root) {
//    if(root == nullptr) {//不需要再次递归
//        return "";
//    }
//    string val = to_string(root->val);
//    //到叶子节点了，拿结果-》 结果是val
//    if(root->left == nullptr && root->right == nullptr) {
//        return val;
//    }
//    //左边为空时，需要左边有一个括号()，右边继续递归
//    if(root->left==nullptr){
//        return val + "()" + "(" + tree2str(root->right) + ")";
//    }
//    //右边为空时，继续左边递归， 右边的()省略
//    if(root->right==nullptr){
//        return val + "(" + tree2str(root->left) + ")";
//    }
//    //都不为空时，就是按照需求拼
//    return val + "(" + tree2str(root->left) + ")"+"("+tree2str(root->right)+")";
//}

void test(TreeNode* root, const string& expected) {
  
    string result =  tree2str(root);

    cout << "result:   " << result << endl;
    cout << "expected: " << expected << endl;

//    assert(result == expected);

//    cout << "pass" << endl << endl;
}

void testTreeNode(){
    // 测试 1:
    //      1
    //     / \
    //    2   3
    //   /
    //  4
    //
    // 输出: "1(2(4))(3)"
    TreeNode* root1 = new TreeNode(1);
    root1->left = new TreeNode(2);
    root1->right = new TreeNode(3);
    root1->left->left = new TreeNode(4);
    
    test(root1, "1(2(4))(3)");
    
    // 测试 2:
    //      1
    //     / \
    //    2   3
    //     \
    //      4
    //
    // 输出: "1(2()(4))(3)"
    TreeNode* root2 = new TreeNode(1);
    root2->left = new TreeNode(2);
    root2->right = new TreeNode(3);
    root2->left->right = new TreeNode(4);
    
    test(root2, "1(2()(4))(3)");
    
    // 测试 3:
    // 只有一个节点
    TreeNode* root3 = new TreeNode(1);
    
    test(root3, "1");
    
    // 测试 4:
    //      1
    //       \
    //        2
    //
    // 输出: "1()(2)"
    TreeNode* root4 = new TreeNode(1);
    root4->right = new TreeNode(2);
    
    test(root4, "1()(2)");
    
    // 测试 5:
    // 空树
    TreeNode* root5 = nullptr;
    
    test(root5, "");
    
    cout << "All tests passed!" << endl;
    
}
