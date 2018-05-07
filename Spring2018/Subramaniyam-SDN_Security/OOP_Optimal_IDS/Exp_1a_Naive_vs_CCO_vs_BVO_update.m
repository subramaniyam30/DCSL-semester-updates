% For Naive Placement
% Consider all the possible combinations of IDS placement - exhuastive
% search
% Find mean performance 
% Find Minimum Performance.
% Plot between the performance and relative cost.
% update: we plot between benefit vs relative cost.
% Find maximum performance also.

%set the budget in OOP_IDS()

ids_naive = OOP_IDS();
ids_CGA   = OOP_IDS();
ids_MOO   = OOP_IDS();
tic;
% Generate the possibile positions
testSet=[];
for i=1:ids_naive.numServers
    setToOnes=combnk(1:(ids_naive.numServers),i);
    for j=1:size(setToOnes,1)
        setVector=setToOnes(j,:);
        newTestSet=zeros(ids_naive.numServers,1);
        newTestSet(setVector)=1;
        testSet=[testSet; newTestSet']; %#ok<AGROW>
    end
end
% Remove all the rows which as 1 in (1,1) - No ids can be
% placed  there.
[m,~] = size(testSet);
index = 1;
for i=1:m
    if testSet(i,1) == 1
        rowtodelete(index) = i;
        index = index+1;
    end
end
testSet(rowtodelete,:) = [];

%Evaluate the objective function for all possible combinations.
testValues=zeros(size(testSet,1),1);
for i=1:numel(testValues)
    testValues(i)= ids_naive.exh_objective_function(testSet(i,:));
end

labels=cell(numel(testValues),1);
for i=1:numel(labels)
    labels{i}=mat2str(testSet(i,:));
end

[testValues,idx]=sort(testValues);  % sorts from smallest to largest.
labels=labels(idx);
strLabels = cell2mat(labels);
finalIDSPlacement = str2num(strLabels(1,:));
runningTime = toc;
ids_naive.lastRunningTime = runningTime;
ids_naive.lastIdsPlacement = finalIDSPlacement ;


for n = 1:size(testSet,1)
    %naivePerformances(n) = (ids_naive.calculate_benefit(testSet(n,:))/ids_naive.maxBenefit);
    naivePerformances(n) = ids_naive.calculate_benefit(testSet(n,:));
    naiveRelCost(n) = (sum(testSet(n,:)==1)/ids_naive.max_IDS);
end
figure(1)
scatter(naiveRelCost,naivePerformances)

naiveRelCostUnique = unique(naiveRelCost);
naivePerformanceUnique={};
arrayindex = 1;
index = 0;
start = 1;
for i = 1:size(naiveRelCostUnique,2)
    for j = start:size(naiveRelCost,2)
        if(naiveRelCost(j) == naiveRelCostUnique(i))
            index = index + 1;
        else
            
            
            break;
        end
       
    end
    naivePerformanceUnique{arrayindex} = naivePerformances(start:index);
            start = j;
            arrayindex = arrayindex + 1;
end

for k = 1:size(naivePerformanceUnique,2)
  meanVal(k) = mean(naivePerformanceUnique{1,k});
  minVal(k) = min(naivePerformanceUnique{1,k});
  maxVal(k) = max(naivePerformanceUnique{1,k}); 
end
% Adding the first element as cost = 0, performance = 0-> to start from 0.
meanVal(k+1) = 0;
minVal(k+1) = 0;
maxVal(k+1) = 0;
naiveRelCostUnique(k+1) = 0;
meanVal = circshift(meanVal,1);
minVal = circshift(minVal,1);
maxVal = circshift(maxVal,1);
naiveRelCostUnique = circshift(naiveRelCostUnique,1);
% % Split into bins
% bins = 11;  %To divide into intervals of 1/11
% edges = linspace(0,1,bins+1);
% [~,~,binNum] = histcounts(naiveRelCost,edges);
% 
% for k = 1:bins
%     memberFlag = (binNum == k);
%     values = naivePerformances(memberFlag == 1);
%     if isempty(values)
%         meanVal(k) = 0;
%         minVal(k) = 0;
%         maxVal(k)= 0;
%     else
%         meanVal(k) = mean(values);
%         minVal(k) = min(values);
%         maxVal(k) = max(values); 
%     end
% end
% 
% binMids = linspace(1/(2*bins),1-1/(2*bins),bins);


% GENETIC ALGORITHM OPTIMIZATION
% naive vs CCO
% varying the budget from 1 to maximum. => relaive cost varying from 0 to 1

a = 1;
for costCut = 0:1:ids_CGA.max_IDS
    %ids_CGA.cost_budget = costCut;
    ids_CGA.budget_IDS = costCut;
    %disp(ids_CGA.cost_budget);
    ids_CGA.optimizeWithGA();
    %disp(ids_CGA.lastIdsPlacement);
    ids_CGA.lastPopulation = [];
    % perfGA(a) = (ids_CGA.calculate_benefit(ids_CGA.lastIdsPlacement)/ids_CGA.maxBenefit);
    perfGA(a) = ids_CGA.calculate_benefit(ids_CGA.lastIdsPlacement);
    %relCostGA(a) = (ids_CGA.calculate_num_cost(ids_CGA.lastIdsPlacement)/ids_CGA.maxCost);
    relCostGA(a) = (sum(ids_CGA.lastIdsPlacement==1)/ids_CGA.max_IDS);
    a = a + 1;
end

%BVO on CCO plot
% alpha varying from 0.2,0.5 and 0.8
ids_MOO.weight = 0.2;  %initial weight
for i = 1:3
    ids_MOO.optimizeWithGAMOO();
    ids_MOO.lastPopulation=[];
    
    %weightedperfArray(i) = (ids_MOO.calculate_benefit(ids_MOO.lastIdsPlacement)/ ids_MOO.maxBenefit);
    weightedperfArray(i) = ids_MOO.calculate_benefit(ids_MOO.lastIdsPlacement);  
    weightedrelativecostArray(i) = (sum(ids_MOO.lastIdsPlacement==1)/ ids_MOO.max_IDS); 
    %weightednumCostArray(i) = ids.calculate_num_cost(ids.lastIdsPlacement);
    ids_MOO.weight = ids_MOO.weight + 0.3;
end
% PLOT RESULTS
%figure('position',[500 500 560 242]);
figure;
hold on
%binMidsShift = binMids - binMids(1);
plot(100*naiveRelCostUnique,maxVal,'r:x','linewidth',1.5)
plot(100*naiveRelCostUnique,meanVal,'g-.x','linewidth',1.5)
%plot(naiveRelCostUnique,minVal,'m','linewidth',1.5)
plot(100*relCostGA,perfGA,'b--o','linewidth',1.5)
plot(100*weightedrelativecostArray(1),weightedperfArray(1),'k^','LineWidth',3.5)
plot(100*weightedrelativecostArray(2),weightedperfArray(2),'k+','LineWidth',3.5)
plot(100*weightedrelativecostArray(3),weightedperfArray(3),'ks','LineWidth',3.5)
xlabel('Cost (% of Maximum Cost)')
ylabel('Performance')
%title('OPTIMISM  vs Naive Placement')
%legend('Maximum Performance of Naive Placement','Mean Performance of Naive Placement','Minimum Performance of Naive Placement','Performance of OPTIMISM-CCO','Performance of OPTIMISM-BVO with alpha = 0.2','Performance of OPTIMISM-BVO with alpha = 0.5', 'Performance of OPTIMISM-BVO with alpha = 0.8')
legend('Optimal Performance','Mean Performance of Naive Placement','Performance of CCO-Static','Performance of BVO-Static with weight(\alpha) = 0.2','Performance of BVO-Static with weight(\alpha) = 0.5', 'Performance of BVO-Static with weight(\alpha) = 0.8')



