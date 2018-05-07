OPTIMISM: Optimal Dynamic Placement of Intrusion Detection Sensors to Identify Multi-Stage Attacks in Software Defined Networks

Submitted to: RAID 2018

Language Used: MATLAB

Abstract: The OPTIMISM can be installed as an application on the SDN controller to identify multi-stage attacks. The system selects the optimal IDS placement for a particular network setup. OPTIMISM maximizes the network protection while minimizing the number of IDS deployed. It is activated on alert generation to dynamically move the IDS towards the attacker path and also to elastically control the number of IDS deployed subject to long term constraints. 

The system is developed in MATLAB and It doesn't not have any dependencies. The main class is present in "OOP_IDS.m". Use Matlab 2013 or higher version to run this code. Set all the input parameters like the number of servers, the crown jewel servers, budget, network connections, network graph, initial edge weights etc in this file. Then, Run the corresponding experiment file to generate the results. All the experiments will result in a placement vector containing 0's and 1's. The IDS should be deployed in the server corresponding to the index in which there is a 1.

Example: Placement Vector: 0 0 0 1 0 0 0 1 1 0 0 => Place IDS at server 4, server 8 and 9.