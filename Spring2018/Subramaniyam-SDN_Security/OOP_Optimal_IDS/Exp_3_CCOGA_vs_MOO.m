ids = OOP_IDS();
for n = 1:20
    costCut = 0.05*n*ids.maxCost;
    budget(n) = costCut;
    ids.cost_budget = budget(n);
    
    ids.optimizeWithGA();
    ids.lastPopulation=[];
    perfArray(n) = (ids.calculate_benefit(ids.lastIdsPlacement)/ ids.maxBenefit);
    relativecostArray(n) = (ids.calculate_num_cost(ids.lastIdsPlacement)/ ids.maxCost);
    numCostArray(n) = ids.calculate_num_cost(ids.lastIdsPlacement);
end


for i = 1:3
    ids.optimizeWithGAMOO();
    ids.lastPopulation=[];
    weightedperfArray(i) = (ids.calculate_benefit(ids.lastIdsPlacement)/ ids.maxBenefit);
    weightedrelativecostArray(i) = (ids.calculate_num_cost(ids.lastIdsPlacement)/ ids.maxCost);
    weightednumCostArray(i) = ids.calculate_num_cost(ids.lastIdsPlacement);
    weight = ids.weight;
    ids.weight = ids.weight + 0.3;
end


for k = 1:3
    costCut = weightednumCostArray(k)*ids.maxCost;
    budget(k) = costCut;
    ids.cost_budget = budget(k);
    
    ids.optimizeWithGA();
    ids.lastPopulation=[];
    GAperfArray(k) = (ids.calculate_benefit(ids.lastIdsPlacement)/ ids.maxBenefit);
    GArelativecostArray(k) = (ids.calculate_num_cost(ids.lastIdsPlacement)/ ids.maxCost);
    GAnumCostArray(k) = ids.calculate_num_cost(ids.lastIdsPlacement);
end