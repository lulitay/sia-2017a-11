
	%{
		>>> Configurator Class:

			Permite obtener la configuración del sistema desde un archivo en
			formato JSON, y provee métodos para acceder a ella.

			El parser de JSON se obtuvo desde el repositorio (@link), y se
			corresponde con el paquete de funciones JSON-Lab 1.5, para Matlab.

			@link https://github.com/fangq/jsonlab/releases
	%}

	classdef Configurator < handle

		properties (Access = public)

			% Tasa de aprendizaje:
			learningRate = 0.1;

			% Beta-value:
			beta = 1;

			% Cantidad de entradas:
			inputs = 1;

			% Arquitectura de la red:
			layerSizes = [1];

			% Funciones de activación por capa:
			transfers = {@sign, @(x) 1};

			% Instancias del problema:
			problem = '';

			% Cantidad de entrenamientos:
			epochs = 1;

			% Error máximo admitido:
			error = 1;

			% Predictores:
			instances = [];

			% Objetivos:
			targets = [];

			% Proporción de instancias de entrenamiento:
			trainRatio = 0.75;

			% Momento de inercia de aprendizaje:
			momentum = 0;

			% Inyección de ruido:
			patternNoise = 0;
			weightNoise = 0;

			% Probabilidad de inyectar ruido en patrones:
			injectionProbability = 0;

			% Vanishing Gradient Problem:
			vanishingLimit = 0;

			% Graficar:
			graph = false;
		end

		methods

			% Constructor:
			function this = Configurator(configuration)

				this.learningRate = configuration.learningRate;
				this.beta = configuration.beta;
				this.inputs = configuration.inputs;
				this.layerSizes = configuration.layerSizes;
				this.transfers = TransferFactory.generate(configuration);
				this.problem = configuration.problem;
				this.epochs = configuration.epochs;
				this.error = configuration.error;
				this.trainRatio = configuration.trainRatio;
				this.momentum = configuration.momentum;
				this.injectionProbability = configuration.injectionProbability;
				this.patternNoise = configuration.patternNoise;
				this.weightNoise = configuration.weightNoise;
				this.vanishingLimit = configuration.vanishingLimit;
				this.graph = configuration.graph;

				% Cargar especificación del problema:
				specification = importdata(this.problem);
				this.instances = specification.data(:, 1:this.inputs);
				this.targets = specification.data(:, 1 + this.inputs:end);
			end
		end

		methods (Static)

			% Fábrica de configuradores:
			function configurator = load(filename)

				addpath(genpath('../lib/jsonlab-1.5'));
				configuration = loadjson(filename);
				configurator = Configurator(configuration);
			end
		end
	end
