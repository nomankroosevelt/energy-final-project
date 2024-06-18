% 读取输入表格
data = readtable('Battery_calculate_input.xlsx');

% 提取参数值，假设参数值在第二列
battery_P = data{1, 2};
battery_S = data{2, 2};
battery_Wh = data{3, 2};
battery_price = data{4, 2};
target_P = data{5, 2};
target_S = data{6, 2};
target_Wh = data{7, 2};
Basic_rate = data{8, 2};

% 计算电池数量、总能量和总价格
[num_batteries, total_energy, total_price, KWH] = calculate_battery_count(target_P, target_S, target_Wh, battery_P, battery_S, battery_Wh, battery_price, Basic_rate);

% 写入输出文件
fileID = fopen('Battery_calculate_output.txt', 'w');
fprintf(fileID, '电池数量: %d\n', num_batteries);
fprintf(fileID, '总能量（Wh）: %d\n', total_energy);
fprintf(fileID, '总价格: $%.2f\n', total_price);
fprintf(fileID, '千瓦时价格: $%.2f\n', KWH);
fclose(fileID);


function [num_batteries, total_energy, total_price, KWH] = calculate_battery_count(target_P, target_S, target_Wh, battery_P, battery_S, battery_Wh, battery_price, Basic_rate)
    % 计算每个电池串联数量
    num_series = floor(target_P / (battery_P * battery_S));
    % 计算每个电池并联数量
    num_parallel = floor(target_S / battery_S);
    % 计算总电池数量
    num_batteries = num_series * num_parallel;
    % 计算总能量
    total_energy = num_batteries * battery_Wh;
    % 计算总价格
    total_price = num_batteries * battery_price * Basic_rate;
    % 调整电池数量，使总能量最接近目标能量
    while total_energy < target_Wh
        num_batteries = num_batteries + 1;
        total_energy = num_batteries * battery_Wh;
        total_price = num_batteries * battery_price * Basic_rate;
        KWH = total_price/(total_energy * 0.001);
    end
end