maxNumTrials=20;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.

target_cost = 5;
kp = 0.01;       % set the kp and ki values correctly.
ki = 0.005;
%time_period = [1,2,4,6,8,10,20];
time_period = [2,4,6,8,10,20];
numTimePeriod = size(time_period,2);

idsDynamic = OOP_IDS();    % Dynamic IDS Deployment.
idsDynamic.weight = 0.4;  % set this.
idsDynamic.learningRate = 10;



placement_final=cell(numTimePeriod,maxNumTrials);
benefit_final=zeros(numTimePeriod,maxNumTrials);
benefit_final_attacker=zeros(numTimePeriod,maxNumTrials);
cost_final=zeros(numTimePeriod,maxNumTrials);
alphavalues=zeros(numTimePeriod,maxNumTrials);

testPath = [1,4,9,11,12];

for i=1:numTimePeriod
    idsDynamic=OOP_IDS(); %Need to re-instantiate for proper parallel operation
    idsDynamic.weight = 0.4;  % set this.
    idsDynamic.learningRate = 10;
    dynamicPlacement=idsDynamic.optimizeWithGAMOO();
    current_error = 0;
    sum_error = 0;
    previous_cost = 0;
    idsDynamic.findAttackerEdgeWeight();
    k=1;
    while k <= maxNumTrials
            [alertNode,success]=idsDynamic.checkAttackPathEwEffect(testPath,dynamicPlacement);
            placement_final{i,k} = dynamicPlacement;
            benefit_final(i,k) = idsDynamic.calculate_benefit(dynamicPlacement);
            benefit_final_attacker(i,k) = idsDynamic.calculate_benefit_attacker(dynamicPlacement);
            cost_final(i,k) = sum(dynamicPlacement == 1);
            actual_cost = cost_final(i,k);
            alphavalues(i,k) = idsDynamic.weight;
            cost_temp = cost_final(i,k);
            disp(k);
            disp(cost_final(i,k));
            disp(previous_cost);
            disp(benefit_final_attacker(i,k));
            disp(placement_final{i,k});
            if k > 1
                if cost_final(i,k) > previous_cost
                    idsDynamic.budget_IDS = previous_cost;
                    dynamicPlacement=idsDynamic.optimizeWithGA();
                    inside = 1;
                    for t=k : (k+(time_period(i)))
                    [alertNode1,success1]=idsDynamic.checkAttackPathEwEffect(testPath,dynamicPlacement);
                    placement_final{i,t} = dynamicPlacement;
                    benefit_final(i,t) = idsDynamic.calculate_benefit(dynamicPlacement);
                    benefit_final_attacker(i,t) = idsDynamic.calculate_benefit_attacker(dynamicPlacement);
                    cost_final(i,t) = sum(dynamicPlacement == 1);
                    %actual_cost = cost_final(i,t);
                    alphavalues(i,t) = idsDynamic.weight;
                    disp('inside');
                    disp(t);
                    disp(cost_final(i,t));
                    disp(previous_cost);
                    disp(benefit_final_attacker(i,t));
                    disp(placement_final{i,t});
                    if ~isempty(alertNode1)
                        %idsDynamic.updateEdgeWeightPredecessor(alertNode);
                        idsDynamic.updateEdgeWeightPathBased(alertNode1);
                        %idsDynamic.updateEdgeWeightDistance(alertNode1);
                        idsDynamic.lastPopulation=[];  %reset the last population
                        %current_error = actual_cost - target_cost;
                        %sum_error = sum_error + current_error;
                        dynamicPlacement=idsDynamic.optimizeWithGA();
                    end
                    end
                    k = k + time_period(i); 
                end
            end
            previous_cost = cost_temp;
           
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
            k=k+1;
     end
 end




