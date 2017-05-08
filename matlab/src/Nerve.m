
	%{
		>>> Nerve® Entry Point:

			La clase principal, la cual permite generar una red neuronal para
			resolver problemas de aproximación de funciones de forma genérica.
	%}

	classdef Nerve

		properties (Constant, Access = public)

			% Archivo de configuración:
			CONFIGURATION_FILENAME = '../nerve.json';
		end

		methods (Static)

			% Función principal:
			function run()

				% Timer global y tiempo acumulado:
				globalTic = tic;

				% Obtener y mostrar configuración:
				config = Configurator.load(Nerve.CONFIGURATION_FILENAME);
				learningRate = config.learningRate;
				Logger.logConfiguration(config);

				% Construir el perceptrón:
				perceptron = Perceptron(config);

				% Pre-procesamiento (para 'bits'):
				config.instances = 2 * config.instances - 1;
				config.targets = 2 * config.targets - 1;

				trainingErrors = [];
				testingErrors = [];

				steps = 0;

				for epoch = 1:config.epochs
					learningRate = perceptron.getLearningRate();

					[trainIndexes, testIndexes] = Nerve ...
						.getIndexes( ...
							size(config.instances, 1), config.trainRatio);

					[trainingInstances, trainingTargets] = Nerve ...
						.getSubset(config, trainIndexes);

					[testingInstances, testingTargets] = Nerve ...
						.getSubset(config, testIndexes);

					% ---------------------------------------------------------

					% Entrenar la red neuronal:
					trainTic = tic;
					results = perceptron.train(trainingInstances, trainingTargets);
					trainingTime = toc(trainTic);

					% Computa el error de entrenamiento actual:
					trainingError = Nerve.E(trainingTargets, results);

					% Predecir los patrones de entrada:
					testTic = tic;
					predictions = perceptron.predict(testingInstances);
					testingTime = toc(testTic);

					% Computa el error de testeo actual:
					testingError = Nerve.E(testingTargets, predictions);

					% Mostrar resultados de la época:
					Logger.logEpoch( ...
						epoch, ...
						config, ...
						trainingTime, ...
						testingTime, ...
						toc(globalTic), ...
						trainingError, ...
						testingError, ...
						learningRate);

					if epoch > 1
						if trainingError < trainingErrors(end)
							steps = steps + 1;
							if steps >= config.minSteps
								perceptron.increaseLearningRate();
							end
						elseif trainingError > trainingErrors(end)
							perceptron.decreaseLearningRate();
							steps = 0;
						end
					end

					trainingErrors = [trainingErrors trainingError];
					testingErrors = [testingErrors testingError];

					% Stopping-criterion:
					if testingError < config.error

						if true == config.graph
							grapher = OutputGrapher(testingInstances,testingTargets);
							grapher.graphCompare(predictions);
						end
						break;
					end
				end

				% Mostrar tiempo de ejecución final:
				Logger.logExecutionTime(toc(globalTic));
				figure;
				plot(1:size(trainingErrors, 2), trainingErrors, 'color', 'r'); hold on;
				plot(1:size(testingErrors, 2), testingErrors, 'color', 'b');
				legend('Training error','Testing error');
			end
		end

		methods (Static, Access = private)

			% Computa la función de costo:
			function error = E(targets, data)

				error = 0.5 * immse(targets, data);
			end

			% Computa una selección aleatoria de índices:
			function [train, test] = getIndexes(instances, trainRatio)

				trainSize = round(instances * trainRatio);
				train = randperm(instances, trainSize);
				test = setdiff(1:instances, train);
			end

			% Genera sub-conjuntos de instancias:
			function [instances, targets] = getSubset(config, indexes)

				instances = config.instances(indexes, :);
				targets = config.targets(indexes, :);
			end
		end
	end
