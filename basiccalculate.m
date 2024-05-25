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

rectA = [9.8, 3.4]; 
rectB = [5.5, 2.6]; 
d1 = 2; 
d2 = 2.8; 
dAB = 2; 
numA = max_elec_need/max_elec_storage; 
numB = numA; 
lineCost = 10;
areaCost = 300;
populationSize = 20000;
generations = 2000000000000000;
optimizedPackingGA(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost, populationSize, generations);

function optimizedPackingGA(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost, populationSize, generations)
    % Define gene encoding: Each gene represents a rectangle
    geneLength = numA + numB;
    
    % Generate initial population
    population = initializePopulation(populationSize, geneLength);
    
    % Evolve the population through generations
    for gen = 1:generations
        % Evaluate fitness
        [fitness, totalCosts] = evaluateFitness(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost);
        
        % Select parents
        parents = selectParents(population, fitness, 2);
        
        % Crossover
        offspring = crossover(parents);
        
        % Mutation
        offspring = mutate(offspring);
        
        % Replace the old population with offspring
        population = offspring;
    end
    
    % Select the best solution from the final population
    [bestSolution, bestCost, bestLineCost, bestAreaCost] = selectBestSolution(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost);
    
    % Plot the best solution
    plotRectangles(bestSolution, bestCost);
    
    % Display the best solution
    disp('Best solution:');
    disp(bestSolution);
    fprintf('Total cost of the best solution: %.2f\n', bestCost);
    fprintf('Total line cost of the best solution: %.2f\n', bestLineCost);
    fprintf('Total area cost of the best solution: %.2f\n', bestAreaCost);
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
    title(['Total cost: ', num2str(totalCost)]);
end

function [fitness, totalCosts] = evaluateFitness(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost)
    fitness = zeros(size(population, 1), 1);
    totalCosts = zeros(size(population, 1), 3); % [totalCost, lineCost, areaCost]
    for i = 1:size(population, 1)
        % Decode the gene to obtain the arrangement of rectangles
        arrangement = decodeGene(population(i, :), rectA, rectB);
        
        % Calculate the fitness based on the arrangement
        [fitness(i), totalCosts(i, 1), totalCosts(i, 2), totalCosts(i, 3)] = calculateFitness(arrangement, d1, d2, dAB, lineCost, areaCost);
    end
end

function [bestSolution, bestCost, bestLineCost, bestAreaCost] = selectBestSolution(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost)
    [fitness, totalCosts] = evaluateFitness(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost);
    [~, bestIndex] = max(fitness);
    bestSolution = decodeGene(population(bestIndex, :), rectA, rectB);
    bestCost = totalCosts(bestIndex, 1);
    bestLineCost = totalCosts(bestIndex, 2);
    bestAreaCost = totalCosts(bestIndex, 3);
end

function [fitness, totalCost, totalLineCost, totalAreaCost] = calculateFitness(arrangement, d1, d2, dAB, lineCost, areaCost)
    % Calculate fitness based on the arrangement
    totalLineCost = 0;
    totalAreaCost = 0;
    overlapPenalty = 1e6; % Large penalty for overlapping rectangles

    % Check for overlaps and calculate total line cost and total area cost
    for i = 1:numel(arrangement)
        for j = i+1:numel(arrangement)
            if isOverlapping(arrangement{i}, arrangement{j})
                totalCost = overlapPenalty; % Penalize heavily for overlap
                fitness = 1 / totalCost; 
                totalLineCost = overlapPenalty; % Assign large values to costs
                totalAreaCost = overlapPenalty;
                return;
            end
        end
    end
    
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
    % Fitness is the inverse of total cost
    fitness = 1 / totalCost;
end

function isOverlap = isOverlapping(rect1, rect2)
    % Check if two rectangles overlap
    x1 = rect1(1);
    y1 = rect1(2);
    w1 = rect1(3);
    h1 = rect1(4);
    
    x2 = rect2(1);
    y2 = rect2(2);
    w2 = rect2(3);
    h2 = rect2(4);
    
    if x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
        isOverlap = true;
    else
        isOverlap = false;
    end
end

function population = initializePopulation(populationSize, geneLength)
    % Randomly initialize the population
    population = randi([0, 1], populationSize, geneLength);
end

function parents = selectParents(population, fitness, numParents)
    [~, sortedIndices] = sort(fitness, 'descend');
    parents = population(sortedIndices(1:numParents), :);
end

function offspring = crossover(parents)
    % Simple one-point crossover
    crossoverPoint = randi(size(parents, 2));
    offspring = parents;
    for i = 1:size(parents, 1)
        if mod(i, 2) == 0
            offspring(i, crossoverPoint:end) = parents(mod(i+1, size(parents, 1))+1, crossoverPoint:end);
        end
    end
end

function mutatedOffspring = mutate(offspring)
    mutationRate = 0.1;
    mutatedOffspring = offspring;
    for i = 1:size(offspring, 1)
        for j = 1:size(offspring, 2)
            if rand < mutationRate
                mutatedOffspring(i, j) = ~mutatedOffspring(i, j);
            end
        end
    end
end

function arrangement = decodeGene(gene, rectA, rectB)
    numA = sum(gene);
    numB = length(gene) - numA;
    arrangement = cell(1, numA + numB);
    index = 1;
    for i = 1:numA
        arrangement{index} = [rand * 100, rand * 100, rectA]; % Random position for demonstration
        index = index + 1;
    end
    for i = 1:numB
        arrangement{index} = [rand * 100, rand * 100, rectB]; % Random position for demonstration
        index = index + 1;
    end
end
