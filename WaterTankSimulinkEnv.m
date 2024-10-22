classdef WaterTankSimulinkEnv < rl.env.MATLABEnvironment
    properties
        % Define the water level property
        WaterLevel (1,1) double = 50;
    end
    
    properties(Access = protected)
        % Internal properties
        IsDone (1,1) logical = false;
    end
    
    methods
        function this = WaterTankSimulinkEnv()
            % Create observation and action info
            ObservationInfo = rlNumericSpec([1 1], 'LowerLimit', 0, 'UpperLimit', 100);
            ActionInfo = rlNumericSpec([1 1], 'LowerLimit', 0, 'UpperLimit', 2);  % Continuous action space between 0 and 2
            ActionInfo.Name = 'Water Inflow Rate';
            ObservationInfo.Name = 'Water Level';
            
            % Initialize the environment
            this = this@rl.env.MATLABEnvironment(ObservationInfo, ActionInfo);
        end
        
        function [Observation, Reward, IsDone, LoggedSignals] = step(this, Action)
            % Simulate one step in Simulink
            simInput = Simulink.SimulationInput('WaterTankSimulinkModel');
            simInput = simInput.setExternalInput(num2str(Action));
            simOut = sim(simInput);
                     
            % Get the water level from the Simulink model
            this.WaterLevel = simOut.get('yout');
            this.WaterLevel = this.WaterLevel(end);
            
            % Set the observation
            Observation = this.WaterLevel;
            
            % Define the reward
            if this.WaterLevel > 80 || this.WaterLevel < 20
                Reward = -1;
            else
                Reward = 1;
            end
            
            % Check if the episode is done
            IsDone = false;
            LoggedSignals = [];
        end
        
        function InitialObservation = reset(this)
            % Reset the environment
            this.WaterLevel = 50;
            InitialObservation = this.WaterLevel;
        end
    end
end



% Create the environment
env = WaterTankSimulinkEnv();

% Create observation and action info
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);

% Define the actor and critic networks
actorNetwork = [
    featureInputLayer(obsInfo.Dimension(1),'Normalization','none','Name','state')
    fullyConnectedLayer(24,'Name','fc1')
    reluLayer('Name','relu1')
    fullyConnectedLayer(24,'Name','fc2')
    reluLayer('Name','relu2')
    fullyConnectedLayer(actInfo.Dimension(1),'Name','fc3')
    tanhLayer('Name','action')
    scalingLayer('Name','actionScaling','Scale',actInfo.UpperLimit)];

criticNetwork = [
    featureInputLayer(obsInfo.Dimension(1),'Normalization','none','Name','state')
    fullyConnectedLayer(24,'Name','fc1')
    reluLayer('Name','relu1')
    fullyConnectedLayer(24,'Name','fc2')
    reluLayer('Name','relu2')
    fullyConnectedLayer(1,'Name','value')];

% Create the actor and critic representations
actorOptions = rlRepresentationOptions('LearnRate',1e-3,'GradientThreshold',1);
criticOptions = rlRepresentationOptions('LearnRate',1e-3,'GradientThreshold',1);

actor = rlContinuousDeterministicActorRepresentation(actorNetwork, obsInfo, actInfo, 'Observation', {'state'}, actorOptions);
critic = rlValueRepresentation(criticNetwork, obsInfo, 'Observation', {'state'}, criticOptions);

% Create the PPO agent
agentOptions = rlPPOAgentOptions(...
    'ExperienceHorizon',64,...
    'ClipFactor',0.2,...
    'EntropyLossWeight',0.01,...
    'MiniBatchSize',64,...
    'NumEpoch',3);

agent = rlPPOAgent(actor, critic, agentOptions);
% Create the environment
env = WaterTankEnv();

% Create observation and action info
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);

% Define the actor and critic networks
actorNetwork = [
    featureInputLayer(obsInfo.Dimension(1))
    fullyConnectedLayer(24)
    reluLayer
    fullyConnectedLayer(24)
    reluLayer
    fullyConnectedLayer(length(actInfo.Elements))
    softmaxLayer
    ];

criticNetwork = [
    featureInputLayer(obsInfo.Dimension(1))
    fullyConnectedLayer(24)
    reluLayer
    fullyConnectedLayer(24)
    reluLayer
    fullyConnectedLayer(1)
    ];

% Create the actor and critic representations
actorOptions = rlRepresentationOptions('LearnRate',1e-3,'GradientThreshold',1);
criticOptions = rlRepresentationOptions('LearnRate',1e-3,'GradientThreshold',1);

actor = rlStochasticActorRepresentation(actorNetwork, obsInfo, actInfo, 'Observation', {'Observation'}, actorOptions);
critic = rlValueRepresentation(criticNetwork, obsInfo, 'Observation', {'Observation'}, criticOptions);

% Create the PPO agent
agentOptions = rlPPOAgentOptions(...
    'ExperienceHorizon',64,...
    'ClipFactor',0.2,...
    'EntropyLossWeight',0.01,...
    'MiniBatchSize',64,...
    'NumEpoch',3);

agent = rlPPOAgent(actor, critic, agentOptions);

% Set training options
trainOpts = rlTrainingOptions(...
    'MaxEpisodes', 500, ...
    'MaxStepsPerEpisode', 200, ...
    'ScoreAveragingWindowLength', 10, ...
    'Verbose', false, ...
    'Plots', 'training-progress', ...
    'StopTrainingCriteria', 'AverageReward', ...
    'StopTrainingValue', 195);

% Train the agent
trainingStats = train(agent, env, trainOpts);

% Simulate the agent in the environment
simOptions = rlSimulationOptions('MaxSteps',200);
experience = sim(env, agent, simOptions);

% Plot the results
waterLevels = experience.Observation.WaterLevel.Data;
time = (0:length(waterLevels)-1) * env.Ts;
plot(time, waterLevels);
xlabel('Time (s)');
ylabel('Water Level');
title('Water Level Over Time');