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

minAreaPackingWithRotation(rectA, rectB, d1, d2, dAB, numA, numB);


function minAreaPackingWithRotation(rectA, rectB, d1, d2, dAB, numA, numB)
    % rectA, rectB: [width, height] of the rectangles A and B
    % d1, d2: minimum distance conditions between same type rectangles
    % dAB: minimum distance condition between different type rectangles
    % numA, numB: number of rectangles A and B
    
    % Unpack the rectangle dimensions
    wA = rectA(1); hA = rectA(2);
    wB = rectB(1); hB = rectB(2);

    % Initialize variables
    maxWidth = max(wA, wB) * (numA + numB);  % An upper bound on width
    maxHeight = max(hA, hB) * (numA + numB); % An upper bound on height
    
    % Initialize a grid to keep track of placement
    grid = zeros(maxHeight, maxWidth);
    
    % Function to check if a rectangle can be placed at a given position
    function canPlace(x, y, w, h, d)
        if x + w > maxWidth || y + h > maxHeight
            canPlace = false;
            return;
        end
        if any(grid(y:y+h-1, x:x+w-1), 'all')
            canPlace = false;
            return;
        end
        if any(grid(max(1, y-d):min(maxHeight, y+h+d-1), max(1, x-d):min(maxWidth, x+w+d-1)), 'all')
            canPlace = false;
            return;
        end
        canPlace = true;
    end

    % Function to place a rectangle at a given position
    function placeRect(x, y, w, h)
        grid(y:y+h-1, x:x+w-1) = 1;
    end

    % Function to check all possible rotations and placements for a rectangle
    function [placed, pos] = tryPlaceRect(w, h, d)
        placed = false;
        pos = [];
        for y = 1:maxHeight
            for x = 1:maxWidth
                if canPlace(x, y, w, h, d)
                    placeRect(x, y, w, h);
                    pos = [x, y, w, h];
                    placed = true;
                    return;
                elseif canPlace(x, y, h, w, d) % Try rotated
                    placeRect(x, y, h, w);
                    pos = [x, y, h, w];
                    placed = true;
                    return;
                end
            end
        end
    end

    % Place rectangles A
    posA = [];
    for i = 1:numA
        [placed, pos] = tryPlaceRect(wA, hA, d1);
        if placed
            posA = [posA; pos];
        else
            error('Cannot place all rectangles A with the given constraints.');
        end
    end

    % Place rectangles B
    posB = [];
    for i = 1:numB
        [placed, pos] = tryPlaceRect(wB, hB, d2);
        if placed
            posB = [posB; pos];
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
    usedHeight = find(any(grid, 2), 1, 'last');
    usedWidth = find(any(grid, 1), 1, 'last');
    minArea = usedHeight * usedWidth;
    
    % Display results
    fprintf('Minimum area required: %d\n', minArea);
    fprintf('Positions of rectangles A:\n');
    disp(posA);
    fprintf('Positions of rectangles B:\n');
    disp(posB);
    
    % Visualization
    figure;
    imshow(grid);
    hold on;
    for i = 1:size(posA, 1)
        rectangle('Position', [posA(i, 1), posA(i, 2), posA(i, 3), posA(i, 4)], 'EdgeColor', 'r');
    end
    for i = 1:size(posB, 1)
        rectangle('Position', [posB(i, 1), posB(i, 2), posB(i, 3), posB(i, 4)], 'EdgeColor', 'b');
    end
    hold off;
end

% Function to check if two rectangles overlap with a given minimum distance
function overlap = rectOverlap(x1, y1, w1, h1, x2, y2, w2, h2, d)
    overlap = ~(x1 + w1 + d < x2 || x2 + w2 + d < x1 || y1 + h1 + d < y2 || y2 + h2 + d < y1);
end
