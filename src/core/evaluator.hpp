#ifndef EVALUATOR_HPP
#define EVALUATOR_HPP
#include "../external/grgen/common.h"
#include "../external/gaga/gaga/gaga.hpp"
#include "config.hpp"
#include "types.hpp"
#include "Environment.h"
#include <random>

using std::vector;
using std::map;

template <class Problem> class Evaluator {
  friend Problem;

public:
  //using Environment = Types::EnvironmentType;
  using dna_t = Types::DNAType;
  using d2 = vector<vector<double>>;

protected:
  d2 inputs;
  d2 outputs;
  vector<double> history;
  map<string, double> fitnesses;

public:
  void evaluate(Problem problem, dna_t dna, int iter) {
    Environment env({Config::X_SIZE, Config::Y_SIZE, Config::Z_SIZE}, dna, iter);
    env.set_random_connectivity();
    while(!problem.stop()) {
      problem.setInputs(&inputs);

      env.develop_grns(problem.getReward());

      env.set_nt_concentration(inputs);

      env.axon_actions();

      env.fire_ann();

      env.set_outputs(&outputs);

      problem.step(&outputs);
    }
    problem.setFootprint(&history);
    problem.setFitness(&fitnesses);
  };

  const map<string, double> *getFitnesses() { return &fitnesses; }
  const vector<double> *getHistory() { return &history; }
};
#endif
