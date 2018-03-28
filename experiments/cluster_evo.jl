using ArgParse
using CGP
using YAML
include("clustering.jl")
include("datasets.jl")
include("seeds.jl")

settings = ArgParseSettings()
@add_arg_table settings begin
    "--seed"
    arg_type = Int
    default = 0
    "--expert"
    arg_type = String
    default = ""
    "--logfile"
    arg_type = String
    default = "stdp.log"
end

args = parse_args(settings)
srand(args["seed"])
Logging.configure(filename=args["logfile"], level=INFO)

CGP.Config.init("cfg/base.yaml")
CGP.Config.init("cfg/functions.yaml")
scfg = YAML.load_file("cfg/stdp.yaml")
fname = string(args["seed"])

problems = ["iris", "spirals"]
data = Dict()
for p in problems
    X, Y = get_data(p)
    dp = Dict()
    dp[:X] = X
    dp[:Y] = Y
    data[p] = dp
end

test_problem = "yeast"
test_X, test_Y = get_data("yeast")
counter = [0]

function cluster_acc(c::Chromosome, X::Array{Float64}, Y::Array{Int64},
                     pname::String)
    n_cluster = length(unique(Y))
    nfunc = i->process(c, i)
    stdp_labels = stdp_cluster(
        X, Y, n_cluster, nfunc; seed=0, logfile=args["logfile"], problem=pname,
        fname=fname, train_epochs=scfg["train_epochs"],
        weight_mean=scfg["weight_mean"], weight_std=scfg["weight_std"],
        t_train=scfg["t_train"], t_blank=scfg["t_blank"], fr=scfg["fr"],
        pre_target=scfg["pre_target"], stdp_lr=scfg["stdp_lr"],
        stdp_mu=scfg["stdp_mu"], inhib_weight=scfg["inhib_weight"])
    acc = randindex(stdp_labels, Y)
    acc[1]
end

function cluster_fit(c::Chromosome)
    counter[1] += 1
    if counter[1] < 75
        p = "iris"
        return cluster_acc(c, data[p][:X], data[p][:Y], p)
    elseif counter[1] < 150
        p = "spirals"
        return 1.0 + cluster_acc(c, data[p][:X], data[p][:Y], p)
    end
    fit = 0.0
    for p in problems
        fit += cluster_acc(c, data[p][:X], data[p][:Y], p)
    end
    fit /= length(problems)
    return 2.0 + fit
end

function gen_fit(c::Chromosome)
    if counter[1] < 150
        return 0.0
    else
        return cluster_acc(c, test_X, test_Y, test_problem)
    end
end

expert = nothing
if args["expert"] == "LIF"
    expert = to_chromo(lif_graph(-0.65, 0.3))
end

maxfit, best = oneplus(PCGPChromo, 5, 5, cluster_fit; seed=args["seed"],
                       record_best=true, record_fitness=gen_fit, expert=expert)
Logging.info(@sprintf("E%0.6f", -maxfit))
