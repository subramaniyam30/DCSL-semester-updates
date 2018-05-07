
numTestPaths=1;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=10;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.
numSeeds=5;       % Number of try for each test path
load('testpaths.mat','testPaths');

target_cost = 5;
kp = 0.01;       % set the kp and ki values correctly.
ki = 0.005;

idsDynamic = OOP_IDS();    % Dynamic IDS Deployment.
idsDynamic.weight = 0.4;  % set this.
idsDynamic.learningRate = 10;


attackerSuccessfulDynamic= -1 * ones(numTestPaths,numSeeds,maxNumTrials);
placement_final=cell(numTestPaths,numSeeds,maxNumTrials);
benefit_final=zeros(numTestPaths,numSeeds,maxNumTrials);
cost_final=zeros(numTestPaths,numSeeds,maxNumTrials);
alphavalues=zeros(numTestPaths,numSeeds,maxNumTrials);



parfor i=1:numTestPaths
    testPath=testPaths{i};
    idsDynamic=OOP_IDS(); %Need to re-instantiate for proper parallel operation
    idsDynamic.weight = 0.4;  % set this.
    idsDynamic.learningRate = 10;
    for j=1:numSeeds
        dynamicPlacement=idsDynamic.optimizeWithGAMOO();
        current_error = 0;
        sum_error = 0;
        idsDynamic.weight = 0.4;
        for k=1:maxNumTrials
            [alertNode,success]=idsDynamic.checkAttackPath(testPath,dynamicPlacement);
            attackerSuccessfulDynamic(i,j,k)=success;
            placement_final{i,j,k} = dynamicPlacement;
            benefit_final(i,j,k) = idsDynamic.calculate_benefit(dynamicPlacement);
            cost_final(i,j,k) = sum(dynamicPlacement == 1);
            actual_cost = cost_final(i,j,k);
            alphavalues(i,j,k) = idsDynamic.weight;
            if  success == 1
                %disp(idsDynamic.edgeWeightAttacker);
                idsDynamic.lastPopulation=[];  %reset the last population
                %decay weight = 0 -> Not using for this experiment.
                %idsDynamic.decayEdgeWeight(); % exponential decay of edge weight irresepective of alert or not.
                break;
            end
            if ~isempty(alertNode)
                %idsDynamic.updateEdgeWeightPredecessor(alertNode);
                idsDynamic.updateEdgeWeightPathBased(alertNode);
                %idsDynamic.updateEdgeWeightDistance(alertNode);
                %disp(alertNode);
                %disp(idsDynamic.edgeWeightAttacker);
                idsDynamic.lastPopulation=[];  %reset the last population
                current_error = actual_cost - target_cost;
                sum_error = sum_error + current_error;
                idsDynamic.weight = idsDynamic.weight + (current_error * kp) + (sum_error * ki);
                dynamicPlacement=idsDynamic.optimizeWithGAMOO();
            end
        end
    end
end


for i=1:numTestPaths
    benefitDynamic(i) = 1-(sum(sum(attackerSuccessfulDynamic(i,:,:) == 1))/(sum(sum(attackerSuccessfulDynamic(i,:,:) == 1)) + sum(sum(attackerSuccessfulDynamic(i,:,:) == 0))));
end

Average_Cost = sum(sum(cost_final,3))/sum(sum(cost_final ~= 0));
