numTestPaths=10;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=50;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.
numSeeds=1;       % Number of try for each test path
target_cost = 5;
kp = -0.05; %0.01
ki = -0.05;
% Each test path run for maxNumTrails * numSeeds time. Break if the
% attacker is once successful.


% 2 Dimensional Matric to track number of times the attacker was successful
% in each path. Attacker is unsuccessful if the IDS generates an alert.
% No alert generation => attacker is successful.
attackerSuccessfulDynamicCtrl= -1 * ones(numTestPaths,numSeeds,maxNumTrials);
attackerSuccessfulDynamic= -1 * ones(numTestPaths,numSeeds,maxNumTrials);
attackerSuccessfulStatic= -1 * ones(numTestPaths,numSeeds,maxNumTrials);

testPaths=cell(numTestPaths,1);  % Stores the test paths or attacker paths.

idsStatic=OOP_IDS();       % Static IDS Deployment.
%idsStatic.budget_IDS = 3;

idsDynamicNoCtrl = OOP_IDS();    % Dynamic IDS Deployment with no control on alpha.
%idsDynamicNoCtrl.budget_IDS = 3;
placement_final=cell(numTestPaths,numSeeds,maxNumTrials);
benefit_final=zeros(numTestPaths,numSeeds,maxNumTrials);
cost_final=zeros(numTestPaths,numSeeds,maxNumTrials);

idsDynamicCtrl = OOP_IDS();    % Dynamic IDS Deployment with control on alpha.
placement_final_ctrl=cell(numTestPaths,numSeeds,maxNumTrials);
benefit_final_ctrl=zeros(numTestPaths,numSeeds,maxNumTrials);
cost_final_ctrl=zeros(numTestPaths,numSeeds,maxNumTrials);

% Create Random Attack Paths.
% Same Attack Path can get repeated.

for i=1:numTestPaths
    testPaths{i}=idsDynamicNoCtrl.getRandomPath();
end


% static deployment with no change in the IDS configuration.
% for the same configuration we check.
staticPlacement=idsStatic.optimizeWithGAMOO();
for i=1:numTestPaths
    testPath=testPaths{i};
    for j=1:numSeeds
        for k=1:maxNumTrials
            [~,success]=idsStatic.checkAttackPath(testPath,staticPlacement);
            attackerSuccessfulStatic(i,j,k)=success;
            %if the attacker is successfull => he has already reached the
            %crownjewel.
           % if success == 1
%                 for z=k+1:maxNumTrials
%                     attackerSuccessfulStatic(i,j,z)= -1;
%                 end
                %break;
           % end
        end
    end
end


% Dynamic Deployment with no control on alpha.
% Running parallel - for each path -> generate dynamic placement for
% MaxNumTrails times.
% Select the first test path -> run GA cost constrainted to generate a
% placement vector.
% check if there is ids in the attack path and does it generate an alert.
% -> if yes attacker unsuccessful
% for each alert generation find new placement after updating the edge weight.
% Attacker takes the same path for MaxNumTrials.
for i=1:numTestPaths
    testPath=testPaths{i};
    idsDynamicNoCtrl=OOP_IDS(); %Need to re-instantiate for proper parallel operation
%     idsDynamicNoCtrl.budget_IDS = 3;
    for j=1:numSeeds
        dynamicPlacement=idsDynamicNoCtrl.optimizeWithGAMOO();
        for k=1:maxNumTrials
            [alertNode,success]=idsDynamicNoCtrl.checkAttackPath(testPath,dynamicPlacement);
            attackerSuccessfulDynamic(i,j,k)=success;
            %if  success == 1
%                 for z=k+1:maxNumTrials
%                     attackerSuccessfulDynamic(i,j,z)= -1; 
%                 end
               % break;
           % end
            placement_final{i,j,k} = dynamicPlacement;
            benefit_final(i,j,k) = idsDynamicNoCtrl.calculate_benefit(dynamicPlacement);
            cost_final(i,j,k) = sum(dynamicPlacement == 1);
            if ~isempty(alertNode)
                idsDynamicNoCtrl.updateEdgeWeight(alertNode);
                idsDynamicNoCtrl.lastPopulation=[];
                dynamicPlacement=idsDynamicNoCtrl.optimizeWithGAMOO();
            end
        end
    end
    %idsDynamicNoCtrl.resetLearnedParams();
end

% Dynamic deployment with control on alpha
alphavalues = zeros(numTestPaths,numSeeds,maxNumTrials);
for i=1:numTestPaths
    testPath=testPaths{i};
    idsDynamicCtrl=OOP_IDS(); %Need to re-instantiate for proper parallel operation
%     idsDynamicCtrl.budget_IDS = 3;
    for j=1:numSeeds
        dynamicPlacement=idsDynamicCtrl.optimizeWithGAMOO();
        current_error = 0;
        sum_error = 0;
        for k=1:maxNumTrials
            [alertNode,success]=idsDynamicCtrl.checkAttackPath(testPath,dynamicPlacement);
            attackerSuccessfulDynamicCtrl(i,j,k)=success;
            %if  success == 1
%                 for z=k+1:maxNumTrials
%                     attackerSuccessfulDynamic(i,j,z)= -1; 
%                 end
               % break;
           % end
            placement_final_ctrl{i,j,k} = dynamicPlacement;
            benefit_final_ctrl(i,j,k) = idsDynamicCtrl.calculate_benefit(dynamicPlacement);
            cost_final_ctrl(i,j,k) = sum(dynamicPlacement == 1);
            actual_cost = cost_final_ctrl(i,j,k);
            alphavalues(i,j,k) = idsDynamicCtrl.weight;
            if ~isempty(alertNode)
                idsDynamicCtrl.updateEdgeWeight(alertNode);
                idsDynamicCtrl.lastPopulation=[];
                current_error = target_cost - actual_cost;
                sum_error = sum_error + current_error;
                idsDynamicCtrl.weight = idsDynamicCtrl.weight + current_error * kp + sum_error * ki;
                dynamicPlacement=idsDynamicCtrl.optimizeWithGAMOO();
            end
        end
    end
    %idsDynamicCtrl.resetLearnedParams();
end

% benefitStatic=[];
% benefitDynamic=[];
% for i=1:numTestPaths
%     benefitStatic(i)=1-sum(attackerSuccessfulStatic(i,:,:))/maxNumTrials;
%     benefitDynamic(i)=1-sum(attackerSuccessfulDynamic(i,:,:))/maxNumTrials;
% end

for i=1:numTestPaths
    benefitStatic(i)  = 1-(sum(sum(attackerSuccessfulStatic(i,:,:) == 1))/(sum(sum(attackerSuccessfulStatic(i,:,:) == 1)) + sum(sum(attackerSuccessfulStatic(i,:,:) == 0))));
    benefitDynamicNoCtrl(i) = 1-(sum(sum(attackerSuccessfulDynamic(i,:,:) == 1))/(sum(sum(attackerSuccessfulDynamic(i,:,:) == 1)) + sum(sum(attackerSuccessfulDynamic(i,:,:) == 0))));
    benefitDynamicCtrl(i) = 1-(sum(sum(attackerSuccessfulDynamicCtrl(i,:,:) == 1))/(sum(sum(attackerSuccessfulDynamicCtrl(i,:,:) == 1)) + sum(sum(attackerSuccessfulDynamicCtrl(i,:,:) == 0))));
end

% figure('position',[500 500 560 242]);
% bar([benefitStatic; benefitDynamic]');
% legend('Static BVO-GA','Dynamic BVO-GA');
% xlabel('Path Number');
% ylabel('Benefit');
% im_hatch = applyhatch_plusC(gcf,'|-+.\/','rgbcmy',[],400,0.8);
% imwrite(im_hatch,'im_hatch.png','png')
%im_hatchC = applyhatch_plusC(1,'\-x.',[1 0 0;0 1 0;0 0 1;0 1 1]);