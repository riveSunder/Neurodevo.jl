using Neurodevo
using CGP

CGP.Config.init("cfg/cgp/base.yaml")
CGP.Config.init("cfg/cgp/functions.yaml")

function make_chromos!(cfg::Dict)
    chromos = Array{CGP.PCGPChromo}(undef, 10)
    nins = Neurodevo.input_lengths(cfg)
    nouts = Neurodevo.output_lengths(cfg)
    for i in 1:10
        chromos[i] = CGP.PCGPChromo(nins[i], nouts[i])
    end
    cfg["chromosomes"] = chromos
    chromos
end

function make_chromos!(cfg::Dict, genes::Array{Array{Float64}})
    chromos = Array{CGP.PCGPChromo}(undef, 10)
    nins = Neurodevo.input_lengths(cfg)
    nouts = Neurodevo.output_lengths(cfg)
    for i in 1:10
        chromos[i] = CGP.PCGPChromo(genes[i], nins[i], nouts[i])
    end
    cfg["chromosomes"] = chromos
    chromos
end

function make_controller(cfg::Dict)
    chromos = cfg["chromosomes"]
    cell_division(x::Array{Float64}) = process(chromos[1], x)[1] > 0
    new_cell_params(x::Array{Float64}) = process(chromos[2], x)
    cell_death(x::Array{Float64}) = process(chromos[3], x)[1] > 0
    cell_state_update(x::Array{Float64}) = process(chromos[4], x)
    cell_param_update(x::Array{Float64}) = process(chromos[5], x)
    connect(x::Array{Float64}) = process(chromos[6], x)[1] > 0
    new_conn_params(x::Array{Float64}) = process(chromos[7], x)
    disconnect(x::Array{Float64}) = process(chromos[8], x)[1] > 0
    conn_state_update(x::Array{Float64}) = process(chromos[9], x)
    conn_param_update(x::Array{Float64}) = process(chromos[10], x)

    Controller(cell_division, new_cell_params, cell_death,
               cell_state_update, cell_param_update,
               connect, new_conn_params, disconnect,
               conn_state_update, conn_param_update)
end

function cgp_controller(cfg::Dict)
    make_chromos!(cfg)
    make_controller(cfg)
end

function cgp_controller(cfg::Dict, genes::Array{Array{Float64}})
    make_chromos!(cfg, genes)
    make_controller(cfg)
end
