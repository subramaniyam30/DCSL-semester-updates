% Result Plots
% Author: Rebecca Salo
% Date: July 20, 2017

% SELECT EXPERIMENT/RESULTS
experiment = 4;

if experiment == 1
    networkSizes = [5,7,9,11,13,15,20,30,50];
    runtimeGA = [1.68,3.7,7.29,10.19,12.04,15.24,24.28,44.79,79.32];
    %runtimeGA = [22.67,29.19,39.18,45.43,66.55,131.68,173.94,276.63,666.07]
    networkSizesSmall = [5,7,9,11,13,15];
    fitX = networkSizesSmall';
    runtimeExh = [0.01,0.07,0.41,2.01,9.84,52.66];
    %runtimeExh = [0.1,0.54,2.91,13.59,80.36,432.12]
    fitY = runtimeExh';
    %figure(experiment)
    %figure(1)
   figure('position',[500 500 560 242]);
    hold on
    plot(networkSizes,runtimeGA,'ro-','LineWidth',2)
    plot(networkSizesSmall,runtimeExh,'bo-','LineWidth',2)
    f = fit(fitX,fitY,'exp1');
    linFit = @(x) 1.761*x-9.252;
    expFit = @(x) 0.0002*exp(0.8355*x);
    fplot(linFit,[0,50])
    fplot(expFit,[0,15.5])
    %plot(f,networkSizesSmall,runtimeExh)
    %plot(f)
    xlim([0,50])
    ylim([0,80])
    xlabel('Number of Servers')
    ylabel('Runtime (sec)')
    %title('Algorithm Runtime vs. Network Size')
    legend('CCO-GA','CCO-ES','Linear Fit: y = 1.761x-9.252',...
        'Exponential Fit: y = 0.002*exp(0.8355x)')
elseif experiment == 0
    [G,crownJewel] = toyNetwork(3);
    labelsArray = {'1';'2';'3';'4';'5';'6';'7';'8';'9';'10';...
        '11 - Crown Jewel'};
%     labelsArray.Font.Size = 16;
    G.Nodes.Numbers = labelsArray;
    xCoords = [1,1,1,3.5,4.5,5,4.5,3.5,6.5,6.5,8];
    yCoords = [7,4.5,2,7,6,4.5,3.75,2,6,3,4.5];
    G.Edges.Index = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]';
    hFig = figure(1);
    set(hFig, 'Position', [400,300,750,500]);
    %set(hFig, 'FontSize', 14);
    p = plot(G,'LineWidth',2,'MarkerSize',6,'NodeLabel',[],...
        'XData',xCoords,'YData',yCoords,'EdgeLabel',G.Edges.Index);
    for i = 1:11
        t = text(xCoords(i)+0.2,yCoords(i)+0.2,num2str(i));
        t.FontSize = 16;
    end
    t = text(xCoords(11)+0.2,yCoords(11)-0.2,'Crown Jewel');
    t.FontSize = 16;
    xlim([0 11]);
    ylim([0 9]);
    % IDS in 7,9,10
elseif experiment == 2
    %costArray = [0,0,0.0944,0.1167,0.1981,0.2463,0.2463,0.3407,0.3630,...
       % 0.4444,0.5000,0.5241,0.5241,0.6407,0.6963,0.7463,0.8000,0.8278,...
       % 0.8833,0.9185,1];
     % benefitArray = [0,0,0.2818,0.3809,0.5844,0.8427,0.8427,0.8878,0.9037,...
      % 0.9363,0.9398,0.9712,0.9712,0.9834,0.9863,0.9897,0.9920,0.99390,...
       % 0.9967,0.9971,1];
    costArray = [0,0,0.0944,0.1167,0.1870,0.2463,0.2463,0.3407,0.3630,0.4444,0.5,0.5241,0.5241,0.6407,0.6963,0.7463,0.8,0.8056,0.8833,0.9222,1]
    budgetArray = [0,0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5,0.55,0.6,...
        0.65,0.7,0.75,0.8,0.85,0.9,0.95,1];
    benefitArray = [0,0,0.2818,0.3809,0.5628,0.8427,0.8427,0.8878,0.9037,...
        0.9363,0.9398,0.9712,0.9712,0.9834,0.9863,0.9897,0.9920,0.9940,...
        0.9967,0.9973,1];
    alphaCost = [0.5241, 0.2463, 0];
    alphaBenefit = [0.9712,0.8427,0];
    alphaBudget = [0.5481,0.2463,0];
    %figure(experiment)
    %figure(1)
    figure('position',[500 500 560 242]);
    hold on
    plot(budgetArray,benefitArray,'r','LineWidth',2)
    plot(budgetArray,costArray,'b','LineWidth',2)
    plot(alphaBudget(1),alphaBenefit(1),'k^','LineWidth',2)
    plot(alphaBudget(2),alphaBenefit(2),'ko','LineWidth',2)
    plot(alphaBudget(3),alphaBenefit(3),'ks','LineWidth',2)
    plot(alphaBudget(1),alphaCost(1),'k^','LineWidth',2)
    plot(alphaBudget(2),alphaCost(2),'ko','LineWidth',2)
    plot(alphaBudget(3),alphaCost(3),'ks','LineWidth',2)
    xlabel('Budget - % Max Cost')
    ylabel('Performance/Relative Cost')
    %title('Constraint vs. Multi-Objective Optimization')
    legend('CCO-GA Performance','CCO-GA Relative Cost','alpha = 0.2',...
        'alpha = 0.5', 'alpha = 0.8')   
elseif experiment == 3
    [G,crownJewel] = toyNetwork(3);
    baseValue = 0.8; % base IDS security value
    depthIncr = 0.02; % amount by which security value increases at each layer
    edgeServers = [];
    for j = 1:numnodes(G)
        if indegree(G,j) == 0
            edgeServers = [edgeServers,j];
        end
    end
    IDSvalues = calculate_IDSvalue(G,crownJewel,edgeServers,baseValue,depthIncr);
    G.Nodes.IDSvalues = IDSvalues';
    plot(G,'NodeLabel',G.Nodes.IDSvalues)
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    
elseif experiment == 4
    [G,crownJewel] = toyNetwork(3);
    G.Edges.Traffic = [16.67,16.67,11.11,11.11,11.11,16.67,16.67,12.96,...
        12.96,3.66,3.66,2.48,2.66,2.66,9.26,9.26,9.26,16.63,14.40]';
    plot(G,'EdgeLabel',G.Edges.Traffic)
    
end