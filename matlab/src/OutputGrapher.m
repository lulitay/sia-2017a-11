
	%{
		>>> OutputGrapher Class:

			Grafica ScatterPlots de tres dimensiones			
	%}

	classdef OutputGrapher < handle

		properties (Access = protected)
			x1;
			x2;
			z;			
		end

		methods
			% Constructor
			function this = OutputGrapher(instances,targets)				
				this.x1=instances(:,1);
				this.x2=instances(:,2);
				this.z=targets;
			end			

			function graphSimple(this)
				figure
				scatter3(this.x1,this.x2,this.z);
			end

			function graphCompare(this,outputs)
				this.graphSimple;
				hold on;
				scatter3(this.x1,this.x2,outputs);
				legend('original','predicted');
			end
		end
	end

