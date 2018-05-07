%numTestPaths is similar to number of scenarios -each scenario u have 2
%unique paths.
%each scenario for 50 trails -> path 1 for 25 trails and path 2 for
%next 25 trails.


numTestPaths=2;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=50;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.

budget = 3;

attackerSuccessfulDynamic= -1 * ones(numTestPaths/2,maxNumTrials);
attackerSuccessfulStatic= -1 * ones(numTestPaths/2,maxNumTrials);

%testPaths=cell(numTestPaths,1);  % Stores the test paths or attacker paths.

placement_final=cell(numTestPaths/2,maxNumTrials);
benefit_final=zeros(numTestPaths/2,maxNumTrials);
cost_final=zeros(numTestPaths/2,maxNumTrials);

% attackerallpath = allpossiblepath(adjacency(idsDynamic.networkGraph),1,idsDynamic.crownJewel);
% randompath = randperm(size(attackerallpath,1),numTestPaths);
% % Create Random Attack Paths.
% % Same Attack Path can get repeated.
% 
% for i=1:numTestPaths
%     testPaths{i}=attackerallpath{randompath(i)};
% end

% load('First','firstpath');
% load('Second','secondpath');


% Dynamic Deployment.
% Running parallel - for each path -> generate dynamic placement for
% MaxNumTrails times.
% Select the first test path -> run GA cost constrainted to generate a
% placement vector.
% check if there is ids in the attack path and does it generate an alert.
% -> if yes attacker unsuccessful
% for each alert generation find new placement after updating the edge weight.
% Attacker takes the same path for MaxNumTrials.
% if attacker success just break for that numseed.

% check only if IDS is present in the path -> if yes the attacker is
% unsuccessful. 
parfor i=1:(numTestPaths/2)
   testPath=firstpath{i};
    idsDynamic=OOP_IDS(); %Need to re-instantiate for proper parallel operation
    idsDynamic.budget_IDS = budget;
    dynamicPlacement=idsDynamic.optimizeWithGA();
     for k=1:maxNumTrials
            if k >= (maxNumTrials/2)
                testPath = secondpath{i};
            end
            idsDynamic.findAttackerEdgeWeight(testPath);
            %disp(idsDynamic.actualAttackerEdgeWeight);
            [alertNode,success]=idsDynamic.checkAttackPathEwEffect(testPath,dynamicPlacement);
            disp(alertNode);
            attackerSuccessfulDynamic(i,k)=success;
            placement_final{i,k} = dynamicPlacement;
            benefit_final(i,k) = idsDynamic.calculate_benefit(dynamicPlacement);
            benefit_final_attacker(i,k) = idsDynamic.calculate_benefit_attacker(dynamicPlacement);
            cost_final(i,k) = sum(dynamicPlacement == 1);
               
            idsDynamic.decayEdgeWeightNoAlert(alertNode,dynamicPlacement);
            disp('No Alert')
            idsDynamic.buildEdgeProbability();
            disp(idsDynamic.edgeWeightProbability);
            % only when there is no IDS on that path.
            % continue even if there is no IDS on the path.
            % Only when there is an IDS in the Path.
            if ~isempty(alertNode)
                %idsDynamic.updateEdgeWeightPredecessor(alertNode);
                %idsDynamic.updateEdgeWeightPathBased(alertNode);
                idsDynamic.updateEdgeWeightDistance(alertNode);
                %disp(alertNode);
                disp('after alert');
                idsDynamic.buildEdgeProbability();
                disp(idsDynamic.edgeWeightProbability);
                %disp(idsDynamic.edgeWeightAttacker);
                
                dynamicPlacement=idsDynamic.optimizeWithGA();
                disp(dynamicPlacement);
            end
            %The edge weight decay is performed only after the optimization
            %has been done. The effect will be seen only in the next
            %iteration and not the immediate iteration.
            idsDynamic.lastPopulation=[];  %reset the last population
            %idsDynamic.decayEdgeWeight(); % exponential decay of edge weight irresepective of alert or not.
      end
end

% benefitStatic=[];
% benefitDynamic=[];
% for i=1:numTestPaths
%     benefitStatic(i)=1-sum(attackerSuccessfulStatic(i,:,:))/maxNumTrials;
%     benefitDynamic(i)=1-sum(attackerSuccessfulDynamic(i,:,:))/maxNumTrials;
% end

% for i=1:numTestPaths
%     benefitStatic(i)  = 1-(sum(sum(attackerSuccessfulStatic(i,:) == 1))/(sum(sum(attackerSuccessfulStatic(i,:) == 1)) + sum(sum(attackerSuccessfulStatic(i,:) == 0))));
%     benefitDynamic(i) = 1-(sum(sum(attackerSuccessfulDynamic(i,:) == 1))/(sum(sum(attackerSuccessfulDynamic(i,:) == 1)) + sum(sum(attackerSuccessfulDynamic(i,:) == 0))));
% end
% 
% for i=1:(numTestPaths/2)
%     for j=1:maxNumTrials
%         benefit_final_trail(i,j) = sum(benefit_final(i,:,j))/numSeeds;
%     end
% end


% figure('position',[500 500 560 242]);
% bar([benefitStatic; benefitDynamic]');
% legend('Static BVO-GA','Dynamic BVO-GA');
% xlabel('Path Number');
% ylabel('Benefit');
% im_hatch = applyhatch_plusC(gcf,'|-+.\/','rgbcmy',[],400,0.8);
% imwrite(im_hatch,'im_hatch.png','png')
%im_hatchC = applyhatch_plusC(1,'\-x.',[1 0 0;0 1 0;0 0 1;0 1 1]);