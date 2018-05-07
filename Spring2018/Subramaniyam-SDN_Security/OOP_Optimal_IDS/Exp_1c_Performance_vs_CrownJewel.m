% generate all possible combinations of placement for given budget.
% randomly select the required number of servers from layer 2 and 3 as
% crown jewels.
% the objective function is minimum of benefit out of all the CJs.
crownjewel = [1 2 4 6];
%for each number repeat for 10 trails.
for l = 1:4
    numCrownJewel = crownjewel(l);
for k = 1:10
ids = OOP_IDS_MC(numCrownJewel);
ids.budget_IDS = 4;
testSet=[];
setToOnes=combnk(1:12,ids.budget_IDS);
for j=1:size(setToOnes,1)
      setVector=setToOnes(j,:);
      newTestSet=zeros(12,1);
      newTestSet(setVector)=1;
      testSet=[testSet; newTestSet']; %#ok<AGROW>
end

[m,~] = size(testSet);
index = 1;
for i=1:m
    if testSet(i,1) == 1
        rowtodelete(index) = i;
        index = index+1;
    end
end
testSet(rowtodelete,:) = [];

for n = 1:size(testSet,1)
    %naivePerformances(n) = (ids_naive.calculate_benefit(testSet(n,:))/ids_naive.maxBenefit);
    naivePerformances(n) = ids.calculate_benefit_exhaustive(testSet(n,:));
end
max_avg_performance_naive_overall(l,k) = max(naivePerformances);
mean_avg_performance_naive_overall(l,k) = mean(naivePerformances);

max_avg_performance_naive(k) = max(naivePerformances);
mean_avg_performance_naive(k) = mean(naivePerformances);

ids.buildEdgeWeights();        %calculate edge weights to distribute traffic.
ids.buildEdgeProbability();
ids.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
ids.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
ids.calculate_max_benefit();        %find the gain or benefit in protection when IDS is everywhere
ids.optimizeWithGA();
avg_performance_cco_overall(l,k) = ids.average_benefit;
avg_performance_cco(k) = ids.average_benefit;
end
max_avg_naive(l) = sum(max_avg_performance_naive)/10;
mean_avg_naive(l) = sum(mean_avg_performance_naive)/10;
avg_cco(l)   = sum(avg_performance_cco,2)/10;
end

%figure('position',[500 500 560 242]);
figure;
hold on
plot(crownjewel,max_avg_naive,'r:x','linewidth',1.5)
plot(crownjewel,mean_avg_naive,'g-.x','linewidth',1.5)
plot(crownjewel,avg_cco,'b--o','linewidth',1.5)
xlabel('Number of Crown Jewels(CJ)')
ylabel('Performance')
%title('OPTIMISM  vs Naive Placement')
legend('Optimal Performance','Mean Performance of Naive Placement','Performance of CCO-Static');