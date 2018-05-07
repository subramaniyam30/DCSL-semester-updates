%path based approach - learning rate = 20

maxNumTrials=60;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.
budget = 3;
edgeWeightAll = [0.1,0.3,0.5,0.7,0.9];
numDecay = size(edgeWeightAll,2);
firstpath = [1,2,5,10,12];
secondpath = [1,4,9,11,12];


placement_final=cell(numDecay,maxNumTrials);
benefit_final=zeros(numDecay,maxNumTrials);
cost_final=zeros(numDecay,maxNumTrials);

parfor i=1:numDecay    
testPath=firstpath;
idsDynamic=OOP_IDS1(); %Need to re-instantiate for proper parallel operation
idsDynamic.budget_IDS = budget;
idsDynamic.edgeWeightDecay = edgeWeightAll(i);
idsDynamic.findAttackerEdgeWeightInitial();
dynamicPlacement=idsDynamic.optimizeWithGA();
     for k=1:maxNumTrials
            if k >= (maxNumTrials/2)
                 testPath = secondpath;
                 idsDynamic.findAttackerEdgeWeight();
            end
            disp(idsDynamic.actualAttackerEdgeWeight);
            [alertNode,success]=idsDynamic.checkAttackPathEwEffect(testPath,dynamicPlacement);
            disp(alertNode);
            placement_final{i,k} = dynamicPlacement;
            benefit_final(i,k) = idsDynamic.calculate_benefit(dynamicPlacement);
            benefit_final_attacker(i,k) = idsDynamic.calculate_benefit_attacker(dynamicPlacement);
            disp(idsDynamic.calculate_benefit_attacker(dynamicPlacement));
            cost_final(i,k) = sum(dynamicPlacement == 1);
        
            % only when there is no IDS on that path.
            % continue even if there is no IDS on the path.
            % Only when there is an IDS in the Path.
            if ~isempty(alertNode)
                %idsDynamic.updateEdgeWeightPredecessor(alertNode);
                idsDynamic.updateEdgeWeightPathBased(alertNode);
                %idsDynamic.updateEdgeWeightDistance(alertNode);
                dynamicPlacement=idsDynamic.optimizeWithGA();
                disp(dynamicPlacement);
            end
            %The edge weight decay is performed only after the optimization
            %has been done. The effect will be seen only in the next
            %iteration and not the immediate iteration.
            idsDynamic.lastPopulation=[];  %reset the last population
            idsDynamic.decayEdgeWeight(); % exponential decay of edge weight irresepective of alert or not.
      end
end


figure;
hold on;
plot(benefit_final_attacker(1,:),'-r','linewidth',1.5);
plot(benefit_final_attacker(2,:),'m-.','linewidth',1.5);
plot(benefit_final_attacker(3,:),'b:','linewidth',1.5);
plot(benefit_final_attacker(5,:),'g--','linewidth',1.5);
xlabel('Time (Relative)')
ylabel('Performance')
legend('DR = 0.1','DR = 0.3','DR = 0.5','DR = 0.9');

