# A Comparative Study of SAC and PPO

This research investigates the performance of three newest version of algorithms in reinforcement
learning (RL) as an advanced control strategy for water level control with
single-tank system and quadruple-tank system, contrasting it with the conventional PID
(proportional-integral-derivative) control within the framework. RL, which autonomously
learns by interacting with its environment, is becoming increasingly popular for developing
optimal controllers for complex, dynamic, and nonlinear processes. Unlike most RL
studies that use open-source platforms like Python and OpenAI Gym, this research utilizes
MATLAB's Reinforcement Learning Toolbox (introduced in R2024a) to design a water tank
model using Transfer function and State Space Equation. The controller is trained using
Soft Actor-Crtic (SAC), Proximal Policy Optimization (PPO), and Deep Deterministic Policy
Gradient (DDPG) algorithm, with Simulink employed to simulate the water tank system
and establish an experimental test bench for comparsion between them.
The ndings indicate that the Soft Actor-Critic (SAC) algorithm deliver the best result
in signal tracking, achieving high speed and low error relative to the reference signal when
compared to other reinforcement learning (RL) algorithms. However, algorithms such as
Proximal Policy Optimization (PPO) demonstrate superior performance in maintaining
minimal steady-state error, despite requiring a signicantly longer training period in the
context of a single-tank system. In more complex scenarios, such as the quadruple-tank
system, SAC proves to be superior due to its advantage in handling continuous action
spaces, where PPO tends to diverge signicantly.
Achieving success in machine learning necessitates the tuning of numerous hyperparameters,
a process that is both time-consuming and labor-intensive. The practical insights
derived from this research are corroborated by existing literature, underscoring the robustness
and applicability of the ndings
