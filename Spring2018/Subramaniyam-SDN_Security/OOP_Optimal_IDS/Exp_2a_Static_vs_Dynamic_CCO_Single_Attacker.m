numTestPaths=10;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=50;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.
numSeeds=5;       % Number of try for each test path

% Each test path run for maxNumTrails * numSeeds time. Break if the
% attacker is once successful.


% 2 Dimensional Matric to track number of times the attacker was successful
% in each path. Attacker is unsuccessful if the IDS generates an alert.
% No alert generation => attacker is successful.
attackerSuccessfulDynamic=ones(numTestPaths,numSeeds,maxNumTrials);
attackerSuccessfulStatic=ones(numTestPaths,numSeeds,maxNumTrials);

testPaths=cell(numTestPaths,1);  % Stores the test paths or attacker paths.

idsStatic=OOP_IDS();       % Static IDS Deployment.
idsStatic.budget_IDS = 3;

idsDynamic = OOP_IDS();    % Dynamic IDS Deployment.
idsDynamic.budget_IDS = 3;

placement_final=cell(numTestPaths,numSeeds,maxNumTrials);
benefit_final=zeros(numTestPaths,numSeeds,maxNumTrials);
cost_final=zeros(numTestPaths,numSeeds,maxNumTrials);

% Create Random Attack Paths.
% Same Attack Path can get repeated.

for i=1:numTestPaths
    testPaths{i}=idsDynamic.getRandomPath();
end


% static deployment with no change in the IDS configuration.
% for the same configuration we check.
staticPlacement=idsStatic.optimizeWithGA();
for i=1:numTestPaths
    testPath=testPaths{i};
    for j=1:numSeeds
        for k=1:maxNumTrials
            [~,success]=idsStatic.checkAttackPath(testPath,staticPlacement);
            attackerSuccessfulStatic(i,j,k)=success;
            %if the attacker is successfull => he has already reached the
            %crownjewel.
            if attackerSuccessfulStatic(i,j,k) == 1
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
parfor i=1:numTestPaths
    testPath=testPaths{i};
    idsDynamic=OOP_IDS(); %Need to re-instantiate for proper parallel operation
    idsDynamic.budget_IDS = 3;
    for j=1:numSeeds
        dynamicPlacement=idsDynamic.optimizeWithGA();
        for k=1:maxNumTrials
            [alertNode,success]=idsDynamic.checkAttackPath(testPath,dynamicPlacement);
            attackerSuccessfulDynamic(i,j,k)=success;
            if  attackerSuccessfulDynamic(i,j,k) == 1
                break;
            end
            placement_final{i,j,k} = dynamicPlacement;
            benefit_final(i,j,k) = idsDynamic.calculate_benefit(dynamicPlacement);
            cost_final(i,j,k) = sum(dynamicPlacement == 1);
            if ~isempty(alertNode)
                idsDynamic.updateEdgeWeight(alertNode);
                idsDynamic.lastPopulation=[];
                dynamicPlacement=idsDynamic.optimizeWithGA();
            end
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

%for i=1:numTestPaths
    benefitStatic  = 1-(sum(sum(attackerSuccessfulStatic,3),2)/(maxNumTrials * numSeeds));
    benefitDynamic = 1-(sum(sum(attackerSuccessfulDynamic,3),2)/(maxNumTrials * numSeeds));
%end

% figure('position',[500 500 560 242]);
% bar([benefitStatic; benefitDynamic]');
% legend('Static BVO-GA','Dynamic BVO-GA');
% xlabel('Path Number');
% ylabel('Benefit');
% im_hatch = applyhatch_plusC(gcf,'|-+.\/','rgbcmy',[],400,0.8);
% imwrite(im_hatch,'im_hatch.png','png')
%im_hatchC = applyhatch_plusC(1,'\-x.',[1 0 0;0 1 0;0 0 1;0 1 1]);