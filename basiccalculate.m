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
generations = 200;
optimizedPackingGA(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost, populationSize, generations);

function optimizedPackingGA(rectA, rectB, d1, d2, dAB, numA, numB, lineCost, areaCost, populationSize, generations)
    % Define gene encoding: Each gene represents a rectangle
    geneLength = numA + numB;
    
    % Generate initial population
    population = initializePopulation(populationSize, geneLength);
    
    % Evolve the population through generations
    for gen = 1:generations
        % Evaluate fitness
        fitness = evaluateFitness(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost);
        
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
    bestSolution = selectBestSolution(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost);
    
    % Display the best solution
    disp('Best solution:');
    disp(bestSolution);
end

function population = initializePopulation(populationSize, geneLength)
    % Randomly initialize the population
    population = randi([0, 1], populationSize, geneLength);
end

function fitness = evaluateFitness(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost)
    fitness = zeros(size(population, 1), 1);
    for i = 1:size(population, 1)
        % Decode the gene to obtain the arrangement of rectangles
        arrangement = decodeGene(population(i, :), rectA, rectB);
        
        % Calculate the fitness based on the arrangement
        fitness(i) = calculateFitness(arrangement, d1, d2, dAB, lineCost, areaCost);
    end
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

function bestSolution = selectBestSolution(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost)
    fitness = evaluateFitness(population, rectA, rectB, d1, d2, dAB, lineCost, areaCost);
    [~, bestIndex] = max(fitness);
    bestSolution = decodeGene(population(bestIndex, :), rectA, rectB);
end

function arrangement = decodeGene(gene, rectA, rectB)
    numA = sum(gene);
    numB = length(gene) - numA;
    arrangement = {};
    index = 1;
    for i = 1:numA
        arrangement{i} = rectA;
        index = index + 1;
    end
    for i = 1:numB
        arrangement{index} = rectB;
        index = index + 1;
    end
end

function fitness = calculateFitness(arrangement, d1, d2, dAB, lineCost, areaCost)
    % Calculate fitness based on the arrangement
    % You can use your existing cost calculation method here
    fitness = 0; % Initialize fitness value
    % Your fitness calculation code goes here
end

%% 