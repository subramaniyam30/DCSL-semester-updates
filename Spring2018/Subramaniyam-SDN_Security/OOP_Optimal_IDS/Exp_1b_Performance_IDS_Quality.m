budget = 7;


%IDS quality is 0.8
%IDS Configuration 1 with uniform distribution  - edge weights 1 ->
%0.333,0.333,0.3333
ids_CGA_1 = OOP_IDS();
ids_CGA_1.budget_IDS = budget;
ids_CGA_1.optimizeWithGA();
placement_1 = ids_CGA_1.lastIdsPlacement;


% Performance of IDS quality = 0.8
%show the benefit.


for i=1:20
% Performance of IDS quality with B = 0;
%show the benefit.
ids_CGA_1.calculate_IDSvalue_quality(0);
performance_config1(i) = ids_CGA_1.calculate_benefit_attacker(ids_CGA_1.lastIdsPlacement);
IDS_quality1(i,:) = ids_CGA_1.IDSquality;
% Performance of IDS quality with B = 0.1;
%show the benefit.
ids_CGA_1.calculate_IDSvalue_quality(0.1);
performance_config2(i) = ids_CGA_1.calculate_benefit_attacker(ids_CGA_1.lastIdsPlacement);
IDS_quality2(i,:) = ids_CGA_1.IDSquality;

% Performance of IDS quality with B = 0.2;
%show the benefit.
ids_CGA_1.calculate_IDSvalue_quality(0.2);
performance_config3(i) = ids_CGA_1.calculate_benefit_attacker(ids_CGA_1.lastIdsPlacement);
IDS_quality3(i,:) = ids_CGA_1.IDSquality;

% Performance of IDS quality with B = 0.3;
%show the benefit.
ids_CGA_1.calculate_IDSvalue_quality(0.3);
performance_config4(i) = ids_CGA_1.calculate_benefit_attacker(ids_CGA_1.lastIdsPlacement);
IDS_quality4(i,:) = ids_CGA_1.IDSquality;
% Performance of IDS quality with B = 0.35;
%show the benefit.
ids_CGA_1.calculate_IDSvalue_quality(0.35);
performance_config5(i) = ids_CGA_1.calculate_benefit_attacker(ids_CGA_1.lastIdsPlacement);
IDS_quality5(i,:) = ids_CGA_1.IDSquality;
end

performance_mean(1) = mean(performance_config1);
performance_mean(2) = mean(performance_config2);
performance_mean(3) = mean(performance_config3);
performance_mean(4) = mean(performance_config4);
performance_mean(5) = mean(performance_config5);