% Plot for traffic
% Rebecca Salo
% September 18, 2017

performance = zeros(1,12);
ids = OOP_IDS();
G = ids.toyNetwork(11);

[trafIn,trafOut] = ids.calculate_traffic_weighted(performance,ids.edgeWeightCosts);
index = 1;
for i = 1:11
    pathTraf(index) = trafOut(i)/length(successors(G,i));
    index = index + 1;
end

n = 1;
for j = 1:11
    for k = 1:length(successors(G,j))
        trafAmt(n) = pathTraf(j);
        n = n + 1;
    end
end

G.Edges.Traffic = round(trafAmt',2);

figure('position',[500 500 560 242]);
plot(G,'EdgeLabel',G.Edges.Traffic,'linewidth',2)