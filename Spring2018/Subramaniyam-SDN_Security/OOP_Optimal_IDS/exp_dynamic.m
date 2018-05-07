
numTestPaths=10;   % Number of Test Paths or Attacker Paths from the first node to the crown jewel.
maxNumTrials=5;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.

% 2 Dimensional Matric to track number of times the attacker was successful
% in each path. Attacker is unsuccessful if the IDS generates an alert. 
% No alert generation => attacker is successful.
attackerSuccessfulDynamic=ones(numTestPaths,maxNumTrials);
attackerSuccessfulStatic=ones(numTestPaths,maxNumTrials);

testPaths=cell(numTestPaths,1);  % Stores the test paths or attacker paths.

%idsStatic=OOP_IDS();       % Static IDS Deployment.

%idsDynamic=OOP_IDS(-1,10,20);
idsDynamic = OOP_IDS();
placement_final=cell(numTestPaths,maxNumTrials);
benefit_final=zeros(numTestPaths,maxNumTrials);
cost_final=zeros(numTestPaths,maxNumTrials);
  
% Create Random Attack Paths.
% Same Attack Path can get repeated.

for i=1:numTestPaths
    testPaths{i}=idsDynamic.getRandomPath();
end



staticPlacement=idsDynamic.optimizeWithGA();
for i=1:numTestPaths
    testPath=testPaths{i};
    for j=1:maxNumTrials
        [~,success]=idsDynamic.checkAttackPath(testPath,staticPlacement);
        attackerSuccessfulStatic(i,j)=success;
    end
end
idsDynamic.lastPopulation = [];

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
    %idsDynamic=OOP_IDS();
    dynamicPlacement=idsDynamic.optimizeWithGA();
    for j=1:maxNumTrials
        [alertNode,success]=idsDynamic.checkAttackPath(testPath,dynamicPlacement);
        attackerSuccessfulDynamic(i,j)=success;
        placement_final{i,j,:} = dynamicPlacement;
        benefit_final(i,j) = idsDynamic.calculate_benefit(dynamicPlacement);
        cost_final(i,j) = idsDynamic.calculate_num_cost(dynamicPlacement)
        if ~isempty(alertNode)
            idsDynamic.updateEdgeWeight(alertNode);
            dynamicPlacement=idsDynamic.optimizeWithGA();
        end
    end
    idsDynamic.resetLearnedParams();
end



