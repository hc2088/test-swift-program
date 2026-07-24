//
//  dynamic_programming_algorithms.cpp
//  nowcoder_practice
//
//  动态规划 / 股票问题复习
//

#include <algorithm>
#include <iostream>
#include <vector>

using namespace std;

// ============================================================
// 股票题：一次、多次、最多两次交易
// ============================================================

//核心思路：
//遍历每天价格，维护历史最低买入价。
//每天假设今天卖出，用 当前价格 - 历史最低价 计算利润。
//不断更新最大利润。

//关键变量：
//minPrice   // 到今天为止见过的最低价格
//maxProfit  // 到今天为止能得到的最大利润

//一句话：
//找一个最低点买入，再找它后面的最高点卖出。
int maxProfitOnce(vector<int> &prices) {
    if(prices.empty()) {//如果为空数组，就返回0，无需计算
        return 0;
    }
    //{100, 10, 120, 130, 70, 60, 100, 125,5,100}
    
    int minPrice = prices[0];//先用第一个价格 作为最低价。
    int maxProfit = 0;//来一个变量存储 最大收益
    
    /// 原理就是： 遍历，每天的价格，维护历史最低买入价
    /// 每天使用，当前价 - minPrice 更新最大利润
    for (int price : prices) {
        
        // 迭代时，第一天计算收益是0，第二天就可以比较了，
        //第二天：遇到一个新的最小值10，10-10 仍然是0，当天价是10，最小价也是10，仍然是0
        //第三天：120-10=110，把这个利润存下来。
        //第四天：130-10=120，最大利润就变成了120
        //第五天：70-10=60，最大利润仍然为120不变
        //第六天：60-10=50，不变
        //第七天：100-10=90，不变
        //第八天：125-10=115，不变 所以最大利润就是120
        //第九天：5-5=0，利润不变（新的最小价格5）
        //第十天：100-5=95，利润不变 最大还是120
        
        int profit = price - minPrice;//用当前价 - 之前发现的更低价
        if (profit > maxProfit) { //这个差值就是收益，如果发现更大的差值，更新为当前发现的更大差值
            maxProfit = profit;
        }
        
        if(price < minPrice) { //如果出现更低价，更新更低价
            minPrice = price;
        }
    }
    
    return maxProfit;
}


//核心思路：
//只要今天价格比昨天高，就把这段上涨利润吃掉。
//关键代码：
//if (prices[i] > prices[i - 1]) {
//    maxProfit += prices[i] - prices[i - 1];
//}
//比如：
//1 -> 2 -> 3 -> 4
//可以拆成：
//1->2 + 2->3 + 3->4
//利润等价于：
//4 - 1
//一句话：
//所有上涨段都累加，能赚一点就赚一点。
int maxProfitMany(vector<int> &prices) {
    
    int maxProfit = 0;
    //这里如果prices是空数组，也会跳过for循环的,所以不需要在多余的判空
    for (int i = 1; i < prices.size(); i++) {
        
        //只要今天比昨天贵，就把这段上涨利润吃掉
        
        //{100, 10, 120, 130, 70, 60, 100, 125,5,100}
        if(prices[i] > prices[i-1]) {
            //从第二天开始计算
            //第二天： 不满足if条件，maxProfit仍然为上一个值， 0
            //第三天：满足条件：120-10=110
            //第四天：130-120=10，需要累加：得到120
            //第五天：不满足条件
            //第六天：不满足条件
            //第七天：100-60=40，累加：160
            //第八天：125-100=25  累加：185
            //第九天：不满足条件
            //第十天：100-5=95 累加：280
            maxProfit += prices[i] - prices[i-1];
        }
    }
    
    return maxProfit;
}


//给定一个数组，它的第 i 个元素是一支给定的股票在第 i 天的价格。
//
//设计一个算法来计算你所能获取的最大利润。你最多可以完成 两笔 交易。
//
//注意：你不能同时参与多笔交易（你必须在再次购买前出售掉之前的股票）。
//
//最多两次交易不是简单地从 maxProfitMany 里面“挑两个最大的上涨段”。
//maxProfitMany 的逻辑是：只要今天比昨天贵，就吃掉这段利润
//因为它允许无限次交易，所以所有上涨都可以累加。


//但最多两次交易时，有个限制：
//最多只能买卖 2 次
//所以不能把所有小上涨都吃掉，也不能简单挑两个最大的上涨段。

//反例：
//prices = [1,6,5,9,1,6]
//上涨段：
//1 -> 6，利润 5
//5 -> 9，利润 4
//1 -> 6，利润 5
//
//如果你挑两个最大的上涨段：
//5 + 5 = 10
//
//但最优其实是：
//1 -> 9，利润 8
//1 -> 6，利润 5
//总利润 = 13



//核心思路：
//每天维护四种状态下的最大收益：
//第一次买入、第一次卖出、第二次买入、第二次卖出。
//四个变量：
//buy1   // 第一次买入后，手里最多还剩多少钱
//sell1  // 第一次卖出后，最多赚多少钱
//buy2   // 第二次买入后，手里最多还剩多少钱
//sell2  // 第二次卖出后，最多总共赚多少钱
//状态转移：
//buy1 = max(buy1, -price);
//sell1 = max(sell1, buy1 + price);
//
//buy2 = max(buy2, sell1 - price);
//sell2 = max(sell2, buy2 + price);
//一句话：
//不记录具体哪天买卖，只记录“到今天为止，每个交易阶段能达到的最大收益”。



//今天这个价格，分别尝试作为买入价，也尝试作为卖出价。
//如果能让某个状态变得更好，就更新；不能变好，就保持原来的状态。
//所以每一天都会问 4 个问题：

//问题 1：
//今天适不适合第一次买入？
//如果今天价格更低，-price 更大，就更新 buy1。

//buy1 = max(buy1, -price);



//问题 2：
//今天适不适合第一次卖出？
//如果今天卖出能让第一次交易利润更高，就更新 sell1。

//sell1 = max(sell1, buy1 + price);


//问题 3：
//今天适不适合第二次买入？
//如果用第一次赚到的钱，今天再买入后剩下的钱更多，就更新 buy2。
//buy2 = max(buy2, sell1 - price);

//问题 4：
//今天适不适合第二次卖出？
//如果今天卖出能让总利润更高，就更新 sell2。

//sell2 = max(sell2, buy2 + price);




//所以“把今天价格当作可能买入 / 卖出的价格”的意思是：今天既可能是某一次买入日，也可能是某一次卖出日，但最终是否采用，要看 max 后有没有让收益变大。
//举个价格 price = 6：
//buy1 = max(buy1, -6);
//如果之前 buy1 = -1，那：
//max(-1, -6) = -1
//说明今天 6 元不适合买入，还是之前 1 元买入更好。
//但：
//sell1 = max(sell1, buy1 + 6);
//如果 buy1 = -1：
//buy1 + 6 = 5
//说明今天 6 元适合卖出，可以赚 5。
//所以同一天价格会被拿来尝试：
//买入：看看是否更便宜
//卖出：看看是否能赚更多
//但不是说同一天同时真的买和卖，而是在动态规划里更新“到今天为止的最优状态”。
int maxProfitAtMostTwoTransactions(vector<int> &prices) {
    // 这个算法每天都在问自己：如果今天买 / 今天卖，会不会让当前阶段的最大收益变得更好。
    // 每天都更新：第一次买、第一次卖、第二次买、第二次卖这四种状态下的最大收益。
    // 它不是在真的模拟某一组固定买卖，而是在保存“到今天为止，这个状态下能达到的最优结果”。
    if(prices.empty()) {
        return 0; // 没有价格，就无法交易，最大利润是 0。
    }

    // 例子：{1,6,5,9,1,6}
    int buy1 = -prices[0]; // 第 0 天完成第一次买入：花掉 prices[0]，所以收益是 -prices[0]。
    int sell1 = 0; // 第 0 天还没有完成有效卖出，第一次卖出后的最大利润先记为 0。

    int buy2 = -prices[0]; // 第 0 天可以理解为：先有 0 利润，再进行第二次买入，所以也是 -prices[0]。
    int sell2 = 0; // 第 0 天还没有完成第二次卖出，最多两次交易后的最大利润先记为 0。

    for (int price : prices) {
        // 遍历每一天的股价，把今天的价格当作可能买入 / 卖出的价格。

        // 第一次买入后的最大收益：
        // 选择 1：之前已经买过，继续保持 buy1。
        // 选择 2：今天才第一次买入，收益是 -price。
        buy1 = max(buy1, -price);

        // 第一次卖出后的最大收益：
        // 选择 1：之前已经卖过，继续保持 sell1。
        // 选择 2：今天第一次卖出，收益是 第一次买入后的收益 buy1 + 今天卖出价格 price。
        sell1 = max(sell1, buy1 + price);

        // 第二次买入后的最大收益：
        // 选择 1：之前已经第二次买入，继续保持 buy2。
        // 选择 2：今天第二次买入，收益是 第一次卖出后的利润 sell1 - 今天买入价格 price。
        buy2 = max(buy2, sell1 - price);

        // 第二次卖出后的最大收益：
        // 选择 1：之前已经第二次卖出，继续保持 sell2。
        // 选择 2：今天第二次卖出，收益是 第二次买入后的收益 buy2 + 今天卖出价格 price。
        sell2 = max(sell2, buy2 + price);
    }

    return sell2; // sell2 表示到最后一天为止，最多完成两次交易能获得的最大利润。
}

int maxProfitMaxTwoTrans(vector<int> prices) {
    if(prices.empty()){
        return 0;
    }
    int buy1 = -prices[0];
    int sell1 = 0;
    int buy2 = -prices[0];
    int sell2 = 0;
    
    for(int price : prices) {
        buy1 = max(buy1, -price);//买就 需要花费，所以减，这里求最大剩余余额
        sell1 = max(sell1, buy1+price);//卖就是加 当前价，把之前剩余的余额+当前卖出的收益，就是第一次总收益
        
        
//        buy2 = max(buy2, sell1-price);
//        sell2 = max(sell2, buy2+price);
        
        
    }
//    return sell2;
    return sell1;
}

void testStockProfitAlgorithms() {
    vector<int> prices = {1,6,5,9,1,6};
    //    vector<int> prices = {100, 10, 120, 130, 70, 60, 100, 125,5,100};
    cout << maxProfitOnce(prices) << endl;
    cout << maxProfitMany(prices) << endl;
    cout << maxProfitMaxTwoTrans(prices) << endl;
    
    //    vector<int> prices = {3,3,5,0,0,3,1,4};
    
    cout << maxProfitAtMostTwoTransactions(prices) << endl;
    
}

//maxProfitOnce：一次交易，维护最低买入价
//maxProfitMany：无限交易，累加所有上涨差价
//maxProfitAtMostTwoTransactions：最多两次交易，动态规划维护四个交易状态


//maxProfitOnce        时间 O(n)，空间 O(1)
//maxProfitMany        时间 O(n)，空间 O(1)
//maxProfitAtMostTwoTransactions  时间 O(n)，空间 O(1)

//
//动态规划类算法一般有这几个特点：
//1. 定义状态：用变量/数组表示某个阶段的最优结果
//2. 状态转移：当前状态由之前状态推出来
//3. 保存历史最优：不用重新枚举之前所有情况
//4. 通常有 max/min 选择：在“不做某操作”和“做某操作”之间取最优

//但注意：有 max 不一定就是动态规划，贪心算法也经常用 max。
//它是标准 DP，因为它定义了 4 个状态：
//buy1
//sell1
//buy2
//sell2
//每天根据旧状态更新新状态：
//buy1 = max(buy1, -price);
//sell1 = max(sell1, buy1 + price);
//buy2 = max(buy2, sell1 - price);
//sell2 = max(sell2, buy2 + price);
//这个非常符合：
//状态 + 状态转移 + 保存最优结果


//另外：
//maxProfitOnce 可以用 DP 视角解释，但通常更准确叫 贪心：维护历史最低价。
//maxProfitMany 当前写法是 贪心：只要今天比昨天贵，就累加差价。




