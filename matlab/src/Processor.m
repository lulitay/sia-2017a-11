
	%{
		>>> Processor Class:

			Permite aplicar un pre-procesamiento sobre un conjunto de
			información, y ofrecer la posibilidad de deshacer el mismo en el
			futuro, siempre y cuando este proceso sea posible.
	%}

	classdef Processor < handle

		properties (Access = protected)

			% Nombre del procesador:
			name;

			% Proceso de transformación:
			process = @(x) x;

			% Proceso inverso (si existe):
			inverse = @(x) x;
		end

		methods (Access = public)

			% Constructor:
			function this = Processor(name)

				this.name = name;
				switch name

					case 'bits'
						this.process = @(x) 2 * x - 1;
						this.inverse = @(x) 0.5 * (x + 1);
					case 'min-max'
						this.process = @Processor.minmax;
						this.inverse = @(x) x;
					otherwise
						this.process = @(x) x;
						this.inverse = @(x) x;
				end
			end

			% Aplica el pre-procesamiento sobre los datos:
			function data = transform(this, data)

				data = this.process(data);
			end

			% Aplica el post-procesamiento (inversa):
			function data = restore(this, data)

				data = this.inverse(data);
			end

			% Nombre del procesador:
			function name = getName(this)

				name = this.name;
			end
		end

		methods (Static, Access = protected)

			% Min-max Normalization:
			function data = minmax(data)

				mins = min(data, [], 1);
				ranges = max(data, [], 1) - mins;
				for k = 1:size(data, 1)

					data(k, :) = 2 * (data(k, :) - mins) ./ ranges - 1;
				end
			end
		end
	end
