budget = 3;

%IDS Configuration 1 with uniform distribution  - edge weights 1 ->
%0.333,0.333,0.3333
ids_CGA_1 = OOP_IDS();
ids_CGA_1.budget_IDS = budget;
ids_CGA_1.optimizeWithGA();
placement_1 = ids_CGA_1.lastIdsPlacement;

%IDS Configuration 2 with non uniform distribution but 0.4 down from
%attacker.
ids_CGA_2 = OOP_IDS();
% update edge weights with 0.4,0.3,0.3
for i = 1: height(ids_CGA_2.edgeWeightAttacker)
    if(ids_CGA_2.edgeWeightAttacker.sources(i) == 1 && ids_CGA_2.edgeWeightAttacker.destination(i) == 3)
        ids_CGA_2.edgeWeightAttacker.weight(i) = 0.75;
    elseif(ids_CGA_2.edgeWeightAttacker.sources(i) == 1 && ids_CGA_2.edgeWeightAttacker.destination(i) == 4)
        ids_CGA_2.edgeWeightAttacker.weight(i) = 0.75;
    elseif(ids_CGA_2.edgeWeightAttacker.sources(i) == 2 && ids_CGA_2.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_2.edgeWeightAttacker.weight(i) = 1.5;
    elseif(ids_CGA_2.edgeWeightAttacker.sources(i) == 5 && ids_CGA_2.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_2.edgeWeightAttacker.weight(i) = 1.5;
    end
end

ids_CGA_2.buildEdgeProbability();
ids_CGA_2.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
ids_CGA_2.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
ids_CGA_2.calculate_max_benefit();   
ids_CGA_2.budget_IDS = budget;
ids_CGA_2.optimizeWithGA();
placement_2 = ids_CGA_2.lastIdsPlacement;

%IDS Configuration 3 with non uniform distribution but 0.2 down from
%attacker.
ids_CGA_3 = OOP_IDS();
% update edge weights with 0.6,0.2,0.2
for i = 1: height(ids_CGA_3.edgeWeightAttacker)
    if(ids_CGA_3.edgeWeightAttacker.sources(i) == 1 && ids_CGA_3.edgeWeightAttacker.destination(i) == 3)
        ids_CGA_3.edgeWeightAttacker.weight(i) = 0.333;
    elseif(ids_CGA_3.edgeWeightAttacker.sources(i) == 1 && ids_CGA_3.edgeWeightAttacker.destination(i) == 4)
        ids_CGA_3.edgeWeightAttacker.weight(i) = 0.333;
    elseif(ids_CGA_3.edgeWeightAttacker.sources(i) == 2 && ids_CGA_3.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_3.edgeWeightAttacker.weight(i) = 0.666;
    elseif(ids_CGA_3.edgeWeightAttacker.sources(i) == 5 && ids_CGA_3.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_3.edgeWeightAttacker.weight(i) = 0.666;
    end
end

ids_CGA_3.buildEdgeProbability();
ids_CGA_3.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
ids_CGA_3.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
ids_CGA_3.calculate_max_benefit();   
ids_CGA_3.budget_IDS = budget;
ids_CGA_3.optimizeWithGA();
placement_3 = ids_CGA_3.lastIdsPlacement;

%IDS Configuration 4 with non uniform distribution same as
%attacker.
%attacker takes the path 1-2-5-10-12.
ids_CGA_4 = OOP_IDS();
% update edge weights probability with 0.8,0.1,0.1
for i = 1: height(ids_CGA_4.edgeWeightAttacker)
    if(ids_CGA_4.edgeWeightAttacker.sources(i) == 1 && ids_CGA_4.edgeWeightAttacker.destination(i) == 3)
        ids_CGA_4.edgeWeightAttacker.weight(i) = 0.125;
    elseif(ids_CGA_4.edgeWeightAttacker.sources(i) == 1 && ids_CGA_4.edgeWeightAttacker.destination(i) == 4)
        ids_CGA_4.edgeWeightAttacker.weight(i) = 0.125;
    elseif(ids_CGA_4.edgeWeightAttacker.sources(i) == 2 && ids_CGA_4.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_4.edgeWeightAttacker.weight(i) = 0.25;
    elseif(ids_CGA_4.edgeWeightAttacker.sources(i) == 5 && ids_CGA_4.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_4.edgeWeightAttacker.weight(i) = 0.25;
    end
end
ids_CGA_4.buildEdgeProbability();
attacker_edge_weight = ids_CGA_4.edgeWeightAttacker;
ids_CGA_4.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
ids_CGA_4.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
ids_CGA_4.calculate_max_benefit();   
ids_CGA_4.budget_IDS = budget;
ids_CGA_4.optimizeWithGA();
placement_4 = ids_CGA_4.lastIdsPlacement;

%IDS Configuration 5 with non uniform distribution with 1. over estimation
%than the attacker.
ids_CGA_5 = OOP_IDS();
% update edge weights with 1,0,0
for i = 1: height(ids_CGA_5.edgeWeightAttacker)
    if(ids_CGA_5.edgeWeightAttacker.sources(i) == 1 && ids_CGA_5.edgeWeightAttacker.destination(i) == 3)
        ids_CGA_5.edgeWeightAttacker.weight(i) = 0;
    elseif(ids_CGA_5.edgeWeightAttacker.sources(i) == 1 && ids_CGA_5.edgeWeightAttacker.destination(i) == 4)
        ids_CGA_5.edgeWeightAttacker.weight(i) = 0;
    elseif(ids_CGA_5.edgeWeightAttacker.sources(i) == 2 && ids_CGA_5.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_5.edgeWeightAttacker.weight(i) = 0;
    elseif(ids_CGA_5.edgeWeightAttacker.sources(i) == 5 && ids_CGA_5.edgeWeightAttacker.destination(i) == 6)
        ids_CGA_5.edgeWeightAttacker.weight(i) = 0;
    end
end
ids_CGA_5.buildEdgeProbability();
ids_CGA_5.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
ids_CGA_5.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
ids_CGA_5.calculate_max_benefit();   
ids_CGA_5.budget_IDS = budget;
ids_CGA_5.optimizeWithGA();
placement_5 = ids_CGA_5.lastIdsPlacement;

% Performance calculation for above placements with attacker probability.
ids_CGA_Performance = OOP_IDS();
ids_CGA_Performance.edgeWeightAttacker = attacker_edge_weight ;
ids_CGA_Performance.buildEdgeProbability();
ids_CGA_Performance.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
ids_CGA_Performance.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
ids_CGA_Performance.calculate_max_benefit();   
ids_CGA_Performance.budget_IDS = budget;

% Performance of IDS configuration 1
%show the benefit.
% difference between the attacker edge weight and system's knowledge.
ids_CGA_Performance.lastIdsPlacement = placement_1;
%performance(1) = (ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement)/ids_CGA_Performance.maxBenefit);
performance(1) = ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement);
Distance(1) = sum(abs(ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_1.edgeWeightProbability.weight));
Distance_actual(1) = sum((ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_1.edgeWeightProbability.weight));

% Performance of IDS configuration 2
ids_CGA_Performance.lastIdsPlacement = placement_2;
%performance(2) = (ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement)/ids_CGA_Performance.maxBenefit);
performance(2) = ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement);
Distance(2) = sum(abs(ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_2.edgeWeightProbability.weight));
Distance_actual(2) = sum((ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_2.edgeWeightProbability.weight));

% Performance of IDS configuration 3
ids_CGA_Performance.lastIdsPlacement = placement_3;
%performance(3) = (ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement)/ids_CGA_Performance.maxBenefit);
performance(3) = ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement);
Distance(3) = sum(abs(ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_3.edgeWeightProbability.weight));
Distance_actual(3) = sum((ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_3.edgeWeightProbability.weight));

% Performance of IDS configuration 4
ids_CGA_Performance.lastIdsPlacement = placement_4;
%performance(4) = (ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement)/ids_CGA_Performance.maxBenefit);
performance(4) = ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement);
Distance(4) = sum(abs(ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_4.edgeWeightProbability.weight));
Distance_actual(4) = sum((ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_4.edgeWeightProbability.weight));

% Performance of IDS configuration 5
% over estimation case.
ids_CGA_Performance.lastIdsPlacement = placement_5;
%performance(5) = (ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement)/ids_CGA_Performance.maxBenefit);
performance(5) = ids_CGA_Performance.calculate_benefit(ids_CGA_Performance.lastIdsPlacement);
Distance(5) = sum(abs(ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_5.edgeWeightProbability.weight));
Distance_actual(5) = sum((ids_CGA_Performance.edgeWeightProbability.weight - ids_CGA_5.edgeWeightProbability.weight));
