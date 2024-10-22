open_system("rlwatertank_DDPG")

%Create Observation (State) 
obsInfo = rlNumericSpec([3 1],'LowerLimit',[-inf -inf 0 ]','UpperLimit',[inf  inf inf]'); 
obsInfo.Name = 'observations'; 
obsInfo.Description = 'integrated error, error, and measured height'; 
numObservations = obsInfo.Dimension(1); 
  
actInfo = rlNumericSpec([1 1]); 
actInfo.Name = 'CV'; 
numActions = actInfo.Dimension(1);

%Create Environtment
env = rlSimulinkEnv('rlwatertank_DDPG','rlwatertank_DDPG/RL Agent',obsInfo,actInfo);

env.ResetFcn = @(in)localResetFcn_modeldm(in);

Ts = 1.0;
Tf = 150;

statePath = [  
   
featureInputLayer(numObservations,'Normalization','none','Name','State')
    fullyConnectedLayer(50,'Name','CriticStateFC1')
    reluLayer('Name','CriticRelu1')
    fullyConnectedLayer(25,'Name','CriticStateFC2')];
actionPath = [
    featureInputLayer(numActions,'Normalization','none','Name','Action')
    fullyConnectedLayer(25,'Name','CriticActionFC1')];
commonPath = [
    additionLayer(2,'Name','add')
    reluLayer('Name','CriticCommonRelu')
    fullyConnectedLayer(1,'Name','CriticOutput')];
 
criticNetwork = layerGraph();
criticNetwork = addLayers(criticNetwork,statePath);
criticNetwork = addLayers(criticNetwork,actionPath);
criticNetwork = addLayers(criticNetwork,commonPath);
criticNetwork = connectLayers(criticNetwork,'CriticStateFC2','add/in1');
criticNetwork = connectLayers(criticNetwork,'CriticActionFC1','add/in2');
 
%Create Critic Representation
criticOpts = rlRepresentationOptions('LearnRate',1e03,'GradientThreshold',1);

critic = rlQValueRepresentation(criticNetwork,obsInfo,actInfo,'Observation',{'State'},'Action',{'Action'},criticOpts);

actorNetwork = [...
featureInputLayer(numObservations,'Normalization','none','Name','State')
    fullyConnectedLayer(3, 'Name','actorFC')
    tanhLayer('Name','actorTanh')
    fullyConnectedLayer(numActions,'Name','Action')
    ];
 
%Create Actor Representation
actorOptions = rlRepresentationOptions('LearnRate',1e04,'GradientThreshold',1);

actor = rlDeterministicActorRepresentation(actorNetwork,obsInfo,actInfo,'Observation',{'State'},'Action',{'Action'},actorOptions);

%DDPG Agent Options 
agentOpts = rlDDPGAgentOptions(... 
    'SampleTime',Ts,... 
    'TargetSmoothFactor',1e-3,... 
    'DiscountFactor',0.9,... 
    'MiniBatchSize',64,... 
    'ExperienceBufferLength',1e6,... 
    'ResetExperienceBufferBeforeTraining',false,... 
    'SaveExperienceBufferWithAgent',true);  
  
 
agentOpts.NoiseOptions.Variance = 0.3; 
agentOpts.NoiseOptions.VarianceDecayRate = 1e-5; 
  
agent = rlDDPGAgent(actor,critic,agentOpts); 
  
maxepisodes = 20000; 
maxsteps = ceil(Tf/Ts);


%DDPG Training Options 
trainOpts = rlTrainingOptions(... 
'MaxEpisodes',maxepisodes,... 
'MaxStepsPerEpisode',maxsteps,... 
'ScoreAveragingWindowLength',50,... 
'Verbose',false,... 
'Plots','training-progress',... 
'StopTrainingCriteria','AverageReward',... 
'StopTrainingValue',4800);  

doTraining = true; 
  
if doTraining
    % Train the agent.
    trainingStats = train(agent,env,trainOpts);
else
    % Load the pretrained agent for the example.
    load('Matlab_model1_Revised7_dm_reward4800_4.mat','agent')
end

simOpts = rlSimulationOptions('MaxSteps',maxsteps,'StopOnError','on');
experiences = sim(env,agent,simOpts);

function in = localResetFcn(in)
% Randomize reference signal
blk = sprintf("rlwatertank/Desired \nWater Level");
h = 3*randn + 10;
while h <= 0 || h >= 20
    h = 3*randn + 10;
end
in = setBlockParameter(in,blk,Value=num2str(h));

% Randomize initial height
h = 3*randn + 10;
while h <= 0 || h >= 20
    h = 3*randn + 10;
end
blk = "rlwatertank/Water-Tank System/H";
in = setBlockParameter(in,blk,InitialCondition=num2str(h));

end