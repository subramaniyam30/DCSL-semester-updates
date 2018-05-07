% set the weight value for GAMOO and the learning rate.

maxNumTrials=75;   % Number of Trails for each test path or attacker path.-> No. of times the attacker repeats the same path.

target_cost = 5;

%kpall = [0.0005,0.001,0.004,0.005,0.006,0.008,0.01,0.02,0.04,0.05,0.01];
kpall = 0.01;
%kiall = [0.0004,0.0005,0.001,0.004,0.005,0.006,0.008,0.01,0.02];
kiall = [0.025,0.03];

numkp = size(kpall,2);
numki = size(kiall,2);

testPath = [1,2,6,8,11,12];


placement_final=cell(maxNumTrials);
benefit_final=zeros(maxNumTrials);
cost_final=zeros(maxNumTrials);
EW_ratio=zeros(maxNumTrials);


placement_final_ctrl=cell(numkp,numki,maxNumTrials);
benefit_final_ctrl=zeros(numkp,numki,maxNumTrials);
cost_final_ctrl=zeros(numkp,numki,maxNumTrials);
EW_ratio_ctrl=zeros(numkp,numki,maxNumTrials);
alphavalues = zeros(numkp,numki,maxNumTrials);

%No control on Alpha
idsDynamicNoCtrl = OOP_IDS();    % Dynamic IDS Deployment with no control on alpha.

idsDynamicNoCtrl.weight = 0.4;  % set this.
idsDynamicNoCtrl.learningRate = 10;

% dynamicPlacement=idsDynamicNoCtrl.optimizeWithGAMOO();
%         for k=1:maxNumTrials
%             [alertNode,success]=idsDynamicNoCtrl.checkAttackPathEwEffect(testPath,dynamicPlacement);
%             placement_final{k} = dynamicPlacement;
%             EW_ratio(k)= (sum(idsDynamicNoCtrl.edgeWeightAttacker.weight)/(numel(idsDynamicNoCtrl.edgeWeightAttacker.weight)));
%             benefit_final(k) = idsDynamicNoCtrl.calculate_benefit(dynamicPlacement);
%             cost_final(k) = sum(dynamicPlacement == 1);
%             if ~isempty(alertNode)
%                 %idsDynamicNoCtrl.updateEdgeWeightDistance(alertNode);
%                 idsDynamicNoCtrl.updateEdgeWeightPathBased(alertNode);
%                 idsDynamicNoCtrl.lastPopulation=[];
%                 dynamicPlacement=idsDynamicNoCtrl.optimizeWithGAMOO();
%             end
%         end


% Dynamic deployment with control on alpha
for i=1:numkp
    kp = kpall(i);
parfor j=1:numki
    ki = kiall(j);
    idsDynamicCtrl=OOP_IDS();
    
    idsDynamicCtrl.weight = 0.4;
    idsDynamicCtrl.learningRate = 10;
    
    dynamicPlacement=idsDynamicCtrl.optimizeWithGAMOO();
    current_error = 0;
    sum_error = 0;
        for k=1:maxNumTrials
            [alertNode,success]=idsDynamicCtrl.checkAttackPathEwEffect(testPath,dynamicPlacement);
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
            end
        end
end
    
end

