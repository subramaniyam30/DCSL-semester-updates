% For Naive Placement
% Consider all the possible combinations of IDS placement - exhuastive
% search
% Find mean performance 
% Find Minimum Performance.
% Budget is taken as 1000 so that all possible can be found - exhaustive
% search.

% Plot between the performance and relative cost.

ids_naive = OOP_IDS();
ids_CGA   = OOP_IDS();

tic;
% Generate the possibile positions
testSet=[];
for i=1:ids_naive.numServers
    setToOnes=combnk(1:(ids_naive.numServers-1),i);
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

%figure(1);
%bar(-1*testValues);
%set(gca,'XTickLabel',labels);
%set(gca,'XTickLabelRotation',90);
%disp('IDS Locations by Exhaustion:')
strLabels = cell2mat(labels);
finalIDSPlacement = str2num(strLabels(1,:));
runningTime = toc;
ids_naive.lastRunningTime = runningTime;
ids_naive.lastIdsPlacement = finalIDSPlacement ;


% CALCULATIONS FOR EXHAUSTIVE
% Calculate all possible performances for exhaustive placements
for n = 1:size(testSet,1)
    naivePerformances(n) = (ids_naive.calculate_benefit(testSet(n,:))/ids_naive.maxBenefit);
    naiveRelCost(n) = (ids_naive.calculate_num_cost(testSet(n,:))/ids_naive.maxCost);
end
figure(1)
scatter(naiveRelCost,naivePerformances)

% Split into bins
bins = 20;  %To divide into intervals of 1/20
edges = linspace(0,1,bins+1);
[~,~,binNum] = histcounts(naiveRelCost,edges);

for k = 1:bins
    memberFlag = (binNum == k);
    values = naivePerformances(memberFlag == 1);
    if isempty(values)
        meanVal(k) = 0;
        minVal(k) = 0;
    else
        meanVal(k) = mean(values);
        minVal(k) = min(values);
    end
end

binMids = linspace(1/(2*bins),1-1/(2*bins),bins);


% GENETIC ALGORITHM OPTIMIZATION
a = 1;
for costCut = (1/bins)*ids_CGA.maxCost:(1/bins)*ids_CGA.maxCost:ids_CGA.maxCost
    ids_CGA.cost_budget = costCut;
    %disp(ids_CGA.cost_budget);
    ids_CGA.optimizeWithGA();
    disp(ids_CGA.lastIdsPlacement);
    ids_CGA.lastPopulation = [];
    perfGA(a) = (ids_CGA.calculate_benefit(ids_CGA.lastIdsPlacement)/ids_CGA.maxBenefit);
    relCostGA(a) = (ids_CGA.calculate_num_cost(ids_CGA.lastIdsPlacement)/ids_CGA.maxCost);
    a = a + 1;
end


% PLOT RESULTS
figure('position',[500 500 560 242]);
hold on
plot(binMids,meanVal,'bo-','linewidth',1.5)
plot(binMids,minVal,'go-','linewidth',1.5)
plot(relCostGA,perfGA,'ro-','linewidth',1.5)
xlabel('Relative Cost')
ylabel('Performance')
%title('OPTIMISM  vs Naive Placement')
legend('Mean Performance of Naive Placement','Minimum Performance of Naive Placement','Performance of CCO-GA') 