% Define parameters
A = 1; % Cross-sectional area of the tanks
k = 1; % Flow coefficient

% Create a new Simulink model
model = 'FourTankWaterSystem';
open_system(new_system(model));

% Add Step block (Inflow)
add_block('simulink/Sources/Step', [model, '/Inflow']);
set_param([model, '/Inflow'], 'Time', '0', 'Before', '1', 'After', '1');
set_param([model, '/Inflow'], 'Position', [50, 50, 80, 70]);

% Add Transfer Function blocks for each tank
for i = 1:4
    add_block('simulink/Continuous/Transfer Fcn', [model, '/Tank', num2str(i)]);
    set_param([model, '/Tank', num2str(i)], 'Position', [150 * i, 50, 150 * i + 30, 70]);
end

% Configure Transfer Function blocks
set_param([model, '/Tank1'], 'Numerator', '[1 k]', 'Denominator', '[A k]');
set_param([model, '/Tank2'], 'Numerator', '[k k]', 'Denominator', '[A 2k]');
set_param([model, '/Tank3'], 'Numerator', '[k k]', 'Denominator', '[A 2k]');
set_param([model, '/Tank4'], 'Numerator', '[k -1]', 'Denominator', '[A k]');

% Add Scope block
add_block('simulink/Sinks/Scope', [model, '/Scope']);
set_param([model, '/Scope'], 'Position', [800, 50, 830, 70]);

% Connect blocks
add_line(model, 'Inflow/1', 'Tank1/1');
add_line(model, 'Tank1/1', 'Tank2/1');
add_line(model, 'Tank2/1', 'Tank3/1');
add_line(model, 'Tank3/1', 'Tank4/1');
add_line(model, 'Tank1/1', 'Scope/1');
add_line(model, 'Tank2/1', 'Scope/2');
add_line(model, 'Tank3/1', 'Scope/3');
add_line(model, 'Tank4/1', 'Scope/4');

% Save and open the model
save_system(model);
open_system(model);