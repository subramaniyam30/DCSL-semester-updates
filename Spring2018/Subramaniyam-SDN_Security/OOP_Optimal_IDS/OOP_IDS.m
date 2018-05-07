classdef OOP_IDS < handle
   
    properties
        networkGraph              % Network Graph in Digraph which stores the entire graph - in table format - The first node is just input node to split the traffic - NO IDS in that.
        edgeServers               % 1D Matrix storing the edge nodes.
        crownJewel                % The index of the crownjewel node.
        numServers                % Total Number of Servers in the network.
        
        IDSquality                % IDS Security Value for each Server Node. Array with each index representing the server node number.
        
        weight                    % importance of relative cost  wrt performance -> (0 < weight < 1)
        budget_IDS = 3                 % Maximum No. of IDS allowed.
        
        attackerTrafInNoIDS        % Traffic Distribution when there is no IDS. It is an array with index representing the server node and value is the total traffic In at that node.
                                   % Traffic IN at each Node.
        trafInMaxIDS               % Traffic Distribution when there is IDS in all possible nodes.
        
        maxBenefit                 % Maximum Benefit - Protection Difference in the amount of traffic reaching crown jewel when there is IDS everywhere.
        max_IDS                     % Maximum number of IDS -> IDS can be placed everywhere except the entry node and the crown jewel.
        
        lastRunningTime            % Simulation Time in seconds.
        lastIdsPlacement           % Final IDS placement.
        
        edgeWeightAttacker         %weight for computing benefit only - Table with source,destination,edge weight.
        initialEdgeWeightAttacker  % initial edge weight for all the edges-> used in the exponential decay.
        edgeWeightProbability      % actual edge weight probability for each edge.
        
        lastPopulation=[]         % Population Matrix of population size which is used to store the population matrix used by the GA for each run. 
        % It includes all the placement vectors used in the last
        % generation. No. of placement vectors will be the population size.
        
        actualAttackerEdgeWeight
        edgeWeightDecay              % edge weight decay factor.
        learningRate
    end
    
    properties(Constant)
        trafInEdge = 1; % Total traffic coming into network - Given as a total input to the network.
        baseValue = 0.80; % base IDS security value - First Node is dummy node to split the traffic. Base value is still 0.8 -> nodes start from layer 2.
        
    end
    
     methods
        %constructor called first.
        function obj=OOP_IDS(graphKey,servers,connections)
            if nargin < 1 || isempty(graphKey)            %if the no. of input parameters are less than 1. Default consider 3rd Toy Network.
                graphKey=3;
            end
            
            if graphKey==-1                                % To create a random network. specify no. of servers and no. of connections.
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
            obj.buildEdgeProbability();
            obj.calculate_IDSvalue();      % Determine the IDS Security Value for each server node.
            obj.calculate_baseline_traffics(); %calculate the traffic distribution depending on the edge weights.
            obj.calculate_max_benefit();        %find the gain or benefit in protection when IDS is everywhere
        end
        
        %Assign weights to each edge to distribute the traffic.
        % Initial weights of all the edges are taken to be one.
        function buildEdgeWeights(obj)
            tableInfo=[obj.networkGraph.Edges{:,:}];
            obj.edgeWeightAttacker=table();
            obj.edgeWeightAttacker.sources=tableInfo(:,1);
            obj.edgeWeightAttacker.destination=tableInfo(:,2);
            % The initial traffic distribution for the attacker is taken to
            % be 1. => uniform distribution
            obj.edgeWeightAttacker.weight=ones(1,size(tableInfo,1))';  %Initial weights to all the edges to distribute traffic - calculate benefit.
            obj.initialEdgeWeightAttacker = obj.edgeWeightAttacker;     % used for exponential decay.
            obj.actualAttackerEdgeWeight = obj.edgeWeightAttacker;
            obj.edgeWeightProbability = obj.edgeWeightAttacker;
            
            %obj.actualAttackerEdgeWeight.weight=zeros(1,size(tableInfo,1))';
        end
        
        function buildEdgeProbability(obj)
             for i = 1: height(obj.edgeWeightAttacker)
                 edgeWeight = obj.edgeWeightAttacker.weight(i);
                 totalEdgeWeights = 0;
                 for j = 1: height(obj.edgeWeightAttacker)
                     if(obj.edgeWeightAttacker.sources(j) == obj.edgeWeightAttacker.sources(i))
                         totalEdgeWeights = totalEdgeWeights + obj.edgeWeightAttacker.weight(j);
                     end
                 end
                 obj.edgeWeightProbability.weight(i) = edgeWeight/totalEdgeWeights;
             end
        end
        
        % Determine the IDS quality for IDS Security value.
        % Update the IDS quality value to be a fixed constant.
        % IDS can't be placed at the first dummy node and the crown jewel.
        %update: IDS can be placed at the crown jewel.
        function calculate_IDSvalue(obj)
            IDSvalue = zeros(1,numnodes(obj.networkGraph));
            for i = 1:numnodes(obj.networkGraph)
                
                IDSvalue(i) = obj.baseValue;
            end
                %IDSvalue(obj.crownJewel) = 0;
                IDSvalue(1) = 0;    %First node is input node or dummy node to split traffic.
                obj.IDSquality=IDSvalue;
                obj.max_IDS = sum(obj.IDSquality ~= 0);  % No. of locations where IDS can be placed.
        end
        
        %----------------Re caculate whenever edge weight changes ------
        %calculates the traffic distribution through the network graph.
        function calculate_baseline_traffics(obj)
            %Traffic Distribution when there is no IDS. Protection = 0
            % Probability distribution when there is no ids will be always
            % 1. traffic comes in, goes out.
            obj.attackerTrafInNoIDS=obj.calculate_traffic_weighted(zeros(1,obj.numServers),obj.edgeWeightAttacker);
            
            %Traffic Distribution when there is IDS in all the nodes - Here
            %we assume the entire input traffic is attacker's traffic.
            %baseline case.
            % this parameter changes whenever edge weight changes.
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
%                                 if totatlEdgeWeights == 0
%                                     addedTraffic = 0;
%                                 else
%                                     addedTraffic=trafOut(preds(i))*(edgeWeight/totatlEdgeWeights);
%                                 end
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
        
        function [trafIn, trafOut] = calculate_traffic_weighted_zero(obj,protection,weightTable)
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
                                if totatlEdgeWeights == 0
                                    addedTraffic = 0;
                                else
                                    addedTraffic=trafOut(preds(i))*(edgeWeight/totatlEdgeWeights);
                                end
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
        
        %----------------Re caculate whenever edge weight changes ------
        % Determine the maximum benefit.
        % Benefit for a particular configuration is defined as 
        %(Maximum Probability of Attacker Success – Probability of Attacker Success for that configuration) / (Maximum Probability of attacker Success)
        %Assume all the traffic is attacker's traffic. 
        function calculate_max_benefit(obj)
            obj.maxBenefit = (obj.attackerTrafInNoIDS(obj.crownJewel) - obj.trafInMaxIDS(obj.crownJewel)) ...  
                /obj.attackerTrafInNoIDS(obj.crownJewel);
            % Attacker Traffic In with No IDS is always 1.
        end
        
        
        % Genetic Algorithm Optimization.
        % GA returns the vector with 0's and 1's -> 0's indicate no IDS whereas 1's
        % indicate IDS at that location (array index).
        function [finalIDSPlacement,runningTime] = optimizeWithGA(obj)
            lb=zeros(obj.numServers,1);   % each element in placement vector is lower bounded by 0
            %ub=[ones((obj.numServers-1),1);0];  % each element in placement vector is upper bounded by 1 except the crown jewel and first node.
            ub= ones((obj.numServers),1);        % IDS can be placed at the crown jewel.
            ub(1) = 0;   % First Node can't have an IDS. The first node is for load balancing or distributing the traffic.
            IntCon=1:obj.numServers;        % each element in placement vector can take only integer value
            % It means each element except the first node and crown jewel can be either 0 (No IDS) or 1 (IDS)
            if ~isempty(obj.lastPopulation)
                opts=optimoptions(@ga,'Display','off','InitialPopulation',obj.lastPopulation,'MaxStallGenerations',8,'TolFun',1e-4,'PopulationSize',200);
            else
                opts=optimoptions(@ga,'Display','off','MaxStallGenerations',8,'TolFun',1e-4,'PopulationSize',200);
            end
            tic;
            % Objective Function that should be optimized.
            objFcn=@(placement) obj.objective_function(placement);
            % Cost constrained function.
            costConstraintFcn=@(placement) obj.cost_constraint(placement);
            [finalIDSPlacement,~,~,~,obj.lastPopulation,~] = ga(objFcn,obj.numServers,[],[],[],[],lb,ub,costConstraintFcn,IntCon,opts);
            %disp(obj.lastPopulation);
            runningTime=toc;
            obj.lastRunningTime=runningTime;
            obj.lastIdsPlacement=finalIDSPlacement;
        end
        
        % Objective Function for Cost Constrained Optimization.
        % Maximize the benefit given a cost constraint.
        % Placement vector is generated by the GA.
        function objFunc = objective_function(obj,placement)
            % Objective Function = - benefit constrained with constraint function
            
            placeBenefit = obj.calculate_benefit(placement);  % returns the benefit for that placement.
            %disp(placement);
            %disp(placeBenefit);
            % GA allows only to minimize the objective function.
            objFunc = -1*placeBenefit;    %to get the maximum benefit we find minimum negative benefit
        end
        
        
        %Determine the benefit of a particular configuration.
        % when ever edge weight changes -> the benefit also changes.
        function benefit = calculate_benefit(obj,placement)
            % Benefit = reduction in probability of attacker succeeding
            % Send the IDS quality values for only those nodes where there
            % is an IDS.
            protection = obj.IDSquality.*placement;
            [trafInIDS,~] = obj.calculate_traffic_weighted(protection,obj.edgeWeightAttacker);
            benefit = (obj.attackerTrafInNoIDS(obj.crownJewel) - trafInIDS(obj.crownJewel))/obj.attackerTrafInNoIDS(obj.crownJewel);
        end
        
        %To study the effect of Edge Weight Decay.
        function benefit = calculate_benefit_attacker(obj,placement)
            % Benefit = reduction in probability of attacker succeeding
            % Send the IDS quality values for only those nodes where there
            % is an IDS.
            protection = obj.IDSquality.*placement;
            [trafInIDS,~] = obj.calculate_traffic_weighted_zero(protection,obj.actualAttackerEdgeWeight);
            %disp(trafInIDS);
            benefit = (1 - trafInIDS(obj.crownJewel));
        end
        
        
         function [c,ceq] = cost_constraint(obj,placement)
             No_IDS = sum(placement == 1);
            c = No_IDS - obj.budget_IDS;   % finds the cost for that particular configuration.
            %disp(c);
            ceq = [];
         end
        
        % Exhaustive search optimization with cost constrainted. 
        % IDS can be placed at the crown jewel.
        % Only first node can't be placed.
        function [finalIDSPlacement,runningTime] = optimizeWithExhSearch(obj)
            tic;
            % Generate the possibile positions
            testSet=[];
            for i=1:obj.numServers
                setToOnes=combnk(1:(obj.numServers),i);
                for j=1:size(setToOnes,1)
                    setVector=setToOnes(j,:);
                    newTestSet=zeros(obj.numServers,1);
                    newTestSet(setVector)=1;
                    testSet=[testSet; newTestSet']; %#ok<AGROW>
                end
            end
            % Remove all the rows which as 1 in (1,1) - No ids can be
            % placed  there.
            [m,~] = size(testSet);
            index = 1;
            for i=1:m
                    if testSet(i,1) == 1
                        rowtodelete(index) = i;
                        index = index+1;
                    end
            end
            testSet(rowtodelete,:) = [];
            
            %Evaluate the objective function for all possible combinations.
            testValues=zeros(size(testSet,1),1);
            for i=1:numel(testValues)
                testValues(i)= obj.exh_objective_function(testSet(i,:));
            end
       
            labels=cell(numel(testValues),1);
            for i=1:numel(labels)
                labels{i}=mat2str(testSet(i,:));
            end

            [testValues,idx]=sort(testValues);  % sorts from smallest to largest.
            labels=labels(idx);
            
            %figure;
            %bar(-1*testValues);
            %set(gca,'XTickLabel',labels);
            %set(gca,'XTickLabelRotation',90);
            %disp('IDS Locations by Exhaustion:')
            strLabels = cell2mat(labels);
            finalIDSPlacement = str2num(strLabels(1,:));
            %for i = 1:length(finalIDSPlacement)
              %  if finalIDSPlacement(i) == 1
               %     disp(i)
                %end
           % end
            runningTime = toc;
            obj.lastRunningTime = runningTime;
            obj.lastIdsPlacement = finalIDSPlacement ;
        end
        
        %Objective Function for Exhaustive Search.
        % Maximize the benefit. Negative is found because sort () sorts
        % from smallest to biggest.
        % if the total cost > budget make benefit very large value - tht
        % placement will be removed.
        function exhObjFunc = exh_objective_function(obj,placement)
            % Objective function which imposes penalty on cost outside of budget
            placeBenefit = obj.calculate_benefit(placement);
            if sum(placement==1) > obj.budget_IDS
                placeCost = 1000;
            else
                placeCost = 0;
            end
            exhObjFunc = -1*(placeBenefit - placeCost);
        end  
        
        
        % MulitObjective Optimization
        % No Cost Constrainted Function.
        function [finalIDSPlacement,runningTime] = optimizeWithGAMOO(obj)
            lb=zeros(obj.numServers,1);
            %ub=[ones((obj.numServers-1),1);0];
            ub=ones((obj.numServers),1);   %IDs can be placed at the crown jewel.
            ub(1) = 0;   % First Node can't have an IDS.
            IntCon=1:obj.numServers;
            if ~isempty(obj.lastPopulation)
                opts=optimoptions(@ga,'Display','off','InitialPopulation',obj.lastPopulation,'MaxStallGenerations',8,'TolFun',1e-4,'PopulationSize',200);
            else
                opts=optimoptions(@ga,'Display','off','MaxStallGenerations',8,'TolFun',1e-4,'PopulationSize',200);
            end
            tic;
            objFcn=@(placement) obj.moo_objective_function(placement);
            [finalIDSPlacement,~,~,~,obj.lastPopulation,~] = ga(objFcn,obj.numServers,[],[],[],[],lb,ub,[],IntCon,opts);
            runningTime=toc;
            obj.lastRunningTime=runningTime;
            obj.lastIdsPlacement=finalIDSPlacement;
        end
        
   
        % The objective function should be updated. 
        function multiObjFunc = moo_objective_function(obj,placement)
            %disp(placement);
            placeBenefit = obj.calculate_benefit(placement);
            placePerformance = placeBenefit/obj.maxBenefit;
            numCost= sum(placement == 1);
            placeCost = numCost/obj.max_IDS;
            %disp(sum(obj.edgeWeightAttacker.weight)/(numel(obj.edgeWeightAttacker.weight)));
            
            value = (1-obj.weight)*placePerformance*(sum(obj.edgeWeightAttacker.weight)/(numel(obj.edgeWeightAttacker.weight))) - obj.weight*placeCost;
            %value = (1-obj.weight)*placePerformance - obj.weight*placeCost;
            %value = ((1-obj.weight)*placePerformance*10) - obj.weight*placeCost;
            
            multiObjFunc = -value;
         end
        
        
         %Exhaustive Search Optimization for Multi Objective Optimization.
         function [finalIDSPlacement,runningTime] = optimizeWithExhSearchMOO(obj)
            tic;
            % Generate the possibile positions
            testSet=[];
            for i=1:obj.numServers
                setToOnes=combnk(1:(obj.numServers),i);
                for j=1:size(setToOnes,1)
                    setVector=setToOnes(j,:);
                    newTestSet=zeros(obj.numServers,1);
                    newTestSet(setVector)=1;
                    testSet=[testSet; newTestSet']; %#ok<AGROW>
                end
            end
            % Remove all the rows which as 1 in (1,1) - No ids can be
            % placed  there.
            [m,~] = size(testSet);
            index = 1;
            for i=1:m
                    if testSet(i,1) == 1
                        rowtodelete(index) = i; %#ok<AGROW>
                        index = index+1;
                    end
            end
            testSet(rowtodelete,:) = [];
            
            %Evaluate the objective function for all possible combinations.
            testValues=zeros(size(testSet,1),1);
            for i=1:numel(testValues)
                testValues(i)= obj.moo_objective_function(testSet(i,:));
            end
       
            labels=cell(numel(testValues),1);
            for i=1:numel(labels)
                labels{i}=mat2str(testSet(i,:));
            end

            [testValues,idx]=sort(testValues);  % sorts from smallest to largest.
            labels=labels(idx);
            
            %figure;
            %bar(-1*testValues);
            %set(gca,'XTickLabel',labels);
            %set(gca,'XTickLabelRotation',90);
            %disp('IDS Locations by Exhaustion:');
            
            strLabels = cell2mat(labels);
            finalIDSPlacement = str2num(strLabels(1,:)); 
            for i = 1:length(finalIDSPlacement)
                if finalIDSPlacement(i) == 1
                    disp(i)
                end
            end
            runningTime = toc;
            obj.lastRunningTime = runningTime;
            obj.lastIdsPlacement = finalIDSPlacement ;
        end
        
  
      
        % Get Random Paths.  from the first node or dummy node to the crown
        % jewel.
        % These paths represent the attacker's path.
        % Crownjewel is always taken as the last node.
        % Only paths from the entry node to the crown jewel is selected
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
                path=obj.getRandomPath();
            end
       end
        
        % Check if IDS is placed at the random attacker's path.
        % IF IDS is at the attacker's path -> Depending on the IDS quality
        % value it may or may not generate an alert.
        % Generate a Random Number. If rand() < the IDS quality value at
        % that alert node then it means alert has been generated.
        % Check for each IDS that is placed on the attacker path if alert
        % was generated. if it was generated at first node then break else
        % check 2nd and subsequent nodes.
        %attacker is successful if no ids at the attacker path or no ids in
        %the path generates an alert.
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
            % if the path has crown jewel in it and no alert is generated
            % then attacker is successful.
            if any(path==obj.crownJewel)
                success=1;
            else
                success=0;
            end
        end
        
        %to study the effect of decaying edge weight.
        function [alertNode,success]=checkAttackPathEwEffect(obj,path,placement)
            numericalPlacement=1:numel(placement);
            numericalPlacement=numericalPlacement(placement==1);
            k = 1;
            alertNodes = [];
            for i=1:numel(path)
                for j=1:numel(numericalPlacement)
                    if path(i)==numericalPlacement(j)
                        alertNodes(k) = numericalPlacement(j);
                        k = k + 1;
                        %if rand() < obj.IDSquality(numericalPlacement(j))
%                             alertNode=numericalPlacement(j);
%                             success=0;
%                             return;
                        %end
                    end
                end
            end
            if isempty(alertNodes) == 0
                index = randi([1,(k-1)]);
                %disp(alertNodes);
               
                alertNode=alertNodes(index); 
                %disp(alertNode);
                success=0;
                return;
            end
            alertNode=[];
            % if the path has crown jewel in it and no alert is generated
            % then attacker is successful.
            if any(path==obj.crownJewel)
                success=1;
            else
                success=0;
            end
        end
        
        % if an alert is generated then update the attacker edge weight
        % that is used for calculating the benefit.
        % Determine all the edges that are on the path to the alert node.
        % update all the edge weights to weight old + 1.
        % Determine the new traffic distribution and the max benefit. 
        % Total Cost remains the same. The amount of traffic processed by
        % IDS remains the same.
        % -----------Edge Weight Update logic is updated------------.
        % Whenever the edge weight is updated -> 1) calculate baseline
        % traffics again (traffic when no ids and traffic when ids at all
        % nodes). -> 2) calculate max benefit again -> 3) caculate benefit
        % again.
        
        function updateEdgeWeightPredecessor(obj,alertNode)
            allpaths = allpossiblepath(adjacency(obj.networkGraph),1,alertNode);
            cummulative_sum = 0;
            for i=1:size(allpaths,1)
                path = allpaths{i};
                for j=1:(size(path,2)-1)
                index=obj.edgeWeightAttacker.sources==path(j) & ...
                    obj.edgeWeightAttacker.destination==path(j+1);
                preds = predecessors(obj.networkGraph,obj.edgeWeightAttacker(index,:).destination);
                %disp(preds);
                num_preds = numel(preds);
                cummulative_sum = cummulative_sum + 1/num_preds;
                end
                
            end
            %disp(cummulative_sum);
            for i=1:size(allpaths,1)
                path = allpaths{i};
                for j=1:(size(path,2)-1)
                index=obj.edgeWeightAttacker.sources==path(j) & ...
                    obj.edgeWeightAttacker.destination==path(j+1);
                preds = predecessors(obj.networkGraph,obj.edgeWeightAttacker(index,:).destination);
                %disp(preds);
                num_preds = numel(preds);
                EW_increase = 1/(cummulative_sum*num_preds);
                %obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+1;
                %obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+(1/num_preds);
                obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+ (obj.learningRate*EW_increase);
                end  
            end
                    
           
            %disp(alertNode);
            %disp(obj.edgeWeightAttacker);
            % ---------------- Max benefit should be fixed for running BVO -
            % MOO-------------------
            % These operations are done after the edge weight decay has
            % happened.
            %obj.calculate_baseline_traffics();
            %obj.calculate_max_benefit();
        end
%         function updateEdgeWeightPredecessor(obj,alertNode)
%             %allEdges=obj.getAllEdgesOnPath(alertNode);
%             allEdges=obj.getAllEdgesOnPathwithDuplicates(alertNode);
%             for i=1:size(allEdges,1)
%                 index=obj.edgeWeightAttacker.sources==allEdges(i,1) & ...
%                     obj.edgeWeightAttacker.destination==allEdges(i,2);
%                 preds = predecessors(obj.networkGraph,obj.edgeWeightAttacker(index,:).destination);
%                 %disp(preds);
%                 num_preds = numel(preds);
%                 %obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+1;
%                 obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+((1/num_preds)*allEdges(i,3));
%             end
%             %disp(alertNode);
%             %disp(obj.edgeWeightAttacker);
%             % ---------------- Max benefit should be fixed for running BVO -
%             % MOO-------------------
%             % These operations are done after the edge weight decay has
%             % happened.
%             %obj.calculate_baseline_traffics();
%             %obj.calculate_max_benefit();
%         end
        
        
        
        %update edge weight using the minimum distance between the
        %destination node and alert node.
        
        function updateEdgeWeightDistance(obj,alertNode)
            allpaths = allpossiblepath(adjacency(obj.networkGraph),1,alertNode);
             cummulative_sum = 0;
            for i=1:size(allpaths,1)
               path = allpaths{i};
               for j=1:(size(path,2)-1)
               index=obj.edgeWeightAttacker.sources==path(j) & ...
                   obj.edgeWeightAttacker.destination==path(j+1);
               distance_alertnode = distances(obj.networkGraph,obj.edgeWeightAttacker(index,:).destination,alertNode)+1;
               cummulative_sum = cummulative_sum + (1/distance_alertnode);
               end
            end
            %disp(cummulative_sum);
            for i=1:size(allpaths,1)
                path = allpaths{i};
                for j=1:(size(path,2)-1)
                index=obj.edgeWeightAttacker.sources==path(j) & ...
                    obj.edgeWeightAttacker.destination==path(j+1);
                distance_alertnode = distances(obj.networkGraph,obj.edgeWeightAttacker(index,:).destination,alertNode) + 1;
                 EW_increase = 1/(cummulative_sum*distance_alertnode);
                %obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+1;
                %obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+(1/distance_alertnode);
                obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+ (obj.learningRate*EW_increase);
                end  
            end
            %disp(alertNode);
            %disp(obj.edgeWeightAttacker);
            % ---------------- Max benefit should be fixed for running BVO -
            % MOO-------------------
            % These operations are done after the edge weight decay has
            % happened.
            %obj.calculate_baseline_traffics();
            %obj.calculate_max_benefit();
        end




%         function updateEdgeWeightDistance(obj,alertNode)
%             allEdges=obj.getAllEdgesOnPath(alertNode);
%             %allEdges=obj.getAllEdgesOnPathwithDuplicates(alertNode);
%             for i=1:size(allEdges,1)
%                 index=obj.edgeWeightAttacker.sources==allEdges(i,1) & ...
%                     obj.edgeWeightAttacker.destination==allEdges(i,2);
%                 distance_alertnode = distances(obj.networkGraph,obj.edgeWeightAttacker(index,:).destination,alertNode) + 1;
%                 %disp(preds);
%                 obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+1;
%                 %obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+((1/distance_alertnode)*allEdges(i,3));
%             end
%             %disp(alertNode);
%             %disp(obj.edgeWeightAttacker);
%             % ---------------- Max benefit should be fixed for running BVO -
%             % MOO-------------------
%             %obj.calculate_baseline_traffics();
%             %obj.calculate_max_benefit();
%         end

        function updateEdgeWeightPathBased(obj,alertNode)
             allpaths = allpossiblepath(adjacency(obj.networkGraph),1,alertNode);
             number_of_paths = 0;
             for i=1:size(allpaths,1)
             number_of_paths = number_of_paths + (size(allpaths{i},2)-1);
             end
            for i=1:size(allpaths,1)
                path = allpaths{i};
                for j=1:(size(path,2)-1)
                index=obj.edgeWeightAttacker.sources==path(j) & ...
                    obj.edgeWeightAttacker.destination==path(j+1);
                obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+ (obj.learningRate*(1/number_of_paths));
                end  
            end
            %disp(alertNode);
            %disp(obj.edgeWeightAttacker);
            % ---------------- Max benefit should be fixed for running BVO -
            % MOO-------------------
            % These operations are done after the edge weight decay has
            % happened.
            %obj.calculate_baseline_traffics();
            %obj.calculate_max_benefit();
        end
        
        
%         function updateEdgeWeightPathBased(obj,alertNode)
%             allEdges=obj.getAllEdgesOnPathwithDuplicates(alertNode);
%             number_of_paths = sum(allEdges(:,3));
%             for i=1:size(allEdges,1)
%                 index=obj.edgeWeightAttacker.sources==allEdges(i,1) & ...
%                     obj.edgeWeightAttacker.destination==allEdges(i,2);
%                 %disp(preds);
%                 %obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+1;
%                 obj.edgeWeightAttacker(index,:).weight=obj.edgeWeightAttacker(index,:).weight+((1/number_of_paths)*allEdges(i,3));
%             end
%             %disp(alertNode);
%             %disp(obj.edgeWeightAttacker);
%             % ---------------- Max benefit should be fixed for running BVO -
%             % MOO-------------------
%             %obj.calculate_baseline_traffics();
%             %obj.calculate_max_benefit();
%         end
        
        %exponential decay of the edge weight.
        function decayEdgeWeight(obj)
            for i = 1: height(obj.edgeWeightAttacker)
                difference_with_initial = obj.edgeWeightAttacker(i,:).weight - obj.initialEdgeWeightAttacker(i,:).weight;
                obj.edgeWeightAttacker(i,:).weight= obj.edgeWeightAttacker(i,:).weight - (obj.edgeWeightDecay * difference_with_initial);
            end
            % ---------------- Max benefit should be fixed for running BVO -
            % MOO-------------------
            %obj.calculate_baseline_traffics();
            %obj.calculate_max_benefit();
        end
        
        function decayEdgeWeightNoAlert(obj,alertNode,dynamicPlacement)
            s = 1;
            for t = 1:size(dynamicPlacement,2)
                if dynamicPlacement(t) == 1
                    place(s) = t;
                    s = s+1;
                end
            end
           
            for i = 1:size(place,2)
                if place(i) == alertNode
                    continue;
                else
                    allpaths = allpossiblepath(adjacency(obj.networkGraph),1,place(i));
                    
                    for k=1:size(allpaths,1)
                    path = allpaths{k};
                    for j=1:(size(path,2)-1)
                    index=obj.edgeWeightAttacker.sources==path(j) & ...
                          obj.edgeWeightAttacker.destination==path(j+1);
                    difference_with_initial = obj.edgeWeightAttacker(index,:).weight - obj.initialEdgeWeightAttacker(index,:).weight;
                    obj.edgeWeightAttacker(index,:).weight= obj.edgeWeightAttacker(index,:).weight - (obj.edgeWeightDecay * difference_with_initial);
                    end  
                    end
                    for p = 1: height(obj.edgeWeightAttacker)
                        if obj.edgeWeightAttacker(p,:).sources==place(i)
                        difference_with_initial = obj.edgeWeightAttacker(p,:).weight - obj.initialEdgeWeightAttacker(p,:).weight;
                        obj.edgeWeightAttacker(p,:).weight= obj.edgeWeightAttacker(p,:).weight - (obj.edgeWeightDecay * difference_with_initial);
                        end
                    end
                 end
            end
            %disp(alertNode);
            %disp(obj.edgeWeightAttacker);
            % ---------------- Max benefit should be fixed for running BVO -
            % MOO-------------------
            % These operations are done after the edge weight decay has
            % happened.
            %obj.calculate_baseline_traffics();
            %obj.calculate_max_benefit();
        end
        
        %Determine all the edges that are on the path of the alert node.
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
        
        function allEdges=getAllEdgesOnPathwithDuplicates(obj,nodeNumber)
            allEdges=[];
            preds=predecessors(obj.networkGraph,nodeNumber);
            for i=1:numel(preds)
                if(preds(i) == 1)
                allEdges=[allEdges; preds(i) nodeNumber 1]; %#ok<AGROW> 
                else 
                allEdges=[allEdges; preds(i) nodeNumber numel(predecessors(obj.networkGraph,preds(i)))]; %#ok<AGROW>
                end
                %disp(preds(i));
                %disp(allEdges);
                newEdges=obj.getAllEdgesOnPathwithDuplicates(preds(i)); 
                allEdges=[allEdges; newEdges]; %#ok<AGROW>
            end
            allEdges=unique(allEdges,'rows');
        end
        
        
        function resetLearnedParams(obj)
            obj.buildEdgeWeights();
            obj.lastPopulation=[];
        end
           
        %determine the attacker actual edge weight from the attacker
            %path
%     function findAttackerEdgeWeight(obj,testPath)
%         for i = 1: height(obj.actualAttackerEdgeWeight)
%             obj.actualAttackerEdgeWeight.weight(i) = 0;
%         end
%         for p=1:(size(testPath,2)-1)
%                 index=obj.actualAttackerEdgeWeight.sources==testPath(p) & ...
%                       obj.actualAttackerEdgeWeight.destination==testPath(p+1);
%                   obj.actualAttackerEdgeWeight(index,:).weight = 1;
%         end
%     end

%attack path 1-4-9-11-12
    function findAttackerEdgeWeight(obj)
        obj.actualAttackerEdgeWeight = obj.initialEdgeWeightAttacker;
        for i = 1: height(obj.actualAttackerEdgeWeight)
        if(obj.actualAttackerEdgeWeight.sources(i) == 1 && obj.actualAttackerEdgeWeight.destination(i) == 2)
           obj.actualAttackerEdgeWeight.weight(i) = 0.125;
        elseif(obj.actualAttackerEdgeWeight.sources(i) == 1 && obj.actualAttackerEdgeWeight.destination(i) == 3)
           obj.actualAttackerEdgeWeight.weight(i) = 0.125;
        elseif(obj.actualAttackerEdgeWeight.sources(i) == 4 && obj.actualAttackerEdgeWeight.destination(i) == 8)
           obj.actualAttackerEdgeWeight.weight(i) = 0.25;
        elseif(obj.actualAttackerEdgeWeight.sources(i) == 9 && obj.actualAttackerEdgeWeight.destination(i) == 8)
           obj.actualAttackerEdgeWeight.weight(i) = 0.125;
        elseif(obj.actualAttackerEdgeWeight.sources(i) == 9 && obj.actualAttackerEdgeWeight.destination(i) == 5)
           obj.actualAttackerEdgeWeight.weight(i) = 0.125;
        end
        end
    end
     
     function findAttackerEdgeWeightInitial(obj)
        for i = 1: height(obj.actualAttackerEdgeWeight)
        if(obj.actualAttackerEdgeWeight.sources(i) == 1 && obj.actualAttackerEdgeWeight.destination(i) == 3)
           obj.actualAttackerEdgeWeight.weight(i) = 0.125;
        elseif(obj.actualAttackerEdgeWeight.sources(i) == 1 && obj.actualAttackerEdgeWeight.destination(i) == 4)
           obj.actualAttackerEdgeWeight.weight(i) = 0.125;
        elseif(obj.actualAttackerEdgeWeight.sources(i) == 2 && obj.actualAttackerEdgeWeight.destination(i) == 6)
           obj.actualAttackerEdgeWeight.weight(i) = 0.25;
        elseif(obj.actualAttackerEdgeWeight.sources(i) == 5 && obj.actualAttackerEdgeWeight.destination(i) == 6)
           obj.actualAttackerEdgeWeight.weight(i) = 0.25;
        end
        end
     end
    
        %display function.
        function displayMetrics(obj,idsPlacement)
            idsNumber=1:numel(idsPlacement);
            idsDisplay=idsNumber(idsPlacement==1);
            disp('IDS Locations:')
            disp(mat2str(idsDisplay));
            disp('Total Time to optimize(in seconds):')
            disp(obj.lastRunningTime)
            finalBenefit = obj.calculate_benefit(idsPlacement);
            disp('Benefit (reduction in attacker probability of success):')
            disp(finalBenefit)
            finalPerf = finalBenefit/obj.maxBenefit;
            disp('Performance (protection compared to max):')
            disp(finalPerf)
            %finalNumCost = obj.calculate_num_cost(idsPlacement);
            finalNumCost = sum(idsPlacement == 1);
            disp('Final Total Cost:')
            disp(finalNumCost)
            finalRelCost = finalNumCost/obj.max_IDS;
            disp('Final Relative Cost (compared to the maximum cost:')            %cost wrt max cost.
            disp(finalRelCost)
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
                s = [1,1,2,2,2,3,4,5,5,6,6,6,7,7,7] + 1;
                s = [1,1,1,s];
                t = [4,5,5,6,7,7,5,8,9,5,8,9,6,8,9]+1;
                t = [2,3,4,t];
                network = digraph(s,t);
                crownJewel = 10;
            elseif key == 2
                s = [1,2,3,4,4,4,5,5,5,5,6,6,6,7,7,7,7,7,7,7,8,9,9,9,9];
                t = [8,3,8,3,6,8,2,4,8,9,2,9,10,1,3,4,5,6,8,9,10,1,2,3,8];
                network = digraph(s,t);
                crownJewel = 10;
            elseif key == 3
                % Experiment 1 example network
                s = [1,1,2,2,2,3,3,4,4,5,5,6,7,7,8,8,8,9,10] + 1;
                s = [1,1,1,s];
                t = [4,5,5,6,8,7,8,5,9,7,9,10,6,10,4,7,10,11,11] + 1;
                t = [2,3,4,t];
                network = digraph(s,t);
                crownJewel = 12;
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
            elseif key == 10
                % Experiment 1 example network
                s = [1,1,1,2,2,3,3,4,4,5,6,7,8,9,10];
                t = [2,3,4,5,6,6,7,7,8,9,9,10,10,11,11];
                network = digraph(s,t);
                crownJewel = 11;
            elseif key == 11
                 s = [1,1,2,2,2,3,3,4,4,5,5,6,7,7,8,8,8,9,10];
               
                t = [4,5,5,6,8,7,8,5,9,7,9,10,6,10,4,7,10,11,11];
                
                network = digraph(s,t);
                crownJewel = 11;
            elseif key == 12
                s = [1,1,2,2,2,3,3,4,5,6,7,8,9,10] + 1;
                s = [1,1,1,s];
                t = [4,5,5,6,8,7,8,9,9,10,10,10,11,11]+1;
                t = [2,3,4,t];
                network = digraph(s,t);
                crownJewel = 10;
            elseif key == 13
              
                s = [1,1,1,2,2,3,3,3,4,4,5,6,7,8,9,10,11];
                t = [2,3,4,5,6,6,7,9,8,9,10,10,11,11,11,12,12];
                network = digraph(s,t);
                crownJewel = 12;
                
                 elseif key == 14
                % Experiment 1 example network
                s = [1,1,2,2,2,3,3,4,4,5,5,6,7,7,8,8,8,9,10];
                
                t = [4,5,5,6,8,7,8,5,9,7,9,10,6,10,4,7,10,11,11];
              
                network = digraph(s,t);
                crownJewel = 11;
            end
        end
    end
    
end