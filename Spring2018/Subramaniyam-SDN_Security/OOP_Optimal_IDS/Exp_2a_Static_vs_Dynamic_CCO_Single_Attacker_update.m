numTestPaths=1;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=50;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.
numSeeds=5;       % Number of try for each test path
budget = 3;
% Each test path run for maxNumTrails * numSeeds time. Break if the
% attacker is once successful.


% 2 Dimensional Matric to track number of times the attacker was successful
% in each path. Attacker is unsuccessful if the IDS generates an alert.
% No alert generation => attacker is successful.
% intially the matrix is all -1.
attackerSuccessfulDynamic= -1 * ones(numTestPaths,numSeeds,maxNumTrials);
attackerSuccessfulStatic= -1 * ones(numTestPaths,numSeeds,maxNumTrials);

testPaths=cell(numTestPaths,1);  % Stores the test paths or attacker paths.

idsStatic=OOP_IDS();       % Static IDS Deployment.
idsStatic.budget_IDS = budget;

idsDynamic = OOP_IDS();    % Dynamic IDS Deployment.
idsDynamic.budget_IDS = budget;

placement_final=cell(numTestPaths,numSeeds,maxNumTrials);
benefit_final=zeros(numTestPaths,numSeeds,maxNumTrials);
cost_final=zeros(numTestPaths,numSeeds,maxNumTrials);
time_final=zeros(numTestPaths,numSeeds,maxNumTrials);

% attackerallpath = allpossiblepath(adjacency(idsDynamic.networkGraph),1,idsDynamic.crownJewel);
% randompath = randperm(size(attackerallpath,1),numTestPaths);

% Create Random Attack Paths.
% Same Attack Path can get repeated.
load('testpaths.mat','testPaths');

% for i=1:numTestPaths
%     testPaths{i}=attackerallpath{randompath(i)};
% end


% static deployment with no change in the IDS configuration.
% for the same configuration we check.
% if the attacker is successful once in that path, then break out of that
% numseed in this path i and try for different seed in the same path.
% success = 1 means the attacker is successful, 0 means not successful, -1
% means the attacker is successs and rest of the trails are not tried.
staticPlacement=idsStatic.optimizeWithGA();
for i=1:numTestPaths
    testPath=testPaths{i};
    for j=1:numSeeds
        for k=1:maxNumTrials
            [~,success]=idsStatic.checkAttackPath(testPath,staticPlacement);
            attackerSuccessfulStatic(i,j,k)=success;
            %if the attacker is successfull => he has already reached the
            %crownjewel.
            if success == 1
%                 for z=k+1:maxNumTrials
%                     attackerSuccessfulStatic(i,j,z)= -1;
%                 end
                break;
            end
        end
    end
end


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
parfor i=1:numTestPaths
    testPath=testPaths{i};
    idsDynamic=OOP_IDS(); %Need to re-instantiate for proper parallel operation
    idsDynamic.budget_IDS = budget;
    for j=1:numSeeds
        dynamicPlacement=idsDynamic.optimizeWithGA();
        %Edge Weights are not resetted back to the Uniform Distribution.
        %Continue with previous Edge Weights.
        for k=1:maxNumTrials
            tic;
            [alertNode,success]=idsDynamic.checkAttackPath(testPath,dynamicPlacement);
            attackerSuccessfulDynamic(i,j,k)=success;
            placement_final{i,j,k} = dynamicPlacement;
            benefit_final(i,j,k) = idsDynamic.calculate_benefit(dynamicPlacement);
            cost_final(i,j,k) = sum(dynamicPlacement == 1);
            if  success == 1
                %disp(idsDynamic.edgeWeightAttacker);
                idsDynamic.lastPopulation=[];  %reset the last population
                %decay weight = 0 -> Not using for this experiment.
                idsDynamic.decayEdgeWeight(); % exponential decay of edge weight irresepective of alert or not.
                time_final(i,j,k) = toc;
                break;
            end
            if ~isempty(alertNode)
                %idsDynamic.updateEdgeWeightPredecessor(alertNode);
                %idsDynamic.updateEdgeWeightPathBased(alertNode);
                idsDynamic.updateEdgeWeightDistance(alertNode);
                %disp(alertNode);
                %disp(idsDynamic.edgeWeightAttacker);
                idsDynamic.lastPopulation=[];  %reset the last population
                dynamicPlacement=idsDynamic.optimizeWithGA();
            end
            %The edge weight decay is performed only after the optimization
            %has been done. The effect will be seen only in the next
            %iteration and not the immediate iteration.
            idsDynamic.decayEdgeWeight(); % exponential decay of edge weight irresepective of alert or not.
            time_final(i,j,k) = toc;
        end
    end
    %idsDynamic.resetLearnedParams();
end

% benefitStatic=[];
% benefitDynamic=[];
% for i=1:numTestPaths
%     benefitStatic(i)=1-sum(attackerSuccessfulStatic(i,:,:))/maxNumTrials;
%     benefitDynamic(i)=1-sum(attackerSuccessfulDynamic(i,:,:))/maxNumTrials;
% end

for i=1:numTestPaths
    benefitStatic(i)  = 1-(sum(sum(attackerSuccessfulStatic(i,:,:) == 1))/(sum(sum(attackerSuccessfulStatic(i,:,:) == 1)) + sum(sum(attackerSuccessfulStatic(i,:,:) == 0))));
    benefitDynamic(i) = 1-(sum(sum(attackerSuccessfulDynamic(i,:,:) == 1))/(sum(sum(attackerSuccessfulDynamic(i,:,:) == 1)) + sum(sum(attackerSuccessfulDynamic(i,:,:) == 0))));
end

% figure('position',[500 500 560 242]);
% bar([benefitStatic; benefitDynamic]');
% legend('Static BVO-GA','Dynamic BVO-GA');
% xlabel('Path Number');
% ylabel('Benefit');
% im_hatch = applyhatch_plusC(gcf,'|-+.\/','rgbcmy',[],400,0.8);
% imwrite(im_hatch,'im_hatch.png','png')
%im_hatchC = applyhatch_plusC(1,'\-x.',[1 0 0;0 1 0;0 0 1;0 1 1]);