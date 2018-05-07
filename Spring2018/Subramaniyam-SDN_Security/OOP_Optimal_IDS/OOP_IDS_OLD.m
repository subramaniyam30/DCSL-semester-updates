classdef OOP_IDS_OLD < handle
   
    properties
        networkGraph              % Network Graph in Digraph which stores the entire graph - in table format - The first node is just input node to split the traffic - NO IDS in that.
        edgeServers               % 1D Matrix storing the edge nodes.
        crownJewel                % The index of the crownjewel node.
        numServers                % Total Number of Servers in the network.
        
        IDSquality                % IDS Security Value for each Server Node. Array with each index representing the server node number.
        
        weight = 0.5; % importance of cost (0 < weight < 1)
        
        attackerTrafInNoIDS        % Traffic Distribution when there is no IDS. It is an array with index representing the server node and value is the total traffic In at that node.
        trafInMaxIDS               % Traffic Distribution when there is IDS in all possible nodes.
        trafForCost                % Traffic Distribution for calcualting the traffic latency cost. NO IDS use edgeweightCost.
                       
        
        maxCost                    % Maximum Total Cost of deploying IDS in all the nodes except the Crownjewel.
        maxBenefit                 % Maximum Benefit - Protection Difference in the amount of traffic reaching crown jewel when there is IDS everywhere.
        
        lastRunningTime
        lastIdsPlacement
        
        edgeWeightAttacker %weight for computing benefit only - Table with source,destination,edge weight.
        edgeWeightCosts %weight for computing Traffic Latency cost only
        
        
        lastPopulation=[];
        costCut = 108; % max cost allowed/budget - cost contrainst. numerical value.
    end
    
    properties(Constant)
        trafInEdge = 5000e3; % Total traffic coming into network - Given as a total input to the network.
        maxTrafAllowed = 5000e3; % Max traffic handled by a single IDS
        
        baseValue = 0.8; % base IDS security value - First Node is dummy node to split the traffic. Base value is still 0.8 -> nodes start from layer 2.
        depthIncr = 0.02; % amount by which security value increases at each layer
        
        unitCost = 5; % cost of installing each IDS in units of price/labor
        runCost = 3; % cost of running an IDS 
        costPerKp = 0.5; % Traffic Latency Cost for eah 50 Kbps
        
    end
    
    methods
        %constructor called first.
        function obj=OOP_IDS_OLD(graphKey,servers,connections)
            if nargin < 1 || isempty(graphKey)            %if the no. of input parameters are less than 1. Default consider 3rd Toy Network.
                graphKey=3;
            end
            
            if graphKey==-1                                % To create a random network. specify no. of servers and no. of connections.
                %servers = 10; % Enter total number of servers in network
                %connections = 12; % Enter number of connections in network
                crownJewel = servers; % Enter index of crown jewel (Default is last server)
                G = obj.create_Network(servers,connections);
            else
                [G,crownJewel] = obj.toyNetwork(graphKey); % Select index of toy network
                servers = numnodes(G);
            end
            obj.networkGraph=G;         % The network Graph
            obj.crownJewel=crownJewel;   %Crownjewel Node
            obj.numServers=servers;       % Total No. of Servers.
            
            edgeServers = [];  %Find the outward facing servers/edge servers.
            for j = 1:servers
                if indegree(G,j) == 0
                    edgeServers = [edgeServers,j];  %#ok<AGROW> % index of edge servers % AGROW -  the array is growing inside the loop.
                end
            end
            obj.edgeServers=edgeServers;
            
            obj.buildEdgeWeights();        %calculate edge weights to distribute traffic.
            obj.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
            obj.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
            obj.calculate_max_costs();          %find the max total cost for IDS everywhere
            obj.calculate_max_benefit();        %find the gain or benefit in protection when IDS is everywhere
            
        end
        
        %Assign weights to each edge to distribute the traffic.
        function buildEdgeWeights(obj)
            tableInfo=[obj.networkGraph.Edges{:,:}];
            obj.edgeWeightAttacker=table();
            obj.edgeWeightAttacker.sources=tableInfo(:,1);
            obj.edgeWeightAttacker.destination=tableInfo(:,2);
            
            obj.edgeWeightAttacker.weight=ones(1,size(tableInfo,1))';  %Initial weights to all the edges to distribute traffic - calculate benefit.
            obj.edgeWeightCosts=obj.edgeWeightAttacker;                % Initial weights to calculate the costs.
        end
        
        
        % Determine the IDS quality for IDS Security value.
        function calculate_IDSvalue(obj)
            minDistance(1,1:numnodes(obj.networkGraph)) = -1;
            % minDistance is shortest distance from server to edge; represents
            % number of layers
            for i = 1:length(obj.edgeServers)
                for j = 1:numnodes(obj.networkGraph)
                    if ismember(j,obj.edgeServers)
                        minDistance(j) = 0;
                    elseif minDistance(j) == -1
                        minDistance(j) = length(shortestpath(obj.networkGraph,obj.edgeServers(i),j)) - 1;
                    elseif (minDistance(j) > (length(shortestpath(obj.networkGraph,obj.edgeServers(i),j)) - 1)) ...
                            && ((length(shortestpath(obj.networkGraph,obj.edgeServers(i),j)) - 1) > 0)
                        minDistance(j) = length(shortestpath(obj.networkGraph,obj.edgeServers(i),j)) - 1;
                    end
                end
            end
            
            IDSvalue = obj.baseValue + obj.depthIncr * minDistance;
            IDSvalue(obj.crownJewel) = 0;
            obj.IDSquality=IDSvalue;
        end
        
        
        %calculates the traffic distribution through the network graph.
        function calculate_baseline_traffics(obj)
            %Traffic Distribution when there is no IDS. Protection = 0
            obj.attackerTrafInNoIDS=obj.calculate_traffic_weighted(zeros(1,obj.numServers),obj.edgeWeightAttacker);
            %Traffic Distribution to calculate the traffic latency cost.No
            %IDS
            %EdgeWeightCost.
            obj.trafForCost=obj.calculate_traffic_weighted(zeros(1,obj.numServers),obj.edgeWeightCosts);
            %Traffic Distribution when there is IDS in all the nodes - Here
            %we assume the entire input traffic is attacker's traffic.
            %baseline case.
            obj.trafInMaxIDS=obj.calculate_traffic_weighted(obj.IDSquality,obj.edgeWeightAttacker);
        end
        
        
         %Calculate the traffic Distribution over the network.
        % protection is the IDS quality 
        % the edge weight table.
        %trafIn - input traffic at each node
        %trafOut - output traffic from each node.
        function [trafIn, trafOut] = calculate_traffic_weighted(obj,protection,weightTable)
            servers = numnodes(obj.networkGraph); % number of server, incl. CJ and edges
            numEdgeServers = sum(indegree(obj.networkGraph) == 0);
            
            trafOut(1,1:servers) = -1; % Indicates traffic not calculated yet
            trafIn = zeros(1,servers);
            noTrafIn = 0; % Flag in case incoming traffic hasn't been calculated
            repeatNodes = 1:servers; % Array to store nodes to recalculate traffic
            contCalc = 1; % Flag telling to repeat calculations
            
            while contCalc == 1
                contCalc = 0;
                nodes = repeatNodes;
                repeatNodes = []; % reset in case of further repetitions
                for n = 1:length(nodes)
                    index = nodes(n);
                    if indegree(obj.networkGraph,index) == 0
                        % Means index is an edge server
                        % trafficInEdge is the total input traffic to the
                        % network.
                        trafIn(index) = obj.trafInEdge/numEdgeServers;
                    else
                        %if the nodes are not edge servers. Find the
                        %predecessors of that node.
                        preds = predecessors(obj.networkGraph,index);
                        for i = 1:length(preds)
                            % Calculate traffic in
                            if trafOut(preds(i)) ~= -1
                                edgeWeight=weightTable(weightTable.sources==preds(i) & weightTable.destination==index,:).weight;
                                totatlEdgeWeights=sum(weightTable(weightTable.sources==preds(i),:).weight);
                                addedTraffic=trafOut(preds(i))*(edgeWeight/totatlEdgeWeights);
                                % Guarantees we have already calculated traffic
                                trafIn(index) = trafIn(index) + ...
                                    addedTraffic;
                            else
                                noTrafIn = 1;
                            end
                        end
                    end
                    
                    if (noTrafIn == 0)
                        % Calculate traffic out for the edge nodes.
                        trafOut(index) = (1-protection(index))*trafIn(index);
                    elseif noTrafIn == 1
                        %for all the nodes other than edge nodes.
                        % if all the predecessor nodes of particular index, output traffic is
                        % not calculated. wait for future iterations to be
                        % calculated.
                        trafIn(index) = 0; % Reset traffic to be calculated later
                        repeatNodes = [repeatNodes, index]; %#ok<AGROW>  stores all the nodes for which traffic out is not calculated.
                        contCalc = 1;
                    end
                    noTrafIn = 0; % Reset traffic flag
                end
            end
        end
        
        %Determine the total cost for deploying IDS in the network.
        % Total Cost = Running Cost + installation Cost + Traffic Latency
        % Cost.
        %Determine the maximum traffic Latency Costs - Cost incurred due to the
        %processing of traffic by the IDS. Depends on the amount of traffic
        %it processes.
        function calculate_max_costs(obj)
            % traffic latency cost - (traffic IN at each node/50kbps) *
            % (cost per 50 kbps).
            % To calcualte maximum cost - assume IDS at all the nodes.
            % reduction in traffic due to IDS is negligible ignore.
            maxTrafCost = 0;
            for m = 1:obj.numServers
                if obj.IDSquality(m) ~= 0
                    maxTrafCost = maxTrafCost + ceil(obj.trafForCost(m)/50e3)*obj.costPerKp;
                end
            end
            % Determine the installation cost and running cost.
            obj.maxCost = obj.unitCost*sum(obj.IDSquality ~= 0) + obj.runCost*sum(obj.IDSquality ~= 0) ...
                + maxTrafCost;
        end
        
        % Determine the maximum benefit.
        % Benefit for a particular configuration is defined as 
        %(Maximum Probability of Attacker Success – Probability of Attacker Success for that configuration) / (Maximum Probability of attacker Success)
        %Assume all the traffic is attacker's traffic. 
        function calculate_max_benefit(obj)
            obj.maxBenefit = (obj.attackerTrafInNoIDS(obj.crownJewel) - obj.trafInMaxIDS(obj.crownJewel)) ...  
                /obj.attackerTrafInNoIDS(obj.crownJewel);
        end
        
        
        % Genetic Algorithm Optimization.
        % GA returns the vector with 0's and 1's -> 0's indicate no IDS whereas 1's
        % indicate IDS at that location (array index).
        % objective function, no. of servers, lowerbound ->0, upperbound -> 1 have
        % ids everywhere except the crownjewel,cost constraint.intcon - it should
        % be a integer -> 0 or 1, opts-> display to be off)
        %objfunc - takes the placement as input and calculates the total objective
        %value.
        %costconstraint-> find a solution less than the budget.
        % it keeps on running with different configurations and converges after
        % some time. starts with a randow configuration and mutates.
        function [finalIDSPlacement,runningTime] = optimizeWithGA(obj)
            lb=zeros(obj.numServers,1);
            ub=[ones((obj.numServers-1),1);0];
            IntCon=1:obj.numServers;
            opts=optimoptions(@ga,'Display','off');
            tic;
            % Objective Function that should be optimized.
            objFcn=@(placement) obj.objective_function(placement);
            costConstraintFcn=@(placement) obj.cost_constraint(placement);
            finalIDSPlacement = ga(objFcn,obj.numServers,[],[],[],[],lb,ub,costConstraintFcn,IntCon,opts);
            runningTime=toc;
            obj.lastRunningTime=runningTime;
            obj.lastIdsPlacement=finalIDSPlacement;
        end
        
        %Objective Function for Cost Constrained Optimization.
        % Maximize the benefit given a cost constraint.
        % Placement vector is generated by the GA.
        function objFunc = objective_function(obj,placement)
            % Objective Function = - benefit constrained with constraint function
            
            placeBenefit = obj.calculate_benefit(placement);  % returns the benefit for that placement.
            % GA allows only to minimize the objective function.
            objFunc = -1*placeBenefit;    %to get the maximum benefit we find minimum negative benefit
        end
        
        
        %Determine the benefit of a particular configuration.
        function benefit = calculate_benefit(obj,placement)
            % Benefit = reduction in probability of attacker succeeding
            % Send the IDS quality values for only those nodes where there
            % is an IDS.
            protection = obj.IDSquality.*placement;
            [trafInIDS,~] = obj.calculate_traffic_weighted(protection,obj.edgeWeightAttacker);
            benefit = (obj.attackerTrafInNoIDS(obj.crownJewel) - trafInIDS(obj.crownJewel))/obj.attackerTrafInNoIDS(obj.crownJewel);
        end
        
        
        function path=getRandomPath(obj)
            firstNode=obj.edgeServers(randi(numel(obj.edgeServers)));
            lastNode=firstNode;
            path=[];
            while(true)
                path=[path lastNode]; %#ok<AGROW>
                sucs=successors(obj.networkGraph,lastNode);
                if isempty(sucs)
                    break;
                end
                lastNode=sucs(randi(numel(sucs)));
            end
            if path(end) ~= obj.crownJewel
                %path=obj.getRandomPath();
            end
        end
        
        function [alertNode,success]=checkAttackPath(obj,path,placement)
            numericalPlacement=1:numel(placement);
            numericalPlacement=numericalPlacement(placement==1);
            for i=1:numel(path)
                for j=1:numel(numericalPlacement)
                    if path(i)==numericalPlacement(j)
                        if rand() < obj.IDSquality(numericalPlacement(j))
                            alertNode=numericalPlacement(j);
                            success=0;
                            return;
                        end
                    end
                end
            end
            alertNode=[];
            if any(path==obj.crownJewel)
                success=1;
            else
                success=0;
            end
            
        end
        
        function addAlertWeighting(obj,alertNode)
            allEdges=obj.getAllEdgesOnPath(alertNode);
            for i=1:size(allEdges,1)
                index=obj.edgeWeightAttacker.sources==allEdges(i,1) & ...
                    obj.edgeWeightAttacker.destination==allEdges(i,2);
                obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+1;
            end
            obj.calculate_baseline_traffics();
            obj.calculate_max_benefit();
        end
        
        function allEdges=getAllEdgesOnPath(obj,nodeNumber)
            allEdges=[];
            preds=predecessors(obj.networkGraph,nodeNumber);
            for i=1:numel(preds)
                allEdges=[allEdges; preds(i) nodeNumber]; %#ok<AGROW>
                newEdges=obj.getAllEdgesOnPath(preds(i)); 
                allEdges=[allEdges; newEdges]; %#ok<AGROW>
            end
            allEdges=unique(allEdges,'rows');
        end
        
        
        
        
        
        function [finalIDSPlacement,runningTime] = optimizeWithGAMOO(obj)
            lb=zeros(obj.numServers,1);
            ub=[ones((obj.numServers-1),1);0];
            IntCon=1:obj.numServers;
            opts=optimoptions(@ga,'Display','off');
            tic;
            objFcn=@(placement) obj.moo_objective_function(placement);
            finalIDSPlacement = ga(objFcn,obj.numServers,[],[],[],[],lb,ub,[],IntCon,opts);
            runningTime=toc;
            obj.lastRunningTime=runningTime;
            obj.lastIdsPlacement=finalIDSPlacement;
        end
        
        function displayMetrics(obj,idsPlacement)
            idsNumber=1:numel(idsPlacement);
            idsDisplay=idsNumber(idsPlacement==1);
            disp('IDS Locations:')
            disp(mat2str(idsDisplay));
            disp('Time to optimize:')
            disp(obj.lastRunningTime)
            finalBenefit = obj.calculate_benefit(idsPlacement);
            disp('Benefit (reduction in attacker probability of success):')
            disp(finalBenefit)
            finalPerf = finalBenefit/obj.maxBenefit;
            disp('Performance (protection compared to max):')
            disp(finalPerf)
            finalNumCost = obj.calculate_num_cost(idsPlacement);
            disp('Final Numerical Cost:')
            disp(finalNumCost)
            finalRelCost = finalNumCost/obj.maxCost;
            disp('Final Relative Cost:')            %cost wrt max cost.
            disp(finalRelCost)
        end
        
        
        
        function numCost = calculate_num_cost(obj,placement)
            % Cost = installation cost + operation cost + traffic latency cost
            
            % Cost of placing IDS at node
            installCost = obj.unitCost*sum(placement == 1); % installation costs
            operateCost = obj.runCost*sum(placement == 1); % operating costs
            
            % Calculate cost due to traffic
            trafCost = 0;
            for n = 1:length(placement)
                if placement(n) == 1
                    if obj.trafForCost(n) > obj.maxTrafAllowed
                        trafCost = 1000;
                    else
                        trafCost = trafCost + ceil(obj.trafForCost(n)/50e3)*obj.costPerKp;
                    end
                end
            end
            
            numCost = installCost + operateCost + trafCost; % numerical cost
        end
        
        
        
       
        
        
         
       
        
        
        
        function multiObjFunc = moo_objective_function(obj,placement)
            placeBenefit = obj.calculate_benefit(placement);
            placePerformance = placeBenefit/obj.maxBenefit;
            numCost=obj.calculate_num_cost(placement);
            placeCost = numCost/obj.maxCost;
            value = (1-obj.weight)*placePerformance - obj.weight*placeCost;
            multiObjFunc = -value;
        end
        
        function exhObjFunc = exh_objective_function(obj,placement)
            % Objective function which imposes penalty on cost outside of budget
            % for exhaustive search only
            
            placeBenefit = obj.calculate_benefit(placement);
            if obj.calculate_num_cost(placement) > obj.costCut
                placeCost = 1000;
            else
                placeCost = 0;
            end
            
            exhObjFunc = -1*(placeBenefit - placeCost);
        end
        
        function [c,ceq] = cost_constraint(obj,placement)
            c = obj.calculate_num_cost(placement) - obj.costCut;   % finds the cost for that particular configuration.
            ceq = [];
        end
        
        % Not used now. - assumes uniform distribution.
         function [trafIn, trafOut] = calculate_traffic_uniform(obj,protection)
            servers = numnodes(obj.networkGraph); % number of server, incl. CJ and edges
            numEdgeServers = sum(indegree(obj.networkGraph) == 0);
            
            trafOut(1,1:servers) = -1; % Indicates traffic not calculated yet
            trafIn = zeros(1,servers);
            noTrafIn = 0; % Flag in case incoming traffic hasn't been calculated
            repeatNodes = 1:servers; % Array to store nodes to recalculate traffic
            contCalc = 1; % Flag telling to repeat calculations
            
            while contCalc == 1
                contCalc = 0;
                nodes = repeatNodes;
                repeatNodes = []; % reset in case of further repetitions
                for n = 1:length(nodes)
                    index = nodes(n);
                    if indegree(obj.networkGraph,index) == 0
                        % Means index is an edge server
                        trafIn(index) = obj.trafInEdge/numEdgeServers;
                    else
                        preds = predecessors(obj.networkGraph,index);
                        for i = 1:length(preds)
                            % Calculate traffic in
                            if trafOut(preds(i)) ~= -1
                                % Guarantees we have already calculated traffic
                                trafIn(index) = trafIn(index) + ...
                                    trafOut(preds(i))/outdegree(obj.networkGraph,preds(i));
                            else
                                noTrafIn = 1;
                            end
                        end
                    end
                    
                    if (noTrafIn == 0)
                        % Calculate traffic out
                        trafOut(index) = (1-protection(index))*trafIn(index);
                    elseif noTrafIn == 1
                        trafIn(index) = 0; % Reset traffic to be calculated later
                        repeatNodes = [repeatNodes, index]; %#ok<AGROW>
                        contCalc = 1;
                    end
                    noTrafIn = 0; % Reset traffic flag
                end
            end
        end
        
    end
    
    
    
    
    methods(Static)
        
        %random network
        function network = create_Network(nodes,edges)
            % Function takes input of number of nodes and edges that exist in the
            % network and returns a random configuration.
            
            g = sparse([],[],true,nodes,nodes);
            while nnz(g) < edges
                edge = randsample(nodes*nodes,1); % get a random edge
                g(edge) = true;
                g(edge) = graphisdag(g);
            end
            
            network = digraph(g);
        end
        
        %default network - key in the value.
        function [network,crownJewel] = toyNetwork(key)
            if key == 1
                % 1 is connected to 4, s to t
                s = [1,1,2,2,2,3,4,5,5,6,6,6,7,7,7];
                t = [4,5,5,6,7,7,5,8,9,5,8,9,6,8,9];
                network = digraph(s,t);
                crownJewel = 8;
            elseif key == 2
                s = [1,2,3,4,4,4,5,5,5,5,6,6,6,7,7,7,7,7,7,7,8,9,9,9,9];
                t = [8,3,8,3,6,8,2,4,8,9,2,9,10,1,3,4,5,6,8,9,10,1,2,3,8];
                network = digraph(s,t);
                crownJewel = 10;
            elseif key == 3
                % Experiment 1 example network
                s = [1,1,2,2,2,3,3,4,4,5,5,6,7,7,8,8,8,9,10];
                
                t = [4,5,5,6,8,7,8,5,9,7,9,10,6,10,4,7,10,11,11];
                
                network = digraph(s,t);
                crownJewel = 11;
            elseif key == 4
                s = [1,1,1,2,2,3,4,5,6,5];
                t = [3,4,5,4,6,7,7,7,7,4];
                network = digraph(s,t);
                crownJewel = 7;
            elseif key == 5
                % Experiment 3 Layer networks - 2 layers before CJ
                s = [1,2,3,4,5,6];
                t = [4,5,6,7,7,7];
                network = digraph(s,t);
                crownJewel = 7;
            elseif key == 6
                % 3 layers before CJ
                s = [1,2,3,4,5,6,7,8,9];
                t = [4,5,6,7,8,9,10,10,10];
                network = digraph(s,t);
                crownJewel = 10;
            elseif key == 7
                % 5 layers before CJ
                s = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];
                t = [4,5,6,7,8,9,10,11,12,13,14,15,16,16,16];
                network = digraph(s,t);
                crownJewel = 16;
            elseif key == 8
                % 8 layers before CJ
                s = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24];
                t = [4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,25,25];
                network = digraph(s,t);
                crownJewel = 25;
            elseif key == 9
                % 10 layers before CJ
                s = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,...
                    25,26,27,28,29,30];
                t = [4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,...
                    28,29,30,31,31,31];
                network = digraph(s,t);
                crownJewel = 31;
            end
        end
    end
    
end

