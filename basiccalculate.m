clear all; clc;
%% Basic electric numbers

elec_price_max = 1.15;%kwh
elec_price_mid = 0.61;%kwh
elec_price_low = 0.31;%kwh

max_elec_storage = 2500;%kwh
max_io_speed = 1250;
io_efficiency = 0.83;

max_elec_need = 100000;

%% smallest area calculate

rectA = [9800, 3400]; 
rectB = [5500, 2600]; 
d1 = 2000; 
d2 = 2800; 
dAB = 2000; 
numA = max_elec_need/max_elec_storage; 
numB = numA; 
lineCost = 100;
areaCost = 30;
minCostPackingWithRotation(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost);


function minCostPackingWithRotation(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost)
    % rectA, rectB: [width, height] of the rectangles A and B
    % d1, d2: minimum distance conditions between same type rectangles
    % dAB: minimum distance condition between different type rectangles
    % numA, numB: number of rectangles A and B
    % lineCost: unit cost of the length of the lines connecting rectangles
    % areaCost: unit cost of the area of the enclosing rectangle

    % Unpack the rectangle dimensions
    wA = rectA(1); hA = rectA(2);
    wB = rectB(1); hB = rectB(2);

    % Initialize lists to store positions
    posA = [];
    posB = [];

    % Initialize boundaries for the containing rectangle
    minX = inf;
    minY = inf;
    maxX = 0;
    maxY = 0;

    % Function to check if a rectangle can be placed at a given position
    function isPlaceable = canPlace(x, y, w, h, positions, minDist)
        isPlaceable = true;
        for i = 1:size(positions, 1)
            if rectOverlap(x, y, w, h, positions(i, 1), positions(i, 2), positions(i, 3), positions(i, 4), minDist)
                isPlaceable = false;
                return;
            end
        end
    end

    % Function to place a rectangle at a given position
    function positions = placeRect(x, y, w, h, positions)
        positions = [positions; x, y, w, h];
    end

    % Function to calculate the distance between two points
    function dist = calcDistance(x1, y1, x2, y2)
        dist = sqrt((x1 - x2)^2 + (y1 - y2)^2);
    end

    % Function to calculate total line length between corresponding rectangles A and B
    function totalLength = calcTotalLineLength()
        totalLength = 0;
        for i = 1:min(size(posA, 1), size(posB, 1))
            xA = posA(i, 1) + posA(i, 3)/2;
            yA = posA(i, 2) + posA(i, 4)/2;
            xB = posB(i, 1) + posB(i, 3)/2;
            yB = posB(i, 2) + posB(i, 4)/2;
            totalLength = totalLength + calcDistance(xA, yA, xB, yB);
        end
    end

    % Function to update boundaries of the containing rectangle
    function updateBounds(x, y, w, h)
        minX = min(minX, x);
        minY = min(minY, y);
        maxX = max(maxX, x + w);
        maxY = max(maxY, y + h);
    end

    % Function to calculate the enclosing rectangle area
    function area = calcEnclosingRectangleArea()
        area = (maxX - minX) * (maxY - minY);
    end

    % Function to calculate the total cost (line cost + area cost)
    function cost = calcTotalCost()
        lineLength = calcTotalLineLength();
        enclosingArea = calcEnclosingRectangleArea();
        cost = lineLength * lineCost + enclosingArea * areaCost;
    end

    % Function to try all possible rotations and placements for a rectangle
    function [bestPos, bestCost] = tryPlaceRect(w, h, d, positions, isA)
        bestPos = positions;
        bestCost = inf;
        maxWidth = (wA + wB) * (numA + numB);
        maxHeight = (hA + hB) * (numA + numB);
        for y = 1:maxHeight
            for x = 1:maxWidth
                if canPlace(x, y, w, h, [posA; posB], d)
                    tempPositions = placeRect(x, y, w, h, positions);
                    updateBounds(x, y, w, h);
                    cost = calcTotalCost();
                    if cost < bestCost
                        bestCost = cost;
                        bestPos = tempPositions;
                    end
                elseif canPlace(x, y, h, w, [posA; posB], d) % Try rotated
                    tempPositions = placeRect(x, y, h, w, positions);
                    updateBounds(x, y, h, w);
                    cost = calcTotalCost();
                    if cost < bestCost
                        bestCost = cost;
                        bestPos = tempPositions;
                    end
                end
            end
        end
    end

    % Place rectangles A
    for i = 1:numA
        [posA, ~] = tryPlaceRect(wA, hA, d1, posA, true);
        if isempty(posA)
            error('Cannot place all rectangles A with the given constraints.');
        end
    end

    % Place rectangles B
    for i = 1:numB
        % Find the closest rectangle A for placement
        minDist = inf;
        bestPos = [];
        for j = 1:size(posA, 1)
            xA = posA(j, 1); yA = posA(j, 2);
            [tempPos, ~] = tryPlaceRect(wB, hB, d2, posB, false);
            if ~isempty(tempPos)
                xB = tempPos(end, 1); yB = tempPos(end, 2);
                dist = calcDistance(xA, yA, xB, yB);
                if dist < minDist
                    minDist = dist;
                    bestPos = tempPos;
                end
            end
        end
        if ~isempty(bestPos)
            posB = bestPos;
        else
            error('Cannot place all rectangles B with the given constraints.');
        end
    end

    % Ensure minimum distance between A and B
    for i = 1:size(posA, 1)
        for j = 1:size(posB, 1)
            x1 = posA(i, 1); y1 = posA(i, 2); w1 = posA(i, 3); h1 = posA(i, 4);
            x2 = posB(j, 1); y2 = posB(j, 2); w2 = posB(j, 3); h2 = posB(j, 4);
            if rectOverlap(x1, y1, w1, h1, x2, y2, w2, h2, dAB)
                error('Cannot maintain the minimum distance between rectangles A and B.');
            end
        end
    end

    % Calculate the used area
    minArea = calcEnclosingRectangleArea();

    % Display results
    fprintf('Minimum cost required: %d\n', calcTotalCost());
    fprintf('Positions of rectangles A:\n');
    disp(posA);
    fprintf('Positions of rectangles B:\n');
    disp(posB);

    % Visualization
    figure;
    hold on;
    for i = 1:size(posA, 1)
        rectangle('Position', [posA(i, 1), posA(i, 2), posA(i, 3), posA(i, 4)], 'EdgeColor', 'r');
    end
    for i = 1:size(posB, 1)
        rectangle('Position', [posB(i, 1), posB(i, 2), posB(i, 3), posB(i, 4)], 'EdgeColor', 'b');
    end
    % Draw lines connecting corresponding rectangles A and B
    for i = 1:min(numA, numB)
        line([posA(i, 1) + posA(i, 3)/2, posB(i, 1) + posB(i, 3)/2], [posA(i, 2) + posA(i, 4)/2, posB(i, 2) + posB(i, 4)/2], 'Color', 'k');
    end
    hold off;
end

% Function to check if two rectangles overlap with a given minimum distance
function overlap = rectOverlap(x1, y1, w1, h1, x2, y2, w2, h2, d)
    overlap = ~(x1 + w1 + d < x2 || x2 + w2 + d < x1 || y1 + h1 + d < y2 || y2 + h2 + d < y1);
end

