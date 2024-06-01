% 给定的电池配置
battery_P = 1;   % 电池功率（W）
battery_S = 1;     % 电池串联数量
battery_Wh = 864;  % 电池能量（Wh）
battery_price = 320; % 单个电池价格

% 目标电池配置
target_P = 1;    % 目标功率（W）
target_S = 342;      % 目标串联数量
target_Wh = 12.5*1000000;   % 目标能量（Wh）

% 计算电池数量、总能量和总价格
[num_batteries, total_energy, total_price] = calculate_battery_count(target_P, target_S, target_Wh, battery_P, battery_S, battery_Wh, battery_price);

fprintf('电池数量: %d\n', num_batteries);
fprintf('总能量（Wh）: %d\n', total_energy);
fprintf('总价格: $%.2f\n', total_price);

function [num_batteries, total_energy, total_price] = calculate_battery_count(target_P, target_S, target_Wh, battery_P, battery_S, battery_Wh, battery_price)
    % 计算每个电池串联数量
    num_series = floor(target_P / (battery_P * battery_S));
    % 计算每个电池并联数量
    num_parallel = floor(target_S / battery_S);
    % 计算总电池数量
    num_batteries = num_series * num_parallel;
    % 计算总能量
    total_energy = num_batteries * battery_Wh;
    % 计算总价格
    total_price = num_batteries * battery_price;
    % 调整电池数量，使总能量最接近目标能量
    while total_energy < target_Wh
        num_batteries = num_batteries + 1;
        total_energy = num_batteries * battery_Wh;
        total_price = num_batteries * battery_price;
    end
end