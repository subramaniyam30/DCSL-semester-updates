p
num_servers = 50;



connections = ceil(num_servers*2);
ids_GA = OOP_IDS(-1,num_servers,connections);
ids_GA.cost_budget = 0.5 * ids_GA.maxCost;


for i = 1:10
    
    ids_GA.optimizeWithGA();
    timeGAMat(i) = ids_GA.lastRunningTime;
    perfGAMat(i) = (ids_GA.calculate_benefit(ids_GA.lastIdsPlacement)/ ids_GA.maxBenefit);
    %disp(ids_GA.lastIdsPlacement);
    ids_GA.lastPopulation=[];
    
   % ids_GA.optimizeWithExhSearch();
   % timeExhMat(i) = ids_GA.lastRunningTime;
   % perfExhMat(i) = (ids_GA.calculate_benefit(ids_GA.lastIdsPlacement)/ ids_GA.maxBenefit);
    %disp(ids_ES.lastIdsPlacement);
end

perfGA = sum(perfGAMat)/10;
%perfExh = sum(perfExhMat)/10;
%error = (perfExh - perfGA)/perfExh;
%errorMat = (perfGAMat - perfExhMat)./perfExhMat;
timeGA = sum(timeGAMat)/10;
%timeExh = sum(timeExhMat)/10;

fprintf("For a network size of %i servers:\n", num_servers)
fprintf("Average Performance of GA: %2.2f\n", perfGA*100)
%fprintf("Average Performance of Exhaustive: %2.2f\n", perfExh*100)
%fprintf("Error (difference in average performance): %2.2f\n", error*100)
fprintf("Average GA Runtime: %2.2f sec\n",timeGA)
%fprintf("Average Exhaustive Runtime: %2.2f sec\n",timeExh)


% networkSizes = [5,7,9,11,13,15,20,30,50];
%     %runtimeGA = [1.68,3.7,7.29,10.19,12.04,15.24,24.28,44.79,79.32];
%     runtimeGA = [22.67,29.19,39.18,45.43,66.55,131.68,173.94,276.63,666.07]
%     networkSizesSmall = [5,7,9,11,13,15];
%     fitX = networkSizesSmall';
%     %runtimeExh = [0.01,0.07,0.41,2.01,9.84,52.66];
%     runtimeExh = [0.1,0.54,2.91,13.59,80.36,432.12]
%     fitY = runtimeExh';
%     %figure(experiment)
%     figure(1)
%     hold on
%     plot(networkSizes,runtimeGA,'bo-','LineWidth',2)
%     plot(networkSizesSmall,runtimeExh,'ro-','LineWidth',2)
%     f = fit(fitX,fitY,'exp1');
%     linFit = @(x) 1.761*x-9.252;
%     expFit = @(x) 0.0002*exp(0.8355*x);
%     fplot(linFit,[0,50])
%     fplot(expFit,[0,15.5])
%     %plot(f,networkSizesSmall,runtimeExh)
%     %plot(f)
%     xlim([0,50])
%     ylim([0,80])
%     xlabel('Number of Servers')
%     ylabel('Runtime (sec)')
%     title('Algorithm Runtime vs. Network Size')
%     legend('Genetic Algorithm','Exhaustive Search','Linear Fit: y = 1.761x-9.252',...
%         'Exponential Fit: y = 0.002*exp(0.8355x)')
