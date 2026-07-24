//
//  array_hash_algorithms.cpp
//  nowcoder_practice
//
//  数组 / 哈希相关算法复习
//

#include <algorithm>
#include <iostream>
#include <unordered_set>
#include <vector>

using namespace std;

// ============================================================
// 数组 / 哈希题
// ============================================================

//给定一个未排序的整数数组 nums，找出数字连续的最长序列
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

        //这句保证只有“连续序列的起点”才会进入 while。
        //比如：nums = [100,4,200,1,3,2]
        //哈希表里有：
        //{100,4,200,1,3,2}
        //只有 1 会作为序列起点：
        //1 -> 2 -> 3 -> 4
        //2、3、4 都会被跳过，因为它们前面有连续数字：
        //        values.contains(value - 1)
        //        所以每个数字最多被检查常数次，整体是：
        //        O(n)
        //        如果严格说最坏情况，unordered_set 哈希冲突严重时可能退化，但面试和刷题默认按平均复杂度算：
        //        时间复杂度 O(n)
        //        空间复杂度 O(n)
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


void testLongestConsecutiveSequence() {

    vector<int> nums = {1,0,2};

    longestConsecutive(nums);
}
