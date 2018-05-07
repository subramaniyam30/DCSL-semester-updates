numTestPaths=1;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=30;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.

target_cost = 5;
kpall = 0.01;
ki = 0;
numkp = size(kpall,2);

% Each test path run for maxNumTrails * numSeeds time. Break if the
% attacker is once successful.


% 2 Dimensional Matric to track number of times the attacker was successful
% in each path. Attacker is unsuccessful if the IDS generates an alert.
% No alert generation => attacker is successful.
attackerSuccessfulDynamicCtrl= -1 * ones(numkp,numTestPaths,maxNumTrials);
attackerSuccessfulDynamic= -1 * ones(numTestPaths,maxNumTrials);

testPaths=cell(numTestPaths,1);  % Stores the test paths or attacker paths.



idsDynamicNoCtrl = OOP_IDS1();    % Dynamic IDS Deployment with no control on alpha.
%idsDynamicNoCtrl.budget_IDS = 3;
placement_final=cell(numTestPaths,maxNumTrials);
benefit_final=zeros(numTestPaths,maxNumTrials);
cost_final=zeros(numTestPaths,maxNumTrials);
EW_ratio=zeros(numTestPaths,maxNumTrials);

idsDynamicCtrl = OOP_IDS1();    % Dynamic IDS Deployment with control on alpha.
placement_final_ctrl=cell(numkp,numTestPaths,maxNumTrials);
benefit_final_ctrl=zeros(numkp,numTestPaths,maxNumTrials);
cost_final_ctrl=zeros(numkp,numTestPaths,maxNumTrials);
EW_ratio_ctrl=zeros(numkp,numTestPaths,maxNumTrials);
alphavalues = zeros(numkp,numTestPaths,maxNumTrials);

% Create Random Attack Paths.
% Same Attack Path can get repeated.

% for i=1:numTestPaths
%     testPaths{i}=idsDynamicNoCtrl.getRandomPath();
% end

testPaths{1} = [1,2,6,8,11,12];

% Dynamic Deployment with no control on alpha.
% Running parallel - for each path -> generate dynamic placement for
% MaxNumTrails times.
% Select the first test path -> run GA cost constrainted to generate a
% placement vector.
% check if there is ids in the attack path and does it generate an alert.
% -> if yes attacker unsuccessful
% for each alert generation find new placement after updating the edge weight.
% Attacker takes the same path for MaxNumTrials.

% for i=1:numTestPaths
%     testPath=testPaths{i};
%     idsDynamicNoCtrl=OOP_IDS(); %Need to re-instantiate for proper parallel operation
%     dynamicPlacement=idsDynamicNoCtrl.optimizeWithGAMOO();
%         for k=1:maxNumTrials
%             [alertNode,success]=idsDynamicNoCtrl.checkAttackPathEwEffect(testPath,dynamicPlacement);
%             attackerSuccessfulDynamic(i,k)=success;
%             placement_final{i,k} = dynamicPlacement;
%             EW_ratio(i,k)= (sum(idsDynamicNoCtrl.edgeWeightAttacker.weight)/(numel(idsDynamicNoCtrl.edgeWeightAttacker.weight)));
%             benefit_final(i,k) = idsDynamicNoCtrl.calculate_benefit(dynamicPlacement);
%             cost_final(i,k) = sum(dynamicPlacement == 1);
%             if ~isempty(alertNode)
%                 %idsDynamicNoCtrl.updateEdgeWeightDistance(alertNode);
%                 idsDynamicNoCtrl.updateEdgeWeightPathBased(alertNode);
%                 idsDynamicNoCtrl.lastPopulation=[];
%                 dynamicPlacement=idsDynamicNoCtrl.optimizeWithGAMOO();
%             end
%         end
%  end
    

% Dynamic deployment with control on alpha
parfor i=1:numkp
    kp = kpall(i);
for j=1:numTestPaths
    %testPath=testPaths{1};
    testPath = [1,2,6,8,11,12];
    idsDynamicCtrl=OOP_IDS1(); %Need to re-instantiate for proper parallel operation
    idsDynamicCtrl.learningRate = 20;
    dynamicPlacement=idsDynamicCtrl.optimizeWithGAMOO();
    current_error = 0;
    sum_error = 0;
        for k=1:maxNumTrials
            [alertNode,success]=idsDynamicCtrl.checkAttackPathEwEffect(testPath,dynamicPlacement);
            attackerSuccessfulDynamicCtrl(i,j,k)=success;
            placement_final_ctrl{i,j,k} = dynamicPlacement;
            benefit_final_ctrl(i,j,k) = idsDynamicCtrl.calculate_benefit(dynamicPlacement);
            cost_final_ctrl(i,j,k) = sum(dynamicPlacement == 1);
            actual_cost = cost_final_ctrl(i,j,k);
            alphavalues(i,j,k) = idsDynamicCtrl.weight;
            EW_ratio_ctrl(i,j,k)= (sum(idsDynamicCtrl.edgeWeightAttacker.weight)/(numel(idsDynamicCtrl.edgeWeightAttacker.weight)));
            if ~isempty(alertNode)
                %idsDynamicCtrl.updateEdgeWeightDistance(alertNode);
                idsDynamicCtrl.updateEdgeWeightPathBased(alertNode);
                idsDynamicCtrl.lastPopulation=[];
                current_error = actual_cost - target_cost;
                sum_error = sum_error + current_error;
                idsDynamicCtrl.weight = idsDynamicCtrl.weight + (current_error * kp) + (sum_error * ki);
                dynamicPlacement=idsDynamicCtrl.optimizeWithGAMOO();
                disp(dynamicPlacement);
            end
        end
end
    
end

% benefitStatic=[];
% benefitDynamic=[];
% for i=1:numTestPaths
%     benefitStatic(i)=1-sum(attackerSuccessfulStatic(i,:,:))/maxNumTrials;
%     benefitDynamic(i)=1-sum(attackerSuccessfulDynamic(i,:,:))/maxNumTrials;
% end

for i=1:numTestPaths
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