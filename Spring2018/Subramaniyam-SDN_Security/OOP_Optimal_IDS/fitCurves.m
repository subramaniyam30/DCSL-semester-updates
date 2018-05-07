
% Select fit for GA: 0 = linear, 1 = quadratic
fitType = 1;

% Plot data
networkSizes = [5,7,9,11,13,15,20,30,50];
runtimeGA = [22.67,29.19,39.18,45.43,66.55,131.68,173.94,276.63,666.07];
networkSizesSmall = [5,7,9,11,13,15];
runtimeExh = [0.1,0.54,2.91,13.59,80.36,432.12];
figure()
hold on
plot(networkSizes,runtimeGA,'bo-','LineWidth',1)
plot(networkSizesSmall,runtimeExh,'ro-','LineWidth',1)
fittedX = [5:1:50];

if fitType == 0
    % For Linear fit for GA
    fitGA = fit(networkSizes',runtimeGA','poly1');
    plot(fittedX,fitGA(fittedX))
elseif fitType == 1
    % For quadratic fit for GA
    coefGA = polyfit(networkSizes',runtimeGA',2);
    aGA = coefGA(1);
    bGA = coefGA(2);
    cGA = coefGA(3);
    plot(fittedX,(aGA.*fittedX.^2+bGA.*fittedX+cGA))
end

% Exponential fit for Exhaustive
fitExh = fit(networkSizesSmall',runtimeExh','exp1');
fittedXSmall = [5:1:15];
plot(fittedXSmall,fitExh(fittedXSmall))