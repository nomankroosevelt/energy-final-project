clear all; clc;
%% Read input from Excel
inputFile = 'Basic_calculate_input.xlsx';
data = readtable(inputFile);

%% Extract input data from table
elec_price_max = data.elec_price_max;
elec_price_mid = data.elec_price_mid;
elec_price_low = data.elec_price_low;
max_elec_storage = data.max_elec_storage;
max_io_speed = data.max_io_speed;
io_efficiency = data.io_efficiency;
max_elec_need = data.max_elec_need;
rectA = [data.rectA_length, data.rectA_width]; 
rectB = [data.rectB_length, data.rectB_width]; 
d1 = data.d1; 
d2 = data.d2; 
dAB = data.dAB; 
numA = max_elec_need/max_elec_storage; 
numB = numA; 
lineCost = data.lineCost;
areaCost = data.areaCost;
maxIterations = data.maxIterations;
initialTemp = data.initialTemp;
coolingRate = data.coolingRate;

%% smallest area calculate

% rectA = [9.8, 3.4]; 
% rectB = [5.5, 2.6]; 
% d1 = 2; 
% d2 = 2.8; 
% dAB = 2; 
% numA = max_elec_need/max_elec_storage; 
% numB = numA; 
% lineCost = 10;
% areaCost = 1500;
% maxIterations = 1000000;
% initialTemp = 10000;
% coolingRate = 0.50;
optimizedPackingSimulatedAnnealing(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost, maxIterations, initialTemp, coolingRate)

%% Main calculate
% 参数设置 
global bestCost;
battery_cost_per_kWh = 0.37; % 电池成本（元/kWh）
installation_cost_per_MWh = 100000; % 安装费用（元/MWh）
boost_device_cost_per_MWh = 200000; % 升压装置费用（元/MWh）
design_cost = 2000000; % 项目设计费（元）
land_cost_per_sqm = 1500; % 工业用地成本（元/平方米）
land_area_sqm = 1904.8; % 占地面积（平方米）
system_capacity_MWh = 100; % 系统容量（MWh）
operation_maintenance_cost_per_year = 2000000; % 运维费用（元/年）
operation_days_per_year = 330; % 每年使用天数
operation_years = 10; % 运行年限
discount_rate = 0.05; % 折现率

% 电价参数
valley_price = 0.31; % 谷电电价（元/kWh）
peak_price = 1.15; % 峰电电价（元/kWh）
flat_price = 0.61; % 平电电价（元/kWh）

% 电池舱参数
battery_capacity_per_cabin_MWh = 2.5; % 每个电池舱容量（MWh）
battery_power_per_cabin_MW = 1.25; % 每个电池舱额定功率（MW）
battery_efficiency = 0.83; % 电池效率

% 计算电池舱数量
num_cabins = system_capacity_MWh / battery_capacity_per_cabin_MWh;

% 计算总投资成本
battery_cost = battery_cost_per_kWh * system_capacity_MWh * 1000; % 电池成本（从MWh转换为kWh）
installation_cost = installation_cost_per_MWh * system_capacity_MWh; % 安装费用
boost_device_cost = boost_device_cost_per_MWh * system_capacity_MWh; % 升压装置费用
%land_cost = land_cost_per_sqm * land_area_sqm; % 占地成本
land_cost = bestCost;
total_investment_cost = battery_cost + installation_cost + boost_device_cost + design_cost + land_cost;

% 计算运维总成本
total_maintenance_cost = operation_maintenance_cost_per_year * operation_years;

% 两种模式下的收入和成本计算
% 模式1：一天两充两放
capacity_degradation_per_year_mode1 = 3.5; % 容量每年衰减（MWh）
charge_discharge_cycles_per_day_mode1 = 2;
annual_revenue_mode1 = zeros(1, operation_years);
for year = 1:operation_years
    effective_capacity = system_capacity_MWh - capacity_degradation_per_year_mode1 * year;
    daily_revenue = ((effective_capacity * 1000 * battery_efficiency * peak_price) - (effective_capacity * 1000 * valley_price)) * charge_discharge_cycles_per_day_mode1; % 单位转换为kWh
    annual_revenue_mode1(year) = daily_revenue * operation_days_per_year;
end
total_revenue_mode1 = sum(annual_revenue_mode1); % 总收入
payback_years_mode1 = find(cumsum(annual_revenue_mode1) >= total_investment_cost + total_maintenance_cost, 1); % 回本年限
net_profit_mode1 = total_revenue_mode1 - total_investment_cost - total_maintenance_cost; % 总收益

% 模式2：一天一充一放
capacity_degradation_per_year_mode2 = 2; % 容量每年衰减（MWh）
charge_discharge_cycles_per_day_mode2 = 1;
annual_revenue_mode2 = zeros(1, operation_years);
for year = 1:operation_years
    effective_capacity = system_capacity_MWh - capacity_degradation_per_year_mode2 * year;
    daily_revenue = ((effective_capacity * 1000 * battery_efficiency * peak_price) - (effective_capacity * 1000 * valley_price)) * charge_discharge_cycles_per_day_mode2; % 单位转换为kWh
    annual_revenue_mode2(year) = daily_revenue * operation_days_per_year;
end
total_revenue_mode2 = sum(annual_revenue_mode2); % 总收入
payback_years_mode2 = find(cumsum(annual_revenue_mode2) >= total_investment_cost + total_maintenance_cost, 1); % 回本年限
net_profit_mode2 = total_revenue_mode2 - total_investment_cost - total_maintenance_cost; % 总收益

% 考虑折现率后的回本年限和总收益计算
discount_factors = 1 ./ (1 + discount_rate) .^ (1:operation_years);

% 模式1折现后的计算
discounted_annual_revenue_mode1 = annual_revenue_mode1 .* discount_factors;
discounted_total_revenue_mode1 = sum(discounted_annual_revenue_mode1);
discounted_total_investment_cost = total_investment_cost + total_maintenance_cost;
discounted_net_profit_mode1 = discounted_total_revenue_mode1 - discounted_total_investment_cost;

% 模式2折现后的计算
discounted_annual_revenue_mode2 = annual_revenue_mode2 .* discount_factors;
discounted_total_revenue_mode2 = sum(discounted_annual_revenue_mode2);
discounted_total_investment_cost = total_investment_cost + total_maintenance_cost;
discounted_net_profit_mode2 = discounted_total_revenue_mode2 - discounted_total_investment_cost;

% 输出结果到文件
outputFile = 'Basic_calculate_output.txt';
fid = fopen(outputFile, 'w');
fprintf(fid, '模式1（一天两充两放）：\n');
fprintf(fid, '总投资成本：%.2f元\n', total_investment_cost);
fprintf(fid, '运维总成本：%.2f元\n', total_maintenance_cost);
fprintf(fid, '总收入：%.2f元\n', total_revenue_mode1);
fprintf(fid, '回本年限：%d年\n', payback_years_mode1);
fprintf(fid, '总收益：%.2f元\n', net_profit_mode1);
fprintf(fid, '折现后总收益：%.2f元\n', discounted_net_profit_mode1);

fprintf(fid, '\n模式2（一天一充一放）：\n');
fprintf(fid, '总投资成本：%.2f元\n', total_investment_cost);
fprintf(fid, '运维总成本：%.2f元\n', total_maintenance_cost);
fprintf(fid, '总收入：%.2f元\n', total_revenue_mode2);
fprintf(fid, '回本年限：%d年\n', payback_years_mode2);
fprintf(fid, '总收益：%.2f元\n', net_profit_mode2);
fprintf(fid, '折现后总收益：%.2f元\n', discounted_net_profit_mode2);
fclose(fid);

%% Functions

function [bestArrangement, bestCost, bestLineCost, bestAreaCost] = optimizedPackingSimulatedAnnealing(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost, maxIterations, initialTemp, coolingRate)
    global bestCost;
    % Generate initial solution
    arrangement = initializeArrangement(rectA, rectB, numA, numB, dAB);
    
    % Calculate initial cost
    [bestCost, bestLineCost, bestAreaCost] = calculateCost(arrangement, d1, d2, lineCost, areaCost);
    
    bestArrangement = arrangement;
    currentCost = bestCost;
    currentArrangement = arrangement;
    
    % Initialize array to record best cost history
    bestCostHistory = zeros(maxIterations, 1);
    bestCostHistory(1) = bestCost;
    
    % Simulated Annealing process
    temp = initialTemp;
    for iter = 1:maxIterations
        % Generate a neighbor solution
        newArrangement = generateNeighbor(currentArrangement, rectA, rectB, dAB);
        
        % Calculate cost of new arrangement
        [newCost, newLineCost, newAreaCost] = calculateCost(newArrangement, d1, d2, lineCost, areaCost);
        
        % Acceptance probability
        if newCost < currentCost
            acceptProbability = 1;
        else
            acceptProbability = exp((currentCost - newCost) / temp);
        end
        
        % Accept or reject the new arrangement
        if rand < acceptProbability
            currentArrangement = newArrangement;
            currentCost = newCost;
            currentLineCost = newLineCost;
            currentAreaCost = newAreaCost;
        end
        
        % Update best solution
        if currentCost < bestCost
            bestArrangement = currentArrangement;
            bestCost = currentCost;
            bestLineCost = currentLineCost;
            bestAreaCost = currentAreaCost;
        end
        
        % Record the best cost in history
        bestCostHistory(iter) = bestCost;
        
        % Cool down
        temp = temp * coolingRate;
        
        % Display current iteration and cost
        fprintf('Iteration %d, Best Cost: %.2f\n', iter, bestCost);
    end
    
    % Plot the best solution
    plotRectangles(bestArrangement, bestCost);
    
    % Display the best solution
    disp('Best solution:');
    disp(bestArrangement);
    fprintf('Total cost of the best solution: %.2f\n', bestCost);
    fprintf('Total line cost of the best solution: %.2f\n', bestLineCost);
    fprintf('Total area cost of the best solution: %.2f\n', bestAreaCost);
    
    % Plot the best cost history
    figure;
    plot(1:maxIterations, bestCostHistory);
    xlabel('Iteration');
    ylabel('Best Cost');
    title('Best Cost vs. Iteration');

    % Return the best solution and its costs
    bestArrangement = bestArrangement;
    bestCost = bestCost;
    bestLineCost = bestLineCost;
    bestAreaCost = bestAreaCost;
end

function plotRectangles(arrangement, totalCost)
    figure;
    hold on;
    colors = ['r', 'g', 'b', 'm', 'c']; % Define colors for different rectangles
    for i = 1:numel(arrangement)
        rect = arrangement{i};
        color = colors(mod(i, numel(colors)) + 1); % Cycle through colors
        rectangle('Position', [rect(1), rect(2), rect(3), rect(4)], 'EdgeColor', color);
    end
    % Draw lines connecting corresponding rectangles A and B
    for i = 1:2:numel(arrangement)-1
        xA = arrangement{i}(1) + arrangement{i}(3)/2;
        yA = arrangement{i}(2) + arrangement{i}(4)/2;
        nextRect = arrangement{i+1};
        xB = nextRect(1) + nextRect(3)/2;
        yB = nextRect(2) + nextRect(4)/2;
        line([xA, xB], [yA, yB], 'Color', 'k');
    end
    hold off;
    axis equal;
end

function [totalCost, totalLineCost, totalAreaCost] = calculateCost(arrangement, d1, d2, lineCost, areaCost)
    % Initialize costs
    totalLineCost = 0;
    totalAreaCost = 0;
    
    % Calculate total line cost and total area cost
    for i = 1:2:numel(arrangement)-1
        xA = arrangement{i}(1) + arrangement{i}(3)/2;
        yA = arrangement{i}(2) + arrangement{i}(4)/2;
        xB = arrangement{i+1}(1) + arrangement{i+1}(3)/2;
        yB = arrangement{i+1}(2) + arrangement{i+1}(4)/2;
        
        totalLineCost = totalLineCost + sqrt((xA - xB)^2 + (yA - yB)^2);
        totalAreaCost = totalAreaCost + (arrangement{i}(3) * arrangement{i}(4) + arrangement{i+1}(3) * arrangement{i+1}(4));
    end
    
    % Calculate total cost
    totalCost = totalLineCost * lineCost + totalAreaCost * areaCost;
end

function isOverlap = isOverlapping(rect1, rect2, minDist)
    % Check if two rectangles overlap with a minimum distance
    x1 = rect1(1);
    y1 = rect1(2);
    w1 = rect1(3);
    h1 = rect1(4);
    
    x2 = rect2(1);
    y2 = rect2(2);
    w2 = rect2(3);
    h2 = rect2(4);
    
    isOverlap = ~(x1 + w1 + minDist < x2 || x2 + w2 + minDist < x1 || y1 + h1 + minDist < y2 || y2 + h2 + minDist < y1);
end

function intersects = isLineIntersectingAnyRect(arrangement, point1, point2)
    % Check if a line intersects with any rectangles in the arrangement
    intersects = false;
    for i = 1:numel(arrangement)
        rect = arrangement{i};
        if isLineIntersectingRect(rect, point1, point2)
            intersects = true;
            return;
        end
    end
end

function intersects = isLineIntersectingRect(rect, point1, point2)
    % Check if a line intersects with a rectangle
    x1 = rect(1);
    y1 = rect(2);
    x2 = rect(1) + rect(3);
    y2 = rect(2) + rect(4);
    
    % Check all four edges of the rectangle
    intersects = lineIntersect([x1, y1], [x2, y1], point1, point2) || ...
                 lineIntersect([x2, y1], [x2, y2], point1, point2) || ...
                 lineIntersect([x2, y2], [x1, y2], point1, point2) || ...
                 lineIntersect([x1, y2], [x1, y1], point1, point2);
end

function intersects = lineIntersect(p1, p2, q1, q2)
    % Check if two line segments [p1, p2] and [q1, q2] intersect
    d = (q2(2) - q1(2)) * (p2(1) - p1(1)) - (q2(1) - q1(1)) * (p2(2) - p1(2));
    if d == 0
        intersects = false;
        return;
    end
    u = ((q1(1) - p1(1)) * (p2(2) - p1(2)) - (q1(2) - p1(2)) * (p2(1) - p1(1))) / d;
    t = ((q1(1) - p1(1)) * (q2(2) - q1(2)) - (q1(2) - p1(2)) * (q2(1) - q1(1))) / d;
    intersects = (u >= 0 && u <= 1 && t >= 0 && t <= 1);
end

function arrangement = initializeArrangement(rectA, rectB, numA, numB, dAB)
    % Randomly initialize the arrangement of rectangles with overlap detection
    arrangement = cell(1, numA + numB);
    for i = 1:numA
        while true
            x = rand * 100;
            y = rand * 100;
            newRect = [x, y, rectA(1), rectA(2)];
            if ~any(cellfun(@(r) isOverlapping(r, newRect, dAB), arrangement(1:i-1)))
                arrangement{i} = newRect;
                break;
            end
        end
    end
    for i = numA+1:numA+numB
        while true
            x = rand * 100;
            y = rand * 100;
            newRect = [x, y, rectB(1), rectB(2)];
            if ~any(cellfun(@(r) isOverlapping(r, newRect, dAB), arrangement(1:i-1)))
                arrangement{i} = newRect;
                break;
            end
        end
    end
end

function newArrangement = generateNeighbor(currentArrangement, rectA, rectB, dAB)
    % Generate a neighbor arrangement by perturbing the current arrangement
    newArrangement = currentArrangement;
    idx = randi(length(currentArrangement));
    for attempt = 1:100  % Try up to 100 times to find a non-overlapping position
        newX = newArrangement{idx}(1) + randn;
        newY = newArrangement{idx}(2) + randn;
        newRect = [newX, newY, newArrangement{idx}(3), newArrangement{idx}(4)];
        if ~any(cellfun(@(r) isOverlapping(r, newRect, dAB), newArrangement(1:idx-1))) && ...
           ~any(cellfun(@(r) isOverlapping(r, newRect, dAB), newArrangement(idx+1:end)))
            newArrangement{idx} = newRect;
            break;
        end
    end
end