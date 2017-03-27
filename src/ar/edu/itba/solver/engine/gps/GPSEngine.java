
	package ar.edu.itba.solver.engine.gps;

	import java.util.ArrayList;
	import java.util.Collection;
	import java.util.Comparator;
	import java.util.Deque;
	import java.util.HashMap;
	import java.util.LinkedList;
	import java.util.Map;
	import java.util.PriorityQueue;
	import java.util.Queue;

	import ar.edu.itba.solver.engine.gps.api.GPSProblem;
	import ar.edu.itba.solver.engine.gps.api.GPSRule;
	import ar.edu.itba.solver.engine.gps.api.GPSState;

		/**
		* <p>El motor principal de búsqueda, permite resolver problemas y
		* seleccionar distintas estrategias, tanto informadas como
		* no-informadas.</p>
		*/

	public final class GPSEngine {

		// Open list:
		private final Deque<GPSNode> open
			= new LinkedList<>();

		// Close list:
		private final Map<GPSState, Integer> close
			= new HashMap<>();

		// La estrategia seleccionada:
		private final SearchStrategy strategy;

		// El problema específico a resolver:
		private final GPSProblem problem;

		// Propiedades dinámicas:
		private GPSNode solution	= null;
		private long explosions		= 0;
		private boolean finished	= false;
		private boolean failed		= false;

		public GPSEngine(
				final GPSProblem problem,
				final SearchStrategy strategy) {

			this.problem = problem;
			this.strategy = strategy;
		}

		/**
		* <p>Ejecuta el motor de búsqueda para resolver el problema propuesto,
		* con la estrategia especificada. La búsqueda puede fallar si el
		* problema está mal definido, si no posee solución, si no hay
		* suficiente memoria para retener las estructuras internas, o si la
		* estrategia utilizada no provee <i>completitud</i>.</p>
		*/

		public void findSolution() {

			int maxDepth = 0;
			if (strategy != SearchStrategy.IDDFS)
				maxDepth = Integer.MAX_VALUE;

			while (!finished)
				explore(maxDepth++);
		}

		/**
		* <p>Aplica el proceso de exploración del árbol, bajo una limitación
		* de profundidad máxima, teóricamente inalcanzable cuando el valor es
		* máximo.</p>
		*
		* @param maxDepth
		*	Máxima profundidad de exploración.
		*/

		private void explore(final int maxDepth) {

			close.clear();
			boolean limit = false;
			open.add(new GPSNode(problem.getInitState(), 0));

			while (!open.isEmpty()) {

				final GPSNode node = open.remove();
				final int depth = depth(node);

				if (maxDepth < depth) limit = true;
				if (problem.isGoal(node.getState())) {

					finished = true;
					solution = node;
					return;
				}
				else if (depth <= maxDepth) explode(node);
			}

			if (open.isEmpty() && !limit) {

				failed = true;
				finished = true;
			}
		}

		/**
		* <p>Permite computar la profundidad del nodo, aplicando un recorrido
		* en dirección inversa hacia la raíz del árbol de búsqueda.</p>
		*
		* @param node
		*	El nodo para el cual se calculará la profundidad.
		*
		* @return Devuelve la profundidad a la que se encuentra el nodo. Si el
		*	nodo es raíz, su profundidad es cero.
		*/

		private int depth(final GPSNode node) {

			final GPSNode parent = node.getParent();
			if (parent == null) return 0;
			return 1 + depth(parent);
		}

		/**
		* <p>Explota un nodo en el árbol de búsqueda, lo que implica la
		* aplicación del conjunto de reglas disponibles en el problema
		* planteado, y la generación de nuevos estados, los cuales se agregan
		* a la estructura <i>open list</i> según lo indica la estrategia
		* utilizada.</p>
		*
		* @param node
		*	El nodo a explotar.
		*/

		private void explode(final GPSNode node) {

			final Collection<GPSNode> candidates;
			switch (strategy) {

				case BFS: {

					if (close.containsKey(node.getState())) return;
					candidates = new ArrayList<>();
					addCandidates(node, candidates);
					open.addAll(candidates);
					break;
				}
				case DFS:
				case IDDFS: {

					if (!isBest(node.getState(), node.getCost())) return;
					candidates = new ArrayList<>();
					addCandidates(node, candidates);
					for (final GPSNode n : candidates) open.addFirst(n);
					break;
				}
				case ASTAR: {

					if (!isBest(node.getState(), node.getCost())) return;
				}
				case GREEDY: {

					final PriorityQueue<GPSNode> queue
						= new PriorityQueue<>(
							Comparator.comparing(n -> evaluation(n)));
					addCandidates(node, queue);
					while (!queue.isEmpty()) open.add(queue.remove());
					break;
				}
			}
		}

		/**
		* <p>Aplica la evaluación de todas las reglas a un nodo particular, y
		* genera un nuevo nodo, el cual se agrega a la estructura contenedora
		* ofrecida.</p>
		*
		* @param node
		*	El nodo a explotar. Representa el padre de los nodos generados.
		* @param candidates
		*	La colección en la cual se agregarán los nodos generados.
		*/

		private void addCandidates(
				final GPSNode node,
				final Collection<GPSNode> candidates) {

			++explosions;
			updateBest(node);

			for (final GPSRule rule : problem.getRules())
				rule.evalRule(node.getState())
					.ifPresent(state -> {

					final GPSNode newNode
						= new GPSNode(state, node.getCost() + rule.getCost());

					newNode.setParent(node);
					candidates.add(newNode);
				});
		}

		/**
		* <p>Se encarga de computar la función de evaluación (en general,
		* denotada con <i>f(n)</i>), para un nodo especificado, en función de
		* la estrategia utilizada. En particular, los parámetros empleados
		* representan la función de costo <i>g(n)</i>, y la función de
		* heurística <i>h(n)</i> (solo durante una búsqueda informada).</p>
		*
		* @param node
		*	El nodo sobre el cual computar la función de evaluación.
		*
		* @return Devuelve <i>f(n)</i>, donde <i>n</i> es el nodo
		*	especificado.
		*/

		private int evaluation(final GPSNode node) {

			int evaluation = 0;
			switch (strategy) {

				// f(n) = g(n)
				case BFS:
				case DFS:
				case IDDFS:
					evaluation += node.getCost();
					break;

				// f(n) = g(n) + h(n)
				case ASTAR:
					evaluation += node.getCost();

				// f(n) = h(n)
				case GREEDY:
					final Integer heuristic
						= problem.getHValue(node.getState());
					evaluation += (heuristic != null? heuristic : 0);
					break;
			}
			return evaluation;
		}

		/**
		* <p>Verifica si un estado explorado es nuevo o si el mismo había sido
		* alcanzado previamente, pero con un costo mayor.</p>
		*
		* @param state
		*	El estado a verificar.
		* @param cost
		*	El costo del estado propuesto.
		*
		* @return Devuelve <i>true</i> si el estado es nuevo, o si posee un
		*	costo menor.
		*/

		private boolean isBest(final GPSState state, final Integer cost) {

			return !close.containsKey(state)
					|| cost < close.get(state);
		}

		/**
		* <p>Agrega un nodo a la estructura <i>close list</i>, o actualiza su
		* costo si ya se encontraba en ella.</p>
		*
		* @param node
		*	El nodo a actualizar.
		*/

		private void updateBest(final GPSNode node) {

			close.put(node.getState(), node.getCost());
		}

		/*
		* Getter's
		*/

		public Queue<GPSNode> getOpen() {

			return open;
		}

		public Map<GPSState, Integer> getBestCosts() {

			return close;
		}

		public GPSProblem getProblem() {

			return problem;
		}

		public long getExplosionCounter() {

			return explosions;
		}

		public boolean isFinished() {

			return finished;
		}

		public boolean isFailed() {

			return failed;
		}

		public GPSNode getSolutionNode() {

			return solution;
		}

		public SearchStrategy getStrategy() {

			return strategy;
		}
	}
