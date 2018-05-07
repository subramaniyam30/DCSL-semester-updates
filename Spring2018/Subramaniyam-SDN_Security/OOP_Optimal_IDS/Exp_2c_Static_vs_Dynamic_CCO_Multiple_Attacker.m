numTestPaths=10;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=50;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.
numSeeds=50;       % Number of try for each test path

% Each test path run for maxNumTrails * numSeeds time. Break if the
% attacker is once successful.


% 2 Dimensional Matric to track number of times the attacker was successful
% in each path. Attacker is unsuccessful if the IDS generates an alert.
% No alert generation => attacker is successful.
attackerSuccessfulDynamic=ones(numTestPaths,numSeeds,maxNumTrials);
attackerSuccessfulStatic=ones(numTestPaths,numSeeds,maxNumTrials);

test_path_attacker_1=cell(numTestPaths,1);  % Stores the test paths or attacker paths.
test_path_attacker_2=cell(numTestPaths,1);

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
    test_path_attacker_1{i}=idsDynamic.getRandomPath();
end

for i=1:numTestPaths
    test_path_attacker_2{i}=idsDynamic.getRandomPath();
end


% static deployment with no change in the IDS configuration.
% for the same configuration we check.
staticPlacement=idsStatic.optimizeWithGA();
for i=1:numTestPaths
    testPath_1=test_path_attacker_1{i};
    testPath_2=test_path_attacker_1{i};
    for j=1:numSeeds
        first_attack = false;
        second_attack = false;
        for k=1:maxNumTrials
            if first_attack == false
                [~,success1]=idsStatic.checkAttackPath(testPath_1,staticPlacement);
                firstattackerSuccessfulStatic(i,j,k)=success1;
            end
            if second_attack == false
                [~,success2]=idsStatic.checkAttackPath(testPath_2,staticPlacement);
                secondattackerSuccessfulStatic(i,j,k)=success2;
            end
            %if the attacker is successfull => he has already reached the
            %crownjewel.
            if firstattackerSuccessfulStatic(i,j,k) == 1 
                first_attack = true;
            end
            if secondattackerSuccessfulStatic(i,j,k) == 1
                second_attack = true;
            end
            if first_attack == true && second_attack == true
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
    testPath_1=test_path_attacker_1{i};
    testPath_2=test_path_attacker_1{i};
     idsDynamic=OOP_IDS(); %Need to re-instantiate for proper parallel operation
     idsDynamic.budget_IDS = 3;
    for j=1:numSeeds
        first_attack = false;
        second_attack = false;
        dynamicPlacement=idsDynamic.optimizeWithGA();
        for k=1:maxNumTrials
            
            if first_attack == false
                [alertNode1,success1]=idsDynamic.checkAttackPath( testPath_1,dynamicPlacement);
                firstattackerSuccessfulDynamic(i,j,k)=success1;
            end
            if second_attack == false
                [alertNode2,success2]=idsDynamic.checkAttackPath( testPath_2,dynamicPlacement);
                secondattackerSuccessfulDynamic(i,j,k)=success2;
            end
            
            if  firstattackerSuccessfulDynamic(i,j,k) == 1
               first_attack = true;
            end
            if  secondattackerSuccessfulDynamic(i,j,k) == 1
               second_attack = true;
            end
            if first_attack == true && second_attack == true
                break;
            end
            placement_final{i,j,k} = dynamicPlacement;
            benefit_final(i,j,k) = idsDynamic.calculate_benefit(dynamicPlacement);
            cost_final(i,j,k) = sum(dynamicPlacement == 1);
            if ~isempty(alertNode1)
                idsDynamic.updateEdgeWeight(alertNode1);
                
            end
            if ~isempty(alertNode2)
                idsDynamic.updateEdgeWeight(alertNode2);
            end
            idsDynamic.lastPopulation=[];
            dynamicPlacement=idsDynamic.optimizeWithGA();
        end
    end
    %idsDynamic.resetLearnedParams();
end

benefitStatic_1=[];
benefitStatic_2=[];
benefitDynamic_1=[];
benefitDynamic_2=[];
benefitStatic_average = [];
benefitDynamic_Average = [];
for i=1:numTestPaths
    benefitStatic_1 = 1-(sum(sum(firstattackerSuccessfulStatic,3),2)/(maxNumTrials * numSeeds));
    benefitStatic_2 = 1-(sum(sum(secondattackerSuccessfulStatic,3),2)/(maxNumTrials * numSeeds));
    benefitDynamic_1 = 1-(sum(sum(firstattackerSuccessfulDynamic,3),2)/(maxNumTrials * numSeeds));
    benefitDynamic_2 = 1-(sum(sum(secondattackerSuccessfulDynamic,3),2)/(maxNumTrials * numSeeds));
end

for i=1:numTestPaths
    benefitStatic_average(i) = (benefitStatic_1(i) + benefitStatic_2(i))/2;
    benefitDynamic_average(i) = (benefitDynamic_1(i) + benefitDynamic_2(i))/2;
end
% figure('position',[500 500 560 242]);
% bar([benefitStatic; benefitDynamic]');
% legend('Static BVO-GA','Dynamic BVO-GA');
% xlabel('Path Number');
% ylabel('Benefit');
% im_hatch = applyhatch_plusC(gcf,'|-+.\/','rgbcmy',[],400,0.8);
% imwrite(im_hatch,'im_hatch.png','png')
%im_hatchC = applyhatch_plusC(1,'\-x.',[1 0 0;0 1 0;0 0 1;0 1 1]);